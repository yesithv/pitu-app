import 'package:flutter/material.dart';

/// Tokens de color del sistema de diseño Pituped (identidad "cálido sereno").
/// Valores tomados 1:1 del entregable de Identidad Visual v1.1.
///
/// Regla de negocio de color: los semánticos (ok/due/overdue) nunca se usan
/// como color de marca; el acento cálido (accent) solo en paywall/ilustración.
@immutable
class AppColors {
  const AppColors({
    required this.brand,
    required this.brandHover,
    required this.brandSoft,
    required this.accent,
    required this.accentInk,
    required this.bg,
    required this.card,
    required this.alt,
    required this.border,
    required this.borderStrong,
    required this.text,
    required this.text2,
    required this.text3,
    required this.onBrand,
    required this.ok,
    required this.okSoft,
    required this.due,
    required this.dueSoft,
    required this.over,
    required this.overSoft,
    required this.dxActive,
    required this.dxTreat,
    required this.dxChronic,
    required this.dxResolved,
    required this.shadowRest,
    required this.shadowUp,
    required this.shadowFab,
  });

  final Color brand;
  final Color brandHover;
  final Color brandSoft;
  final Color accent;

  /// Tinta de texto sobre superficies de acento (chips "Pro").
  final Color accentInk;

  final Color bg;
  final Color card;
  final Color alt;
  final Color border;
  final Color borderStrong;

  final Color text;
  final Color text2;
  final Color text3;
  final Color onBrand;

  // Semánticos de cumplimiento.
  final Color ok;
  final Color okSoft;
  final Color due;
  final Color dueSoft;
  final Color over;
  final Color overSoft;

  // Semánticos de diagnóstico (escala distinta al cumplimiento).
  final Color dxActive;
  final Color dxTreat;
  final Color dxChronic;
  final Color dxResolved;

  final Color shadowRest;
  final Color shadowUp;
  final Color shadowFab;

  static const AppColors light = AppColors(
    brand: Color(0xFF14595F),
    brandHover: Color(0xFF0E4247),
    brandSoft: Color(0xFFD8EAEB),
    accent: Color(0xFFE8B04B),
    accentInk: Color(0xFF8A6A1F),
    bg: Color(0xFFFAF7F2),
    card: Color(0xFFFFFFFF),
    alt: Color(0xFFF3EEE6),
    border: Color(0xFFE4DCD0),
    borderStrong: Color(0xFFCFC4B4),
    text: Color(0xFF2A2724),
    text2: Color(0xFF6B645C),
    text3: Color(0xFF948C82),
    onBrand: Color(0xFFFFFFFF),
    ok: Color(0xFF47935B),
    okSoft: Color(0xFFE3F1E6),
    due: Color(0xFFC98518),
    dueSoft: Color(0xFFFBEEDA),
    over: Color(0xFFC2473D),
    overSoft: Color(0xFFFAE3E1),
    dxActive: Color(0xFF7B5EA7),
    dxTreat: Color(0xFF4A7BC8),
    dxChronic: Color(0xFF6B645C),
    dxResolved: Color(0xFF948C82),
    shadowRest: Color(0x0F2A2724),
    shadowUp: Color(0x1A2A2724),
    shadowFab: Color(0x3D14595F),
  );

  static const AppColors dark = AppColors(
    brand: Color(0xFF4FA8AD),
    brandHover: Color(0xFF7EC4C8),
    brandSoft: Color(0xFF1C3D40),
    accent: Color(0xFFE8B04B),
    accentInk: Color(0xFFE8B04B),
    bg: Color(0xFF1A1917),
    card: Color(0xFF232120),
    alt: Color(0xFF2C2927),
    border: Color(0xFF3A3633),
    borderStrong: Color(0xFF4A4541),
    text: Color(0xFFF0EBE4),
    text2: Color(0xFFB0A89E),
    text3: Color(0xFF847C73),
    onBrand: Color(0xFF10302F),
    ok: Color(0xFF63B377),
    okSoft: Color(0xFF1E3527),
    due: Color(0xFFE0A548),
    dueSoft: Color(0xFF3A2E17),
    over: Color(0xFFE07A6E),
    overSoft: Color(0xFF3B221F),
    dxActive: Color(0xFFA98BD1),
    dxTreat: Color(0xFF7BA6E8),
    dxChronic: Color(0xFFB0A89E),
    dxResolved: Color(0xFF847C73),
    shadowRest: Color(0x4D000000),
    shadowUp: Color(0x66000000),
    shadowFab: Color(0x80000000),
  );
}

/// Acceso ergonómico a los tokens desde cualquier widget: `context.colors`.
extension AppColorsX on BuildContext {
  AppColors get colors =>
      Theme.of(this).brightness == Brightness.dark ? AppColors.dark : AppColors.light;
}
