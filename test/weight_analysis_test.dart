import 'package:flutter_test/flutter_test.dart';
import 'package:pitu_app/features/clinical/domain/services/weight_analysis.dart';
import 'package:pitu_app/features/pets/domain/entities/pet.dart';

/// Aviso informativo (no diagnóstico) de variación de peso (RF-23).
void main() {
  WeightVariation? call(double prev, double now,
          {WeightUnit prevU = WeightUnit.kg, WeightUnit nowU = WeightUnit.kg}) =>
      weightVariation(
        previousValue: prev,
        previousUnit: prevU,
        newValue: now,
        newUnit: nowU,
      );

  test('variación por debajo del 10% no genera aviso', () {
    expect(call(10, 10.9), isNull); // +9%
    expect(call(10, 9.1), isNull); // -9%
    expect(call(10, 10), isNull); // sin cambio
  });

  test('subida significativa se reporta hacia arriba', () {
    final v = call(10, 12); // +20%
    expect(v, isNotNull);
    expect(v!.trend, WeightTrend.up);
    expect(v.percent, 20);
  });

  test('bajada significativa se reporta hacia abajo', () {
    final v = call(10, 8); // -20%
    expect(v!.trend, WeightTrend.down);
    expect(v.percent, 20);
  });

  test('el umbral del 10% exacto se considera significativo', () {
    final v = call(10, 11); // +10%
    expect(v, isNotNull);
    expect(v!.percent, 10);
  });

  test('normaliza unidades distintas antes de comparar', () {
    // 10 kg ≈ 22.05 lb. Registrar 22 lb es prácticamente el mismo peso.
    expect(call(10, 22, nowU: WeightUnit.lb), isNull);
    // Registrar 30 lb (~13.6 kg) sí es una subida >10%.
    final v = call(10, 30, nowU: WeightUnit.lb);
    expect(v, isNotNull);
    expect(v!.trend, WeightTrend.up);
  });

  test('peso previo no válido (<=0) no genera aviso', () {
    expect(call(0, 12), isNull);
  });
}
