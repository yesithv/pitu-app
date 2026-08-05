import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitu_app/core/data/db_codec.dart';
import 'package:pitu_app/core/data/drift/app_database.dart';
import 'package:pitu_app/core/data/drift_persistence.dart';
import 'package:pitu_app/core/data/in_memory_database.dart';
import 'package:pitu_app/core/data/seed.dart';
import 'package:pitu_app/core/utils/clock.dart';
import 'package:pitu_app/core/utils/id_generator.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Verifica la **migración sin pérdida** del snapshot JSON previo
/// (`pituapp.snapshot.v1` en `shared_preferences`) a la base Drift la primera vez
/// que arranca el build cifrado.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final clock = FixedClock(DateTime(2026, 7, 22));

  test('migra el snapshot v1 previo a la base sin pérdida de datos', () async {
    // Snapshot previo (formato DbCodec) presente en shared_preferences.
    final legacy = InMemoryDatabase();
    DatabaseSeeder(legacy, const UuidGenerator(), clock, demo: true).seed();
    final snapshot = jsonEncode(DbCodec.encode(legacy));
    SharedPreferences.setMockInitialValues({'pituapp.snapshot.v1': snapshot});
    final prefs = await SharedPreferences.getInstance();

    final db = AppDatabase(NativeDatabase.memory());
    final persistence = await DriftPersistence.open(db, prefs: prefs);

    // El cache tras la migración ya trae los datos.
    final restored = InMemoryDatabase();
    expect(persistence.loadInto(restored), isTrue);
    expect(restored.pets.length, legacy.pets.length);
    expect(restored.pets.first.id, legacy.pets.first.id);

    // Y quedaron escritos en la base: reabrir SIN prefs debe leerlos de Drift.
    final reopened = await DriftPersistence.open(db);
    final again = InMemoryDatabase();
    expect(reopened.loadInto(again), isTrue);
    expect(again.pets.length, legacy.pets.length);

    await db.close();
  });

  test('sin snapshot previo la base arranca vacía', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase(NativeDatabase.memory());
    final persistence = await DriftPersistence.open(db, prefs: prefs);
    final restored = InMemoryDatabase();
    expect(persistence.loadInto(restored), isFalse);
    await db.close();
  });
}
