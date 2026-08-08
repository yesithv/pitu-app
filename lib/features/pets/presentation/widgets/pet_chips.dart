import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text.dart';
import '../pets_providers.dart';

/// Fila de chips de mascota (scroll horizontal): "Todas" + una por mascota.
/// El filtro es persistente vía [petFilterProvider].
class PetChips extends ConsumerWidget {
  const PetChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pets = ref.watch(petViewsProvider);
    final selected = ref.watch(petFilterProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _Chip(
            emoji: '🐾',
            label: AppLocalizations.of(context)!.chipsAll,
            selected: selected == null,
            onTap: () => ref.read(petFilterProvider.notifier).state = null,
          ),
          for (final pv in pets) ...[
            const SizedBox(width: 8),
            _Chip(
              emoji: pv.pet.species.emoji,
              label: pv.pet.name,
              selected: selected == pv.pet.id,
              onTap: () =>
                  ref.read(petFilterProvider.notifier).state = pv.pet.id,
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: selected ? c.brandSoft : Colors.transparent,
      borderRadius: Radii.pillAll,
      child: InkWell(
        borderRadius: Radii.pillAll,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(5, 5, 14, 5),
          decoration: BoxDecoration(
            borderRadius: Radii.pillAll,
            border: Border.all(
                color: selected ? Colors.transparent : c.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: c.alt, shape: BoxShape.circle),
                child: Text(emoji, style: const TextStyle(fontSize: 14)),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppText.button(selected ? c.brand : c.text2)
                    .copyWith(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
