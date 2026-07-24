import '../../../../core/domain/sync_metadata.dart';

/// Estado de un diagnóstico (RF-20). Escala cromática distinta a la del
/// cumplimiento (identidad §2) para no confundir "condición" con "tarea".
enum DiagnosisStatus {
  active('Activo'),
  treatment('En tratamiento'),
  chronic('Crónico'),
  resolved('Resuelto');

  const DiagnosisStatus(this.label);
  final String label;
}

/// Diagnóstico / condición (RD-08).
class Diagnosis {
  const Diagnosis({
    required this.meta,
    required this.petId,
    required this.condition,
    required this.date,
    this.status = DiagnosisStatus.active,
    this.visitId,
    this.notes,
  });

  final SyncMetadata meta;
  final String petId;
  final String condition;
  final DateTime date;
  final DiagnosisStatus status;
  final String? visitId;
  final String? notes;

  String get id => meta.id;
  bool get isCurrent =>
      status == DiagnosisStatus.active ||
      status == DiagnosisStatus.treatment ||
      status == DiagnosisStatus.chronic;

  Diagnosis copyWith({SyncMetadata? meta, DiagnosisStatus? status, String? notes}) {
    return Diagnosis(
      meta: meta ?? this.meta,
      petId: petId,
      condition: condition,
      date: date,
      status: status ?? this.status,
      visitId: visitId,
      notes: notes ?? this.notes,
    );
  }
}
