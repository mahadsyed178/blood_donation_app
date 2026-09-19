import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/geo/geo_utils.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/map/location_picker_screen.dart';

export '../../../core/geo/geo_utils.dart' show PickedLocation;

/// What confirming a location does.
enum LocationPickerMode {
  /// Pop with a [PickedLocation] for a form (e.g. a new blood request).
  pick,

  /// `PATCH /donors/me/location` — where the donor can be reached from.
  donorLocation,
}

/// The OSM location picker, configured for one of the two flows. The
/// donor's stored point is their own, so it's shown exactly to them; it is
/// never sent to anyone else un-fuzzed (see backend `approximate_point`).
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
  Future<void> _saveDonorLocation(PickedLocation picked) async {
    var label = picked.displayAddress?.trim() ?? '';
    if (label.isEmpty) {
      // Reverse geocoding gave nothing (offline, rate-limited) — ask.
      final typed = await _askAreaLabel(ref.read(currentUserProvider)?.donor?.areaLabel);
      if (typed == null || typed.trim().isEmpty) {
        throw StateError('Give the area a name so requesters know roughly where you are.');
      }
      label = typed.trim();
    }
    await ref.read(authProvider.notifier).setDonorLocation(
          latitude: picked.latitude,
          longitude: picked.longitude,
          areaLabel: label,
        );
    if (mounted) showSnack(context, 'Location saved — you’ll now see requests near $label');
  }

  Future<String?> _askAreaLabel(String? initial) {
    final controller = TextEditingController(text: initial ?? '');
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Name this area'),
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
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mode == LocationPickerMode.pick) {
      return LocationPickerScreen(
        title: 'Patient location',
        draftKey: 'request-location',
        confirmLabel: 'Confirm this location',
        pinLabel: 'Patient location',
        embedded: widget.embedded,
      );
    }
    final donor = ref.watch(currentUserProvider)?.donor;
    return LocationPickerScreen(
      title: 'My location',
      draftKey: 'donor-location',
      confirmLabel: donor?.hasLocation ?? false ? 'Update my location' : 'Save as my location',
      pinLabel: 'Where you can donate from',
      onConfirm: _saveDonorLocation,
      embedded: widget.embedded,
    );
  }
}
