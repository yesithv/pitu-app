/// Abstracción del reloj para permitir pruebas deterministas y, en Fase 2,
/// alinear marcas de tiempo con el servidor.
abstract class Clock {
  DateTime now();
}

class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}

/// Reloj fijo para pruebas.
class FixedClock implements Clock {
  FixedClock(this._now);
  DateTime _now;

  set now(DateTime value) => _now = value;

  @override
  DateTime now() => _now;
}
