import '../../../../core/domain/sync_metadata.dart';
import 'species.dart';

enum WeightUnit {
  kg('kg'),
  lb('lb');

  const WeightUnit(this.label);
  final String label;
}

enum PetStatus { active, archived }

/// Motivo de archivado (RF-04). Opcional, sin texto obligatorio.
enum ArchiveReason {
  deceased('Falleció'),
  rehomed('Cambió de hogar'),
  other('Otro');

  const ArchiveReason(this.label);
  final String label;
}

/// Mascota (RD-02). Entidad de dominio inmutable.
class Pet {
  const Pet({
    required this.meta,
    required this.name,
    required this.species,
    this.birthDate,
    this.ageText,
    this.weight,
    this.weightUnit = WeightUnit.kg,
    this.breed,
    this.photoPath,
    this.photoBase64,
    this.status = PetStatus.active,
    this.archiveReason,
  });

  final SyncMetadata meta;
  final String name;
  final Species species;
  final DateTime? birthDate;

  /// Edad aproximada en texto cuando no hay fecha exacta (ej. "4 años").
  final String? ageText;
  final double? weight;
  final WeightUnit weightUnit;
  final String? breed;
  final String? photoPath;

  /// Foto de la mascota embebida en base64 (sin prefijo `data:`). Local-first:
  /// viaja en el snapshot y el respaldo, como los adjuntos.
  final String? photoBase64;
  final PetStatus status;
  final ArchiveReason? archiveReason;

  String get id => meta.id;
  bool get isActive => status == PetStatus.active && !meta.isDeleted;
  bool get isArchived => status == PetStatus.archived;

  /// Subtítulo tipo "Perro · Labrador · 4 años · 28 kg".
  String get subtitle {
    final parts = <String>[species.label];
    if (breed != null && breed!.isNotEmpty) parts.add(breed!);
    if (ageText != null && ageText!.isNotEmpty) parts.add(ageText!);
    if (weight != null) parts.add('${_trimWeight(weight!)} ${weightUnit.label}');
    return parts.join(' · ');
  }

  /// Subtítulo corto para listas (sin peso).
  String get shortSubtitle {
    final parts = <String>[species.label];
    if (breed != null && breed!.isNotEmpty) parts.add(breed!);
    if (ageText != null && ageText!.isNotEmpty) parts.add(ageText!);
    return parts.join(' · ');
  }

  static String _trimWeight(double w) =>
      w == w.roundToDouble() ? w.toInt().toString() : w.toString();

  Pet copyWith({
    SyncMetadata? meta,
    String? name,
    Species? species,
    DateTime? birthDate,
    String? ageText,
    double? weight,
    WeightUnit? weightUnit,
    String? breed,
    String? photoPath,
    String? photoBase64,
    bool clearPhoto = false,
    bool clearBirthDate = false,
    PetStatus? status,
    ArchiveReason? archiveReason,
  }) {
    return Pet(
      meta: meta ?? this.meta,
      name: name ?? this.name,
      species: species ?? this.species,
      birthDate: clearBirthDate ? null : (birthDate ?? this.birthDate),
      ageText: ageText ?? this.ageText,
      weight: weight ?? this.weight,
      weightUnit: weightUnit ?? this.weightUnit,
      breed: breed ?? this.breed,
      photoPath: photoPath ?? this.photoPath,
      photoBase64: clearPhoto ? null : (photoBase64 ?? this.photoBase64),
      status: status ?? this.status,
      archiveReason: archiveReason ?? this.archiveReason,
    );
  }
}
