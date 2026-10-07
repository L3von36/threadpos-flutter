import 'package:flutter/material.dart';

/// ThreadPOS visual language: warm cream surfaces, terracotta accents,
/// elegant serif typography.
class AppTheme {
  AppTheme._();

  static const Color cream = Color(0xFFFAF5EE);
  static const Color creamDeep = Color(0xFFF0E6D8);
  static const Color ink = Color(0xFF2D2620);
  static const Color muted = Color(0xFF8A7B6C);
  static const Color terracotta = Color(0xFFC4633C);
  static const Color terracottaDark = Color(0xFFA34E2C);
  static const Color sage = Color(0xFF7D8F69);
  static const Color amber = Color(0xFFD99A2B);
  static const Color danger = Color(0xFFB4443C);
  static const Color border = Color(0xFFEDE2D3);

  static ThemeData light() {
    final ColorScheme scheme = ColorScheme.fromSeed(seedColor: terracotta)
        .copyWith(
      primary: terracotta,
      onPrimary: Colors.white,
      secondary: terracottaDark,
      surface: Colors.white,
      onSurface: ink,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: cream,
      fontFamily: 'serif',
      appBarTheme: const AppBarTheme(
        backgroundColor: cream,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'serif',
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: ink,
        ),
      ),
    );
  }

  static ButtonStyle get primaryButton => FilledButton.styleFrom(
        backgroundColor: terracotta,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(
          fontFamily: 'serif',
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      );

  static InputDecoration input(String label,
      {IconData? icon, String? hint, Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon, size: 20, color: muted),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: terracotta, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: danger, width: 1.4),
      ),
    );
  }
}
