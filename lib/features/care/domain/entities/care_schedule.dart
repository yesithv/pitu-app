import '../../../../core/domain/sync_metadata.dart';
import 'care_frequency.dart';
import 'care_kind.dart';

/// Programación de un cuidado para una mascota (RD-04). Mantiene la frecuencia
/// efectiva (editable respecto a la sugerida) y la próxima fecha calculada.
class CareSchedule {
  const CareSchedule({
    required this.meta,
    required this.petId,
    required this.careTypeId,
    required this.name,
    required this.kind,
    required this.frequency,
    required this.nextDate,
    this.lastDoneDate,
    this.reminderEnabled = true,
    this.isActive = true,
  });

  final SyncMetadata meta;
  final String petId;
  final String careTypeId;

  /// Se denormaliza el nombre y tipo del cuidado para render eficiente.
  final String name;
  final CareKind kind;

  final CareFrequency frequency;
  final DateTime nextDate;
  final DateTime? lastDoneDate;
  final bool reminderEnabled;
  final bool isActive;

  String get id => meta.id;

  CareSchedule copyWith({
    SyncMetadata? meta,
    String? name,
    CareFrequency? frequency,
    DateTime? nextDate,
    DateTime? lastDoneDate,
    bool? reminderEnabled,
    bool? isActive,
  }) {
    return CareSchedule(
      meta: meta ?? this.meta,
      petId: petId,
      careTypeId: careTypeId,
      name: name ?? this.name,
      kind: kind,
      frequency: frequency ?? this.frequency,
      nextDate: nextDate ?? this.nextDate,
      lastDoneDate: lastDoneDate ?? this.lastDoneDate,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      isActive: isActive ?? this.isActive,
    );
  }
}
