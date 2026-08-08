import 'package:flutter_test/flutter_test.dart';
import 'package:pitu_app/features/reports/application/pet_report_service.dart';

/// Selección de contenido del reporte veterinario (RF-38): completo, solo
/// vacunas o rango de fechas.
void main() {
  group('ReportOptions.includes', () {
    test('full incluye cualquier fecha', () {
      expect(ReportOptions.full.includes(DateTime(2000, 1, 1)), isTrue);
      expect(ReportOptions.full.includes(DateTime(2030, 12, 31)), isTrue);
    });

    test('respeta el límite inferior del rango', () {
      const opts = ReportOptions(from: null);
      expect(opts.includes(DateTime(2026, 1, 1)), isTrue);
      final ranged = ReportOptions(from: DateTime(2026, 6, 1));
      expect(ranged.includes(DateTime(2026, 5, 31)), isFalse);
      expect(ranged.includes(DateTime(2026, 6, 1)), isTrue);
    });

    test('respeta el límite superior del rango', () {
      final ranged = ReportOptions(to: DateTime(2026, 6, 30));
      expect(ranged.includes(DateTime(2026, 6, 30)), isTrue);
      expect(ranged.includes(DateTime(2026, 7, 1)), isFalse);
    });

    test('rango cerrado acepta solo fechas dentro', () {
      final ranged =
          ReportOptions(from: DateTime(2026, 6, 1), to: DateTime(2026, 6, 30));
      expect(ranged.includes(DateTime(2026, 6, 15)), isTrue);
      expect(ranged.includes(DateTime(2026, 5, 20)), isFalse);
      expect(ranged.includes(DateTime(2026, 7, 20)), isFalse);
    });

    test('onlyVaccines es una bandera independiente del rango', () {
      const opts = ReportOptions(onlyVaccines: true);
      expect(opts.onlyVaccines, isTrue);
      expect(opts.includes(DateTime(2026, 1, 1)), isTrue);
    });
  });
}
