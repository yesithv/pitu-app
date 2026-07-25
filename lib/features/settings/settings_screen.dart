import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/common.dart';
import '../backup/application/backup_providers.dart';
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
              _Row(
                label: 'Anticipación por defecto',
                trailing: const ProBadge(),
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
                label: 'El respaldo es un archivo .json que puedes guardar donde quieras.',
                labelColor: c.text3,
              ),
            ],
          ),
        ),
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

  Future<void> _onCreateBackup() async {
    final path = await ref.read(backupServiceProvider).export();
    _snack(path == null
        ? 'Respaldo descargado (revisa tus descargas).'
        : 'Respaldo guardado en: $path');
  }

  Future<void> _onRestoreBackup() async {
    final service = ref.read(backupServiceProvider);
    if (!service.canImport) {
      _snack('La restauración desde archivo está disponible en la versión web '
          'por ahora.');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Restaurar respaldo'),
        content: const Text(
            'Se reemplazarán los datos actuales de este dispositivo con los '
            'del respaldo. Esta acción no se puede deshacer. ¿Continuar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final result = await service.import();
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
    await scheduler.requestPermission();
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
