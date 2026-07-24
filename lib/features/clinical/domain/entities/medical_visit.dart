import '../../../../core/domain/sync_metadata.dart';

/// Visita médica (RD-06).
class MedicalVisit {
  const MedicalVisit({
    required this.meta,
    required this.petId,
    required this.date,
    this.clinic,
    this.reason,
    this.diagnosis,
    this.treatment,
    this.notes,
    this.attachments = const [],
  });

  final SyncMetadata meta;
  final String petId;
  final DateTime date;
  final String? clinic;
  final String? reason;
  final String? diagnosis;
  final String? treatment;
  final String? notes;
  final List<String> attachments;

  String get id => meta.id;
}
