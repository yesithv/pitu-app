import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/common.dart';
import '../backup/application/backup_providers.dart';
import '../backup/application/backup_service.dart';
import '../backup/domain/backup_result.dart';
import '../pets/presentation/pets_providers.dart';
import '../plan/application/entitlement_controller.dart';
import '../plan/domain/plan.dart';
import '../plan/presentation/plans_screen.dart';
import 'profile_edit_screen.dart';
import '../reminders/application/reminders_providers.dart';
import '../security/application/security_providers.dart';
import '../../core/di/providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _reminders = true;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final owner = ref.watch(ownerNameProvider);
    final entitlement = ref.watch(entitlementProvider);
    final isPro = entitlement.isPro;

    return ListView(
      padding: const EdgeInsets.fromLTRB(Gap.screenH, 8, Gap.screenH, 100),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text('Ajustes', style: AppText.display(c.text)),
        ),

        // Perfil local
        AppCard(
          onTap: () => ProfileEditScreen.open(context),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: c.brandSoft, shape: BoxShape.circle),
                child: const Text('🧑', style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(owner, style: AppText.cardTitle(c.text).copyWith(fontSize: 16)),
                    Text('Perfil local', style: AppText.meta(c.text3)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: c.text3),
            ],
          ),
        ),
        const SizedBox(height: 20),

        const GroupHeader('Suscripción'),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isPro ? 'Pro · Comprado' : 'Plan Free',
                        style: AppText.cardTitle(c.text).copyWith(fontSize: 15)),
                    Text(
                      isPro
                          ? 'Todas las funciones locales, para siempre'
                          : '1 mascota · funciones básicas',
                      style: AppText.meta(c.text3),
                    ),
                  ],
                ),
              ),
              if (isPro)
                TextButton(
                  onPressed: () => PlansScreen.open(context),
                  child: Text('Ver planes', style: AppText.metaStrong(c.brand)),
                )
              else
                _AccentButton(
                  label: 'Desbloquear Pro',
                  onTap: () => PlansScreen.open(context),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        const GroupHeader('Notificaciones'),
        AppCard(
          clip: true,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _SwitchRow(
                label: 'Recordatorios',
                value: _reminders,
                onChanged: _onRemindersToggle,
                divider: true,
              ),
              InkWell(
                onTap: () => _onAnticipation(isPro),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                          child: Text('Anticipación por defecto',
                              style: AppText.body(c.text))),
                      if (isPro) ...[
                        Text(_leadLabel(ref.watch(databaseProvider).reminderLeadDays),
                            style: AppText.meta(c.text3)),
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right, color: c.text3),
                      ] else
                        const ProBadge(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        const GroupHeader('Seguridad'),
        AppCard(
          padding: EdgeInsets.zero,
          child: _SwitchRow(
            label: 'Desbloqueo con huella / Face ID',
            value: ref.watch(biometricEnabledProvider),
            onChanged: _onBiometricToggle,
          ),
        ),
        const SizedBox(height: 20),

        const GroupHeader('Datos'),
        AppCard(
          clip: true,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _LinkRow(label: 'Crear respaldo', onTap: _onCreateBackup, divider: true),
              _LinkRow(label: 'Restaurar respaldo', onTap: _onRestoreBackup, divider: true),
              _Row(
                label: _lastBackupLabel(ref.watch(databaseProvider).lastBackupAt),
                labelColor: c.text3,
              ),
            ],
          ),
        ),
        if (_shouldRemindBackup(ref.watch(databaseProvider).lastBackupAt)) ...[
          const SizedBox(height: 12),
          const InfoNote(
            'Te recomendamos crear un respaldo para no perder tus datos si '
            'cambias de dispositivo.',
            icon: Icons.backup_outlined,
          ),
        ],
        const SizedBox(height: 16),

        const InfoNote(
          'Toda la información se guarda solo en este dispositivo. No la enviamos a ningún servidor.',
          icon: Icons.shield_outlined,
        ),
        const SizedBox(height: 20),

        // Demo helper para explorar ambos estados de plan.
        Center(
          child: TextButton(
            onPressed: () {
              final ctrl = ref.read(entitlementProvider.notifier);
              if (isPro) {
                ctrl.useFreeForDemo();
              } else {
                ctrl.unlockPro();
              }
            },
            child: Text(
              isPro ? 'Demo: ver como plan Free' : 'Demo: volver a Pro',
              style: AppText.meta(c.text3),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text('Hecho con cariño, en memoria de Pitufo 🐾',
              style: AppText.meta(c.text3)),
        ),
      ],
    );
  }

  static String _lastBackupLabel(DateTime? at) {
    if (at == null) return 'Aún no has creado un respaldo.';
    final d = DateTime.now().difference(at);
    if (d.inDays >= 1) {
      return 'Último respaldo: hace ${d.inDays} día${d.inDays == 1 ? '' : 's'}';
    }
    if (d.inHours >= 1) return 'Último respaldo: hace ${d.inHours} h';
    return 'Último respaldo: hace un momento';
  }

  static bool _shouldRemindBackup(DateTime? at) {
    if (at == null) return true;
    return DateTime.now().difference(at).inDays >= 7;
  }

  Future<void> _onCreateBackup() async {
    try {
      final path = await ref.read(backupServiceProvider).export();
      _snack(path == null
          ? 'Respaldo descargado (revisa tus descargas).'
          : 'Respaldo guardado en: $path');
    } catch (_) {
      _snack('No se pudo crear el respaldo.');
    }
  }

  Future<void> _onRestoreBackup() async {
    final service = ref.read(backupServiceProvider);
    if (!service.canImport) {
      _snack('La restauración desde archivo está disponible en la versión web '
          'por ahora.');
      return;
    }
    // 1) Selecciona y muestra un resumen antes de aplicar (RF-42).
    final pick = await service.pickForImport();
    if (pick.cancelled) return;
    if (pick.error != null) {
      _snack(pick.error!);
      return;
    }
    final preview = pick.preview!;
    if (!mounted) return;

    // 2) El usuario elige reemplazar o combinar (RF-43).
    final mode = await _chooseImportMode(preview);
    if (mode == null) return;

    // 3) Aplica y reprograma recordatorios (RF-44, vía bump del autoguardado).
    final result = service.apply(preview, mode);
    switch (result.status) {
      case BackupImportStatus.success:
        _snack('Respaldo restaurado: ${result.pets} mascota(s) y '
            '${result.records} registro(s).');
      case BackupImportStatus.invalid:
        _snack(result.message ?? 'No se pudo restaurar el respaldo.');
      case BackupImportStatus.cancelled:
        break;
    }
  }

  Future<BackupMode?> _chooseImportMode(BackupPreview p) {
    final c = context.colors;
    final when = p.exportedAt == null
        ? ''
        : ' · creado el ${p.exportedAt!.day}/${p.exportedAt!.month}/${p.exportedAt!.year}';
    return showModalBottomSheet<BackupMode>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Contenido del respaldo', style: AppText.title2(c.text)),
              const SizedBox(height: 6),
              Text(
                '${p.pets} mascota(s) · ${p.records} registro(s) · '
                '${p.attachments} documento(s)$when',
                style: AppText.body(c.text2),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.merge_type, color: c.brand),
                title: const Text('Combinar (recomendado)'),
                subtitle: const Text('Agrega lo que falte, sin duplicar.'),
                onTap: () => Navigator.of(sheetContext).pop(BackupMode.combine),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.swap_horiz, color: c.over),
                title: const Text('Reemplazar todo'),
                subtitle: const Text('Borra los datos actuales de este dispositivo.'),
                onTap: () => Navigator.of(sheetContext).pop(BackupMode.replace),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onRemindersToggle(bool value) async {
    setState(() => _reminders = value);
    if (!value) return;
    final scheduler = ref.read(reminderSchedulerProvider);
    if (!scheduler.isSupported) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(
            content: Text(
                'Los recordatorios funcionan en la app móvil (Android / iOS).')));
      return;
    }
    final granted = await scheduler.requestPermission();
    if (!granted) {
      _snack('Permiso de notificaciones denegado. Actívalo en los Ajustes del '
          'sistema para recibir recordatorios.');
    }
  }

  Future<void> _onBiometricToggle(bool value) async {
    final lock = ref.read(appLockProvider);
    final db = ref.read(databaseProvider);
    if (value) {
      if (!lock.isSupported) {
        _snack('El bloqueo biométrico funciona en la app móvil (Android / iOS).');
        return;
      }
      if (!await lock.canAuthenticate()) {
        _snack('No hay biometría configurada en este dispositivo.');
        return;
      }
      if (!await lock.authenticate('Confirma para activar el bloqueo')) return;
    }
    db.biometricLockEnabled = value;
    db.bump();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  static String _leadLabel(int d) => switch (d) {
        0 => 'Mismo día',
        1 => '1 día antes',
        _ => '$d días antes',
      };

  Future<void> _onAnticipation(bool isPro) async {
    if (!isPro) {
      PlansScreen.open(context, blockedFeature: 'Anticipación configurable');
      return;
    }
    final choice = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final d in const [0, 1, 3, 7])
              ListTile(
                title: Text(_leadLabel(d)),
                onTap: () => Navigator.of(sheetContext).pop(d),
              ),
          ],
        ),
      ),
    );
    if (choice == null) return;
    final db = ref.read(databaseProvider);
    db.reminderLeadDays = choice;
    db.bump();
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.divider = false,
  });
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        border: divider ? Border(bottom: BorderSide(color: c.border)) : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppText.body(c.text))),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: c.brand,
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, this.trailing, this.labelColor});
  final String label;
  final Widget? trailing;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppText.body(labelColor ?? c.text))),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({required this.label, required this.onTap, this.divider = false});
  final String label;
  final VoidCallback onTap;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: divider ? Border(bottom: BorderSide(color: c.border)) : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            Expanded(child: Text(label, style: AppText.bodyStrong(c.brand))),
            Icon(Icons.chevron_right, color: c.brand, size: 20),
          ],
        ),
      ),
    );
  }
}

class _AccentButton extends StatelessWidget {
  const _AccentButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.accent.withOpacity(0.22),
      borderRadius: Radii.pillAll,
      child: InkWell(
        borderRadius: Radii.pillAll,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
          child: Text(label, style: AppText.metaStrong(c.accentInk)),
        ),
      ),
    );
  }
}
