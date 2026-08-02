import 'package:flutter_test/flutter_test.dart';
import 'package:pitu_app/features/care/domain/entities/care_frequency.dart';
import 'package:pitu_app/features/care/domain/entities/compliance.dart';
import 'package:pitu_app/features/care/domain/services/scheduling_service.dart';

/// Complementa a `widget_test.dart` cubriendo los bordes de `SchedulingService`
/// que allí no se ejercitan (nextDateFrom, daysUntil, ventana y etiquetas).
void main() {
  const service = SchedulingService(); // dueWindowDays = 7
  final now = DateTime(2026, 7, 22);

  test('nextDateFrom aplica la frecuencia sobre la última ejecución', () {
    final next = service.nextDateFrom(
        DateTime(2026, 1, 15), const CareFrequency(6, FrequencyUnit.months));
    expect(next, DateTime(2026, 7, 15));
  });

  group('daysUntil', () {
    test('futuro es positivo', () {
      expect(service.daysUntil(DateTime(2026, 7, 25), now), 3);
    });
    test('pasado es negativo', () {
      expect(service.daysUntil(DateTime(2026, 7, 20), now), -2);
    });
    test('mismo día es cero (ignora la hora)', () {
      expect(service.daysUntil(DateTime(2026, 7, 22, 23), now), 0);
    });
  });

  group('statusOf en los bordes de la ventana', () {
    test('exactamente en la ventana (7 días) es due', () {
      expect(service.statusOf(DateTime(2026, 7, 29), now), ComplianceStatus.due);
    });
    test('justo fuera de la ventana (8 días) es ok', () {
      expect(service.statusOf(DateTime(2026, 7, 30), now), ComplianceStatus.ok);
    });
    test('hoy es due', () {
      expect(service.statusOf(now, now), ComplianceStatus.due);
    });
  });

  group('relativeLabel casos límite', () {
    test('hoy', () => expect(service.relativeLabel(now, now), 'Hoy'));
    test('mañana', () =>
        expect(service.relativeLabel(DateTime(2026, 7, 23), now), 'Mañana'));
    test('venció ayer', () =>
        expect(service.relativeLabel(DateTime(2026, 7, 21), now), 'Venció ayer'));
  });

  test('complianceOf sin programaciones devuelve vacío', () {
    final compliance = service.complianceOf(const [], now);
    expect(compliance.total, 0);
  });
}
