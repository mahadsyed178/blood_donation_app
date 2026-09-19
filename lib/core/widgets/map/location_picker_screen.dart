import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../geo/geo_utils.dart';
import '../../geo/geocoding_service.dart';
import '../../geo/location_draft_provider.dart';
import '../../geo/location_service.dart';
import '../../geo/map_config.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../app_button.dart';
import '../feedback.dart';
import 'osm_map.dart';

/// Full-screen OpenStreetMap location picker.
///
/// Search (Nominatim, debounced 500 ms, cached, 429-backoff) · use current
/// location (GPS with every failure explained, never blocking) · tap
/// anywhere to drop the pin · drag the map under a centre pin · confirm.
/// Resolves with a [PickedLocation]; the confirm button is disabled until
/// the pin is on a valid coordinate.
///
/// [draftKey] preserves the selection if the app is backgrounded or the
/// route is left and re-entered. [onConfirm], when given, runs before the
/// screen pops (used to save a donor's location) and may throw to keep the
/// screen open.
class LocationPickerScreen extends ConsumerStatefulWidget {
  final String title;
  final String draftKey;
  final PickedLocation? initial;
  final String confirmLabel;
  final String pinLabel;
  final Future<void> Function(PickedLocation location)? onConfirm;

  /// Rendered inside a tab shell: no AppBar, no pop after confirm.
  final bool embedded;

  const LocationPickerScreen({
    super.key,
    required this.title,
    required this.draftKey,
    this.initial,
    this.confirmLabel = 'Confirm location',
    this.pinLabel = 'Selected location',
    this.onConfirm,
    this.embedded = false,
  });

  @override
  ConsumerState<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends ConsumerState<LocationPickerScreen>
    with WidgetsBindingObserver {
  final _map = MapController();
  final _health = TileHealth();
  final _search = TextEditingController();
  final _searchFocus = FocusNode();

  LatLng? _pin;
  String? _address;
  bool _addressLoading = false;
  bool _mapReady = false;
  int _pinVersion = 0;

  bool _locating = false;
  bool _confirming = false;
  String? _fixMessage;
  LocationFixStatus? _fixStatus;

  Timer? _debounce;
  int _searchSeq = 0;
  List<GeocodeResult> _results = const [];
  bool _searching = false;
  String? _searchError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final draft = ref.read(locationDraftProvider.notifier).of(widget.draftKey);
    final start = widget.initial ?? draft;
    if (start != null && start.isValid) {
      _pin = start.latLng;
      _address = start.displayAddress;
    } else {
      // No pin yet: try GPS, but the map stays usable whatever happens.
      WidgetsBinding.instance.addPostFrameCallback((_) => _useCurrentLocation(silent: true));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounce?.cancel();
    _search.dispose();
    _searchFocus.dispose();
    _map.dispose();
    _health.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) _saveDraft();
  }

  void _saveDraft() {
    final p = _pin;
    if (p == null) return;
    ref.read(locationDraftProvider.notifier).save(
          widget.draftKey,
          PickedLocation(latitude: p.latitude, longitude: p.longitude, displayAddress: _address),
        );
  }

  // --- Pin -------------------------------------------------------------------

  void _placePin(LatLng point, {bool move = true, double? zoom}) {
    if (!GeoUtils.isValidCoordinate(point.latitude, point.longitude)) {
      showSnack(context, 'That spot isn’t a valid location — try again.', isError: true);
      return;
    }
    setState(() {
      _pin = point;
      _pinVersion++;
      _address = null;
    });
    if (move && _mapReady) _map.move(point, zoom ?? _map.camera.zoom);
    _saveDraft();
    _reverseGeocode(point);
  }

  Future<void> _reverseGeocode(LatLng point) async {
    setState(() => _addressLoading = true);
    final result = await ref.read(geocodingServiceProvider).reverse(point);
    if (!mounted || _pin != point) return;
    setState(() {
      _addressLoading = false;
      // Fallback: no address text; the confirm sheet will show the area only.
      _address = result?.areaLabel.isNotEmpty == true ? result!.areaLabel : null;
    });
    _saveDraft();
  }

  // --- GPS -------------------------------------------------------------------

  Future<void> _useCurrentLocation({bool silent = false}) async {
    if (_locating) return; // debounce rapid taps
    setState(() {
      _locating = true;
      _fixMessage = null;
    });
    final fix = await ref.read(locationServiceProvider).getCurrentFix();
    if (!mounted) return;
    setState(() {
      _locating = false;
      _fixStatus = fix.status;
      _fixMessage = fix.ok ? null : fix.message;
    });
    if (fix.ok) {
      _placePin(fix.point!, zoom: MapConfig.pickZoom);
    } else if (!silent) {
      _explainFix(fix);
    }
  }

  Future<void> _explainFix(LocationFix fix) async {
    final svc = ref.read(locationServiceProvider);
    final action = switch (fix.status) {
      LocationFixStatus.servicesDisabled => ('Turn on location', svc.openLocationSettings),
      LocationFixStatus.permissionDeniedForever => ('Open settings', svc.openAppSettings),
      LocationFixStatus.permissionDenied => ('Try again', () async {
          await _useCurrentLocation();
          return true;
        }),
      _ => null,
    };
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Location unavailable'),
        content: Text('${fix.message}\n\nYou can search for an address above, or tap anywhere on the map to place the pin.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Use the map')),
          if (action != null)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                action.$2();
              },
              child: Text(action.$1),
            ),
        ],
      ),
    );
  }

  // --- Search ----------------------------------------------------------------

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 3) {
      setState(() {
        _results = const [];
        _searchError = null;
        _searching = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () => _runSearch(value));
  }

  Future<void> _runSearch(String value) async {
    final seq = ++_searchSeq;
    setState(() {
      _searching = true;
      _searchError = null;
    });
    try {
      final results = await ref
          .read(geocodingServiceProvider)
          .search(value, near: _pin ?? MapConfig.defaultCenter);
      if (!mounted || seq != _searchSeq) return;
      setState(() => _results = results);
    } on GeocodeException catch (e) {
      if (!mounted || seq != _searchSeq) return;
      setState(() {
        _results = const [];
        _searchError = e.message;
      });
    } finally {
      if (mounted && seq == _searchSeq) setState(() => _searching = false);
    }
  }

  void _selectResult(GeocodeResult r) {
    _searchFocus.unfocus();
    _search.text = r.areaLabel;
    setState(() {
      _results = const [];
      _searchError = null;
    });
    _placePin(r.point, zoom: MapConfig.pickZoom);
    setState(() => _address = r.areaLabel);
  }

  // --- Confirm ---------------------------------------------------------------

  Future<void> _confirm() async {
    final p = _pin;
    if (p == null || _confirming) return;
    if (!GeoUtils.isValidCoordinate(p.latitude, p.longitude)) {
      showSnack(context, 'Pick a valid spot on the map first.', isError: true);
      return;
    }
    final outside = !MapConfig.serviceArea.contains(p);
    if (outside) {
      final ok = await confirmDialog(
        context,
        title: 'Outside the pilot area',
        message:
            'This spot is outside the ${MapConfig.serviceArea.name}. Matching works best inside it — use it anyway?',
        confirmLabel: 'Use anyway',
      );
      if (!ok) return;
    }
    setState(() => _confirming = true);
    final picked = PickedLocation(latitude: p.latitude, longitude: p.longitude, displayAddress: _address);
    try {
      if (widget.onConfirm != null) await widget.onConfirm!(picked);
      if (!mounted) return;
      ref.read(locationDraftProvider.notifier).clear(widget.draftKey);
      if (!widget.embedded) context.pop(picked);
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  // --- UI --------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final pin = _pin;
    final outside = pin != null && !MapConfig.serviceArea.contains(pin);

    final map = FlutterMap(
      mapController: _map,
      options: MapOptions(
        initialCenter: pin ?? MapConfig.defaultCenter,
        initialZoom: pin != null ? MapConfig.pickZoom : MapConfig.defaultZoom,
        minZoom: 3,
        maxZoom: MapConfig.maxZoom,
        backgroundColor: const Color(0xFFE8ECF1),
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
        onMapReady: () => setState(() => _mapReady = true),
        onTap: (_, point) {
          _searchFocus.unfocus();
          _placePin(point, move: false);
        },
        onLongPress: (_, point) => _placePin(point, move: false),
      ),
      children: [
        osmTileLayer(health: _health),
        if (pin != null)
          MarkerLayer(
            markers: [
              Marker(
                point: pin,
                width: 48,
                height: 48,
                alignment: Alignment.topCenter,
                child: AnimatedPin(animationKey: ValueKey(_pinVersion)),
              ),
            ],
          ),
        const OsmAttribution(),
      ],
    );

    final body = Stack(
      children: [
        Positioned.fill(child: map),
        // Search
        Positioned(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.md,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SearchBar(
                controller: _search,
                focusNode: _searchFocus,
                searching: _searching,
                onChanged: _onSearchChanged,
                onClear: () {
                  _search.clear();
                  _onSearchChanged('');
                },
              ),
              if (_results.isNotEmpty || _searchError != null)
                _SearchResults(
                  results: _results,
                  error: _searchError,
                  onSelect: _selectResult,
                  onRetry: () => _runSearch(_search.text),
                ),
              if (_fixMessage != null && _results.isEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                _InlineNotice(
                  icon: Icons.location_off_rounded,
                  text: _fixMessage!,
                  actionLabel: _fixStatus == LocationFixStatus.permissionDeniedForever
                      ? 'Settings'
                      : 'Details',
                  onAction: () => _explainFix(LocationFix(_fixStatus ?? LocationFixStatus.failed)),
                  onClose: () => setState(() => _fixMessage = null),
                ),
              ],
              if (outside) ...[
                const SizedBox(height: AppSpacing.sm),
                _InlineNotice(
                  icon: Icons.warning_amber_rounded,
                  color: AppColors.amber,
                  text: 'Outside the ${MapConfig.serviceArea.name} — matching may not find donors here.',
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: AppRadius.mdAll,
                child: TileOfflineBanner(health: _health, onRetry: () => setState(() {})),
              ),
            ],
          ),
        ),
        // GPS button
        Positioned(
          right: AppSpacing.lg,
          bottom: AppSpacing.lg,
          child: _RoundAction(
            tooltip: 'Use current location',
            icon: Icons.my_location_rounded,
            busy: _locating,
            onTap: () => _useCurrentLocation(),
          ),
        ),
        if (pin == null && !_locating)
          Positioned(
            left: AppSpacing.lg,
            right: 80,
            bottom: AppSpacing.lg,
            child: _InlineNotice(
              icon: Icons.touch_app_rounded,
              text: 'Tap anywhere on the map to drop the pin, or search above.',
            ),
          ),
      ],
    );

    final bottom = BottomActionBar(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SelectedSummary(pin: pin, address: _address, loading: _addressLoading, pinLabel: widget.pinLabel),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: widget.confirmLabel,
            icon: Icons.check_rounded,
            enabled: pin != null,
            busy: _confirming,
            onPressed: pin == null ? null : _confirm,
          ),
        ],
      ),
    );

    if (widget.embedded) {
      return Scaffold(body: body, bottomNavigationBar: bottom);
    }
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: body,
      bottomNavigationBar: bottom,
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool searching;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.searching,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) => Material(
        elevation: 3,
        shadowColor: Colors.black26,
        borderRadius: AppRadius.lgAll,
        child: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) => TextField(
            controller: controller,
            focusNode: focusNode,
            onChanged: onChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search area, street or hospital',
              prefixIcon: const Icon(Icons.search_rounded),
              fillColor: Colors.white,
              suffixIcon: searching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : value.text.isEmpty
                      ? null
                      : AppIconButton(icon: Icons.close_rounded, tooltip: 'Clear search', onPressed: onClear, size: 18),
            ),
          ),
        ),
      );
}

class _SearchResults extends StatelessWidget {
  final List<GeocodeResult> results;
  final String? error;
  final ValueChanged<GeocodeResult> onSelect;
  final VoidCallback onRetry;
  const _SearchResults({required this.results, this.error, required this.onSelect, required this.onRetry});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 6),
        constraints: const BoxConstraints(maxHeight: 260),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.lgAll,
          boxShadow: AppShadows.card,
          border: Border.all(color: AppColors.borderGrey),
        ),
        child: error != null
            ? Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    const Icon(Icons.search_off_rounded, color: AppColors.textGrey, size: 18),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text(error!, style: AppText.bodySmall)),
                    TextButton(onPressed: onRetry, child: const Text('Retry')),
                  ],
                ),
              )
            : ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: results.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (_, i) {
                  final r = results[i];
                  return ListTile(
                    leading: const Icon(Icons.place_outlined, color: AppColors.primaryRed),
                    title: Text(r.areaLabel, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.title),
                    subtitle: Text(r.displayName, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.caption),
                    onTap: () => onSelect(r),
                  );
                },
              ),
      );
}

class _SelectedSummary extends StatelessWidget {
  final LatLng? pin;
  final String? address;
  final bool loading;
  final String pinLabel;
  const _SelectedSummary({required this.pin, required this.address, required this.loading, required this.pinLabel});

  @override
  Widget build(BuildContext context) {
    final hasPin = pin != null;
    return Row(
      children: [
        Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: hasPin ? AppColors.lightPink : AppColors.bgGrey,
            shape: BoxShape.circle,
          ),
          child: Icon(hasPin ? Icons.place_rounded : Icons.place_outlined,
              color: hasPin ? AppColors.primaryRed : AppColors.textGrey),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(hasPin ? pinLabel : 'No location selected', style: AppText.label),
              const SizedBox(height: 2),
              AnimatedSwitcher(
                duration: AppDurations.fast,
                child: loading
                    ? const Text('Finding the area name…', key: ValueKey('l'), style: AppText.caption)
                    : Text(
                        !hasPin
                            ? 'Search, tap the map, or use your current location.'
                            : address ?? 'Area name unavailable — you can type it on the next step.',
                        key: ValueKey(address ?? hasPin),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.bodySmall,
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RoundAction extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final bool busy;
  final VoidCallback onTap;
  const _RoundAction({required this.tooltip, required this.icon, required this.busy, required this.onTap});

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.white,
          shape: const CircleBorder(),
          elevation: 4,
          shadowColor: Colors.black26,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: busy ? null : onTap,
            child: SizedBox(
              width: 52,
              height: 52,
              child: busy
                  ? const Padding(
                      padding: EdgeInsets.all(15),
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    )
                  : Icon(icon, color: AppColors.primaryRed),
            ),
          ),
        ),
      );
}

class _InlineNotice extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onClose;
  const _InlineNotice({
    required this.icon,
    required this.text,
    this.color = AppColors.primaryRed,
    this.actionLabel,
    this.onAction,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) => Material(
        elevation: 2,
        shadowColor: Colors.black26,
        borderRadius: AppRadius.mdAll,
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
          child: Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(text, style: AppText.bodySmall.copyWith(color: AppColors.textDark))),
              if (actionLabel != null) TextButton(onPressed: onAction, child: Text(actionLabel!)),
              if (onClose != null)
                AppIconButton(icon: Icons.close_rounded, tooltip: 'Dismiss', onPressed: onClose, size: 16),
            ],
          ),
        ),
      );
}
