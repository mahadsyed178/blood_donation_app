import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

enum AppButtonVariant { primary, secondary, outline, text, success, danger }

/// The one button. Handles the async states every screen kept re-implementing:
/// a spinner *inside* the button while [busy], disabled while busy so a
/// second tap can't double-submit, and press feedback via the theme's ripple.
class AppButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final Future<void> Function()? onPressed;
  final bool busy;
  final bool enabled;
  final AppButtonVariant variant;
  final bool expand;
  final double height;
  final String? tooltip;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.busy = false,
    this.enabled = true,
    this.variant = AppButtonVariant.primary,
    this.expand = true,
    this.height = 48,
    this.tooltip,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _running = false;

  bool get _isBusy => widget.busy || _running;

  Future<void> _handle() async {
    if (_isBusy || widget.onPressed == null) return;
    setState(() => _running = true);
    try {
      await widget.onPressed!();
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled && widget.onPressed != null && !_isBusy;
    final fg = switch (widget.variant) {
      AppButtonVariant.primary || AppButtonVariant.success || AppButtonVariant.danger => Colors.white,
      AppButtonVariant.secondary => AppColors.primaryRed,
      AppButtonVariant.outline => AppColors.primaryRed,
      AppButtonVariant.text => AppColors.primaryRed,
    };

    final child = AnimatedSwitcher(
      duration: AppDurations.fast,
      child: _isBusy
          ? SizedBox(
              key: const ValueKey('busy'),
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: fg),
            )
          : Row(
              key: const ValueKey('label'),
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 18, color: fg),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.button.copyWith(color: fg)),
                ),
              ],
            ),
    );

    final VoidCallback? onTap = enabled ? _handle : null;
    final shape = RoundedRectangleBorder(borderRadius: AppRadius.lgAll);
    final size = Size(widget.expand ? double.infinity : 0, widget.height);

    Widget button = switch (widget.variant) {
      AppButtonVariant.primary => ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(minimumSize: size, shape: shape),
          child: child,
        ),
      AppButtonVariant.success => ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            minimumSize: size,
            shape: shape,
            backgroundColor: AppColors.successGreen,
            disabledBackgroundColor: AppColors.successGreen.withValues(alpha: 0.45),
          ),
          child: child,
        ),
      AppButtonVariant.danger => ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            minimumSize: size,
            shape: shape,
            backgroundColor: AppColors.critical,
            disabledBackgroundColor: AppColors.critical.withValues(alpha: 0.45),
          ),
          child: child,
        ),
      AppButtonVariant.secondary => ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            minimumSize: size,
            shape: shape,
            backgroundColor: AppColors.lightPink,
            disabledBackgroundColor: AppColors.lightPink.withValues(alpha: 0.6),
            foregroundColor: AppColors.primaryRed,
          ),
          child: child,
        ),
      AppButtonVariant.outline => OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(minimumSize: size, shape: shape),
          child: child,
        ),
      AppButtonVariant.text => TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(minimumSize: size, shape: shape),
          child: child,
        ),
    };

    if (widget.tooltip != null) {
      button = Tooltip(message: widget.tooltip!, child: button);
    }
    return AnimatedOpacity(
      duration: AppDurations.fast,
      opacity: widget.enabled ? 1 : 0.7,
      child: button,
    );
  }
}

/// Icon-only actions always carry a tooltip so the meaning is never ambiguous.
class AppIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? background;
  final double size;

  const AppIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
    this.background,
    this.size = 22,
  });

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: Semantics(
          button: true,
          label: tooltip,
          child: Material(
            color: background ?? Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onPressed,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(icon, size: size, color: color ?? AppColors.textDark),
              ),
            ),
          ),
        ),
      );
}

/// Sticky bottom action bar shared by every form screen.
class BottomActionBar extends StatelessWidget {
  final Widget child;
  const BottomActionBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.lg),
        decoration: BoxDecoration(color: Colors.white, boxShadow: AppShadows.raised),
        child: SafeArea(top: false, child: child),
      );
}
