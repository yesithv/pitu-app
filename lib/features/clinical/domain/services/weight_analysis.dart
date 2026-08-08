import '../../../pets/domain/entities/pet.dart';

/// Sentido de la variación de peso.
enum WeightTrend { up, down }

/// Resultado de comparar un peso nuevo contra el anterior (RF-23). Es un aviso
/// **informativo, no diagnóstico**: solo indica el sentido y el porcentaje de la
/// variación cuando supera el umbral.
class WeightVariation {
  const WeightVariation(this.trend, this.percent);
  final WeightTrend trend;
  final int percent;
}

/// Umbral de variación (10%) por encima del cual se muestra el aviso.
const double kWeightVariationThreshold = 0.10;

/// Convierte un peso a kg para comparar en una única unidad.
double _toKg(double value, WeightUnit unit) =>
    unit == WeightUnit.lb ? value * 0.453592 : value;

/// Calcula la variación de peso respecto al registro anterior. Devuelve `null`
/// cuando no hay variación significativa (< 10%) o el peso previo no es válido.
/// Mantiene la lógica pura y sin dependencias de UI para poder validarla con
/// pruebas unitarias (RF-23).
WeightVariation? weightVariation({
  required double previousValue,
  required WeightUnit previousUnit,
  required double newValue,
  required WeightUnit newUnit,
}) {
  final prevKg = _toKg(previousValue, previousUnit);
  if (prevKg <= 0) return null;
  final newKg = _toKg(newValue, newUnit);
  final delta = (newKg - prevKg) / prevKg;
  if (delta.abs() < kWeightVariationThreshold) return null;
  return WeightVariation(
    delta > 0 ? WeightTrend.up : WeightTrend.down,
    (delta.abs() * 100).round(),
  );
}
