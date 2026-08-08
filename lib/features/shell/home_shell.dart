import 'package:flutter/material.dart';
import 'package:pitu_app/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text.dart';
import '../calendar/calendar_screen.dart';
import '../clinical/presentation/medical_visit_form_screen.dart';
import '../clinical/presentation/weight_form_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../pets/presentation/pet_form_screen.dart';
import '../pets/presentation/pet_picker.dart';
import '../pets/presentation/pets_list_screen.dart';
import '../pets/presentation/pets_providers.dart';
import '../plan/application/entitlement_controller.dart';
import '../plan/presentation/plans_screen.dart';
import '../settings/settings_screen.dart';

/// Contenedor principal con la navegación inferior de 4 destinos (Fase 1):
/// Inicio · Mascotas · Calendario · Ajustes.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  static const _pages = [
    DashboardScreen(),
    PetsListScreen(),
    CalendarScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: _index, children: _pages),
      ),
      floatingActionButton: _index == 0
          ? _Fab(onTap: () => _openActions(context))
          : null,
      bottomNavigationBar: _BottomNav(
        index: _index,
        onSelect: (i) => setState(() => _index = i),
      ),
    );
  }

  void _openActions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => _ActionSheet(
        onAction: (key) async {
          Navigator.of(sheetContext).pop();
          switch (key) {
            case 'newpet':
              _addPet(context);
            case 'weight':
              {
                final id = await pickPetId(context, ref);
                if (id != null && context.mounted) WeightFormScreen.open(context, id);
              }
            case 'visit':
              {
                final id = await pickPetId(context, ref);
                if (id != null && context.mounted) MedicalVisitFormScreen.open(context, id);
              }
            case 'care':
              ScaffoldMessenger.of(context)
                ..clearSnackBars()
                ..showSnackBar(SnackBar(
                    content: Text(
                        AppLocalizations.of(context)!.careRegisterFromCard)));
          }
        },
      ),
    );
  }

  void _addPet(BuildContext context) {
    final pets = ref.read(petViewsProvider);
    final limits = ref.read(entitlementProvider).limits;
    final max = limits.maxActivePets;
    if (max != null && pets.length >= max) {
      PlansScreen.open(context,
          blockedFeature: AppLocalizations.of(context)!.blockedUnlimitedPets);
    } else {
      PetFormScreen.open(context);
    }
  }
}

class _Fab extends StatelessWidget {
  const _Fab({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return FloatingActionButton(
      onPressed: onTap,
      backgroundColor: c.brand,
      foregroundColor: c.onBrand,
      elevation: 4,
      shape: const CircleBorder(),
      child: const Icon(Icons.add, size: 26),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.index, required this.onSelect});
  final int index;
  final ValueChanged<int> onSelect;

  static const _icons = [
    (Icons.home_outlined, Icons.home_rounded),
    (Icons.pets_outlined, Icons.pets),
    (Icons.calendar_today_outlined, Icons.calendar_today),
    (Icons.settings_outlined, Icons.settings),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final labels = [l10n.navHome, l10n.navPets, l10n.navCalendar, l10n.navSettings];
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Row(
            children: [
              for (var i = 0; i < _icons.length; i++)
                Expanded(
                  child: _NavItem(
                    icon: _icons[i].$1,
                    activeIcon: _icons[i].$2,
                    label: labels[i],
                    active: index == i,
                    onTap: () => onSelect(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.onTap,
  });
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = active ? c.brand : c.text3;
    return InkWell(
      onTap: onTap,
      borderRadius: Radii.fieldAll,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(active ? activeIcon : icon, size: 24, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppText.label(color).copyWith(
                letterSpacing: 0,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionSheet extends StatelessWidget {
  const _ActionSheet({required this.onAction});
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 6),
              child: Text(l10n.actionSheetTitle, style: AppText.title2(c.text)),
            ),
            _SheetRow(
              icon: Icons.check_circle_outline,
              title: l10n.actionRegisterCareTitle,
              subtitle: l10n.actionRegisterCareSubtitle,
              onTap: () => onAction('care'),
            ),
            _SheetRow(
              icon: Icons.medical_services_outlined,
              title: l10n.actionAddVisitTitle,
              subtitle: l10n.actionAddVisitSubtitle,
              onTap: () => onAction('visit'),
            ),
            _SheetRow(
              icon: Icons.monitor_weight_outlined,
              title: l10n.actionLogWeightTitle,
              subtitle: l10n.actionLogWeightSubtitle,
              onTap: () => onAction('weight'),
            ),
            _SheetRow(
              icon: Icons.add,
              title: l10n.actionNewPetTitle,
              subtitle: l10n.actionNewPetSubtitle,
              onTap: () => onAction('newpet'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetRow extends StatelessWidget {
  const _SheetRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: Radii.fieldAll,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.brandSoft,
                borderRadius: Radii.fieldAll,
              ),
              child: Icon(icon, color: c.brand, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.cardTitle(c.text).copyWith(fontSize: 16)),
                  Text(subtitle, style: AppText.meta(c.text3)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: c.text3),
          ],
        ),
      ),
    );
  }
}
