import 'package:flutter/material.dart';

/// ThreadPOS compact design system.
///
/// Sizing follows the Instagram / WhatsApp school of UI: dense sans-serif
/// typography, 44-46dp controls, 10-14dp corner radii, short labels and
/// quiet hairline borders. The warm cream + terracotta palette stays as
/// the brand layer; serif is reserved for the brand wordmark only.
class AppTheme {
  AppTheme._();

  // --- Palette -------------------------------------------------------------
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

  // --- Type scale (WhatsApp-like density) ----------------------------------
  static const TextStyle pageTitle = TextStyle(
      fontSize: 17, fontWeight: FontWeight.w700, color: ink, letterSpacing: -0.2);
  static const TextStyle sectionTitle =
      TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ink);
  static const TextStyle cardTitle =
      TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ink);
  static const TextStyle body = TextStyle(fontSize: 13, color: ink);
  static const TextStyle bodyStrong =
      TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ink);
  static const TextStyle caption = TextStyle(fontSize: 11.5, color: muted);
  static const TextStyle micro = TextStyle(fontSize: 10.5, color: muted);
  static const TextStyle brand = TextStyle(
      fontFamily: 'serif',
      fontSize: 25,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.3,
      color: ink);

  // --- Corner radii ----------------------------------------------------------
  static const double rXs = 8;
  static const double rSm = 10;
  static const double rMd = 12;
  static const double rLg = 14;
  static const double rSheet = 20;

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
      visualDensity: VisualDensity.compact,
      appBarTheme: const AppBarTheme(
        backgroundColor: cream,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 16,
        iconTheme: IconThemeData(size: 21, color: ink),
        actionsIconTheme: IconThemeData(size: 21, color: ink),
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: ink,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: terracotta,
          foregroundColor: Colors.white,
          disabledBackgroundColor: creamDeep,
          disabledForegroundColor: muted,
          minimumSize: const Size.fromHeight(46),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(rMd)),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: terracotta,
          minimumSize: const Size.fromHeight(44),
          side: const BorderSide(color: terracotta, width: 1.1),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(rMd)),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(rMd),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(rMd),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(rMd),
          borderSide: const BorderSide(color: terracotta, width: 1.3),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(rMd),
          borderSide: const BorderSide(color: danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(rMd),
          borderSide: const BorderSide(color: danger, width: 1.3),
        ),
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        labelPadding: EdgeInsets.symmetric(horizontal: 2),
        labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        side: BorderSide(color: border),
        shape: StadiumBorder(),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(rLg),
        ),
        titleTextStyle: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.w700, color: ink),
        contentTextStyle: const TextStyle(
            fontSize: 13, height: 1.45, color: muted),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ink,
        contentTextStyle: const TextStyle(fontSize: 12.5, color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(rSm),
        ),
      ),
      dividerTheme: const DividerThemeData(
          color: border, thickness: 0.8, space: 1),
    );
  }

  /// Primary CTA — compact 46dp pill with terracotta fill.
  static ButtonStyle get primaryButton => FilledButton.styleFrom(
        backgroundColor: terracotta,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(46),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(rMd)),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
      );

  /// Compact input decoration kept for call sites that attach
  /// icons / hints / suffix widgets.
  static InputDecoration input(String label,
      {IconData? icon, String? hint, Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: muted),
      labelStyle: const TextStyle(fontSize: 13, color: muted),
      floatingLabelStyle:
          const TextStyle(fontSize: 12, color: terracottaDark),
      prefixIcon: icon == null
          ? null
          : Icon(icon, size: 17, color: muted),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(rMd),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(rMd),
        borderSide: const BorderSide(color: terracotta, width: 1.3),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(rMd),
        borderSide: const BorderSide(color: danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(rMd),
        borderSide: const BorderSide(color: danger, width: 1.3),
      ),
    );
  }
}
