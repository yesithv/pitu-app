import 'package:flutter/widgets.dart';

/// Escala de espaciado base 4 (identidad §5). Valores permitidos únicamente.
abstract class Gap {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Padding horizontal estándar de pantalla.
  static const double screenH = 16;

  /// Área táctil mínima (sin excepciones).
  static const double minTouch = 48;
}

/// Radios de esquina (identidad §5): píldoras para acción/navegación,
/// radios moderados para contenedores de datos.
abstract class Radii {
  static const Radius card = Radius.circular(16);
  static const Radius field = Radius.circular(12);
  static const Radius pill = Radius.circular(999);
  static const Radius sheet = Radius.circular(24);
  static const Radius thumb = Radius.circular(8);

  static const BorderRadius cardAll = BorderRadius.all(card);
  static const BorderRadius fieldAll = BorderRadius.all(field);
  static const BorderRadius pillAll = BorderRadius.all(pill);
  static const BorderRadius sheetTop =
      BorderRadius.only(topLeft: sheet, topRight: sheet);
}
