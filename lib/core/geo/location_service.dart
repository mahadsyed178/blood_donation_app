import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'geo_utils.dart';

/// Every way a one-shot GPS fix can end, so the UI can explain each one
/// instead of showing a generic failure.
enum LocationFixStatus {
  ok,
  servicesDisabled,
  permissionDenied,
  permissionDeniedForever,
  timeout,
  invalidFix,
  failed,
}

class LocationFix {
  final LocationFixStatus status;
  final LatLng? point;
  const LocationFix(this.status, [this.point]);

  bool get ok => status == LocationFixStatus.ok && point != null;

  String get message => switch (status) {
        LocationFixStatus.ok => 'Location found',
        LocationFixStatus.servicesDisabled =>
          'Location services are turned off. Turn them on, or drop the pin by hand.',
        LocationFixStatus.permissionDenied =>
          'Location permission was denied. You can still search for an address or tap the map.',
        LocationFixStatus.permissionDeniedForever =>
          'Location permission is blocked. Enable it in Settings, or search / tap the map instead.',
        LocationFixStatus.timeout =>
          'Couldn’t get a GPS fix in time. Try again, or tap the map to place the pin.',
        LocationFixStatus.invalidFix =>
          'The GPS fix looked wrong. Try again, or tap the map to place the pin.',
        LocationFixStatus.failed =>
          'Couldn’t read your location. Search for an address or tap the map instead.',
      };
}

/// Thin wrapper over geolocator: one call, one clear outcome. Deliberately
/// no streaming — the PRD rules out live tracking.
class LocationService {
  const LocationService();

  Future<LocationFix> getCurrentFix({Duration timeout = const Duration(seconds: 15)}) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LocationFix(LocationFixStatus.servicesDisabled);
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        return const LocationFix(LocationFixStatus.permissionDeniedForever);
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.unableToDetermine) {
        return const LocationFix(LocationFixStatus.permissionDenied);
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(accuracy: LocationAccuracy.high, timeLimit: timeout),
      ).timeout(timeout + const Duration(seconds: 2));

      if (!GeoUtils.isValidCoordinate(position.latitude, position.longitude)) {
        return const LocationFix(LocationFixStatus.invalidFix);
      }
      return LocationFix(LocationFixStatus.ok, LatLng(position.latitude, position.longitude));
    } on TimeoutException {
      return const LocationFix(LocationFixStatus.timeout);
    } on LocationServiceDisabledException {
      return const LocationFix(LocationFixStatus.servicesDisabled);
    } on PermissionDeniedException {
      return const LocationFix(LocationFixStatus.permissionDenied);
    } catch (_) {
      return const LocationFix(LocationFixStatus.failed);
    }
  }

  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();
  Future<bool> openAppSettings() => Geolocator.openAppSettings();
}
