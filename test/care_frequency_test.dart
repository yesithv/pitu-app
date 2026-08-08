import 'package:flutter_test/flutter_test.dart';
import 'package:pitu_app/features/care/domain/entities/care_frequency.dart';

/// Cálculo de fechas de la frecuencia de un cuidado (RF-12) y su serialización.
void main() {
  group('addTo', () {
    test('días', () {
      expect(const CareFrequency(10, FrequencyUnit.days).addTo(DateTime(2026, 1, 1)),
          DateTime(2026, 1, 11));
    });

    test('semanas', () {
      expect(const CareFrequency(2, FrequencyUnit.weeks).addTo(DateTime(2026, 1, 1)),
          DateTime(2026, 1, 15));
    });

    test('meses con acarreo de año', () {
      expect(const CareFrequency(3, FrequencyUnit.months).addTo(DateTime(2026, 11, 15)),
          DateTime(2027, 2, 15));
    });

    test('años', () {
      expect(const CareFrequency(1, FrequencyUnit.years).addTo(DateTime(2024, 2, 29)),
          DateTime(2025, 3, 1)); // 29-feb no existe en 2025 -> normaliza a 1-mar
    });

    test('preserva la hora del punto de partida en días', () {
      final from = DateTime(2026, 1, 1, 9, 30);
      expect(const CareFrequency(1, FrequencyUnit.days).addTo(from),
          DateTime(2026, 1, 2, 9, 30));
    });
  });

  group('label', () {
    test('singular', () {
      expect(const CareFrequency(1, FrequencyUnit.months).label, 'Cada mes');
    });
    test('plural', () {
      expect(const CareFrequency(6, FrequencyUnit.months).label, 'Cada 6 meses');
    });
  });

  test('json round-trip', () {
    const f = CareFrequency(4, FrequencyUnit.weeks);
    final restored = CareFrequency.fromJson(f.toJson());
    expect(restored.every, 4);
    expect(restored.unit, FrequencyUnit.weeks);
  });

  test('every debe ser positivo', () {
    expect(() => CareFrequency(0, FrequencyUnit.days), throwsA(isA<AssertionError>()));
  });
}
