/// Formato de fechas en español sin requerir inicialización de locale de intl.
/// (La arquitectura queda preparada para i18n; aquí se resuelve el es-CO.)
abstract class AppDates {
  static const _months = [
    'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
    'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
  ];

  static const _monthsShort = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];

  static const _weekdays = [
    'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo',
  ];

  static String _cap(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  /// "Martes 22 de julio"
  static String longWeekday(DateTime d) {
    final wd = _weekdays[d.weekday - 1];
    return '${_cap(wd)} ${d.day} de ${_months[d.month - 1]}';
  }

  /// "22 de julio de 2026"
  static String longDate(DateTime d) =>
      '${d.day} de ${_months[d.month - 1]} de ${d.year}';

  /// "22 jul"
  static String shortDate(DateTime d) => '${d.day} ${_monthsShort[d.month - 1]}';

  /// "22 jul 2026"
  static String shortDateYear(DateTime d) =>
      '${d.day} ${_monthsShort[d.month - 1]} ${d.year}';

  static String monthYear(DateTime d) =>
      '${_cap(_months[d.month - 1])} ${d.year}';

  static String weekdayShort(DateTime d) => _weekdays[d.weekday - 1];
}
