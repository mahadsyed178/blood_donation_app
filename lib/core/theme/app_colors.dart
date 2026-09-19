import 'package:flutter/material.dart';

/// The palette every screen was already declaring privately, in one place.
class AppColors {
  AppColors._();

  static const Color primaryRed = Color(0xFFE53935);
  static const Color deepRed = Color(0xFFB71C1C);
  static const Color lightPink = Color(0xFFFFF5F5);
  static const Color pinkBorder = Color(0xFFFFE0E0);
  static const Color textDark = Color(0xFF1E293B);
  static const Color textGrey = Color(0xFF64748B);
  static const Color hintGrey = Color(0xFFA0AEC0);
  static const Color bgGrey = Color(0xFFF8FAFC);
  static const Color borderGrey = Color(0xFFE2E8F0);
  static const Color successGreen = Color(0xFF16A34A);
  static const Color successBg = Color(0xFFF0FDF4);
  static const Color amber = Color(0xFFF59E0B);
  static const Color orange = Color(0xFFF97316);
  static const Color critical = Color(0xFFDC2626);
  static const Color blue = Color(0xFF2563EB);

  static Color urgency(String apiValue) => switch (apiValue) {
        'critical' => critical,
        'urgent' => orange,
        _ => amber,
      };
}

/// Field styling shared by every form screen.
InputDecoration appInputDecoration({
  required String hint,
  IconData? icon,
  Widget? suffix,
  String? errorText,
}) {
  OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c, width: w),
      );
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.hintGrey, fontSize: 13),
    prefixIcon: icon != null ? Icon(icon, color: AppColors.hintGrey, size: 20) : null,
    suffixIcon: suffix,
    errorText: errorText,
    errorStyle: const TextStyle(fontSize: 11),
    filled: true,
    fillColor: AppColors.bgGrey,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: border(AppColors.borderGrey),
    enabledBorder: border(AppColors.borderGrey),
    focusedBorder: border(AppColors.primaryRed, 1.5),
    errorBorder: border(Colors.redAccent, 1.2),
    focusedErrorBorder: border(Colors.redAccent, 1.5),
  );
}
