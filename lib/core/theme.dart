import 'package:flutter/material.dart';
import 'dart:ui' show FontFeature;

/// Spacing scale (multiples of 4).
class Sp {
  Sp._();
  static const double x1 = 4, x2 = 8, x3 = 12, x4 = 16, x6 = 24, x8 = 32, x12 = 48, x16 = 64;
}

/// Radius scale (soft and round, from the design reference).
class Rd {
  Rd._();
  static const double s = 12, m = 16, l = 20, xl = 28;
}

/// Motion tokens.
class Mo {
  Mo._();
  static const Curve out = Cubic(0.16, 1, 0.3, 1);
  static const Duration tap = Duration(milliseconds: 150);
  static const Duration screen = Duration(milliseconds: 320);
}

/// Brand colors, derived from the design reference and the logo.
class Brand {
  Brand._();
  static const violet = Color(0xFF7B5CFA);
  static const violetDeep = Color(0xFF5F37E0);
  static const violetSoft = Color(0xFFA98BFF);
  static const teal = Color(0xFF34D6B8);
  static const pink = Color(0xFFFF7AB2);
  static const orange = Color(0xFFFFA24C);
  static const sky = Color(0xFF5CB8FF);
  static const onTeal = Color(0xFF062B25);

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8A6BFA), Color(0xFF5B34D8)],
  );
  static const ctaGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF4CE6C7), Color(0xFF2CC9AA)],
  );
}

/// Light and dark palettes. Both are designed, not inverted.
@immutable
class Pal extends ThemeExtension<Pal> {
  const Pal({
    required this.dark,
    required this.bg1,
    required this.bg2,
    required this.surface,
    required this.glass,
    required this.border,
    required this.text,
    required this.muted,
    required this.sheet,
    required this.warn,
    required this.ok,
  });

  final bool dark;
  final Color bg1, bg2, surface, glass, border, text, muted, sheet, warn, ok;

  static const light = Pal(
    dark: false,
    bg1: Color(0xFFF1ECFF),
    bg2: Color(0xFFFBFAFF),
    surface: Color(0xFFFFFFFF),
    glass: Color(0xB8FFFFFF),
    border: Color(0x14281C64),
    text: Color(0xFF1B1536),
    muted: Color(0xFF625C7E),
    sheet: Color(0xFFFFFFFF),
    warn: Color(0xFFC81E5E),
    ok: Color(0xFF087F6B),
  );

  static const darkPal = Pal(
    dark: true,
    bg1: Color(0xFF120E26),
    bg2: Color(0xFF1C1540),
    surface: Color(0x14FFFFFF),
    glass: Color(0x1FFFFFFF),
    border: Color(0x1FFFFFFF),
    text: Color(0xFFF3F0FF),
    muted: Color(0xFFB4AED2),
    sheet: Color(0xFF211A46),
    warn: Color(0xFFFF8FBF),
    ok: Color(0xFF4FE3C8),
  );

  static Pal of(BuildContext c) => Theme.of(c).extension<Pal>()!;

  @override
  Pal copyWith() => this;

  @override
  Pal lerp(ThemeExtension<Pal>? other, double t) => t < 0.5 ? this : (other is Pal ? other : this);
}

ThemeData buildTheme(Brightness b) {
  final dark = b == Brightness.dark;
  final p = dark ? Pal.darkPal : Pal.light;
  final scheme = ColorScheme.fromSeed(seedColor: Brand.violet, brightness: b).copyWith(
    primary: dark ? Brand.violetSoft : Brand.violetDeep,
    surface: p.sheet,
    onSurface: p.text,
  );
  final base = ThemeData(
    useMaterial3: true,
    brightness: b,
    colorScheme: scheme,
    scaffoldBackgroundColor: p.bg1,
    extensions: [p],
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    }),
    dialogTheme: DialogThemeData(
      backgroundColor: p.sheet,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Rd.xl)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: dark ? const Color(0xFF2D2460) : const Color(0xFF1B1536),
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Rd.m)),
    ),
  );
  return base.copyWith(textTheme: base.textTheme.apply(bodyColor: p.text, displayColor: p.text));
}

/// Text styles. Arabic never gets negative letter spacing (it breaks joined letters).
class Tx {
  Tx._();
  static bool _ar(BuildContext c) => Localizations.localeOf(c).languageCode == 'ar';

  static TextStyle title(BuildContext c, {double size = 28, Color? color}) => TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: _ar(c) ? 0 : -0.028 * size,
        height: 1.15,
        color: color ?? Pal.of(c).text,
      );

  static TextStyle body(BuildContext c, {double size = 15, FontWeight w = FontWeight.w500, Color? color}) =>
      TextStyle(fontSize: size, fontWeight: w, height: 1.35, color: color ?? Pal.of(c).text);

  static TextStyle muted(BuildContext c, {double size = 13, FontWeight w = FontWeight.w500}) =>
      TextStyle(fontSize: size, fontWeight: w, height: 1.35, color: Pal.of(c).muted);

  /// Numbers use tabular figures so columns of prices line up.
  static TextStyle num(BuildContext c, {double size = 15, FontWeight w = FontWeight.w700, Color? color}) => TextStyle(
        fontSize: size,
        fontWeight: w,
        height: 1.15,
        color: color ?? Pal.of(c).text,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}
