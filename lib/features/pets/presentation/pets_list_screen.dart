import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/common.dart';
import '../../plan/application/entitlement_controller.dart';
import '../../plan/domain/plan.dart';
import '../../plan/presentation/plans_screen.dart';
import 'archived_pets_screen.dart';
import 'pet_detail_screen.dart';
import 'pet_form_screen.dart';
import 'pet_view.dart';
import 'pets_providers.dart';

class PetsListScreen extends ConsumerWidget {
  const PetsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final pets = ref.watch(petViewsProvider);
    final archived = ref.watch(archivedPetsProvider);
    final limits = ref.watch(entitlementProvider).limits;

    return ListView(
      padding: const EdgeInsets.fromLTRB(Gap.screenH, 8, Gap.screenH, 100),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Text('Mis mascotas', style: AppText.display(c.text)),
        ),
        for (final pv in pets) ...[
          _PetRow(view: pv),
          const SizedBox(height: 12),
        ],
        DashedActionButton(
          label: 'Agregar mascota',
          onPressed: () => _onAddPet(context, ref, pets, limits),
        ),
        if (archived.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 22),
            child: Center(
              child: TextButton(
                onPressed: () => ArchivedPetsScreen.open(context),
                child: Text('Ver mascotas archivadas (${archived.length})',
                    style: AppText.button(c.text2).copyWith(fontSize: 14)),
              ),
            ),
          ),
      ],
    );
  }

  void _onAddPet(
    BuildContext context,
    WidgetRef ref,
    List<PetView> pets,
    PlanLimits limits,
  ) {
    final max = limits.maxActivePets;
    if (max != null && pets.length >= max) {
      // Candado honesto: al topar el límite Free, ofrecer la mejora (RF-50).
      PlansScreen.open(context, blockedFeature: 'Mascotas ilimitadas');
      return;
    }
    PetFormScreen.open(context);
  }
}

class _PetRow extends StatelessWidget {
  const _PetRow({required this.view});
  final PetView view;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final pet = view.pet;
    return AppCard(
      onTap: () => PetDetailScreen.open(context, pet.id),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          PetAvatar(emoji: pet.species.emoji, photoBase64: pet.photoBase64, size: 60),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pet.name, style: AppText.title2(c.text)),
                const SizedBox(height: 1),
                Text(pet.shortSubtitle, style: AppText.meta(c.text3)),
              ],
            ),
          ),
          _MiniStatus(view: view),
        ],
      ),
    );
  }
}

class _MiniStatus extends StatelessWidget {
  const _MiniStatus({required this.view});
  final PetView view;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final comp = view.compliance;
    late final Color color;
    late final Color soft;
    late final String label;
    if (comp.overdue > 0) {
      color = c.over;
      soft = c.overSoft;
      label = '${comp.overdue} atrasada${comp.overdue == 1 ? '' : 's'}';
    } else if (comp.due > 0) {
      color = c.due;
      soft = c.dueSoft;
      label = '${comp.due} próxima${comp.due == 1 ? '' : 's'}';
    } else {
      color = c.ok;
      soft = c.okSoft;
      label = 'Al día';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: soft, borderRadius: Radii.pillAll),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label, style: AppText.metaStrong(color)),
        ],
      ),
    );
  }
}
