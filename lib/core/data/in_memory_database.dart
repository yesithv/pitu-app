import 'package:flutter/foundation.dart';

import '../../features/attachments/domain/entities/attachment.dart';
import '../../features/care/domain/entities/care_execution.dart';
import '../../features/care/domain/entities/care_schedule.dart';
import '../../features/care/domain/entities/care_type.dart';
import '../../features/clinical/domain/entities/diagnosis.dart';
import '../../features/clinical/domain/entities/diagnosis_status_change.dart';
import '../../features/clinical/domain/entities/medical_visit.dart';
import '../../features/clinical/domain/entities/vaccine.dart';
import '../../features/clinical/domain/entities/weight_record.dart';
import '../../features/pets/domain/entities/pet.dart';
import '../../features/plan/domain/plan.dart';

/// Almacén local en memoria para la Fase 1 (MVP). Es la única "fuente de
/// verdad" del prototipo y se comporta como un stub de la futura BD Drift:
/// las implementaciones de repositorio operan sobre estas listas.
///
/// Extiende [ChangeNotifier] para que la capa de presentación (Riverpod) se
/// re-renderice reactivamente ante cualquier mutación, conservando la
/// sensación local-first de guardado instantáneo (RNF-02).
class InMemoryDatabase extends ChangeNotifier {
  final List<Pet> pets = [];
  final List<CareType> careTypes = [];
  final List<CareSchedule> schedules = [];
  final List<CareExecution> executions = [];
  final List<Diagnosis> diagnoses = [];
  final List<DiagnosisStatusChange> diagnosisStatusChanges = [];
  final List<WeightRecord> weights = [];
  final List<MedicalVisit> visits = [];
  final List<Vaccine> vaccines = [];
  final List<Attachment> attachments = [];

  String ownerName = 'Yesith';

  /// Preferencia de bloqueo biométrico (RNF-11).
  bool biometricLockEnabled = false;

  /// Entitlement persistido localmente (RD-12). Por defecto Free; una compra
  /// (o el desbloqueo de demostración) lo eleva a Pro y se conserva.
  PlanType planType = PlanType.free;
  String? purchaseSource;
  DateTime? purchasedAt;

  /// Anticipación (en días) de los recordatorios (RF-35, función Pro). 0 = el
  /// mismo día.
  int reminderLeadDays = 0;

  /// Fecha del último respaldo creado (RF-46). `null` si nunca se ha hecho.
  DateTime? lastBackupAt;

  /// Versión del catálogo de cuidados ya aplicada a las mascotas (RF-13). Se usa
  /// para agregar cuidados nuevos de futuras versiones sin sobrescribir
  /// personalizaciones. 0 = aún no reconciliado.
  int catalogAppliedVersion = 0;

  /// Notifica a los observadores tras una mutación.
  void bump() => notifyListeners();
}
