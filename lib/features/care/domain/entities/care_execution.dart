import '../../../../core/domain/sync_metadata.dart';

/// Registro de ejecución de un cuidado (RD-05). Queda en el historial (RF-17).
class CareExecution {
  const CareExecution({
    required this.meta,
    required this.scheduleId,
    required this.petId,
    required this.name,
    required this.date,
    this.notes,
    this.attachments = const [],
  });

  final SyncMetadata meta;
  final String scheduleId;
  final String petId;
  final String name;
  final DateTime date;
  final String? notes;
  final List<String> attachments;

  String get id => meta.id;
}
