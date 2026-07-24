import 'package:flutter_test/flutter_test.dart';
import 'package:pitu_app/features/care/domain/entities/care_frequency.dart';
import 'package:pitu_app/features/care/domain/entities/care_kind.dart';
import 'package:pitu_app/features/care/domain/entities/care_schedule.dart';
import 'package:pitu_app/features/care/domain/entities/compliance.dart';
import 'package:pitu_app/features/care/domain/services/scheduling_service.dart';
import 'package:pitu_app/core/domain/sync_metadata.dart';

void main() {
  const service = SchedulingService();
  final now = DateTime(2026, 7, 22);

  group('CareFrequency', () {
    test('suma meses correctamente', () {
      final result = const CareFrequency(6, FrequencyUnit.months)
          .addTo(DateTime(2026, 1, 15));
      expect(result, DateTime(2026, 7, 15));
    });

    test('suma años correctamente', () {
      final result =
          const CareFrequency(1, FrequencyUnit.years).addTo(DateTime(2026, 3, 1));
      expect(result, DateTime(2027, 3, 1));
    });

    test('etiqueta legible', () {
      expect(const CareFrequency(1, FrequencyUnit.months).label, 'Cada mes');
      expect(const CareFrequency(4, FrequencyUnit.months).label, 'Cada 4 meses');
    });
  });

  group('SchedulingService.statusOf', () {
    test('vencido -> overdue', () {
      expect(service.statusOf(DateTime(2026, 7, 17), now),
          ComplianceStatus.overdue);
    });
    test('dentro de la ventana -> due', () {
      expect(service.statusOf(DateTime(2026, 7, 25), now), ComplianceStatus.due);
    });
    test('lejano -> ok', () {
      expect(service.statusOf(DateTime(2026, 9, 1), now), ComplianceStatus.ok);
    });
  });

  group('SchedulingService.relativeLabel', () {
    test('texto de vencido', () {
      expect(service.relativeLabel(DateTime(2026, 7, 17), now),
          'Venció hace 5 días');
    });
    test('texto de próximo', () {
      expect(service.relativeLabel(DateTime(2026, 7, 25), now), 'En 3 días');
    });
  });

  group('SchedulingService.complianceOf', () {
    CareSchedule schedule(DateTime next) => CareSchedule(
          meta: SyncMetadata.create(id: next.toIso8601String(), now: now),
          petId: 'p1',
          careTypeId: 'c1',
          name: 'Cuidado',
          kind: CareKind.bath,
          frequency: const CareFrequency(1, FrequencyUnit.months),
          nextDate: next,
        );

    test('cuenta atrasados y al día', () {
      final schedules = [
        schedule(DateTime(2026, 7, 10)), // overdue
        schedule(DateTime(2026, 7, 24)), // due
        schedule(DateTime(2026, 9, 1)), // ok
      ];
      final compliance = service.complianceOf(schedules, now);
      expect(compliance.total, 3);
      expect(compliance.overdue, 1);
      expect(compliance.due, 1);
      expect(compliance.upToDate, 2);
      expect(compliance.isAllUpToDate, isFalse);
    });

    test('todo al día', () {
      final compliance = service.complianceOf([schedule(DateTime(2026, 9, 1))], now);
      expect(compliance.isAllUpToDate, isTrue);
      expect(compliance.percent, 100);
    });
  });
}
