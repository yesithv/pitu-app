/// Metadatos transversales presentes en TODAS las entidades desde la Fase 1
/// (RD-18). Habilitan la sincronización y el hogar compartido de la Fase 2 sin
/// migraciones destructivas:
///  - [id]        UUID generado en el cliente (no autoincremental).
///  - [createdAt] / [updatedAt] marcas de tiempo.
///  - [createdBy] reservado; valor local por defecto en F1, usuario real en F2.
///  - [deletedAt] borrado lógico (nunca físico) para sincronizar borrados (RN-13).
class SyncMetadata {
  const SyncMetadata({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy = localAuthor,
    this.deletedAt,
  });

  /// Autor local reservado mientras no exista cuenta (Fase 1).
  static const String localAuthor = 'local';

  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  /// Crea los metadatos de una entidad nueva.
  factory SyncMetadata.create({
    required String id,
    required DateTime now,
    String createdBy = localAuthor,
  }) {
    return SyncMetadata(
      id: id,
      createdAt: now,
      updatedAt: now,
      createdBy: createdBy,
    );
  }

  SyncMetadata copyWith({
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return SyncMetadata(
      id: id,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  /// Marca la entidad como tocada (actualiza [updatedAt]).
  SyncMetadata touched(DateTime now) => copyWith(updatedAt: now);

  /// Aplica borrado lógico.
  SyncMetadata deleted(DateTime now) =>
      copyWith(updatedAt: now, deletedAt: now);

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'createdBy': createdBy,
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory SyncMetadata.fromJson(Map<String, dynamic> json) {
    return SyncMetadata(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      createdBy: (json['createdBy'] as String?) ?? localAuthor,
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.parse(json['deletedAt'] as String),
    );
  }
}
