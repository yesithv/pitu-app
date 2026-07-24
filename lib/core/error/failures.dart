/// Errores de dominio. Se mantienen independientes de la UI y de la fuente de
/// datos; la capa de presentación decide cómo mostrarlos.
sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Se intentó una acción bloqueada por el plan actual (RN-01..RN-07).
class PlanLimitException extends AppException {
  const PlanLimitException(super.message, {required this.feature});

  /// Función bloqueada, para que la UI ofrezca la mejora correcta (RF-50).
  final String feature;
}

/// Validación de dominio fallida (p. ej. fecha futura — RN-12).
class ValidationException extends AppException {
  const ValidationException(super.message);
}

/// La entidad solicitada no existe.
class NotFoundException extends AppException {
  const NotFoundException(super.message);
}
