import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import 'geo_utils.dart';
import 'map_config.dart';

class GeocodeResult {
  final LatLng point;
  final String displayName;

  /// Short label: neighbourhood / suburb / city, for `area_label`.
  final String areaLabel;

  const GeocodeResult({required this.point, required this.displayName, required this.areaLabel});
}

enum GeocodeErrorKind { network, rateLimited, empty, invalid }

class GeocodeException implements Exception {
  final GeocodeErrorKind kind;
  final String message;
  const GeocodeException(this.kind, this.message);
  @override
  String toString() => message;
}

/// Nominatim (OSM) forward + reverse geocoding.
///
/// Nominatim's policy: at most 1 request/second, identify yourself with a
/// User-Agent, and cache. So: a small LRU cache, a minimum gap between
/// calls, and exponential backoff on 429 — the picker adds its own 500 ms
/// input debounce on top.
class GeocodingService {
  final Dio _dio;
  final _forwardCache = <String, List<GeocodeResult>>{};
  final _reverseCache = <String, GeocodeResult?>{};
  DateTime _lastCall = DateTime.fromMillisecondsSinceEpoch(0);
  int _backoffLevel = 0;
  static const _cacheLimit = 60;

  GeocodingService([Dio? dio])
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: MapConfig.nominatimUrl,
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 8),
              headers: {
                'User-Agent': MapConfig.userAgent,
                'Accept': 'application/json',
                // Latin-script place names; Nominatim otherwise returns the
                // local script (Urdu for Karachi).
                'Accept-Language': 'en',
              },
              validateStatus: (_) => true,
            ));

  Future<List<GeocodeResult>> search(String query, {LatLng? near, int limit = 6}) async {
    final q = query.trim();
    if (q.length < 3) return const [];
    final key = '${q.toLowerCase()}|${near?.latitude.toStringAsFixed(1)},${near?.longitude.toStringAsFixed(1)}';
    final cached = _forwardCache[key];
    if (cached != null) return cached;

    final data = await _get('/search', {
      'q': q,
      'format': 'jsonv2',
      'accept-language': 'en',
      'limit': limit,
      'addressdetails': 1,
      if (near != null) ...{
        // Bias, don't restrict: a viewbox around the user's area.
        'viewbox': '${near.longitude - 0.5},${near.latitude + 0.5},${near.longitude + 0.5},${near.latitude - 0.5}',
      },
    });
    if (data is! List) throw const GeocodeException(GeocodeErrorKind.invalid, 'Unexpected response');
    final results = <GeocodeResult>[];
    for (final item in data) {
      final r = _parse(item);
      if (r != null) results.add(r);
    }
    if (results.isEmpty) {
      throw const GeocodeException(GeocodeErrorKind.empty, 'No places match that search');
    }
    _remember(_forwardCache, key, results);
    return results;
  }

  /// Human address for a point. Returns null (never throws) when the service
  /// can't answer — the caller falls back to the raw area label.
  Future<GeocodeResult?> reverse(LatLng point) async {
    if (!GeoUtils.isValidCoordinate(point.latitude, point.longitude)) return null;
    final key = '${point.latitude.toStringAsFixed(4)},${point.longitude.toStringAsFixed(4)}';
    if (_reverseCache.containsKey(key)) return _reverseCache[key];
    try {
      final data = await _get('/reverse', {
        'lat': point.latitude,
        'lon': point.longitude,
        'format': 'jsonv2',
        'accept-language': 'en',
        'zoom': 16,
        'addressdetails': 1,
      });
      final result = data is Map ? _parse(data) : null;
      _remember(_reverseCache, key, result);
      return result;
    } on GeocodeException catch (e) {
      debugPrint('[geocode] reverse failed: ${e.message}');
      return null;
    }
  }

  Future<dynamic> _get(String path, Map<String, dynamic> query) async {
    // Respect the 1 req/s policy plus any backoff a 429 asked for.
    final minGap = Duration(milliseconds: 1000 * (1 << _backoffLevel));
    final wait = minGap - DateTime.now().difference(_lastCall);
    if (wait > Duration.zero) await Future<void>.delayed(wait);
    _lastCall = DateTime.now();

    Response<dynamic> res;
    try {
      res = await _dio.get<dynamic>(path, queryParameters: query);
    } on DioException catch (e) {
      throw GeocodeException(
        GeocodeErrorKind.network,
        e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout
            ? 'Address lookup timed out'
            : 'No connection for address lookup',
      );
    }
    if (res.statusCode == 429 || res.statusCode == 503) {
      _backoffLevel = (_backoffLevel + 1).clamp(0, 4); // up to 16 s between calls
      throw const GeocodeException(GeocodeErrorKind.rateLimited, 'Address service is busy — try again in a moment');
    }
    if (res.statusCode != 200) {
      throw GeocodeException(GeocodeErrorKind.network, 'Address lookup failed (${res.statusCode})');
    }
    _backoffLevel = 0;
    return res.data;
  }

  GeocodeResult? _parse(dynamic item) {
    if (item is! Map) return null;
    final lat = double.tryParse(item['lat']?.toString() ?? '');
    final lon = double.tryParse(item['lon']?.toString() ?? '');
    if (!GeoUtils.isValidCoordinate(lat, lon)) return null;
    final display = item['display_name']?.toString() ?? '';
    final address = item['address'];
    String area = '';
    if (address is Map) {
      for (final k in const ['neighbourhood', 'suburb', 'quarter', 'town', 'village', 'city_district', 'city', 'county', 'state']) {
        final v = address[k]?.toString();
        if (v != null && v.isNotEmpty) {
          area = area.isEmpty ? v : '$area, $v';
          if (area.split(',').length >= 2) break;
        }
      }
    }
    if (area.isEmpty) area = display.split(',').take(2).map((s) => s.trim()).join(', ');
    return GeocodeResult(point: LatLng(lat!, lon!), displayName: display, areaLabel: area);
  }

  void _remember<T>(Map<String, T> cache, String key, T value) {
    cache[key] = value;
    if (cache.length > _cacheLimit) cache.remove(cache.keys.first);
  }
}
