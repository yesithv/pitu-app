/// Estado de cumplimiento de un cuidado (RF-36). Se acompaña SIEMPRE de
/// ícono + texto en la UI, nunca solo color (accesibilidad, identidad §10).
enum ComplianceStatus { ok, due, overdue }

/// Resumen de cumplimiento por mascota (RF-37): recomendado vs. realizado.
class PetCompliance {
  const PetCompliance({
    required this.total,
    required this.upToDate,
    required this.overdue,
    required this.due,
  });

  final int total;

  /// Cuidados que no están atrasados.
  final int upToDate;
  final int overdue;
  final int due;

  bool get isAllUpToDate => overdue == 0;

  double get ratio => total == 0 ? 1 : upToDate / total;

  int get percent => (ratio * 100).round();

  static const PetCompliance empty =
      PetCompliance(total: 0, upToDate: 0, overdue: 0, due: 0);
}
