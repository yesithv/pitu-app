import '../../../../core/domain/sync_metadata.dart';
import '../../../pets/domain/entities/pet.dart';

/// Registro de peso (RD-09).
class WeightRecord {
  const WeightRecord({
    required this.meta,
    required this.petId,
    required this.value,
    required this.unit,
    required this.date,
    this.note,
  });

  final SyncMetadata meta;
  final String petId;
  final double value;
  final WeightUnit unit;
  final DateTime date;
  final String? note;

  String get id => meta.id;
}
