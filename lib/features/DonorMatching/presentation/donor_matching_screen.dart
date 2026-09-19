import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/feedback.dart';

/// What confirming a location does.
enum LocationPickerMode {
  /// Pop with a [PickedLocation] for a form (e.g. a new blood request).
  pick,

  /// `PATCH /donors/me/location` — where the donor can be reached from.
  donorLocation,
}

class PickedLocation {
  final double latitude;
  final double longitude;
  final String? label;
  const PickedLocation({required this.latitude, required this.longitude, this.label});
}

/// Map with a draggable pin. The backend has no reverse geocoding and the
/// request/donor payloads want a human `area_label`, so the label is typed.
///
/// The nearby-request feed does not include coordinates, so requests are
/// not plotted here (see backend gaps in the integration notes).
class DonorMatchingScreen extends ConsumerStatefulWidget {
  final LocationPickerMode mode;

  /// Rendered inside the dashboard's tab shell: no own AppBar, no pop.
  final bool embedded;

  const DonorMatchingScreen({
    super.key,
    this.mode = LocationPickerMode.pick,
    this.embedded = false,
  });

  @override
  ConsumerState<DonorMatchingScreen> createState() => _DonorMatchingScreenState();
}

class _DonorMatchingScreenState extends ConsumerState<DonorMatchingScreen> {
  static const CameraPosition _fallbackPosition = CameraPosition(
    target: LatLng(24.8607, 67.0011), // Karachi
    zoom: 13.0,
  );

  GoogleMapController? _mapController;
  LatLng? _pin;
  bool _isLocating = true;
  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    setState(() {
      _isLocating = true;
      _errorMessage = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _locateFailed('Location services are disabled. Tap the map to place the pin manually.');
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _locateFailed('Location permission denied. Tap the map to place the pin manually.');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 15));
      if (!mounted) return;
      _moveTo(LatLng(position.latitude, position.longitude), zoom: 16);
      setState(() => _isLocating = false);
    } catch (_) {
      _locateFailed('Could not get a GPS fix. Tap the map to place the pin manually.');
    }
  }

  void _locateFailed(String message) {
    if (!mounted) return;
    setState(() {
      _isLocating = false;
      _errorMessage = message;
    });
  }

  void _moveTo(LatLng target, {double? zoom}) {
    setState(() => _pin = target);
    _mapController?.animateCamera(
      zoom != null
          ? CameraUpdate.newCameraPosition(CameraPosition(target: target, zoom: zoom))
          : CameraUpdate.newLatLng(target),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_pin != null) {
      controller.animateCamera(
        CameraUpdate.newCameraPosition(CameraPosition(target: _pin!, zoom: 16)),
      );
    }
  }

  Future<void> _confirm() async {
    final pin = _pin;
    if (pin == null) return;

    if (widget.mode == LocationPickerMode.pick) {
      context.pop(PickedLocation(latitude: pin.latitude, longitude: pin.longitude));
      return;
    }

    final current = ref.read(currentUserProvider)?.donor?.areaLabel;
    final label = await _askAreaLabel(current);
    if (label == null || label.trim().isEmpty) return;

    setState(() => _saving = true);
    try {
      await ref.read(authProvider.notifier).setDonorLocation(
            latitude: pin.latitude,
            longitude: pin.longitude,
            areaLabel: label.trim(),
          );
      if (!mounted) return;
      showSnack(context, 'Location saved — you’ll now see requests near $label');
      if (!widget.embedded) context.pop();
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<String?> _askAreaLabel(String? initial) {
    final controller = TextEditingController(text: initial ?? '');
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Name this area', style: TextStyle(fontWeight: FontWeight.w800)),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          maxLength: 120,
          decoration: appInputDecoration(hint: 'e.g. Gulshan-e-Iqbal, Karachi'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryRed),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final donor = ref.watch(currentUserProvider)?.donor;
    final isDonorMode = widget.mode == LocationPickerMode.donorLocation;

    final body = Stack(
      children: [
        GoogleMap(
          initialCameraPosition: _fallbackPosition,
          onMapCreated: _onMapCreated,
          onTap: (latLng) => _moveTo(latLng),
          markers: {
            if (_pin != null)
              Marker(
                markerId: const MarkerId('pin'),
                position: _pin!,
                draggable: true,
                onDragEnd: (p) => setState(() => _pin = p),
                infoWindow: InfoWindow(
                    title: isDonorMode ? 'Your location' : 'Patient location'),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
              ),
          },
          mapType: MapType.normal,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          compassEnabled: true,
        ),
        Positioned(
          left: 16,
          right: 16,
          top: 16,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  _errorMessage != null ? Icons.info_outline_rounded : Icons.touch_app_rounded,
                  color: AppColors.primaryRed,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _errorMessage ??
                        (isDonorMode
                            ? (donor?.hasLocation ?? false)
                                ? 'Currently: ${donor!.areaLabel}. Tap or drag the pin to update.'
                                : 'Tap or drag the pin to where you can donate from.'
                            : 'Tap or drag the pin to the patient’s location.'),
                    style: const TextStyle(fontSize: 12.5, color: AppColors.textDark),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isLocating)
          Container(
            color: Colors.white.withValues(alpha: 0.7),
            child: const Center(child: LoadingDots()),
          ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            heroTag: 'recenter_${widget.mode.name}',
            mini: true,
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primaryRed,
            elevation: 4,
            onPressed: _determinePosition,
            child: const Icon(Icons.my_location_rounded),
          ),
        ),
      ],
    );

    final bottom = SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, -4)),
          ],
        ),
        child: SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: (_pin == null || _saving) ? null : _confirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
              disabledBackgroundColor: AppColors.primaryRed.withValues(alpha: 0.5),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.check_rounded, color: Colors.white),
            label: Text(
              isDonorMode ? 'Save as My Location' : 'Confirm This Location',
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );

    if (widget.embedded) {
      return Scaffold(
        backgroundColor: AppColors.bgGrey,
        body: body,
        bottomNavigationBar: bottom,
      );
    }
    return Scaffold(
      backgroundColor: AppColors.bgGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: AppColors.textDark,
        title: Text(
          isDonorMode ? 'My Location' : 'Patient Location',
          style: const TextStyle(
              color: AppColors.textDark, fontWeight: FontWeight.w800, fontSize: 17),
        ),
      ),
      body: body,
      bottomNavigationBar: bottom,
    );
  }
}

class LoadingDots extends StatelessWidget {
  const LoadingDots({super.key});
  @override
  Widget build(BuildContext context) => const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.primaryRed),
          SizedBox(height: 12),
          Text('Getting your location...',
              style: TextStyle(color: AppColors.textGrey, fontSize: 13)),
        ],
      );
}
