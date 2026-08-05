import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/in_memory_database.dart';
import '../../../core/data/local_persistence.dart';
import '../../../core/di/providers.dart';
import '../../reminders/application/reminders_providers.dart';
import '../../reminders/domain/reminder_scheduler.dart';

/// Borra **todos los datos personales** del dispositivo (RNF-13, Ley 1581): las
/// mascotas y su historial, los documentos adjuntos (BD y archivos), el perfil y
/// las preferencias. **Conserva el entitlement de plan** (la compra de Pro no es
/// un dato personal). Cancela los recordatorios programados.
class WipeService {
  WipeService(this._db, this._persistence, this._scheduler);

  final InMemoryDatabase _db;
  final LocalPersistence? _persistence;
  final ReminderScheduler _scheduler;

  Future<void> wipeAll() async {
    _db.pets.clear();
    _db.careTypes.clear();
    _db.schedules.clear();
    _db.executions.clear();
    _db.diagnoses.clear();
    _db.diagnosisStatusChanges.clear();
    _db.weights.clear();
    _db.visits.clear();
    _db.vaccines.clear();
    _db.attachments.clear();

    // Perfil y preferencias (datos personales) → valores por defecto.
    _db.ownerName = '';
    _db.biometricLockEnabled = false;
    _db.reminderLeadDays = 0;
    _db.lastBackupAt = null;
    _db.catalogAppliedVersion = 0;

    // Adjuntos en el filesystem (RF-29).
    await _persistence?.deleteAllAttachmentFiles();
    // Persiste el estado vacío y cancela las notificaciones pendientes.
    _persistence?.trySave(_db);
    await _scheduler.cancelAll();
    _db.bump();
  }
}

final wipeServiceProvider = Provider<WipeService>(
  (ref) => WipeService(
    ref.read(databaseProvider),
    ref.read(persistenceProvider),
    ref.read(reminderSchedulerProvider),
  ),
);
