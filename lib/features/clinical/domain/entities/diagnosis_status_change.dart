import '../../../../core/domain/sync_metadata.dart';
import 'diagnosis.dart';

/// Registro de un cambio de estado de un diagnóstico (RF-21). Cada cambio queda
/// como una entrada propia del historial clínico, sin sobrescribir el
/// diagnóstico original. Lleva [SyncMetadata] como el resto de entidades (RD-18)
/// para viajar en el respaldo y sincronizarse en la Fase 2.
class DiagnosisStatusChange {
  const DiagnosisStatusChange({
    required this.meta,
    required this.petId,
    required this.diagnosisId,
    required this.condition,
    required this.fromStatus,
    required this.toStatus,
    required this.changedAt,
  });

  final SyncMetadata meta;
  final String petId;
  final String diagnosisId;

  /// Nombre de la condición al momento del cambio (para mostrar sin depender de
  /// que el diagnóstico siga existiendo).
  final String condition;
  final DiagnosisStatus fromStatus;
  final DiagnosisStatus toStatus;
  final DateTime changedAt;

  String get id => meta.id;
}
