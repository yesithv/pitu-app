import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'crash_reporter.dart';

/// Reporter de errores. Se sobrescribe en `main` con la instancia real (ya
/// inicializada); por defecto es no-op. Las features pueden leerlo para reportar
/// errores capturados (`ref.read(crashReporterProvider).recordError(...)`).
final crashReporterProvider =
    Provider<CrashReporter>((ref) => const NoopCrashReporter());
