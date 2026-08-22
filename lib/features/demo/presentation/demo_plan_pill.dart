import 'package:flutter/material.dart';
import 'package:pitu_app/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text.dart';
import '../../plan/application/entitlement_controller.dart';

/// Conmutador Free↔Pro **visible dentro del recorrido del demo**
/// (`docs/DEMO_ENFOQUE.md` §3.3). Hasta ahora este conmutador vivía escondido en
/// Ajustes; sacarlo a la barra del demo hace **palpable** el contraste: al pasar a
/// Free, el dashboard muestra el teaser con candado y las acciones Pro (2.ª
/// mascota, PDF, recordatorios anticipados) abren el paywall ya existente.
///
/// Reutiliza `EntitlementController.useFreeForDemo()` / `unlockPro()`; no altera
/// la lógica de negocio (`PlanLimits`).
class DemoPlanPill extends ConsumerWidget {
  const DemoPlanPill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final isPro = ref.watch(entitlementProvider).isPro;
    final ctrl = ref.read(entitlementProvider.notifier);

    // Estado actual (ícono + texto) y acción del toque.
    final planLabel = isPro ? l10n.demoPlanPillProLabel : l10n.demoPlanPillFreeLabel;
    final actionLabel = isPro ? l10n.demoPlanPillPro : l10n.demoPlanPillFree;

    return Material(
      color: c.card,
      borderRadius: Radii.pillAll,
      child: InkWell(
        borderRadius: Radii.pillAll,
        onTap: () => isPro ? ctrl.useFreeForDemo() : ctrl.unlockPro(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPro ? Icons.workspace_premium : Icons.lock_open_outlined,
                size: 15,
                color: c.accentInk,
              ),
              const SizedBox(width: 5),
              Text(planLabel, style: AppText.label(c.accentInk)),
              const SizedBox(width: 6),
              Container(width: 1, height: 12, color: c.accentInk.withValues(alpha: 0.3)),
              const SizedBox(width: 6),
              Text(actionLabel,
                  style: AppText.metaStrong(c.accentInk).copyWith(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
