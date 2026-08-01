import 'package:flutter_test/flutter_test.dart';
import 'package:pitu_app/core/data/db_codec.dart';
import 'package:pitu_app/core/data/in_memory_database.dart';
import 'package:pitu_app/core/data/seed.dart';
import 'package:pitu_app/core/utils/clock.dart';
import 'package:pitu_app/core/utils/id_generator.dart';
import 'package:pitu_app/features/plan/domain/plan.dart';

void main() {
  final clock = FixedClock(DateTime(2026, 7, 22));

  InMemoryDatabase seededDb() {
    final db = InMemoryDatabase();
    DatabaseSeeder(db, const UuidGenerator(), clock, demo: true).seed();
    db.reminderLeadDays = 3;
    db.biometricLockEnabled = true;
    return db;
  }

  test('encode incluye la versión de esquema actual', () {
    final map = DbCodec.encode(seededDb());
    expect(map['schemaVersion'], DbCodec.schemaVersion);
  });

  test('round-trip encode -> decode conserva conteos y campos clave', () {
    final source = seededDb();
    final map = DbCodec.encode(source);

    final restored = InMemoryDatabase();
    DbCodec.decodeInto(restored, map);

    // Conteos por colección.
    expect(restored.pets.length, source.pets.length);
    expect(restored.careTypes.length, source.careTypes.length);
    expect(restored.schedules.length, source.schedules.length);
    expect(restored.executions.length, source.executions.length);
    expect(restored.diagnoses.length, source.diagnoses.length);
    expect(restored.weights.length, source.weights.length);
    expect(restored.visits.length, source.visits.length);
    expect(restored.vaccines.length, source.vaccines.length);
    expect(restored.attachments.length, source.attachments.length);

    // Campos escalares.
    expect(restored.ownerName, source.ownerName);
    expect(restored.planType, source.planType);
    expect(restored.planType, PlanType.pro);
    expect(restored.biometricLockEnabled, isTrue);
    expect(restored.reminderLeadDays, 3);

    // Identidad preservada (UUID de la primera mascota).
    expect(restored.pets.first.id, source.pets.first.id);
  });
}
