/// Tipo de cuidado del catálogo. Cada uno lleva un ícono propio y constante
/// en toda la app (identidad §6). El mapeo a iconos vive en la capa de UI.
enum CareKind {
  vaccine('Vacunas'),
  deworming('Desparasitación'),
  dental('Limpieza dental'),
  bath('Baño'),
  grooming('Cepillado'),
  nails('Corte de uñas'),
  weight('Control de peso'),
  vetVisit('Consulta veterinaria'),
  medication('Medicación'),
  birthday('Cumpleaños'),
  custom('Personalizado');

  const CareKind(this.defaultName);
  final String defaultName;

  static CareKind fromName(String name) => CareKind.values
      .firstWhere((k) => k.name == name, orElse: () => CareKind.custom);
}
