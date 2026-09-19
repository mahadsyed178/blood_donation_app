import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

/// A captured location. [displayAddress] is human text (from reverse
/// geocoding or typed by the user), never a coordinate string.
class PickedLocation {
  final double latitude;
  final double longitude;
  final String? displayAddress;

  const PickedLocation({
    required this.latitude,
    required this.longitude,
    this.displayAddress,
  });

  LatLng get latLng => LatLng(latitude, longitude);

  bool get isValid => GeoUtils.isValidCoordinate(latitude, longitude);

  PickedLocation copyWith({String? displayAddress}) => PickedLocation(
        latitude: latitude,
        longitude: longitude,
        displayAddress: displayAddress ?? this.displayAddress,
      );
}

class GeoUtils {
  GeoUtils._();

  static const double earthRadiusKm = 6371.0088;

  /// Great-circle distance in km.
  static double haversineKm(double lat1, double lng1, double lat2, double lng2) {
    final dLat = _rad(lat2 - lat1);
    final dLng = _rad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(lat1)) * math.cos(_rad(lat2)) * math.sin(dLng / 2) * math.sin(dLng / 2);
    return earthRadiusKm * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static double distanceKm(LatLng a, LatLng b) =>
      haversineKm(a.latitude, a.longitude, b.latitude, b.longitude);

  /// "~350 m", "~3.2 km", "~14 km". Always approximate, never a coordinate.
  static String formatDistance(double km) {
    if (km < 0.95) return '~${((km * 1000) / 50).round() * 50} m';
    if (km < 10) return '~${km.toStringAsFixed(1)} km';
    return '~${km.round()} km';
  }

  /// Rejects null island, out-of-range values and NaN — the values a broken
  /// GPS fix or an empty geocode result would otherwise hand us.
  static bool isValidCoordinate(double? lat, double? lng) {
    if (lat == null || lng == null) return false;
    if (lat.isNaN || lng.isNaN || lat.isInfinite || lng.isInfinite) return false;
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return false;
    if (lat.abs() < 0.0001 && lng.abs() < 0.0001) return false; // 0,0
    return true;
  }

  /// Client-side twin of the backend's privacy offset: shifts a point
  /// 300–500 m in a direction derived from [seed], so repeated renders show
  /// the same approximate spot. Use only when exact coordinates for someone
  /// *else* somehow reach the client (the backend already fuzzes its own).
  static LatLng approximate(LatLng exact, {required String seed}) {
    final h = seed.hashCode;
    final angle = ((h & 0xFFFF) / 0xFFFF) * 2 * math.pi;
    final metres = 300 + (((h >> 16) & 0xFFFF) / 0xFFFF) * 200;
    const metresPerDegLat = 111320.0;
    final dLat = metres * math.cos(angle) / metresPerDegLat;
    final cosLat = math.max(math.cos(_rad(exact.latitude)), 0.01);
    final dLng = metres * math.sin(angle) / (metresPerDegLat * cosLat);
    return LatLng(exact.latitude + dLat, exact.longitude + dLng);
  }

  static double _rad(double deg) => deg * math.pi / 180;
}

/// The pilot geography. Points outside get an inline warning in the picker
/// but are still allowed — the platform has no hard business rule yet.
class ServiceArea {
  final String name;
  final LatLng center;
  final double radiusKm;
  const ServiceArea({required this.name, required this.center, required this.radiusKm});

  bool contains(LatLng p) => GeoUtils.distanceKm(center, p) <= radiusKm;
}
