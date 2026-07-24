import 'diagnosis.dart';

/// Tipo de entrada en la línea de tiempo del historial (RF-24).
enum TimelineKind { visit, vaccine, care, diagnosis, weight }

/// Entrada unificada del historial clínico: integra visitas, vacunas,
/// diagnósticos, ejecuciones de cuidados y registros de peso (RF-24),
/// ordenada cronológicamente inversa.
class TimelineEntry {
  const TimelineEntry({
    required this.date,
    required this.kind,
    required this.title,
    this.subtitle,
    this.diagnosisStatus,
    this.diagnosisLabel,
  });

  final DateTime date;
  final TimelineKind kind;
  final String title;
  final String? subtitle;

  /// Si la entrada lleva una etiqueta de diagnóstico.
  final DiagnosisStatus? diagnosisStatus;
  final String? diagnosisLabel;
}
