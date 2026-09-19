import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'geo_utils.dart';
import 'geocoding_service.dart';
import 'location_service.dart';

/// Services shared by every map screen.
final locationServiceProvider = Provider<LocationService>((_) => const LocationService());
final geocodingServiceProvider = Provider<GeocodingService>((_) => GeocodingService());

/// The last spot the user put the pin on, keyed by which picker asked. Kept
/// outside the widget tree so backgrounding the app, a process restart of
/// the route, or an accidental back-swipe doesn't lose the selection.
class LocationDraftNotifier extends Notifier<Map<String, PickedLocation>> {
  @override
  Map<String, PickedLocation> build() => const {};

  void save(String key, PickedLocation location) => state = {...state, key: location};

  void clear(String key) => state = {...state}..remove(key);

  PickedLocation? of(String key) => state[key];
}

final locationDraftProvider =
    NotifierProvider<LocationDraftNotifier, Map<String, PickedLocation>>(LocationDraftNotifier.new);
