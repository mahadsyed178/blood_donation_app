import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Shimmering placeholder blocks shown while a list loads, instead of a bare
/// spinner on an empty page.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final BorderRadius? radius;
  const SkeletonBox({super.key, this.width, this.height = 14, this.radius});

  @override
  Widget build(BuildContext context) => _Shimmer(
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: AppColors.borderGrey,
            borderRadius: radius ?? AppRadius.smAll,
          ),
        ),
      );
}

/// A list of card-shaped skeletons matching the app's request/commitment cards.
class SkeletonList extends StatelessWidget {
  final int count;
  final double cardHeight;
  final EdgeInsets padding;
  const SkeletonList({
    super.key,
    this.count = 3,
    this.cardHeight = 150,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 90),
  });

  @override
  Widget build(BuildContext context) => ListView.separated(
        padding: padding,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.lg),
        itemBuilder: (_, __) => Container(
          height: cardHeight,
          padding: AppSpacing.card,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppRadius.lgAll,
            border: Border.all(color: AppColors.borderGrey),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SkeletonBox(width: 56, height: 40, radius: AppRadius.mdAll),
                  const SizedBox(width: AppSpacing.md),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(width: 180, height: 16),
                        SizedBox(height: 6),
                        SkeletonBox(width: 120, height: 12),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const Row(
                children: [
                  SkeletonBox(width: 70, height: 22),
                  SizedBox(width: 8),
                  SkeletonBox(width: 90, height: 22),
                  SizedBox(width: 8),
                  SkeletonBox(width: 60, height: 22),
                ],
              ),
              const Spacer(),
              const SkeletonBox(height: 6),
            ],
          ),
        ),
      );
}

class _Shimmer extends StatefulWidget {
  final Widget child;
  const _Shimmer({required this.child});

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: const [
              AppColors.borderGrey,
              Color(0xFFF1F5F9),
              AppColors.borderGrey,
            ],
            stops: [
              (_controller.value - 0.3).clamp(0, 1),
              _controller.value.clamp(0, 1),
              (_controller.value + 0.3).clamp(0, 1),
            ],
          ).createShader(bounds),
          child: child,
        ),
        child: widget.child,
      );
}
