import 'diagnosis.dart';

/// Tipo de entrada en la línea de tiempo del historial (RF-24).
enum TimelineKind { visit, vaccine, care, diagnosis, weight }

/// Textos localizados que la capa de datos usa para construir los títulos de la
/// línea de tiempo, sin acoplar el dominio a la UI ni a `AppLocalizations`.
class TimelineLabels {
  const TimelineLabels({
    required this.visit,
    required this.visitWithReason,
    required this.weightLogged,
    required this.statusChange,
    required this.statusTransition,
    required this.diagnosisStatusLabel,
  });

  final String visit;
  final String Function(String reason) visitWithReason;
  final String Function(String value, String unit) weightLogged;
  final String Function(String condition) statusChange;
  final String Function(String from, String to) statusTransition;
  final String Function(DiagnosisStatus status) diagnosisStatusLabel;
}

/// Entrada unificada del historial clínico: integra visitas, vacunas,
/// diagnósticos, ejecuciones de cuidados y registros de peso (RF-24),
/// ordenada cronológicamente inversa.
class TimelineEntry {
  const TimelineEntry({
    required this.date,
    required this.kind,
    required this.title,
    this.sourceId,
    this.subtitle,
    this.diagnosisStatus,
    this.diagnosisLabel,
  });

  final DateTime date;
  final TimelineKind kind;
  final String title;

  /// Id del registro de origen (para abrir su edición desde el historial).
  final String? sourceId;
  final String? subtitle;

  /// Si la entrada lleva una etiqueta de diagnóstico.
  final DiagnosisStatus? diagnosisStatus;
  final String? diagnosisLabel;
}
