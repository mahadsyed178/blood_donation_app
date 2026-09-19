import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../geo/map_config.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import 'osm_map.dart';

/// Read-only mini-map showing a shaded circle around an already-fuzzed
/// point. It never draws a pin for someone else's location and it says so.
///
/// Pass [exact] = true only for a location the viewer is entitled to see
/// precisely (their own request, or a hospital verifying one); it then draws
/// a pin instead of the circle and drops the "approximate" label.
class ApproximateLocationMap extends StatelessWidget {
  final LatLng point;
  final bool exact;
  final double height;
  final String? caption;

  const ApproximateLocationMap({
    super.key,
    required this.point,
    this.exact = false,
    this.height = 160,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    final label = exact ? 'Exact location' : 'Approximate area';
    return ClipRRect(
      borderRadius: AppRadius.lgAll,
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: point,
                    initialZoom: exact ? 15.5 : 14.2,
                    backgroundColor: const Color(0xFFE8ECF1),
                    interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                  ),
                  children: [
                    osmTileLayer(),
                    if (exact)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: point,
                            width: 44,
                            height: 44,
                            alignment: Alignment.topCenter,
                            child: const AnimatedPin(size: 40),
                          ),
                        ],
                      )
                    else
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: point,
                            radius: MapConfig.approximateRadiusMetres,
                            useRadiusInMeter: true,
                            color: AppColors.primaryRed.withValues(alpha: 0.18),
                            borderColor: AppColors.primaryRed.withValues(alpha: 0.6),
                            borderStrokeWidth: 2,
                          ),
                        ],
                      ),
                    const OsmAttribution(),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 8,
              top: 8,
              child: Semantics(
                label: label,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: AppRadius.smAll,
                    border: Border.all(color: AppColors.borderGrey),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(exact ? Icons.place_rounded : Icons.blur_circular_rounded,
                          size: 13, color: AppColors.primaryRed),
                      const SizedBox(width: 4),
                      Text(label,
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                    ],
                  ),
                ),
              ),
            ),
            if (caption != null)
              Positioned(
                left: 8,
                right: 8,
                bottom: 22,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: AppRadius.smAll,
                  ),
                  child: Text(caption!, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
