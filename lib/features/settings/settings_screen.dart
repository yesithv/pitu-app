import 'package:flutter/material.dart';
import 'package:pitu_app/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/data/in_memory_database.dart';
import '../../core/i18n/locale_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_dates.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/common.dart';
import '../../core/utils/byte_format.dart';
import '../auth/application/auth_providers.dart';
import '../backup/application/backup_providers.dart';
import '../backup/application/backup_service.dart';
import '../backup/domain/backup_result.dart';
import 'application/wipe_service.dart';
import '../pets/presentation/pets_providers.dart';
import '../plan/application/entitlement_controller.dart';
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
    final l10n = AppLocalizations.of(context)!;
    final owner = ref.watch(ownerNameProvider);
    final entitlement = ref.watch(entitlementProvider);
    final isPro = entitlement.isPro;
    final session = ref.watch(sessionControllerProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(Gap.screenH, 8, Gap.screenH, 100),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(l10n.settingsTitle, style: AppText.display(c.text)),
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
                    Text(l10n.settingsLocalProfile, style: AppText.meta(c.text3)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: c.text3),
            ],
          ),
        ),
        const SizedBox(height: 20),

        GroupHeader(l10n.settingsGroupSubscription),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isPro ? l10n.settingsPlanProPurchased : l10n.settingsPlanFree,
                        style: AppText.cardTitle(c.text).copyWith(fontSize: 15)),
                    Text(
                      isPro
                          ? l10n.settingsPlanProDesc
                          : l10n.settingsPlanFreeDesc,
                      style: AppText.meta(c.text3),
                    ),
                  ],
                ),
              ),
              if (isPro)
                TextButton(
                  onPressed: () => PlansScreen.open(context),
                  child: Text(l10n.settingsViewPlans, style: AppText.metaStrong(c.brand)),
                )
              else
                _AccentButton(
                  label: l10n.settingsUnlockPro,
                  onTap: () => PlansScreen.open(context),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        GroupHeader(l10n.settingsGroupNotifications),
        AppCard(
          clip: true,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _SwitchRow(
                label: l10n.settingsReminders,
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
                          child: Text(l10n.settingsDefaultLead,
                              style: AppText.body(c.text))),
                      if (isPro) ...[
                        Text(_leadLabel(l10n, ref.watch(databaseProvider).reminderLeadDays),
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

        GroupHeader(l10n.settingsGroupSecurity),
        AppCard(
          padding: EdgeInsets.zero,
          child: _SwitchRow(
            label: l10n.settingsBiometric,
            value: ref.watch(biometricEnabledProvider),
            onChanged: _onBiometricToggle,
          ),
        ),
        const SizedBox(height: 20),

        GroupHeader(l10n.settingsGroupData),
        AppCard(
          clip: true,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _LinkRow(label: l10n.settingsCreateBackup, onTap: _onCreateBackup, divider: true),
              _LinkRow(label: l10n.settingsRestoreBackup, onTap: _onRestoreBackup, divider: true),
              _Row(
                label: _documentsSpaceLabel(l10n, ref.watch(databaseProvider)),
                labelColor: c.text3,
              ),
              _Row(
                label: _lastBackupLabel(l10n, ref.watch(databaseProvider).lastBackupAt),
                labelColor: c.text3,
              ),
            ],
          ),
        ),
        if (_shouldRemindBackup(ref.watch(databaseProvider).lastBackupAt)) ...[
          const SizedBox(height: 12),
          InfoNote(
            l10n.settingsBackupRecommend,
            icon: Icons.backup_outlined,
          ),
        ],
        const SizedBox(height: 16),

        InfoNote(
          l10n.settingsLocalOnly,
          icon: Icons.shield_outlined,
        ),
        const SizedBox(height: 16),

        // Idioma / Language (RF: multiidioma con selector manual).
        GroupHeader(l10n.settingsGroupLanguage),
        AppCard(
          clip: true,
          padding: EdgeInsets.zero,
          child: _LanguageRow(),
        ),
        const SizedBox(height: 20),

        // Borrar todos los datos (RNF-13, Ley 1581).
        AppCard(
          clip: true,
          padding: EdgeInsets.zero,
          child: _LinkRow(
            label: l10n.settingsWipe,
            color: c.over,
            onTap: _onWipeData,
          ),
        ),
        const SizedBox(height: 20),

        // Conmutador de plan solo para la demo/desarrollo; en producción no
        // debe existir un botón que otorgue Pro sin compra.
        if (kDemoMode) ...[
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
                isPro ? l10n.settingsDemoSeeFree : l10n.settingsDemoBackToPro,
                style: AppText.meta(c.text3),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        // Cuenta local: se muestra solo con sesión iniciada (no en la demo).
        if (session.status == SessionStatus.authenticated) ...[
          GroupHeader(l10n.settingsGroupAccount),
          AppCard(
            clip: true,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                if (session.user != null)
                  _Row(label: session.user!.email, labelColor: c.text3),
                _LinkRow(
                  label: l10n.settingsLogout,
                  color: c.over,
                  onTap: _onLogout,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        Center(
          child: Text(l10n.settingsMadeWithLove,
              style: AppText.meta(c.text3)),
        ),
      ],
    );
  }

  /// Cierra la sesión de la cuenta local y vuelve a la pantalla de login. Los
  /// datos locales quedan intactos (no se borran); se recuperan al iniciar
  /// sesión de nuevo.
  Future<void> _onLogout() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.logoutTitle),
        content: Text(l10n.logoutMessage),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.commonCancel)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.settingsLogout)),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(sessionControllerProvider.notifier).logout();
  }

  static String _lastBackupLabel(AppLocalizations l10n, DateTime? at) {
    if (at == null) return l10n.backupNever;
    final d = DateTime.now().difference(at);
    if (d.inDays >= 1) return l10n.backupDaysAgo(d.inDays);
    if (d.inHours >= 1) return l10n.backupHoursAgo(d.inHours);
    return l10n.backupMomentAgo;
  }

  static bool _shouldRemindBackup(DateTime? at) {
    if (at == null) return true;
    return DateTime.now().difference(at).inDays >= 7;
  }

  /// Espacio ocupado por los documentos adjuntos (RNF-06).
  static String _documentsSpaceLabel(AppLocalizations l10n, InMemoryDatabase db) {
    final docs = db.attachments.where((a) => !a.meta.isDeleted).toList();
    if (docs.isEmpty) return l10n.docsSpaceEmpty;
    final bytes = docs.fold<int>(0, (sum, a) => sum + a.sizeBytes);
    return l10n.docsSpaceUsed(formatBytes(bytes), docs.length);
  }

  /// Borra todos los datos del dispositivo con doble confirmación (RNF-13).
  Future<void> _onWipeData() async {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final first = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.wipeTitle),
        content: Text(l10n.wipeMessage),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.commonCancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.commonContinue, style: TextStyle(color: c.over)),
          ),
        ],
      ),
    );
    if (first != true || !mounted) return;

    final second = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.wipeConfirmTitle),
        content: Text(l10n.wipeConfirmMessage),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.commonNo)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.wipeConfirmButton, style: TextStyle(color: c.over)),
          ),
        ],
      ),
    );
    if (second != true || !mounted) return;

    await ref.read(wipeServiceProvider).wipeAll();
    if (!mounted) return;
    _snack(l10n.wipeDone);
  }

  Future<void> _onCreateBackup() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final path = await ref.read(backupServiceProvider).export();
      _snack(path == null ? l10n.backupDownloaded : l10n.backupSavedTo(path));
    } catch (_) {
      _snack(l10n.backupFailed);
    }
  }

  Future<void> _onRestoreBackup() async {
    final l10n = AppLocalizations.of(context)!;
    final service = ref.read(backupServiceProvider);
    if (!service.canImport) {
      _snack(l10n.restoreWebOnly);
      return;
    }
    // 1) Selecciona y muestra un resumen antes de aplicar (RF-42).
    final pick = await service.pickForImport();
    if (pick.cancelled) return;
    if (pick.error != null) {
      _snack(l10n.restoreFailed);
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
        _snack(l10n.restoreSuccess(result.pets, result.records));
      case BackupImportStatus.invalid:
        _snack(l10n.restoreFailed);
      case BackupImportStatus.cancelled:
        break;
    }
  }

  Future<BackupMode?> _chooseImportMode(BackupPreview p) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final localeName = Localizations.localeOf(context).toString();
    final summary =
        l10n.importSummary(p.pets, p.records, p.attachments);
    final when = p.exportedAt == null
        ? summary
        : '$summary · ${l10n.importCreatedOn(AppDates.shortDateYear(p.exportedAt!, localeName))}';
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
              Text(l10n.importContentTitle, style: AppText.title2(c.text)),
              const SizedBox(height: 6),
              Text(
                when,
                style: AppText.body(c.text2),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.merge_type, color: c.brand),
                title: Text(l10n.importCombine),
                subtitle: Text(l10n.importCombineDesc),
                onTap: () => Navigator.of(sheetContext).pop(BackupMode.combine),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.swap_horiz, color: c.over),
                title: Text(l10n.importReplace),
                subtitle: Text(l10n.importReplaceDesc),
                onTap: () => Navigator.of(sheetContext).pop(BackupMode.replace),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onRemindersToggle(bool value) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _reminders = value);
    if (!value) return;
    final scheduler = ref.read(reminderSchedulerProvider);
    if (!scheduler.isSupported) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(l10n.remindersMobileOnly)));
      return;
    }
    final granted = await scheduler.requestPermission();
    if (!granted) {
      _snack(l10n.notifPermissionDenied);
    }
  }

  Future<void> _onBiometricToggle(bool value) async {
    final l10n = AppLocalizations.of(context)!;
    final lock = ref.read(appLockProvider);
    final db = ref.read(databaseProvider);
    if (value) {
      if (!lock.isSupported) {
        _snack(l10n.biometricMobileOnly);
        return;
      }
      if (!await lock.canAuthenticate()) {
        _snack(l10n.biometricNotConfigured);
        return;
      }
      if (!await lock.authenticate(l10n.biometricConfirmEnable)) return;
    }
    db.biometricLockEnabled = value;
    db.bump();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  static String _leadLabel(AppLocalizations l10n, int d) => switch (d) {
        0 => l10n.leadSameDay,
        1 => l10n.leadOneDayBefore,
        _ => l10n.leadDaysBefore(d),
      };

  Future<void> _onAnticipation(bool isPro) async {
    final l10n = AppLocalizations.of(context)!;
    if (!isPro) {
      PlansScreen.open(context, blockedFeature: l10n.anticipationBlockedFeature);
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
                title: Text(_leadLabel(l10n, d)),
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
            activeThumbColor: Colors.white,
            activeTrackColor: c.brand,
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, this.labelColor});
  final String label;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppText.body(labelColor ?? c.text))),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.label,
    required this.onTap,
    this.divider = false,
    this.color,
  });
  final String label;
  final VoidCallback onTap;
  final bool divider;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tint = color ?? c.brand;
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: divider ? Border(bottom: BorderSide(color: c.border)) : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            Expanded(child: Text(label, style: AppText.bodyStrong(tint))),
            Icon(Icons.chevron_right, color: tint, size: 20),
          ],
        ),
      ),
    );
  }
}

/// Nombre de cada idioma en su propio idioma (para el selector).
String _languageNativeName(String code) => switch (code) {
      'es' => 'Español',
      'en' => 'English',
      'fr' => 'Français',
      'pt' => 'Português',
      'de' => 'Deutsch',
      _ => code,
    };

/// Fila de Ajustes para elegir idioma: muestra la selección actual (Automático o
/// un idioma) y abre una hoja con las opciones. `null` = automático (dispositivo).
class _LanguageRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final current = ref.watch(localeControllerProvider);
    final currentLabel = current == null
        ? l10n.settingsLanguageAutomatic
        : _languageNativeName(current.languageCode);

    return InkWell(
      onTap: () => _pick(context, ref, current),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            Icon(Icons.language, color: c.text3, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(l10n.settingsGroupLanguage, style: AppText.body(c.text))),
            Text(currentLabel, style: AppText.meta(c.text3)),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, color: c.text3),
          ],
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context, WidgetRef ref, Locale? current) async {
    final l10n = AppLocalizations.of(context)!;
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final c = sheetContext.colors;
        // 'auto' representa el modo automático (sin override).
        final options = <(String, String)>[
          ('auto', l10n.settingsLanguageAutomatic),
          for (final loc in kSupportedLocales)
            (loc.languageCode, _languageNativeName(loc.languageCode)),
        ];
        final currentKey = current?.languageCode ?? 'auto';
        return SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final o in options)
                ListTile(
                  title: Text(o.$2),
                  trailing: o.$1 == currentKey
                      ? Icon(Icons.check, color: c.brand)
                      : null,
                  onTap: () => Navigator.of(sheetContext).pop(o.$1),
                ),
            ],
          ),
        );
      },
    );
    if (selected == null) return;
    final notifier = ref.read(localeControllerProvider.notifier);
    await notifier.setLocale(selected == 'auto' ? null : Locale(selected));
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
      color: c.accent.withValues(alpha: 0.22),
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
