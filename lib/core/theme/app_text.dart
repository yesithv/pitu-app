import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Escala tipográfica del sistema (identidad §4).
/// Nunito para títulos/acciones/números; Nunito Sans para cuerpo/datos.
/// Máximo 4 niveles jerárquicos por pantalla; cuerpo ≥14sp, botón ≥16sp.
abstract class AppText {
  static TextStyle display(Color c) => GoogleFonts.nunito(
      fontSize: 28, fontWeight: FontWeight.w800, height: 1.2, letterSpacing: -0.5, color: c);

  static TextStyle title1(Color c) => GoogleFonts.nunito(
      fontSize: 22, fontWeight: FontWeight.w700, height: 1.25, color: c);

  static TextStyle title2(Color c) => GoogleFonts.nunito(
      fontSize: 18, fontWeight: FontWeight.w700, height: 1.3, color: c);

  static TextStyle cardTitle(Color c) => GoogleFonts.nunito(
      fontSize: 17, fontWeight: FontWeight.w700, height: 1.3, color: c);

  static TextStyle body(Color c) => GoogleFonts.nunitoSans(
      fontSize: 15, fontWeight: FontWeight.w400, height: 1.45, color: c);

  static TextStyle bodyStrong(Color c) => GoogleFonts.nunitoSans(
      fontSize: 15, fontWeight: FontWeight.w700, height: 1.45, color: c);

  static TextStyle button(Color c) => GoogleFonts.nunito(
      fontSize: 16, fontWeight: FontWeight.w700, height: 1.2, color: c);

  static TextStyle meta(Color c) => GoogleFonts.nunitoSans(
      fontSize: 13, fontWeight: FontWeight.w400, height: 1.4, color: c);

  static TextStyle metaStrong(Color c) => GoogleFonts.nunitoSans(
      fontSize: 13, fontWeight: FontWeight.w700, height: 1.4, color: c);

  /// Etiquetas en mayúsculas (chips de estado, encabezados de grupo).
  static TextStyle label(Color c) => GoogleFonts.nunito(
      fontSize: 11, fontWeight: FontWeight.w700, height: 1.2, letterSpacing: 0.5, color: c);

  /// Números grandes destacados (peso, precios).
  static TextStyle numberXL(Color c) => GoogleFonts.nunito(
      fontSize: 52, fontWeight: FontWeight.w800, height: 1, color: c);
}
