import '../../care/domain/entities/compliance.dart';
import '../domain/entities/pet.dart';

/// Modelo de vista de una mascota en listas: incluye su cumplimiento y el
/// estado "peor" para el mini-semáforo.
class PetView {
  const PetView({
    required this.pet,
    required this.compliance,
    required this.worstStatus,
    required this.pendingCount,
  });

  final Pet pet;
  final PetCompliance compliance;
  final ComplianceStatus worstStatus;
  final int pendingCount;
}
