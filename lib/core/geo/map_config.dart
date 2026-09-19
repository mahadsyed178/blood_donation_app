import 'package:latlong2/latlong.dart';

import 'geo_utils.dart';

/// OpenStreetMap settings. The public OSM tile server is fine for a pilot;
/// point `OSM_TILE_URL` at your own tile host (or a provider like MapTiler /
/// Stadia with your key in the URL) before scaling, per OSM's usage policy.
class MapConfig {
  MapConfig._();

  static const String tileUrl = String.fromEnvironment(
    'OSM_TILE_URL',
    defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  );

  /// Required by the OSM tile usage policy and by Nominatim.
  static const String userAgent = 'BloodBridge/1.0 (com.example.blood_donation_app)';

  static const String nominatimUrl = String.fromEnvironment(
    'NOMINATIM_URL',
    defaultValue: 'https://nominatim.openstreetmap.org',
  );

  static const String attribution = '© OpenStreetMap contributors';

  /// Where the camera starts before any fix or pick: Karachi.
  static const LatLng defaultCenter = LatLng(24.8607, 67.0011);
  static const double defaultZoom = 12;
  static const double pickZoom = 16;
  static const double maxZoom = 19;

  /// Radius of the shaded circle on approximate-location maps, matching the
  /// backend's 300–500 m fuzz band so the true point is always inside it.
  static const double approximateRadiusMetres = 600;

  static const ServiceArea serviceArea = ServiceArea(
    name: 'Karachi pilot area',
    center: LatLng(24.8607, 67.0011),
    radiusKm: 60,
  );
}
