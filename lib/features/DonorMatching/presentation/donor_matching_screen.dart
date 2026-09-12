import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DonorMatchingScreen extends StatefulWidget {
  const DonorMatchingScreen({super.key});

  @override
  State<DonorMatchingScreen> createState() => _GoogleMapScreenState();
}

class _GoogleMapScreenState extends State<DonorMatchingScreen> {
  static const Color primaryRed = Color(0xFFE53935);
  static const Color textDark = Color(0xFF1E293B);
  static const Color textGrey = Color(0xFF64748B);
  static const Color bgGrey = Color(0xFFF8FAFC);

  // Fallback camera position (used only if location fetch fails)
  static const CameraPosition _fallbackPosition = CameraPosition(
    target: LatLng(24.8607, 67.0011), // Karachi, as a sensible regional default
    zoom: 14.0,
  );

  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _isLoading = true;
  String? _errorMessage;

  final Set<Marker> _markers = {};

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
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check if location services are enabled on the device
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Location services are disabled. Please enable them.';
        });
        return;
      }

      // Check and request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Location permission was denied.';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoading = false;
          _errorMessage =
          'Location permission is permanently denied. Enable it from app settings.';
        });
        return;
      }

      // Permission granted — fetch current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;

      setState(() {
        _currentPosition = position;
        _isLoading = false;
        _markers.clear();
        _markers.add(
          Marker(
            markerId: const MarkerId('current_location'),
            position: LatLng(position.latitude, position.longitude),
            infoWindow: const InfoWindow(title: 'Your current location'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed),
          ),
        );
      });

      // Animate camera to the fetched location
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 16.0,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Could not fetch your location. Please try again.';
      });
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    // If location was already fetched before the map finished creating,
    // move the camera immediately instead of waiting for the next fetch.
    if (_currentPosition != null) {
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
            ),
            zoom: 16.0,
          ),
        ),
      );
    }
  }

  void _confirmLocation() {
    if (_currentPosition == null) return;

    // TODO: return the selected coordinates to the calling screen
    // (e.g. Navigator.pop(context, _currentPosition), or update a
    // Riverpod provider for the request/donor location field).
    Navigator.pop(context, _currentPosition);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: textDark,
        title: const Text(
          'Current Address',
          style: TextStyle(
            color: textDark,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
      ),
      body: Stack(
        children: [
          if (_errorMessage != null)
            _buildErrorState()
          else
            GoogleMap(
              initialCameraPosition: _fallbackPosition,
              onMapCreated: _onMapCreated,
              markers: _markers,
              mapType: MapType.normal,
              myLocationEnabled: true,
              myLocationButtonEnabled: false, // using custom FAB instead
              zoomControlsEnabled: false,
              compassEnabled: true,
            ),

          if (_isLoading)
            Container(
              color: Colors.white.withOpacity(0.85),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: primaryRed),
                    SizedBox(height: 12),
                    Text(
                      'Getting your location...',
                      style: TextStyle(color: textGrey, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),

          // --- Recenter button ---
          if (_errorMessage == null)
            Positioned(
              right: 16,
              bottom: 100,
              child: FloatingActionButton(
                heroTag: 'recenter',
                mini: true,
                backgroundColor: Colors.white,
                foregroundColor: primaryRed,
                elevation: 4,
                onPressed: _determinePosition,
                child: const Icon(Icons.my_location_rounded),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _errorMessage == null
          ? SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _currentPosition == null ? null : _confirmLocation,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryRed,
                disabledBackgroundColor: primaryRed.withOpacity(0.5),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.check_rounded, color: Colors.white),
              label: const Text(
                'Confirm This Location',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      )
          : null,
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_off_rounded,
                size: 56, color: textGrey.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: textDark, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _determinePosition,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryRed,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}