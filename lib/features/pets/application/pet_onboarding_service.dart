import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/in_memory_database.dart';
import '../../../core/di/providers.dart';
import '../../../core/domain/sync_metadata.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/id_generator.dart';
import '../../care/data/care_catalog.dart';
import '../../care/domain/entities/care_schedule.dart';
import '../../care/domain/entities/care_type.dart';
import '../domain/entities/pet.dart';
import '../domain/entities/species.dart';

/// Caso de uso: crear una mascota y **precargar su plan de cuidados** según la
/// especie (RF-08). Vive en la capa de aplicación; orquesta dominio + catálogo.
class PetOnboardingService {
  PetOnboardingService(this._db, this._ids, this._clock);

  final InMemoryDatabase _db;
  final IdGenerator _ids;
  final Clock _clock;

  Pet createPet({
    required String name,
    required Species species,
    String? breed,
    String? ageText,
    DateTime? birthDate,
    double? weight,
    WeightUnit weightUnit = WeightUnit.kg,
    String? photoBase64,
  }) {
    final now = _clock.now();
    final pet = Pet(
      meta: SyncMetadata.create(id: _ids.newId(), now: now),
      name: name.trim(),
      species: species,
      breed: (breed != null && breed.trim().isEmpty) ? null : breed?.trim(),
      ageText: (ageText != null && ageText.trim().isEmpty) ? null : ageText?.trim(),
      birthDate: birthDate,
      weight: weight,
      weightUnit: weightUnit,
      photoBase64: photoBase64,
    );
    _db.pets.add(pet);

    for (final template in CareCatalog.forSpecies(species)) {
      final careType = CareType(
        meta: SyncMetadata.create(id: _ids.newId(), now: now),
        name: template.name,
        kind: template.kind,
        suggestedFrequency: template.frequency,
        speciesApplicable: species,
        catalogVersion: CareCatalog.version,
      );
      _db.careTypes.add(careType);
      _db.schedules.add(CareSchedule(
        meta: SyncMetadata.create(id: _ids.newId(), now: now),
        petId: pet.id,
        careTypeId: careType.id,
        name: template.name,
        kind: template.kind,
        frequency: template.frequency,
        nextDate: template.frequency.addTo(now),
      ));
    }

    _db.bump();
    return pet;
  }
}

final petOnboardingServiceProvider = Provider<PetOnboardingService>(
  (ref) => PetOnboardingService(
    ref.read(databaseProvider),
    ref.read(idGeneratorProvider),
    ref.read(clockProvider),
  ),
);
