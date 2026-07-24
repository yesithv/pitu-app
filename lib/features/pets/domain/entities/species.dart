/// Especie de la mascota. Define el catálogo de cuidados precargado (RF-08).
enum Species {
  dog('Perro', '🐕'),
  cat('Gato', '🐈'),
  other('Otro', '🐾');

  const Species(this.label, this.emoji);
  final String label;
  final String emoji;

  static Species fromName(String name) =>
      Species.values.firstWhere((s) => s.name == name, orElse: () => Species.other);
}
