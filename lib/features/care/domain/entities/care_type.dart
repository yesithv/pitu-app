import '../../../../core/domain/sync_metadata.dart';
import '../../../pets/domain/entities/species.dart';
import 'care_frequency.dart';
import 'care_kind.dart';

/// Tipo de cuidado (RD-03). Puede provenir del catálogo predefinido por especie
/// o ser personalizado por el usuario (RF-11). Las personalizaciones no se
/// sobrescriben con las actualizaciones del catálogo (RN-09).
class CareType {
  const CareType({
    required this.meta,
    required this.name,
    required this.kind,
    required this.suggestedFrequency,
    this.speciesApplicable,
    this.isCustom = false,
    this.isActive = true,
    this.catalogVersion,
  });

  final SyncMetadata meta;
  final String name;
  final CareKind kind;
  final CareFrequency suggestedFrequency;

  /// `null` = aplica a cualquier especie.
  final Species? speciesApplicable;
  final bool isCustom;
  final bool isActive;

  /// Versión del catálogo del que proviene (RF-13), null si es personalizado.
  final int? catalogVersion;

  String get id => meta.id;

  CareType copyWith({
    SyncMetadata? meta,
    String? name,
    CareKind? kind,
    CareFrequency? suggestedFrequency,
    Species? speciesApplicable,
    bool? isCustom,
    bool? isActive,
    int? catalogVersion,
  }) {
    return CareType(
      meta: meta ?? this.meta,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      suggestedFrequency: suggestedFrequency ?? this.suggestedFrequency,
      speciesApplicable: speciesApplicable ?? this.speciesApplicable,
      isCustom: isCustom ?? this.isCustom,
      isActive: isActive ?? this.isActive,
      catalogVersion: catalogVersion ?? this.catalogVersion,
    );
  }
}
