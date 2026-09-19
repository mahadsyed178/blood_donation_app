import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../geo/geo_utils.dart';
import '../network/api_exception.dart';
import '../theme/app_colors.dart';

/// Consistent snackbars. Every API failure surfaces through [showApiError].
void showSnack(BuildContext context, String message, {bool isError = false}) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.primaryRed : AppColors.successGreen,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
}

void showApiError(BuildContext context, Object error) {
  final message = error is ApiException ? error.message : 'Something went wrong';
  showSnack(context, message, isError: true);
}

/// Simple yes/no dialog. Resolves true on confirm.
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: destructive ? AppColors.primaryRed : AppColors.successGreen,
          ),
          child: Text(confirmLabel, style: const TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Optional free-text prompt (cancel reasons). Null when dismissed.
Future<String?> promptText(
  BuildContext context, {
  required String title,
  String hint = '',
  String confirmLabel = 'Submit',
}) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      content: TextField(
        controller: controller,
        maxLines: 3,
        maxLength: 500,
        buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
            currentLength >= 400 ? Text('$currentLength / $maxLength', style: const TextStyle(fontSize: 10)) : null,
        decoration: appInputDecoration(hint: hint),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, controller.text.trim()),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryRed),
          child: Text(confirmLabel, style: const TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

// --- Formatting -------------------------------------------------------------

/// "just now", "15 min ago", "2 h ago", "3 d ago".
String timeAgo(DateTime time) {
  final diff = DateTime.now().difference(time.toLocal());
  if (diff.inSeconds < 45) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} h ago';
  if (diff.inDays < 7) return '${diff.inDays} d ago';
  return DateFormat('d MMM').format(time.toLocal());
}

String formatDateTime(DateTime time) => DateFormat('d MMM, h:mm a').format(time.toLocal());

String formatDate(DateTime d) => DateFormat('dd/MM/yyyy').format(d.toLocal());

String formatTime(DateTime d) => DateFormat('h:mm a').format(d.toLocal());

/// "in 2 h", "in 35 min", "overdue"
String untilLabel(DateTime deadline) {
  final diff = deadline.difference(DateTime.now());
  if (diff.isNegative) return 'overdue';
  if (diff.inMinutes < 60) return 'in ${diff.inMinutes} min';
  if (diff.inHours < 48) return 'in ${diff.inHours} h';
  return 'in ${diff.inDays} d';
}

/// Distances are always shown rounded and prefixed "~" — see GeoUtils.
String formatKm(double km) => GeoUtils.formatDistance(km);

/// Mirrors the backend password rule: 8–128 chars, a letter and a digit.
String? validatePassword(String? value) {
  final v = value ?? '';
  if (v.length < 8) return 'At least 8 characters';
  if (v.length > 128) return 'At most 128 characters';
  if (!v.contains(RegExp(r'[A-Za-z]'))) return 'Must contain a letter';
  if (!v.contains(RegExp(r'\d'))) return 'Must contain a digit';
  return null;
}

String? validateEmail(String? value) {
  final v = (value ?? '').trim();
  if (v.isEmpty) return 'Email is required';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) return 'Enter a valid email';
  return null;
}

/// Backend: 7–20 characters after trimming. Client adds a format check:
/// digits with an optional leading +, spaces/dashes/parentheses allowed.
String? validatePhone(String? value) {
  final v = (value ?? '').trim();
  if (v.isEmpty) return 'Phone number is required';
  if (v.length < 7) return 'At least 7 digits';
  if (v.length > 20) return 'At most 20 characters';
  if (!RegExp(r'^\+?[0-9][0-9\s\-()]{5,}[0-9]$').hasMatch(v)) return 'Enter a valid phone number';
  final digits = v.replaceAll(RegExp(r'\D'), '');
  if (digits.length < 7) return 'At least 7 digits';
  return null;
}
