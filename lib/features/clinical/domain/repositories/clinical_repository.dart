import '../entities/diagnosis.dart';
import '../entities/medical_visit.dart';
import '../entities/timeline_entry.dart';
import '../entities/vaccine.dart';
import '../entities/weight_record.dart';

abstract interface class ClinicalRepository {
  List<Diagnosis> diagnosesForPet(String petId);
  List<Diagnosis> activeDiagnosesForPet(String petId);
  List<WeightRecord> weightsForPet(String petId);
  List<MedicalVisit> visitsForPet(String petId);
  List<Vaccine> vaccinesForPet(String petId);

  /// Línea de tiempo unificada y ordenada (más reciente primero) (RF-24).
  List<TimelineEntry> timelineForPet(String petId);

  void addWeight(WeightRecord record);
  void addVisit(MedicalVisit visit);
  void addVaccine(Vaccine vaccine);
  void addDiagnosis(Diagnosis diagnosis);
  void updateDiagnosisStatus(String diagnosisId, DiagnosisStatus status);

  // Edición y eliminación de registros ya insertados.
  void updateWeight(WeightRecord record);
  void deleteWeight(String id);
  void updateVisit(MedicalVisit visit);
  void deleteVisit(String id);
  void updateVaccine(Vaccine vaccine);
  void deleteVaccine(String id);
  void updateDiagnosis(Diagnosis diagnosis);
  void deleteDiagnosis(String id);
}
