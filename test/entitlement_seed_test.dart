import 'package:flutter_test/flutter_test.dart';
import 'package:pitu_app/core/data/db_codec.dart';
import 'package:pitu_app/core/data/in_memory_database.dart';
import 'package:pitu_app/core/data/seed.dart';
import 'package:pitu_app/core/utils/clock.dart';
import 'package:pitu_app/core/utils/id_generator.dart';
import 'package:pitu_app/features/plan/domain/plan.dart';

void main() {
  final clock = FixedClock(DateTime(2026, 7, 22));

  group('DatabaseSeeder', () {
    test('producción (demo: false) siembra datos de ejemplo en Free', () {
      final db = InMemoryDatabase();
      DatabaseSeeder(db, const UuidGenerator(), clock, demo: false).seed();

      expect(db.pets, isNotEmpty,
          reason: 'los datos de ejemplo se siembran también en producción');
      expect(db.planType, PlanType.free);
      expect(db.purchaseSource, isNull);
    });

    test('demo (demo: true) siembra los mismos datos pero en Pro', () {
      final db = InMemoryDatabase();
      DatabaseSeeder(db, const UuidGenerator(), clock, demo: true).seed();

      expect(db.pets, isNotEmpty);
      expect(db.planType, PlanType.pro);
      expect(db.purchaseSource, 'demo');
    });
  });

  group('DbCodec.decodeInto', () {
    test('un snapshot sin planType se decodifica como Free', () {
      final db = InMemoryDatabase()..planType = PlanType.pro;
      // Mapa mínimo válido sin la clave 'planType'.
      DbCodec.decodeInto(db, <String, dynamic>{'ownerName': 'Ana'});

      expect(db.planType, PlanType.free);
    });

    test('un snapshot con planType: pro conserva Pro', () {
      final db = InMemoryDatabase();
      DbCodec.decodeInto(db, <String, dynamic>{'planType': 'pro'});

      expect(db.planType, PlanType.pro);
    });
  });
}
