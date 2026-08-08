import 'package:flutter_test/flutter_test.dart';
import 'package:pitu_app/core/data/in_memory_database.dart';
import 'package:pitu_app/core/domain/sync_metadata.dart';
import 'package:pitu_app/core/utils/clock.dart';
import 'package:pitu_app/core/utils/id_generator.dart';
import 'package:pitu_app/features/care/data/care_repository_impl.dart';
import 'package:pitu_app/features/care/domain/entities/care_frequency.dart';
import 'package:pitu_app/features/care/domain/entities/care_kind.dart';
import 'package:pitu_app/features/care/domain/entities/care_schedule.dart';
import 'package:pitu_app/features/care/domain/services/scheduling_service.dart';
import 'package:pitu_app/features/pets/domain/entities/pet.dart';
import 'package:pitu_app/features/pets/domain/entities/species.dart';

/// Generador de ids determinista para asertar con exactitud.
class _SeqIds implements IdGenerator {
  int _n = 0;
  @override
  String newId() => 'id-${++_n}';
}

/// Cobertura del repositorio de cuidados: marcar hecho + recálculo (RF-14/RF-17),
/// deshacer (RF-16), cuidados personalizados (RF-11) y recordatorio de
/// cumpleaños (extra), además del filtrado de programaciones activas.
void main() {
  late InMemoryDatabase db;
  late FixedClock clock;
  late _SeqIds ids;
  late InMemoryCareRepository repo;

  setUp(() {
    db = InMemoryDatabase();
    clock = FixedClock(DateTime(2026, 7, 22, 10));
    ids = _SeqIds();
    repo = InMemoryCareRepository(db, clock, ids, const SchedulingService());
  });

  void addPet(String id, {PetStatus status = PetStatus.active}) {
    db.pets.add(Pet(
      meta: SyncMetadata.create(id: id, now: clock.now()),
      name: 'Pitufo',
      species: Species.dog,
      status: status,
    ));
  }

  CareSchedule addSchedule(String id, String petId,
      {DateTime? next, CareFrequency freq = const CareFrequency(1, FrequencyUnit.months)}) {
    final s = CareSchedule(
      meta: SyncMetadata.create(id: id, now: clock.now()),
      petId: petId,
      careTypeId: 'ct-$id',
      name: 'Desparasitación',
      kind: CareKind.deworming,
      frequency: freq,
      nextDate: next ?? DateTime(2026, 8, 1),
    );
    db.schedules.add(s);
    return s;
  }

  group('marcar como hecho (RF-14/RF-17)', () {
    test('registra la ejecución con la fecha y recalcula la próxima fecha', () {
      addPet('p1');
      addSchedule('s1', 'p1',
          freq: const CareFrequency(3, FrequencyUnit.months));

      final exec = repo.markDone('s1', date: DateTime(2026, 7, 22));

      expect(exec.petId, 'p1');
      expect(exec.date, DateTime(2026, 7, 22));
      expect(db.executions, hasLength(1));
      final s = db.schedules.single;
      expect(s.lastDoneDate, DateTime(2026, 7, 22));
      // Próxima = última + 3 meses.
      expect(s.nextDate, DateTime(2026, 10, 22));
    });

    test('sin fecha usa el reloj actual', () {
      addPet('p1');
      addSchedule('s1', 'p1');
      final exec = repo.markDone('s1');
      expect(exec.date, clock.now());
    });

    test('lanza si la programación no existe', () {
      expect(() => repo.markDone('desconocida'), throwsStateError);
    });
  });

  group('deshacer (RF-16)', () {
    test('elimina la ejecución y restaura la programación previa', () {
      addPet('p1');
      final original = addSchedule('s1', 'p1',
          next: DateTime(2026, 8, 1),
          freq: const CareFrequency(1, FrequencyUnit.months));

      final exec = repo.markDone('s1', date: DateTime(2026, 7, 22));
      // Tras marcar, la próxima fecha cambió.
      expect(db.schedules.single.nextDate, isNot(original.nextDate));

      repo.undo(exec.id);

      expect(db.executions, isEmpty);
      final restored = db.schedules.single;
      expect(restored.nextDate, original.nextDate);
      expect(restored.lastDoneDate, isNull);
    });

    test('deshacer un id desconocido no rompe el estado', () {
      addPet('p1');
      addSchedule('s1', 'p1');
      expect(() => repo.undo('no-existe'), returnsNormally);
    });
  });

  group('cuidados personalizados (RF-11)', () {
    test('crea el tipo y la programación con la frecuencia dada', () {
      addPet('p1');
      repo.createCustomCare(
        petId: 'p1',
        name: 'Cepillado',
        frequency: const CareFrequency(2, FrequencyUnit.weeks),
      );

      final type = db.careTypes.single;
      expect(type.isCustom, isTrue);
      expect(type.kind, CareKind.custom);
      expect(type.name, 'Cepillado');

      final s = db.schedules.single;
      expect(s.name, 'Cepillado');
      expect(s.kind, CareKind.custom);
      expect(s.frequency.every, 2);
      // Próxima fecha = hoy + 2 semanas.
      expect(s.nextDate, const CareFrequency(2, FrequencyUnit.weeks).addTo(clock.now()));
    });
  });

  group('recordatorio de cumpleaños', () {
    test('crea la programación anual con la próxima fecha correcta', () {
      addPet('p1');
      // Nace un 10 de marzo; hoy es 22 jul -> próximo cumple: 2027-03-10.
      repo.syncBirthday('p1', DateTime(2020, 3, 10));
      final s = db.schedules.firstWhere((s) => s.kind == CareKind.birthday);
      expect(s.frequency.unit, FrequencyUnit.years);
      expect(s.nextDate, DateTime(2027, 3, 10));
    });

    test('cumpleaños posterior este año se mantiene en el año actual', () {
      addPet('p1');
      // Nace un 25 de diciembre; hoy 22 jul -> este año.
      repo.syncBirthday('p1', DateTime(2019, 12, 25));
      final s = db.schedules.firstWhere((s) => s.kind == CareKind.birthday);
      expect(s.nextDate, DateTime(2026, 12, 25));
    });

    test('actualiza la programación existente sin duplicarla', () {
      addPet('p1');
      repo.syncBirthday('p1', DateTime(2020, 3, 10));
      repo.syncBirthday('p1', DateTime(2020, 5, 5));
      final births =
          db.schedules.where((s) => s.kind == CareKind.birthday).toList();
      expect(births, hasLength(1));
      expect(births.single.nextDate, DateTime(2027, 5, 5));
    });

    test('sin fecha desactiva el recordatorio existente', () {
      addPet('p1');
      repo.syncBirthday('p1', DateTime(2020, 3, 10));
      repo.syncBirthday('p1', null);
      final births =
          db.schedules.where((s) => s.kind == CareKind.birthday).toList();
      expect(births.single.isActive, isFalse);
    });
  });

  group('filtrado de programaciones', () {
    test('allActiveSchedules excluye las de mascotas archivadas', () {
      addPet('p1');
      addPet('p2', status: PetStatus.archived);
      addSchedule('s1', 'p1');
      addSchedule('s2', 'p2');
      final active = repo.allActiveSchedules();
      expect(active.map((s) => s.id), ['s1']);
    });

    test('schedulesForPet omite las inactivas y borradas', () {
      addPet('p1');
      addSchedule('s1', 'p1');
      final inactive = addSchedule('s2', 'p1').copyWith(isActive: false);
      db.schedules[db.schedules.indexWhere((s) => s.id == 's2')] = inactive;
      expect(repo.schedulesForPet('p1').map((s) => s.id), ['s1']);
    });
  });
}
