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
  void updateDiagnosisStatus(String diagnosisId, DiagnosisStatus status);
}
