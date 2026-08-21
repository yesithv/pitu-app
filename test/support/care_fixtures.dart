import 'package:pitu_app/core/domain/sync_metadata.dart';
import 'package:pitu_app/features/care/domain/entities/care_frequency.dart';
import 'package:pitu_app/features/care/domain/entities/care_kind.dart';
import 'package:pitu_app/features/care/domain/entities/care_schedule.dart';

/// Fixture compartido para construir [CareSchedule] en las pruebas (antes estaba
/// duplicado en `pet_compliance_test`, `widget_test` y `pet_repository_test`).
/// Los valores por defecto reproducen el cuerpo que usaban esos tests; cada uno
/// mantiene su firma local con un wrapper de una línea, por lo que los call-sites
/// y el comportamiento no cambian.
CareSchedule careSchedule(
  DateTime next, {
  required DateTime now,
  String? id,
  String petId = 'p1',
  String careTypeId = 'c1',
  String name = 'Cuidado',
  CareKind kind = CareKind.bath,
  CareFrequency frequency = const CareFrequency(1, FrequencyUnit.months),
}) {
  return CareSchedule(
    meta: SyncMetadata.create(id: id ?? next.toIso8601String(), now: now),
    petId: petId,
    careTypeId: careTypeId,
    name: name,
    kind: kind,
    frequency: frequency,
    nextDate: next,
  );
}
