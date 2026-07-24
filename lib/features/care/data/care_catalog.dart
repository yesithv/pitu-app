import '../../pets/domain/entities/species.dart';
import '../domain/entities/care_frequency.dart';
import '../domain/entities/care_kind.dart';

/// Plantilla de cuidado del catálogo predefinido (sin identidad; es una
/// definición, no una instancia por mascota).
class CareTemplate {
  const CareTemplate(this.kind, this.name, this.frequency);
  final CareKind kind;
  final String name;
  final CareFrequency frequency;
}

/// Catálogo de cuidados por especie (RF-08), **versionado** (RF-13 / RN-09).
/// Las frecuencias son un punto de partida orientativo y quedan pendientes de
/// validación con criterio veterinario (ERS §11).
abstract class CareCatalog {
  /// Versión del catálogo. Incrementar al cambiar plantillas en una release.
  static const int version = 1;

  static const Map<Species, List<CareTemplate>> _bySpecies = {
    Species.dog: [
      CareTemplate(CareKind.vaccine, 'Vacunas', CareFrequency(6, FrequencyUnit.months)),
      CareTemplate(CareKind.deworming, 'Desparasitación', CareFrequency(4, FrequencyUnit.months)),
      CareTemplate(CareKind.dental, 'Limpieza dental', CareFrequency(12, FrequencyUnit.months)),
      CareTemplate(CareKind.bath, 'Baño', CareFrequency(2, FrequencyUnit.months)),
      CareTemplate(CareKind.nails, 'Corte de uñas', CareFrequency(2, FrequencyUnit.months)),
      CareTemplate(CareKind.weight, 'Control de peso', CareFrequency(1, FrequencyUnit.months)),
    ],
    Species.cat: [
      CareTemplate(CareKind.vaccine, 'Vacunas', CareFrequency(6, FrequencyUnit.months)),
      CareTemplate(CareKind.deworming, 'Desparasitación', CareFrequency(3, FrequencyUnit.months)),
      CareTemplate(CareKind.dental, 'Limpieza dental', CareFrequency(12, FrequencyUnit.months)),
      CareTemplate(CareKind.bath, 'Baño', CareFrequency(6, FrequencyUnit.months)),
      CareTemplate(CareKind.nails, 'Corte de uñas', CareFrequency(1, FrequencyUnit.months)),
      CareTemplate(CareKind.weight, 'Control de peso', CareFrequency(1, FrequencyUnit.months)),
    ],
    Species.other: [
      CareTemplate(CareKind.deworming, 'Desparasitación', CareFrequency(6, FrequencyUnit.months)),
      CareTemplate(CareKind.vetVisit, 'Consulta veterinaria', CareFrequency(12, FrequencyUnit.months)),
      CareTemplate(CareKind.weight, 'Control de peso', CareFrequency(1, FrequencyUnit.months)),
    ],
  };

  static List<CareTemplate> forSpecies(Species species) =>
      _bySpecies[species] ?? const [];
}
