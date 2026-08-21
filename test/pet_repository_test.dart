import 'package:flutter_test/flutter_test.dart';
import 'package:pitu_app/core/data/in_memory_database.dart';
import 'package:pitu_app/core/domain/sync_metadata.dart';
import 'package:pitu_app/core/utils/clock.dart';
import 'package:pitu_app/features/attachments/domain/entities/attachment.dart';
import 'package:pitu_app/features/care/domain/entities/care_execution.dart';
import 'package:pitu_app/features/care/domain/entities/care_schedule.dart';
import 'package:pitu_app/features/clinical/domain/entities/diagnosis.dart';
import 'package:pitu_app/features/clinical/domain/entities/medical_visit.dart';
import 'package:pitu_app/features/clinical/domain/entities/vaccine.dart';
import 'package:pitu_app/features/clinical/domain/entities/weight_record.dart';
import 'package:pitu_app/features/pets/data/pet_repository_impl.dart';
import 'package:pitu_app/features/pets/domain/entities/pet.dart';
import 'package:pitu_app/features/pets/domain/entities/species.dart';

import 'support/care_fixtures.dart';

/// Cobertura del ciclo de vida de una mascota en el repositorio: archivar
/// (RF-03/RF-04), desarchivar (RF-05), eliminar definitivamente (RF-06),
/// listar activas/archivadas (RF-07) y borrado lógico (RD-18).
void main() {
  late InMemoryDatabase db;
  late FixedClock clock;
  late InMemoryPetRepository repo;

  setUp(() {
    db = InMemoryDatabase();
    clock = FixedClock(DateTime(2026, 7, 22));
    repo = InMemoryPetRepository(db, clock);
  });

  Pet buildPet(String id, {PetStatus status = PetStatus.active}) => Pet(
        meta: SyncMetadata.create(id: id, now: clock.now()),
        name: 'Pitufo-$id',
        species: Species.dog,
        status: status,
      );

  CareSchedule schedule(String id, String petId, DateTime next) => careSchedule(
        next,
        now: clock.now(),
        id: id,
        petId: petId,
        careTypeId: 'ct-$id',
        name: 'Baño',
      );

  group('listado y búsqueda (RF-07)', () {
    test('activePets excluye archivadas y borradas', () {
      repo.create(buildPet('a'));
      repo.create(buildPet('b', status: PetStatus.archived));
      final active = repo.activePets();
      expect(active, hasLength(1));
      expect(active.single.id, 'a');
    });

    test('archivedPets solo lista archivadas no borradas', () {
      repo.create(buildPet('a'));
      repo.create(buildPet('b', status: PetStatus.archived));
      final archived = repo.archivedPets();
      expect(archived, hasLength(1));
      expect(archived.single.id, 'b');
    });

    test('findById ignora las mascotas con borrado lógico', () {
      repo.create(buildPet('a'));
      expect(repo.findById('a'), isNotNull);
      repo.softDelete('a');
      expect(repo.findById('a'), isNull);
    });
  });

  group('archivar (RF-03/RF-04)', () {
    test('detiene los recordatorios de sus programaciones', () {
      repo.create(buildPet('a'));
      db.schedules.add(schedule('s1', 'a', DateTime(2026, 8, 1)));
      db.schedules.add(schedule('s2', 'a', DateTime(2026, 8, 5)));
      // Programación de otra mascota: no debe tocarse.
      repo.create(buildPet('b'));
      db.schedules.add(schedule('s3', 'b', DateTime(2026, 8, 5)));

      repo.archive('a', reason: ArchiveReason.rehomed);

      expect(db.schedules.firstWhere((s) => s.id == 's1').reminderEnabled, isFalse);
      expect(db.schedules.firstWhere((s) => s.id == 's2').reminderEnabled, isFalse);
      expect(db.schedules.firstWhere((s) => s.id == 's3').reminderEnabled, isTrue);
    });

    test('marca el estado como archivada y guarda el motivo opcional', () {
      repo.create(buildPet('a'));
      repo.archive('a', reason: ArchiveReason.deceased);
      final pet = repo.archivedPets().single;
      expect(pet.isArchived, isTrue);
      expect(pet.archiveReason, ArchiveReason.deceased);
    });

    test('conserva íntegro el historial de la mascota (RF-03)', () {
      repo.create(buildPet('a'));
      db.weights.add(WeightRecord(
        meta: SyncMetadata.create(id: 'w1', now: clock.now()),
        petId: 'a',
        value: 10,
        unit: WeightUnit.kg,
        date: DateTime(2026, 7, 1),
      ));
      repo.archive('a');
      expect(db.weights, hasLength(1));
    });

    test('archivar un id inexistente no lanza', () {
      expect(() => repo.archive('nope'), returnsNormally);
    });
  });

  group('desarchivar (RF-05)', () {
    test('reactiva recordatorios y recalcula la próxima fecha vencida', () {
      repo.create(buildPet('a', status: PetStatus.archived));
      // Próxima fecha en el pasado y recordatorio detenido.
      db.schedules.add(schedule('s1', 'a', DateTime(2026, 5, 15))
          .copyWith(reminderEnabled: false));

      repo.unarchive('a');

      final s = db.schedules.single;
      expect(s.reminderEnabled, isTrue);
      // Frecuencia mensual: la próxima fecha debe ser >= hoy (2026-07-22).
      expect(s.nextDate.isBefore(DateTime(2026, 7, 22)), isFalse);
      expect(s.nextDate, DateTime(2026, 8, 15));
    });

    test('no adelanta una próxima fecha que aún es futura', () {
      repo.create(buildPet('a', status: PetStatus.archived));
      db.schedules.add(schedule('s1', 'a', DateTime(2026, 9, 1))
          .copyWith(reminderEnabled: false));
      repo.unarchive('a');
      expect(db.schedules.single.nextDate, DateTime(2026, 9, 1));
    });

    test('vuelve a listar la mascota como activa', () {
      repo.create(buildPet('a', status: PetStatus.archived));
      repo.unarchive('a');
      expect(repo.activePets().map((p) => p.id), contains('a'));
      expect(repo.archivedPets(), isEmpty);
    });
  });

  group('eliminar definitivamente (RF-06 / RD-18)', () {
    test('aplica borrado lógico a la mascota y purga sus datos asociados', () {
      repo.create(buildPet('a'));
      db.schedules.add(schedule('s1', 'a', DateTime(2026, 8, 1)));
      db.executions.add(CareExecution(
        meta: SyncMetadata.create(id: 'e1', now: clock.now()),
        scheduleId: 's1',
        petId: 'a',
        name: 'Baño',
        date: DateTime(2026, 7, 1),
      ));
      db.diagnoses.add(Diagnosis(
        meta: SyncMetadata.create(id: 'd1', now: clock.now()),
        petId: 'a',
        condition: 'x',
        date: DateTime(2026, 7, 1),
        status: DiagnosisStatus.active,
      ));
      db.weights.add(WeightRecord(
        meta: SyncMetadata.create(id: 'w1', now: clock.now()),
        petId: 'a',
        value: 10,
        unit: WeightUnit.kg,
        date: DateTime(2026, 7, 1),
      ));
      db.visits.add(MedicalVisit(
        meta: SyncMetadata.create(id: 'v1', now: clock.now()),
        petId: 'a',
        date: DateTime(2026, 7, 1),
      ));
      db.vaccines.add(Vaccine(
        meta: SyncMetadata.create(id: 'vac1', now: clock.now()),
        petId: 'a',
        type: 'Rabia',
        appliedDate: DateTime(2026, 7, 1),
      ));
      db.attachments.add(Attachment(
        meta: SyncMetadata.create(id: 'at1', now: clock.now()),
        petId: 'a',
        filename: 'f.pdf',
        mimeType: 'application/pdf',
        sizeBytes: 10,
        dataBase64: 'AA==',
        addedAt: clock.now(),
      ));

      repo.softDelete('a');

      // La mascota conserva su fila pero con deleted_at (borrado lógico).
      final row = db.pets.firstWhere((p) => p.id == 'a');
      expect(row.meta.isDeleted, isTrue);
      // Sus datos asociados quedan purgados.
      expect(db.schedules, isEmpty);
      expect(db.executions, isEmpty);
      expect(db.diagnoses, isEmpty);
      expect(db.weights, isEmpty);
      expect(db.visits, isEmpty);
      expect(db.vaccines, isEmpty);
      expect(db.attachments, isEmpty);
    });

    test('la mascota borrada desaparece de todas las listas', () {
      repo.create(buildPet('a'));
      repo.softDelete('a');
      expect(repo.activePets(), isEmpty);
      expect(repo.archivedPets(), isEmpty);
    });
  });

  test('update refresca updatedAt (RD-18)', () {
    repo.create(buildPet('a'));
    final before = repo.findById('a')!.meta.updatedAt;
    clock.setTo(DateTime(2026, 7, 23));
    repo.update(repo.findById('a')!.copyWith(name: 'Nuevo'));
    final after = repo.findById('a')!;
    expect(after.name, 'Nuevo');
    expect(after.meta.updatedAt.isAfter(before), isTrue);
  });
}
