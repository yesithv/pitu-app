import '../../../../core/domain/sync_metadata.dart';

/// Vacuna (RD-07).
class Vaccine {
  const Vaccine({
    required this.meta,
    required this.petId,
    required this.type,
    required this.appliedDate,
    this.nextDoseDate,
    this.clinic,
    this.attachment,
  });

  final SyncMetadata meta;
  final String petId;
  final String type;
  final DateTime appliedDate;
  final DateTime? nextDoseDate;
  final String? clinic;
  final String? attachment;

  String get id => meta.id;
}
