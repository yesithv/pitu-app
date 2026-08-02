import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_dimens.dart';

/// Construye los [ThemeData] claro y oscuro a partir de los tokens de
/// [AppColors]. Los colores semánticos y de marca se consumen vía
/// `context.colors`; aquí se configura lo que Material necesita globalmente.
abstract class AppTheme {
  static ThemeData light() => _build(AppColors.light, Brightness.light);
  static ThemeData dark() => _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppColors c, Brightness brightness) {
    final base = ThemeData(brightness: brightness, useMaterial3: true);
    final scheme = ColorScheme.fromSeed(
      seedColor: c.brand,
      brightness: brightness,
    ).copyWith(
      primary: c.brand,
      onPrimary: c.onBrand,
      surface: c.card,
      onSurface: c.text,
    );

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: c.bg,
      canvasColor: c.bg,
      dividerColor: c.border,
      textTheme: GoogleFonts.nunitoSansTextTheme(base.textTheme).apply(
        bodyColor: c.text,
        displayColor: c.text,
      ),
      splashColor: c.brand.withValues(alpha: 0.08),
      highlightColor: c.brand.withValues(alpha: 0.05),
      appBarTheme: AppBarTheme(
        backgroundColor: c.bg,
        foregroundColor: c.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),
      iconTheme: IconThemeData(color: c.text2),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.card,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: Radii.sheetTop),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.text,
        contentTextStyle: TextStyle(color: c.bg),
        shape: const RoundedRectangleBorder(borderRadius: Radii.fieldAll),
      ),
    );
  }
}
