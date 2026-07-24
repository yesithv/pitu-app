/// Unidad de la frecuencia de un cuidado.
enum FrequencyUnit {
  days('días', 'día'),
  weeks('semanas', 'semana'),
  months('meses', 'mes'),
  years('años', 'año');

  const FrequencyUnit(this.plural, this.singular);
  final String plural;
  final String singular;
}

/// Frecuencia de un cuidado: "cada N unidades" (ej. cada 6 meses).
class CareFrequency {
  const CareFrequency(this.every, this.unit) : assert(every > 0);

  final int every;
  final FrequencyUnit unit;

  /// Etiqueta legible: "Cada 6 meses" / "Cada mes".
  String get label {
    if (every == 1) return 'Cada ${unit.singular}';
    return 'Cada $every ${unit.plural}';
  }

  /// Calcula la fecha resultante de sumar esta frecuencia a [from].
  DateTime addTo(DateTime from) {
    return switch (unit) {
      FrequencyUnit.days => from.add(Duration(days: every)),
      FrequencyUnit.weeks => from.add(Duration(days: every * 7)),
      FrequencyUnit.months => DateTime(from.year, from.month + every, from.day),
      FrequencyUnit.years => DateTime(from.year + every, from.month, from.day),
    };
  }

  Map<String, dynamic> toJson() => {'every': every, 'unit': unit.name};

  factory CareFrequency.fromJson(Map<String, dynamic> json) => CareFrequency(
        json['every'] as int,
        FrequencyUnit.values.firstWhere((u) => u.name == json['unit']),
      );

  CareFrequency copyWith({int? every, FrequencyUnit? unit}) =>
      CareFrequency(every ?? this.every, unit ?? this.unit);
}
