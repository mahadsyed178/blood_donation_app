import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_exception.dart';
import '../theme/app_colors.dart';

/// Renders an [AsyncValue] with the app's loading / error / empty states, so
/// no list screen ever shows a blank page.
///
/// Stale data stays visible while a refresh is in flight; the pull-to-refresh
/// indicator already signals the reload. [isEmpty] decides when to show
/// [emptyBuilder] instead of [builder].
class AsyncView<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final Future<void> Function()? onRetry;
  final bool Function(T data)? isEmpty;
  final Widget Function()? emptyBuilder;

  /// Skeleton (or anything else) to show on first load instead of a spinner.
  final Widget Function()? loadingBuilder;

  const AsyncView({
    super.key,
    required this.value,
    required this.builder,
    this.onRetry,
    this.isEmpty,
    this.emptyBuilder,
    this.loadingBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (value.hasValue && !value.hasError) {
      final data = value.value as T;
      if (isEmpty?.call(data) ?? false) {
        return emptyBuilder?.call() ?? const EmptyState();
      }
      return builder(data);
    }
    if (value.hasError) {
      return ErrorState(error: value.error!, onRetry: onRetry);
    }
    return loadingBuilder?.call() ?? const LoadingState();
  }
}

class LoadingState extends StatelessWidget {
  final String? message;
  const LoadingState({super.key, this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.primaryRed),
            if (message != null) ...[
              const SizedBox(height: 12),
              Text(message!, style: const TextStyle(color: AppColors.textGrey, fontSize: 13)),
            ],
          ],
        ),
      );
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const EmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    this.title = 'Nothing here yet',
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56, color: AppColors.textGrey.withValues(alpha: 0.4)),
              const SizedBox(height: 12),
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textDark)),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textGrey.withValues(alpha: 0.8), fontSize: 12.5)),
              ],
              if (action != null) ...[const SizedBox(height: 16), action!],
            ],
          ),
        ),
      );
}

class ErrorState extends StatelessWidget {
  final Object error;
  final Future<void> Function()? onRetry;
  const ErrorState({super.key, required this.error, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final e = error;
    final message = e is ApiException ? e.message : 'Something went wrong.';
    final offline = e is ApiException &&
        (e.kind == ApiErrorKind.network || e.kind == ApiErrorKind.timeout);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(offline ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
                size: 56, color: AppColors.primaryRed.withValues(alpha: 0.6)),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600)),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryRed,
                  side: BorderSide(color: AppColors.primaryRed.withValues(alpha: 0.4)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Small coloured pill used for statuses and urgency.
class Chip2 extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  const Chip2({super.key, required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 12, color: color), const SizedBox(width: 2)],
            Text(label,
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
          ],
        ),
      );
}
