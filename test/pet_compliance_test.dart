import 'package:flutter_test/flutter_test.dart';
import 'package:pitu_app/features/care/domain/entities/care_schedule.dart';
import 'package:pitu_app/features/care/domain/entities/compliance.dart';
import 'package:pitu_app/features/care/domain/services/scheduling_service.dart';

import 'support/care_fixtures.dart';

/// Indicador de cumplimiento por mascota (RF-36) con estados **mixtos**
/// (overdue + due + ok a la vez) y sus bordes de `ratio`/`percent`, que las
/// pruebas existentes no aseveran de forma explícita.
void main() {
  const service = SchedulingService(); // dueWindowDays = 7
  final now = DateTime(2026, 7, 22);

  CareSchedule schedule(DateTime next) => careSchedule(next, now: now);

  test('estados mixtos: percent/ratio se calculan sobre lo no atrasado', () {
    final schedules = [
      schedule(DateTime(2026, 7, 10)), // overdue
      schedule(DateTime(2026, 7, 24)), // due (dentro de 7 días)
      schedule(DateTime(2026, 9, 1)), // ok
      schedule(DateTime(2026, 9, 2)), // ok
    ];
    final c = service.complianceOf(schedules, now);
    expect(c.total, 4);
    expect(c.overdue, 1);
    expect(c.due, 1);
    expect(c.upToDate, 3); // total - overdue
    expect(c.ratio, closeTo(0.75, 1e-9));
    expect(c.percent, 75);
    expect(c.isAllUpToDate, isFalse);
  });

  test('todo atrasado: ratio 0 y percent 0', () {
    final schedules = [
      schedule(DateTime(2026, 7, 1)),
      schedule(DateTime(2026, 7, 2)),
    ];
    final c = service.complianceOf(schedules, now);
    expect(c.overdue, 2);
    expect(c.upToDate, 0);
    expect(c.ratio, 0);
    expect(c.percent, 0);
    expect(c.isAllUpToDate, isFalse);
  });

  test('percent redondea (2 de 3 atrasados -> 33%)', () {
    final schedules = [
      schedule(DateTime(2026, 7, 1)), // overdue
      schedule(DateTime(2026, 7, 2)), // overdue
      schedule(DateTime(2026, 9, 1)), // ok
    ];
    final c = service.complianceOf(schedules, now);
    expect(c.upToDate, 1);
    expect(c.percent, 33); // 1/3 = 0.333… -> 33
  });

  test('due no cuenta como atrasado: al día con avisos próximos', () {
    final schedules = [
      schedule(DateTime(2026, 7, 24)), // due
      schedule(DateTime(2026, 9, 1)), // ok
    ];
    final c = service.complianceOf(schedules, now);
    expect(c.overdue, 0);
    expect(c.due, 1);
    expect(c.isAllUpToDate, isTrue); // isAllUpToDate depende solo de overdue == 0
    expect(c.percent, 100);
  });

  test('sin programaciones activas devuelve el cumplimiento vacío (ratio 1)', () {
    final c = service.complianceOf(const [], now);
    expect(c, same(PetCompliance.empty));
    expect(c.ratio, 1);
    expect(c.percent, 100);
    expect(c.isAllUpToDate, isTrue);
  });
}
