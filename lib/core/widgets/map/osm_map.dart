import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../geo/map_config.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

/// Tracks tile failures so the map can say "offline" instead of going blank.
///
/// Counts failures in a rolling window; a burst of them means the tile host
/// is unreachable. Successes don't cancel failures (cached tiles keep
/// "succeeding" while offline) — only an explicit retry, or a fresh network
/// load after the window has passed, clears the banner.
class TileHealth extends ChangeNotifier {
  static const _window = Duration(seconds: 20);
  static const _threshold = 3;
  final List<DateTime> _failures = [];
  bool _degraded = false;

  bool get degraded => _degraded;

  void onError() {
    final now = DateTime.now();
    _failures.add(now);
    _failures.removeWhere((t) => now.difference(t) > _window);
    if (!_degraded && _failures.length >= _threshold) {
      _degraded = true;
      notifyListeners();
    }
  }

  /// A tile that just finished loading over the network.
  void onLoaded() {
    if (!_degraded) return;
    final now = DateTime.now();
    _failures.removeWhere((t) => now.difference(t) > _window);
    if (_failures.isEmpty) {
      _degraded = false;
      notifyListeners();
    }
  }

  void reset() {
    _failures.clear();
    if (_degraded) {
      _degraded = false;
      notifyListeners();
    }
  }
}

/// The OSM tile layer every map uses. `keepBuffer` and the grey `errorImage`
/// mean a failed tile shows as a neutral square, never white; [health] drives
/// the offline banner.
TileLayer osmTileLayer({TileHealth? health}) => TileLayer(
      urlTemplate: MapConfig.tileUrl,
      userAgentPackageName: 'com.example.blood_donation_app',
      maxNativeZoom: 19,
      maxZoom: MapConfig.maxZoom,
      keepBuffer: 4,
      panBuffer: 1,
      errorImage: const AssetImage('lib/core/constants/assets/images/tile_placeholder.png'),
      evictErrorTileStrategy: EvictErrorTileStrategy.notVisible,
      errorTileCallback: (tile, error, stack) => health?.onError(),
      tileBuilder: (context, tileWidget, tile) {
        final finished = tile.loadFinishedAt;
        if (finished != null &&
            !tile.loadError &&
            DateTime.now().difference(finished) < const Duration(seconds: 2)) {
          health?.onLoaded();
        }
        return tileWidget;
      },
    );

/// Mandatory OSM credit.
class OsmAttribution extends StatelessWidget {
  const OsmAttribution({super.key});
  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.bottomRight,
        child: Container(
          margin: const EdgeInsets.all(6),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            borderRadius: AppRadius.smAll,
          ),
          child: const Text(MapConfig.attribution,
              style: TextStyle(fontSize: 9.5, color: AppColors.textGrey)),
        ),
      );
}

/// "Map tiles couldn't load" strip with a retry, driven by [TileHealth].
class TileOfflineBanner extends StatelessWidget {
  final TileHealth health;
  final VoidCallback onRetry;
  const TileOfflineBanner({super.key, required this.health, required this.onRetry});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: health,
        builder: (context, _) => AnimatedSwitcher(
          duration: AppDurations.normal,
          child: !health.degraded
              ? const SizedBox.shrink()
              : Material(
                  key: const ValueKey('offline'),
                  color: AppColors.textDark,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 18),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Map tiles couldn’t load — check your connection. You can still pick a spot.',
                            style: TextStyle(color: Colors.white, fontSize: 12.5),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            health.reset();
                            onRetry();
                          },
                          icon: const Icon(Icons.refresh_rounded, size: 16, color: Colors.white),
                          label: const Text('Retry', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      );
}

/// The map pin, with a drop-in animation when it first appears or moves.
class AnimatedPin extends StatelessWidget {
  final Color color;
  final double size;
  final Key? animationKey;
  const AnimatedPin({super.key, this.color = AppColors.primaryRed, this.size = 44, this.animationKey});

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        key: animationKey,
        tween: Tween(begin: 0, end: 1),
        duration: AppDurations.slow,
        curve: Curves.elasticOut,
        builder: (context, t, child) => Transform.translate(
          offset: Offset(0, -24 * (1 - t)),
          child: Opacity(opacity: t.clamp(0, 1), child: child),
        ),
        child: Semantics(
          label: 'Selected location pin',
          child: Icon(Icons.location_on_rounded, color: color, size: size, shadows: const [
            Shadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 3)),
          ]),
        ),
      );
}
