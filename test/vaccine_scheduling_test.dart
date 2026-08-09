import 'package:flutter_test/flutter_test.dart';
import 'package:pitu_app/features/clinical/domain/services/vaccine_scheduling.dart';

/// Autosugerencia de la próxima dosis de vacuna (RF-19): un año después.
void main() {
  test('sugiere un año después de la aplicación', () {
    expect(suggestNextVaccineDose(DateTime(2026, 7, 22)), DateTime(2027, 7, 22));
  });

  test('conserva día y mes', () {
    expect(suggestNextVaccineDose(DateTime(2026, 1, 5)), DateTime(2027, 1, 5));
  });

  test('29 de febrero se normaliza al 1 de marzo del año siguiente', () {
    expect(suggestNextVaccineDose(DateTime(2024, 2, 29)), DateTime(2025, 3, 1));
  });
}
