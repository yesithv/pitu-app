import '../../features/attachments/domain/entities/attachment.dart';
import '../../features/care/domain/entities/care_execution.dart';
import '../../features/care/domain/entities/care_frequency.dart';
import '../../features/care/domain/entities/care_kind.dart';
import '../../features/care/domain/entities/care_schedule.dart';
import '../../features/care/domain/entities/care_type.dart';
import '../../features/clinical/domain/entities/diagnosis.dart';
import '../../features/clinical/domain/entities/medical_visit.dart';
import '../../features/clinical/domain/entities/vaccine.dart';
import '../../features/clinical/domain/entities/weight_record.dart';
import '../../features/pets/domain/entities/pet.dart';
import '../../features/pets/domain/entities/species.dart';
import '../domain/sync_metadata.dart';
import 'in_memory_database.dart';

/// Códec de la base local ↔ JSON. Vive en la capa de datos para mantener el
/// dominio agnóstico de la serialización. El esquema es **versionado** y está
/// pensado para servir también como formato de respaldo (RF-41) y de migración
/// a la API de la Fase 2 (RF-54).
abstract class DbCodec {
  /// Versión del esquema del snapshot/respaldo. v2 añade `attachments`; v3 añade
  /// la foto de la mascota y el entitlement. Los respaldos anteriores siguen
  /// restaurándose (los campos nuevos quedan con su valor por defecto).
  static const int schemaVersion = 3;

  static Map<String, dynamic> encode(InMemoryDatabase db) => {
        'schemaVersion': schemaVersion,
        'ownerName': db.ownerName,
        'biometricLockEnabled': db.biometricLockEnabled,
        'pets': db.pets.map(_petToJson).toList(),
        'careTypes': db.careTypes.map(_careTypeToJson).toList(),
        'schedules': db.schedules.map(_scheduleToJson).toList(),
        'executions': db.executions.map(_executionToJson).toList(),
        'diagnoses': db.diagnoses.map(_diagnosisToJson).toList(),
        'weights': db.weights.map(_weightToJson).toList(),
        'visits': db.visits.map(_visitToJson).toList(),
        'vaccines': db.vaccines.map(_vaccineToJson).toList(),
        'attachments': db.attachments.map(_attachmentToJson).toList(),
      };

  static void decodeInto(InMemoryDatabase db, Map<String, dynamic> json) {
    db.pets
      ..clear()
      ..addAll(_list(json['pets']).map(_petFromJson));
    db.careTypes
      ..clear()
      ..addAll(_list(json['careTypes']).map(_careTypeFromJson));
    db.schedules
      ..clear()
      ..addAll(_list(json['schedules']).map(_scheduleFromJson));
    db.executions
      ..clear()
      ..addAll(_list(json['executions']).map(_executionFromJson));
    db.diagnoses
      ..clear()
      ..addAll(_list(json['diagnoses']).map(_diagnosisFromJson));
    db.weights
      ..clear()
      ..addAll(_list(json['weights']).map(_weightFromJson));
    db.visits
      ..clear()
      ..addAll(_list(json['visits']).map(_visitFromJson));
    db.vaccines
      ..clear()
      ..addAll(_list(json['vaccines']).map(_vaccineFromJson));
    db.attachments
      ..clear()
      ..addAll(_list(json['attachments']).map(_attachmentFromJson));
    db.ownerName = (json['ownerName'] as String?) ?? db.ownerName;
    db.biometricLockEnabled = json['biometricLockEnabled'] as bool? ?? false;
  }

  // ---- helpers ----------------------------------------------------------

  static List<Map<String, dynamic>> _list(Object? v) => (v as List? ?? [])
      .map((e) => (e as Map).cast<String, dynamic>())
      .toList();

  static String? _iso(DateTime? d) => d?.toIso8601String();
  static DateTime? _date(Object? v) =>
      v == null ? null : DateTime.parse(v as String);
  static DateTime _dateReq(Object? v) => DateTime.parse(v as String);

  static T _enumByName<T extends Enum>(List<T> values, Object? name, T fallback) {
    for (final v in values) {
      if (v.name == name) return v;
    }
    return fallback;
  }

  // ---- pets -------------------------------------------------------------

  static Map<String, dynamic> _petToJson(Pet p) => {
        'meta': p.meta.toJson(),
        'name': p.name,
        'species': p.species.name,
        'birthDate': _iso(p.birthDate),
        'ageText': p.ageText,
        'weight': p.weight,
        'weightUnit': p.weightUnit.name,
        'breed': p.breed,
        'photoPath': p.photoPath,
        'photoBase64': p.photoBase64,
        'status': p.status.name,
        'archiveReason': p.archiveReason?.name,
      };

  static Pet _petFromJson(Map<String, dynamic> j) => Pet(
        meta: SyncMetadata.fromJson((j['meta'] as Map).cast<String, dynamic>()),
        name: j['name'] as String,
        species: Species.fromName(j['species'] as String),
        birthDate: _date(j['birthDate']),
        ageText: j['ageText'] as String?,
        weight: (j['weight'] as num?)?.toDouble(),
        weightUnit: _enumByName(WeightUnit.values, j['weightUnit'], WeightUnit.kg),
        breed: j['breed'] as String?,
        photoPath: j['photoPath'] as String?,
        photoBase64: j['photoBase64'] as String?,
        status: _enumByName(PetStatus.values, j['status'], PetStatus.active),
        archiveReason: j['archiveReason'] == null
            ? null
            : _enumByName(ArchiveReason.values, j['archiveReason'], ArchiveReason.other),
      );

  // ---- care -------------------------------------------------------------

  static Map<String, dynamic> _careTypeToJson(CareType t) => {
        'meta': t.meta.toJson(),
        'name': t.name,
        'kind': t.kind.name,
        'suggestedFrequency': t.suggestedFrequency.toJson(),
        'speciesApplicable': t.speciesApplicable?.name,
        'isCustom': t.isCustom,
        'isActive': t.isActive,
        'catalogVersion': t.catalogVersion,
      };

  static CareType _careTypeFromJson(Map<String, dynamic> j) => CareType(
        meta: SyncMetadata.fromJson((j['meta'] as Map).cast<String, dynamic>()),
        name: j['name'] as String,
        kind: _enumByName(CareKind.values, j['kind'], CareKind.custom),
        suggestedFrequency: CareFrequency.fromJson(
            (j['suggestedFrequency'] as Map).cast<String, dynamic>()),
        speciesApplicable: j['speciesApplicable'] == null
            ? null
            : Species.fromName(j['speciesApplicable'] as String),
        isCustom: j['isCustom'] as bool? ?? false,
        isActive: j['isActive'] as bool? ?? true,
        catalogVersion: j['catalogVersion'] as int?,
      );

  static Map<String, dynamic> _scheduleToJson(CareSchedule s) => {
        'meta': s.meta.toJson(),
        'petId': s.petId,
        'careTypeId': s.careTypeId,
        'name': s.name,
        'kind': s.kind.name,
        'frequency': s.frequency.toJson(),
        'nextDate': _iso(s.nextDate),
        'lastDoneDate': _iso(s.lastDoneDate),
        'reminderEnabled': s.reminderEnabled,
        'isActive': s.isActive,
      };

  static CareSchedule _scheduleFromJson(Map<String, dynamic> j) => CareSchedule(
        meta: SyncMetadata.fromJson((j['meta'] as Map).cast<String, dynamic>()),
        petId: j['petId'] as String,
        careTypeId: j['careTypeId'] as String,
        name: j['name'] as String,
        kind: _enumByName(CareKind.values, j['kind'], CareKind.custom),
        frequency:
            CareFrequency.fromJson((j['frequency'] as Map).cast<String, dynamic>()),
        nextDate: _dateReq(j['nextDate']),
        lastDoneDate: _date(j['lastDoneDate']),
        reminderEnabled: j['reminderEnabled'] as bool? ?? true,
        isActive: j['isActive'] as bool? ?? true,
      );

  static Map<String, dynamic> _executionToJson(CareExecution e) => {
        'meta': e.meta.toJson(),
        'scheduleId': e.scheduleId,
        'petId': e.petId,
        'name': e.name,
        'date': _iso(e.date),
        'notes': e.notes,
        'attachments': e.attachments,
      };

  static CareExecution _executionFromJson(Map<String, dynamic> j) => CareExecution(
        meta: SyncMetadata.fromJson((j['meta'] as Map).cast<String, dynamic>()),
        scheduleId: j['scheduleId'] as String,
        petId: j['petId'] as String,
        name: j['name'] as String,
        date: _dateReq(j['date']),
        notes: j['notes'] as String?,
        attachments:
            (j['attachments'] as List? ?? []).map((e) => e as String).toList(),
      );

  // ---- clinical ---------------------------------------------------------

  static Map<String, dynamic> _diagnosisToJson(Diagnosis d) => {
        'meta': d.meta.toJson(),
        'petId': d.petId,
        'condition': d.condition,
        'date': _iso(d.date),
        'status': d.status.name,
        'visitId': d.visitId,
        'notes': d.notes,
      };

  static Diagnosis _diagnosisFromJson(Map<String, dynamic> j) => Diagnosis(
        meta: SyncMetadata.fromJson((j['meta'] as Map).cast<String, dynamic>()),
        petId: j['petId'] as String,
        condition: j['condition'] as String,
        date: _dateReq(j['date']),
        status: _enumByName(DiagnosisStatus.values, j['status'], DiagnosisStatus.active),
        visitId: j['visitId'] as String?,
        notes: j['notes'] as String?,
      );

  static Map<String, dynamic> _weightToJson(WeightRecord w) => {
        'meta': w.meta.toJson(),
        'petId': w.petId,
        'value': w.value,
        'unit': w.unit.name,
        'date': _iso(w.date),
        'note': w.note,
      };

  static WeightRecord _weightFromJson(Map<String, dynamic> j) => WeightRecord(
        meta: SyncMetadata.fromJson((j['meta'] as Map).cast<String, dynamic>()),
        petId: j['petId'] as String,
        value: (j['value'] as num).toDouble(),
        unit: _enumByName(WeightUnit.values, j['unit'], WeightUnit.kg),
        date: _dateReq(j['date']),
        note: j['note'] as String?,
      );

  static Map<String, dynamic> _visitToJson(MedicalVisit v) => {
        'meta': v.meta.toJson(),
        'petId': v.petId,
        'date': _iso(v.date),
        'clinic': v.clinic,
        'reason': v.reason,
        'diagnosis': v.diagnosis,
        'treatment': v.treatment,
        'notes': v.notes,
        'attachments': v.attachments,
      };

  static MedicalVisit _visitFromJson(Map<String, dynamic> j) => MedicalVisit(
        meta: SyncMetadata.fromJson((j['meta'] as Map).cast<String, dynamic>()),
        petId: j['petId'] as String,
        date: _dateReq(j['date']),
        clinic: j['clinic'] as String?,
        reason: j['reason'] as String?,
        diagnosis: j['diagnosis'] as String?,
        treatment: j['treatment'] as String?,
        notes: j['notes'] as String?,
        attachments:
            (j['attachments'] as List? ?? []).map((e) => e as String).toList(),
      );

  static Map<String, dynamic> _vaccineToJson(Vaccine v) => {
        'meta': v.meta.toJson(),
        'petId': v.petId,
        'type': v.type,
        'appliedDate': _iso(v.appliedDate),
        'nextDoseDate': _iso(v.nextDoseDate),
        'clinic': v.clinic,
        'attachment': v.attachment,
      };

  static Vaccine _vaccineFromJson(Map<String, dynamic> j) => Vaccine(
        meta: SyncMetadata.fromJson((j['meta'] as Map).cast<String, dynamic>()),
        petId: j['petId'] as String,
        type: j['type'] as String,
        appliedDate: _dateReq(j['appliedDate']),
        nextDoseDate: _date(j['nextDoseDate']),
        clinic: j['clinic'] as String?,
        attachment: j['attachment'] as String?,
      );

  // ---- attachments ------------------------------------------------------

  static Map<String, dynamic> _attachmentToJson(Attachment a) => {
        'meta': a.meta.toJson(),
        'petId': a.petId,
        'filename': a.filename,
        'mimeType': a.mimeType,
        'sizeBytes': a.sizeBytes,
        'dataBase64': a.dataBase64,
        'addedAt': _iso(a.addedAt),
        'source': a.source,
      };

  static Attachment _attachmentFromJson(Map<String, dynamic> j) => Attachment(
        meta: SyncMetadata.fromJson((j['meta'] as Map).cast<String, dynamic>()),
        petId: j['petId'] as String,
        filename: j['filename'] as String,
        mimeType: j['mimeType'] as String,
        sizeBytes: (j['sizeBytes'] as num?)?.toInt() ?? 0,
        dataBase64: j['dataBase64'] as String,
        addedAt: _dateReq(j['addedAt']),
        source: j['source'] as String?,
      );
}
