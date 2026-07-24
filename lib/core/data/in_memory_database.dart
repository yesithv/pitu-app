import 'package:flutter/foundation.dart';

import '../../features/care/domain/entities/care_execution.dart';
import '../../features/care/domain/entities/care_schedule.dart';
import '../../features/care/domain/entities/care_type.dart';
import '../../features/clinical/domain/entities/diagnosis.dart';
import '../../features/clinical/domain/entities/medical_visit.dart';
import '../../features/clinical/domain/entities/vaccine.dart';
import '../../features/clinical/domain/entities/weight_record.dart';
import '../../features/pets/domain/entities/pet.dart';

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
  final List<WeightRecord> weights = [];
  final List<MedicalVisit> visits = [];
  final List<Vaccine> vaccines = [];

  String ownerName = 'Yesith';

  /// Notifica a los observadores tras una mutación.
  void bump() => notifyListeners();
}
