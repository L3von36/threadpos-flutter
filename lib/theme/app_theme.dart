import 'package:flutter/material.dart';

/// Sami POS compact design system.
///
/// Sizing follows the Instagram / WhatsApp school of UI: dense sans-serif
/// typography, 44-46dp controls, 10-14dp corner radii, short labels and
/// quiet hairline borders. The warm cream + terracotta palette stays as
/// the brand layer; serif is reserved for the brand wordmark only.
///
/// The app ships a full dark theme alongside the light one. All runtime
/// color lookups go through [Pal] — a semantic palette resolved from the
/// current [Theme] brightness — so every screen is dark-mode aware.
class AppTheme {
  AppTheme._();

  // --- Brand constants (work on both themes) --------------------------------
  static const Color terracotta = Color(0xFFC4633C);
  static const Color terracottaDark = Color(0xFFA34E2C);
  static const Color scannerBg = Color(0xFF121011);

  // --- Semantic palettes ----------------------------------------------------
  static const Pal palLight = Pal(
    dark: false,
    bg: Color(0xFFFAF5EE),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF0E6D8),
    ink: Color(0xFF2D2620),
    muted: Color(0xFF8A7B6C),
    border: Color(0xFFEDE2D3),
    accent: terracotta,
    accentDeep: terracottaDark,
    sage: Color(0xFF7D8F69),
    amber: Color(0xFFD99A2B),
    danger: Color(0xFFB4443C),
    toastBg: Color(0xFF2D2620),
    toastText: Color(0xFFFFFFFF),
    bannerBg: Color(0xFF2D2620),
    bannerText: Color(0xFFFFFFFF),
    bannerSub: Color(0xB3FFFFFF),
  );

  static const Pal palDark = Pal(
    dark: true,
    bg: Color(0xFF161210),
    surface: Color(0xFF211B16),
    surfaceAlt: Color(0xFF2C251D),
    ink: Color(0xFFF0E8DD),
    muted: Color(0xFFA5927F),
    border: Color(0xFF332B23),
    accent: Color(0xFFD97A4E),
    accentDeep: Color(0xFFB95E38),
    sage: Color(0xFF97AC80),
    amber: Color(0xFFE4AC43),
    danger: Color(0xFFE06A5A),
    toastBg: Color(0xFF3A322A),
    toastText: Color(0xFFF0E8DD),
    bannerBg: Color(0xFF33291F),
    bannerText: Color(0xFFF5EDE3),
    bannerSub: Color(0xB8F5EDE3),
  );

  // --- Type scale (WhatsApp-like density) ----------------------------------
  static TextStyle pageTitle(BuildContext c) => TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
      color: Pal.of(c).ink);
  static TextStyle sectionTitle(BuildContext c) => TextStyle(
      fontSize: 14, fontWeight: FontWeight.w700, color: Pal.of(c).ink);
  static TextStyle cardTitle(BuildContext c) => TextStyle(
      fontSize: 13, fontWeight: FontWeight.w600, color: Pal.of(c).ink);
  static TextStyle body(BuildContext c) =>
      TextStyle(fontSize: 13, color: Pal.of(c).ink);
  static TextStyle bodyStrong(BuildContext c) => TextStyle(
      fontSize: 13, fontWeight: FontWeight.w600, color: Pal.of(c).ink);
  static TextStyle caption(BuildContext c) =>
      TextStyle(fontSize: 11.5, color: Pal.of(c).muted);
  static TextStyle micro(BuildContext c) =>
      TextStyle(fontSize: 10.5, color: Pal.of(c).muted);
  static TextStyle brand(BuildContext c) => TextStyle(
      fontFamily: 'serif',
      fontSize: 25,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.3,
      color: Pal.of(c).ink);

  // --- Corner radii ----------------------------------------------------------
  static const double rXs = 8;
  static const double rSm = 10;
  static const double rMd = 12;
  static const double rLg = 14;
  static const double rSheet = 20;

  static ThemeData light() => _build(palLight);
  static ThemeData dark() => _build(palDark);

  static ThemeData _build(Pal p) {
    final ColorScheme scheme =
        ColorScheme.fromSeed(
                seedColor: terracotta,
                brightness: p.dark ? Brightness.dark : Brightness.light)
            .copyWith(
      primary: p.accent,
      onPrimary: Colors.white,
      secondary: p.accentDeep,
      surface: p.surface,
      onSurface: p.ink,
      error: p.danger,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.bg,
      visualDensity: VisualDensity.compact,
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: _FadeUpPageTransitionsBuilder(),
          TargetPlatform.iOS: _FadeUpPageTransitionsBuilder(),
          TargetPlatform.linux: _FadeUpPageTransitionsBuilder(),
          TargetPlatform.macOS: _FadeUpPageTransitionsBuilder(),
          TargetPlatform.windows: _FadeUpPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.bg,
        foregroundColor: p.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 16,
        iconTheme: IconThemeData(size: 21, color: p.ink),
        actionsIconTheme: IconThemeData(size: 21, color: p.ink),
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: p.ink,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: p.surfaceAlt,
          disabledForegroundColor: p.muted,
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
          foregroundColor: p.accent,
          minimumSize: const Size.fromHeight(44),
          side: BorderSide(color: p.accent, width: 1.1),
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
        fillColor: p.surface,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(rMd),
          borderSide: BorderSide(color: p.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(rMd),
          borderSide: BorderSide(color: p.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(rMd),
          borderSide: BorderSide(color: p.accent, width: 1.3),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(rMd),
          borderSide: BorderSide(color: p.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(rMd),
          borderSide: BorderSide(color: p.danger, width: 1.3),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.surface,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        labelPadding: const EdgeInsets.symmetric(horizontal: 2),
        labelStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: p.ink),
        side: BorderSide(color: p.border),
        shape: const StadiumBorder(),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        modalBackgroundColor: p.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(rSheet)),
        ),
        showDragHandle: false,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(rLg),
        ),
        titleTextStyle: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w700, color: p.ink),
        contentTextStyle:
            TextStyle(fontSize: 13, height: 1.45, color: p.muted),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.toastBg,
        contentTextStyle: TextStyle(fontSize: 12.5, color: p.toastText),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(rSm),
        ),
      ),
      dividerTheme: DividerThemeData(
          color: p.border, thickness: 0.8, space: 1),
    );
  }

  /// Primary CTA — compact 46dp pill with the theme accent fill.
  static ButtonStyle primaryButton(BuildContext context) {
    final Pal p = Pal.of(context);
    return FilledButton.styleFrom(
      backgroundColor: p.accent,
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
  }

  /// Compact input decoration kept for call sites that attach
  /// icons / hints / suffix widgets.
  static InputDecoration input(BuildContext context, String label,
      {IconData? icon, String? hint, Widget? suffix}) {
    final Pal p = Pal.of(context);
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: TextStyle(fontSize: 13, color: p.muted),
      labelStyle: TextStyle(fontSize: 13, color: p.muted),
      floatingLabelStyle: TextStyle(fontSize: 12, color: p.accentDeep),
      prefixIcon: icon == null
          ? null
          : Icon(icon, size: 17, color: p.muted),
      suffixIcon: suffix,
      filled: true,
      fillColor: p.surface,
      isDense: true,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(rMd),
        borderSide: BorderSide(color: p.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(rMd),
        borderSide: BorderSide(color: p.accent, width: 1.3),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(rMd),
        borderSide: BorderSide(color: p.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(rMd),
        borderSide: BorderSide(color: p.danger, width: 1.3),
      ),
    );
  }
}

/// Semantic color palette resolved from the current theme brightness.
/// Screens read `Pal.of(context)` instead of hardcoding light-only colors.
@immutable
class Pal {
  const Pal({
    required this.dark,
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.ink,
    required this.muted,
    required this.border,
    required this.accent,
    required this.accentDeep,
    required this.sage,
    required this.amber,
    required this.danger,
    required this.toastBg,
    required this.toastText,
    required this.bannerBg,
    required this.bannerText,
    required this.bannerSub,
  });

  final bool dark;
  final Color bg;
  final Color surface;
  final Color surfaceAlt;
  final Color ink;
  final Color muted;
  final Color border;
  final Color accent;
  final Color accentDeep;
  final Color sage;
  final Color amber;
  final Color danger;
  final Color toastBg;
  final Color toastText;
  final Color bannerBg;
  final Color bannerText;
  final Color bannerSub;

  /// Accent tint for selected states (pills, soft highlights).
  Color get softAccent =>
      accent.withValues(alpha: dark ? 0.16 : 0.09);

  static Pal of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? AppTheme.palDark
          : AppTheme.palLight;
}

/// Gentle fade + slide-up page transition shared by every pushed route.
class _FadeUpPageTransitionsBuilder extends PageTransitionsBuilder {
  const _FadeUpPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final Animation<double> fade = animation.drive(CurveTween(
        curve: const Interval(0.15, 1.0, curve: Curves.easeOut)));
    final Animation<Offset> slide = animation.drive(
      Tween<Offset>(begin: const Offset(0, 0.035), end: Offset.zero)
          .chain(CurveTween(curve: Curves.easeOutCubic)),
    );
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(position: slide, child: child),
    );
  }
}
