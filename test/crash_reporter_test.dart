import 'package:flutter_test/flutter_test.dart';
import 'package:pitu_app/core/observability/crash_reporter.dart';

void main() {
  test('NoopCrashReporter no lanza en ninguna operación', () async {
    const reporter = NoopCrashReporter();
    await reporter.init();
    expect(() => reporter.log('hola'), returnsNormally);
    expect(
      () => reporter.recordError(Exception('boom'), StackTrace.current, fatal: true),
      returnsNormally,
    );
  });

  test('createCrashReporter devuelve una implementación usable', () {
    final reporter = createCrashReporter();
    expect(() => reporter.recordError('x', null), returnsNormally);
  });
}
