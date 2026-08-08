import 'package:intl/intl.dart';

/// Formato de fechas dependiente del idioma activo. Cada método recibe el nombre
/// de locale (p. ej. "es", "en") para que los nombres de meses y días salgan en
/// el idioma correcto. Los símbolos de fecha se cargan en `main` con
/// `initializeDateFormatting()`.
abstract class AppDates {
  static String _cap(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  /// "Tuesday, 22 July" / "Martes, 22 de julio"
  static String longWeekday(DateTime d, String locale) =>
      _cap(DateFormat.MMMMEEEEd(locale).format(d));

  /// "22 July 2026" / "22 de julio de 2026"
  static String longDate(DateTime d, String locale) =>
      DateFormat.yMMMMd(locale).format(d);

  /// "22 Jul" / "22 jul"
  static String shortDate(DateTime d, String locale) =>
      DateFormat.MMMd(locale).format(d);

  /// "22 Jul 2026"
  static String shortDateYear(DateTime d, String locale) =>
      DateFormat.yMMMd(locale).format(d);

  /// "July 2026" / "Julio 2026"
  static String monthYear(DateTime d, String locale) =>
      _cap(DateFormat.yMMMM(locale).format(d));

  /// "Tue" / "mar."
  static String weekdayShort(DateTime d, String locale) =>
      DateFormat.E(locale).format(d);
}
