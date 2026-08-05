import 'package:flutter_test/flutter_test.dart';
import 'package:pitu_app/core/data/in_memory_database.dart';
import 'package:pitu_app/core/data/seed.dart';
import 'package:pitu_app/core/utils/clock.dart';
import 'package:pitu_app/core/utils/id_generator.dart';
import 'package:pitu_app/features/plan/domain/plan.dart';
import 'package:pitu_app/features/reminders/domain/reminder_scheduler.dart';
import 'package:pitu_app/features/settings/application/wipe_service.dart';

/// Verifica "borrar todos mis datos" (RNF-13): limpia los datos personales y
/// conserva el entitlement de plan (la compra no es dato personal).
void main() {
  test('wipeAll vacía los datos y conserva el plan', () async {
    final db = InMemoryDatabase();
    DatabaseSeeder(db, const UuidGenerator(), FixedClock(DateTime(2026, 7, 22)),
            demo: true)
        .seed();
    db.planType = PlanType.pro;
    db.purchaseSource = 'play';
    db.ownerName = 'Ana';
    expect(db.pets, isNotEmpty);

    // Sin persistencia (null) ni notificaciones reales (Noop) para el test.
    final service = WipeService(db, null, const NoopReminderScheduler());
    await service.wipeAll();

    expect(db.pets, isEmpty);
    expect(db.careTypes, isEmpty);
    expect(db.schedules, isEmpty);
    expect(db.attachments, isEmpty);
    expect(db.visits, isEmpty);
    expect(db.vaccines, isEmpty);
    expect(db.weights, isEmpty);
    expect(db.diagnoses, isEmpty);
    expect(db.ownerName, '');
    expect(db.lastBackupAt, isNull);

    // El plan (compra) se conserva.
    expect(db.planType, PlanType.pro);
    expect(db.purchaseSource, 'play');
  });
}
