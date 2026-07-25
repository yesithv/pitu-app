import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/data/in_memory_database.dart';
import 'core/data/persistence.dart';
import 'core/data/seed.dart';
import 'core/di/providers.dart';
import 'core/utils/clock.dart';
import 'core/utils/id_generator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Carga el estado persistido (o siembra datos de ejemplo la primera vez) y
  // activa el autoguardado antes de arrancar la app.
  final prefs = await SharedPreferences.getInstance();
  final persistence = Persistence(prefs);

  final db = InMemoryDatabase();
  final loaded = persistence.loadInto(db);
  if (!loaded) {
    DatabaseSeeder(db, const UuidGenerator(), const SystemClock()).seed();
    persistence.save(db);
  }
  persistence.attachAutosave(db);

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWith((ref) => db),
      ],
      child: const PituApp(),
    ),
  );
}
