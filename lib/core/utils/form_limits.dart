import 'package:flutter/services.dart';

/// Límites de entrada compartidos para evitar valores que rompan la interfaz
/// (textos desmedidos, números fuera de rango, letras donde van cifras).
abstract class FormLimits {
  static const int name = 40;
  static const int breed = 40;
  static const int note = 600;
  static const int shortText = 80; // clínica, motivo, tipo de vacuna, condición
  static const int ageText = 30;

  /// Peso máximo admitido (kg o lb), holgado para cualquier mascota.
  static const double maxWeight = 1000;

  /// Repetición máxima de una frecuencia ("cada N ..."), evita desbordes de fecha.
  static const int maxFrequencyEvery = 999;

  /// Solo dígitos y un separador decimal, hasta 6 caracteres.
  static List<TextInputFormatter> get weight => [
        LengthLimitingTextInputFormatter(6),
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
      ];
}
