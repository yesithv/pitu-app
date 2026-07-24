import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/common.dart';
import '../application/entitlement_controller.dart';
import '../domain/plan.dart';

/// Pantalla de planes (RF-50). En Fase 1 solo Free y Pro (pago único). Lenguaje
/// "Desbloquear" (no "suscribirse"); candados honestos por función.
class PlansScreen extends ConsumerWidget {
  const PlansScreen({super.key, this.blockedFeature});
  final String? blockedFeature;

  static Future<void> open(BuildContext context, {String? blockedFeature}) {
    return Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PlansScreen(blockedFeature: blockedFeature),
      fullscreenDialog: true,
    ));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final plan = ref.watch(entitlementProvider).plan;

    return Scaffold(
      appBar: AppBar(leading: const CloseButton()),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            Text('Desbloquea todo el cuidado de tus mascotas',
                style: AppText.title1(c.text)),
            const SizedBox(height: 4),
            Text('Un solo pago. Para siempre. Sin suscripción.',
                style: AppText.body(c.text2)),
            const SizedBox(height: 18),
            if (blockedFeature != null) ...[
              InfoNote('Disponible en Pro: $blockedFeature', icon: Icons.lock_outline),
              const SizedBox(height: 14),
            ],
            _FreeCard(current: plan == PlanType.free),
            const SizedBox(height: 14),
            _ProCard(
              isCurrent: plan == PlanType.pro,
              onUnlock: () {
                ref.read(entitlementProvider.notifier).unlockPro();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context)
                  ..clearSnackBars()
                  ..showSnackBar(const SnackBar(
                      content: Text('¡Pro desbloqueado! Gracias 🐾')));
              },
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () =>
                    ref.read(entitlementProvider.notifier).restore(),
                child: Text('Restaurar compra',
                    style: AppText.metaStrong(c.text3)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FreeCard extends StatelessWidget {
  const _FreeCard({required this.current});
  final bool current;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('Free', style: AppText.title2(c.text)),
              Text('\$0', style: AppText.title1(c.text)),
            ],
          ),
          const SizedBox(height: 12),
          _Feature(text: '1 mascota', yes: true),
          _Feature(text: 'Recordatorios y catálogo', yes: true),
          _Feature(text: 'Historial básico · respaldo', yes: true),
          _Feature(text: 'Mascotas ilimitadas', yes: false),
          _Feature(text: 'Panel de cumplimiento', yes: false),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.alt,
              borderRadius: Radii.pillAll,
              border: Border.all(color: c.border),
            ),
            child: Text(current ? 'Plan actual' : 'Plan gratuito',
                style: AppText.button(c.text2).copyWith(fontSize: 15)),
          ),
        ],
      ),
    );
  }
}

class _ProCard extends StatelessWidget {
  const _ProCard({required this.isCurrent, required this.onUnlock});
  final bool isCurrent;
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(Gap.lg),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: Radii.cardAll,
        border: Border.all(color: c.brand, width: 2),
        boxShadow: [
          BoxShadow(color: c.shadowRest, blurRadius: 3, offset: const Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ProBadge(label: 'Pago único · Para siempre'),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('Pro', style: AppText.title2(c.text)),
              Text('\$34.900', style: AppText.display(c.text)),
            ],
          ),
          const SizedBox(height: 12),
          _Feature(text: 'Mascotas ilimitadas', yes: true),
          _Feature(text: 'Adjuntos y tareas ilimitadas', yes: true),
          _Feature(text: 'Panel recomendado vs. realizado', yes: true),
          _Feature(text: 'Reporte PDF para el veterinario', yes: true),
          _Feature(text: 'Recordatorios avanzados', yes: true),
          const SizedBox(height: 14),
          if (isCurrent)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.brandSoft,
                borderRadius: Radii.pillAll,
              ),
              child: Text('Pro · Comprado', style: AppText.button(c.brand).copyWith(fontSize: 15)),
            )
          else
            PrimaryButton(label: 'Desbloquear Pro', onPressed: onUnlock),
        ],
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.text, required this.yes});
  final String text;
  final bool yes;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(yes ? Icons.check : Icons.remove, size: 17, color: yes ? c.ok : c.text3),
          const SizedBox(width: 9),
          Expanded(child: Text(text, style: AppText.body(yes ? c.text2 : c.text3))),
        ],
      ),
    );
  }
}
