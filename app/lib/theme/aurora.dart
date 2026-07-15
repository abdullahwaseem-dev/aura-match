import 'package:flutter/material.dart';

/// The Aurora 2026 design system — bento glass, neon-cyan / hyper-violet,
/// true-black grounds. One typeface (Plus Jakarta Sans), weight-driven
/// hierarchy, layered-shadow depth instead of borders.
///
/// Token *names* are kept stable across the redesign so every screen built
/// against the original Aurora system picks up the new look automatically —
/// only the underlying values (and a few additive tokens) changed.
class AuroraColors {
  AuroraColors._();

  static const void_ = Color(0xFF040406);
  static const void2 = Color(0xFF0C0D14); // glass panel base tone
  static const surface2 = Color(0xFF14161F); // raised surfaces, rails
  static const ink = Color(0xFFF5F6FB);
  static const mist = Color(0xFF868CA8);
  static const mistDim = Color(0xFF4C5169);
  static const cyan = Color(0xFF00E8FF);
  static const cyanSoft = Color(0xFF8FF4FF);
  static const violet = Color(0xFFA64DFF);
  static const violetSoft = Color(0xFFD3ADFF);
  static const amber = Color(0xFFFFB020);
  static const warning = amber;
  static const success = Color(0xFF39FFB4);
  static const danger = Color(0xFFFF4D6D);

  static const line = Color(0x0FFFFFFF); // rgba(255,255,255,.06)
  static const lineSoft = Color(0x08FFFFFF); // rgba(255,255,255,.03)

  static const aurora = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cyan, violet],
  );

  /// The resting-state layered shadow that gives glass tiles depth without
  /// a border doing the work — contact, near, mid, ambient.
  static const List<BoxShadow> glassShadow = [
    BoxShadow(color: Color(0x80000000), blurRadius: 1, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x52000000), blurRadius: 18, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x57000000), blurRadius: 50, offset: Offset(0, 26)),
    BoxShadow(color: Color(0x3D000000), blurRadius: 96, offset: Offset(0, 50)),
  ];

  /// Appended to [glassShadow] on hover/press for AI-produced content tiles.
  static const BoxShadow cyanGlow = BoxShadow(color: Color(0x2400E8FF), blurRadius: 70);

  /// Appended to [glassShadow] on hover/press for judgment-produced tiles.
  static const BoxShadow violetGlow = BoxShadow(color: Color(0x28A64DFF), blurRadius: 70);
}

class AuroraSpacing {
  AuroraSpacing._();
  static const xs = 4.0;
  static const sm = 8.0;
  static const smd = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
  static const xxxl = 64.0;
  static const section = 96.0;
}

class AuroraRadius {
  AuroraRadius._();
  static const control = 16.0;
  static const card = 24.0;
  static const sheet = 32.0;
  static const xl = 40.0;
  static const pill = 999.0;
}

class AuroraMotion {
  AuroraMotion._();
  static const micro = Duration(milliseconds: 120);
  static const panel = Duration(milliseconds: 320);
  static const screen = Duration(milliseconds: 280);
  static const hero = Duration(milliseconds: 500);
  static const scoreReveal = Duration(milliseconds: 900);
  static const orbPulse = Duration(milliseconds: 3200);
  static const auroraEase = Curves.easeOutCubic; // "glide" — panels, hover, transitions
  static const spring = Curves.elasticOut; // press / pop feedback
}

class AuroraText {
  AuroraText._();

  static const _font = 'PlusJakartaSans';

  static const displayXl = TextStyle(
    fontFamily: _font,
    fontWeight: FontWeight.w800,
    fontSize: 42,
    height: 1.02,
    letterSpacing: -1.2,
    color: AuroraColors.ink,
  );
  static const displayL = TextStyle(
    fontFamily: _font,
    fontWeight: FontWeight.w800,
    fontSize: 28,
    height: 1.1,
    letterSpacing: -0.6,
    color: AuroraColors.ink,
  );
  static const displayM = TextStyle(
    fontFamily: _font,
    fontWeight: FontWeight.w800,
    fontSize: 20,
    height: 1.2,
    letterSpacing: -0.4,
    color: AuroraColors.ink,
  );
  static const tileValue = TextStyle(
    fontFamily: _font,
    fontWeight: FontWeight.w800,
    fontSize: 34,
    height: 1.0,
    letterSpacing: -0.8,
    color: AuroraColors.ink,
  );
  static const bodyL = TextStyle(
    fontFamily: _font,
    fontWeight: FontWeight.w500,
    fontSize: 17,
    height: 1.55,
    color: AuroraColors.ink,
  );
  static const body = TextStyle(
    fontFamily: _font,
    fontWeight: FontWeight.w500,
    fontSize: 15,
    height: 1.5,
    color: AuroraColors.ink,
  );
  static const bodySm = TextStyle(
    fontFamily: _font,
    fontWeight: FontWeight.w600,
    fontSize: 13,
    height: 1.4,
    color: AuroraColors.mist,
  );
  static const mono = TextStyle(
    fontFamily: _font,
    fontWeight: FontWeight.w700,
    fontSize: 12.5,
    letterSpacing: 0.2,
    color: AuroraColors.cyanSoft,
    fontFeatures: [FontFeature.tabularFigures()],
  );
  static const caption = TextStyle(
    fontFamily: _font,
    fontWeight: FontWeight.w700,
    fontSize: 11,
    letterSpacing: 1.4,
    color: AuroraColors.mistDim,
  );
}

ThemeData buildAuroraTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AuroraColors.void_,
    colorScheme: base.colorScheme.copyWith(
      surface: AuroraColors.void_,
      primary: AuroraColors.cyan,
      secondary: AuroraColors.violet,
      error: AuroraColors.danger,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: AuroraColors.ink,
      displayColor: AuroraColors.ink,
      fontFamily: 'PlusJakartaSans',
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    dividerColor: AuroraColors.lineSoft,
  );
}
