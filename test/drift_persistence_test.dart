import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitu_app/core/data/drift/app_database.dart';
import 'package:pitu_app/core/data/drift_persistence.dart';
import 'package:pitu_app/core/data/in_memory_database.dart';
import 'package:pitu_app/core/data/seed.dart';
import 'package:pitu_app/core/domain/sync_metadata.dart';
import 'package:pitu_app/core/utils/clock.dart';
import 'package:pitu_app/core/utils/id_generator.dart';
import 'package:pitu_app/features/attachments/domain/entities/attachment.dart';
import 'package:pitu_app/features/plan/domain/plan.dart';

/// Pruebas de [DriftPersistence] usando una base Drift **en memoria sin cifrar**
/// (`NativeDatabase.memory()`). El cifrado (SQLCipher) se valida en dispositivo
/// (#4); aquí se cubre el mapeo entidad↔fila y el round-trip guardar/cargar.
void main() {
  final clock = FixedClock(DateTime(2026, 7, 22));

  AppDatabase memDb() => AppDatabase(NativeDatabase.memory());

  final attachmentBytes = Uint8List.fromList([1, 2, 3, 4]);

  InMemoryDatabase seededDb() {
    final db = InMemoryDatabase();
    DatabaseSeeder(db, const UuidGenerator(), clock, demo: true).seed();
    db.reminderLeadDays = 3;
    db.biometricLockEnabled = true;
    db.catalogAppliedVersion = 7;
    db.attachments.add(Attachment(
      meta: SyncMetadata.create(id: 'att1', now: clock.now()),
      petId: db.pets.first.id,
      filename: 'doc.pdf',
      mimeType: 'application/pdf',
      sizeBytes: attachmentBytes.length,
      dataBase64: base64Encode(attachmentBytes),
      addedAt: clock.now(),
      source: 'test',
    ));
    return db;
  }

  test('round-trip: guarda en Drift y rehidrata conservando datos', () async {
    final db = memDb();
    final source = seededDb();

    final persistence = await DriftPersistence.open(db);
    persistence.save(source);
    await persistence.flush();

    // Reabrir sobre la misma base y cargar en un modelo nuevo.
    final reopened = await DriftPersistence.open(db);
    final restored = InMemoryDatabase();
    final had = reopened.loadInto(restored);

    expect(had, isTrue);
    expect(restored.pets.length, source.pets.length);
    expect(restored.careTypes.length, source.careTypes.length);
    expect(restored.schedules.length, source.schedules.length);
    expect(restored.executions.length, source.executions.length);
    expect(restored.diagnoses.length, source.diagnoses.length);
    expect(restored.weights.length, source.weights.length);
    expect(restored.visits.length, source.visits.length);
    expect(restored.vaccines.length, source.vaccines.length);
    expect(restored.attachments.length, source.attachments.length);

    // Escalares (tabla __app_state__).
    expect(restored.ownerName, source.ownerName);
    expect(restored.planType, PlanType.pro);
    expect(restored.biometricLockEnabled, isTrue);
    expect(restored.reminderLeadDays, 3);
    expect(restored.catalogAppliedVersion, 7);

    // Adjunto: el binario viaja por la columna BLOB y se reconstruye el base64.
    final att = restored.attachments.singleWhere((a) => a.id == 'att1');
    expect(att.dataBase64, base64Encode(attachmentBytes));
    expect(att.filename, 'doc.pdf');

    // Identidad preservada (UUID de la primera mascota).
    expect(restored.pets.first.id, source.pets.first.id);

    await db.close();
  });

  test('base vacía: loadInto devuelve false para que se siembre', () async {
    final db = memDb();
    final persistence = await DriftPersistence.open(db);
    final restored = InMemoryDatabase();
    expect(persistence.loadInto(restored), isFalse);
    await db.close();
  });
}
