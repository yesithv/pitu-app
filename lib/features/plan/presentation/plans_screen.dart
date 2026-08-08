import 'package:flutter/material.dart';
import 'package:pitu_app/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/common.dart';
import '../../purchases/application/purchases_providers.dart';
import '../../purchases/domain/purchase_service.dart';
import '../application/entitlement_controller.dart';
import '../domain/plan.dart';

/// Pantalla de planes (RF-50). En Fase 1 solo Free y Pro (pago único). Lenguaje
/// "Desbloquear" (no "suscribirse"); candados honestos por función.
class PlansScreen extends ConsumerStatefulWidget {
  const PlansScreen({super.key, this.blockedFeature});
  final String? blockedFeature;

  static Future<void> open(BuildContext context, {String? blockedFeature}) {
    return Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PlansScreen(blockedFeature: blockedFeature),
      fullscreenDialog: true,
    ));
  }

  @override
  ConsumerState<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends ConsumerState<PlansScreen> {
  bool _busy = false;
  String? _priceLabel;

  @override
  void initState() {
    super.initState();
    _loadPrice();
  }

  Future<void> _loadPrice() async {
    final product = await ref.read(purchaseServiceProvider).loadProProduct();
    if (mounted && product != null) {
      setState(() => _priceLabel = product.price);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final plan = ref.watch(entitlementProvider).plan;

    return Scaffold(
      appBar: AppBar(leading: const CloseButton()),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            Text(l10n.plansHeadline,
                style: AppText.title1(c.text)),
            const SizedBox(height: 4),
            Text(l10n.plansSubhead,
                style: AppText.body(c.text2)),
            const SizedBox(height: 18),
            if (widget.blockedFeature != null) ...[
              InfoNote(l10n.plansAvailableInPro(widget.blockedFeature!),
                  icon: Icons.lock_outline),
              const SizedBox(height: 14),
            ],
            _FreeCard(current: plan == PlanType.free),
            const SizedBox(height: 14),
            _ProCard(
              isCurrent: plan == PlanType.pro,
              priceLabel: _priceLabel ?? '\$34.900',
              busy: _busy,
              onUnlock: _unlock,
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: _busy ? null : _restore,
                child:
                    Text(l10n.plansRestore, style: AppText.metaStrong(c.text3)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _unlock() async {
    final purchases = ref.read(purchaseServiceProvider);
    final entitlement = ref.read(entitlementProvider.notifier);

    // Sin tienda (web/escritorio): solo en modo demo se desbloquea Pro para
    // exhibición; en producción no se otorga Pro sin una compra real.
    if (!purchases.isSupported) {
      if (kDemoMode) {
        entitlement.unlockPro();
        _finishSuccess();
      } else {
        _snack(AppLocalizations.of(context)!.purchaseMobileOnly);
      }
      return;
    }

    setState(() => _busy = true);
    final result = await purchases.buyPro();
    if (!mounted) return;
    setState(() => _busy = false);

    if (result.grantsPro) {
      entitlement.unlockPro();
      _finishSuccess();
    } else if (result.status == PurchaseStatus.cancelled) {
      // El usuario canceló: sin ruido.
    } else if (result.status == PurchaseStatus.pending) {
      _snack(AppLocalizations.of(context)!.purchasePending);
    } else {
      _snack(AppLocalizations.of(context)!.purchaseFailed);
    }
  }

  Future<void> _restore() async {
    final purchases = ref.read(purchaseServiceProvider);
    final entitlement = ref.read(entitlementProvider.notifier);

    if (!purchases.isSupported) {
      _snack(AppLocalizations.of(context)!.restoreMobileOnly);
      return;
    }

    setState(() => _busy = true);
    final result = await purchases.restore();
    if (!mounted) return;
    setState(() => _busy = false);

    if (result.grantsPro) {
      entitlement.unlockPro();
      _finishSuccess(restored: true);
    } else {
      _snack(AppLocalizations.of(context)!.restoreNoneFound);
    }
  }

  void _finishSuccess({bool restored = false}) {
    final l10n = AppLocalizations.of(context)!;
    Navigator.of(context).pop();
    _snack(restored ? l10n.purchaseRestored : l10n.purchaseUnlocked);
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _FreeCard extends StatelessWidget {
  const _FreeCard({required this.current});
  final bool current;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(l10n.planNameFree, style: AppText.title2(c.text)),
              Text('\$0', style: AppText.title1(c.text)),
            ],
          ),
          const SizedBox(height: 12),
          _Feature(text: l10n.planFreeFeature1, yes: true),
          _Feature(text: l10n.planFreeFeature2, yes: true),
          _Feature(text: l10n.planFreeFeature3, yes: true),
          _Feature(text: l10n.planFreeFeature4, yes: false),
          _Feature(text: l10n.planFreeFeature5, yes: false),
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
            child: Text(current ? l10n.planCurrent : l10n.planFreeButton,
                style: AppText.button(c.text2).copyWith(fontSize: 15)),
          ),
        ],
      ),
    );
  }
}

class _ProCard extends StatelessWidget {
  const _ProCard({
    required this.isCurrent,
    required this.onUnlock,
    required this.priceLabel,
    required this.busy,
  });
  final bool isCurrent;
  final VoidCallback onUnlock;
  final String priceLabel;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
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
          ProBadge(label: l10n.planProBadge),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(l10n.planNamePro, style: AppText.title2(c.text)),
              Text(priceLabel, style: AppText.display(c.text)),
            ],
          ),
          const SizedBox(height: 12),
          _Feature(text: l10n.planProFeature1, yes: true),
          _Feature(text: l10n.planProFeature2, yes: true),
          _Feature(text: l10n.planProFeature3, yes: true),
          _Feature(text: l10n.planProFeature4, yes: true),
          _Feature(text: l10n.planProFeature5, yes: true),
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
              child: Text(l10n.planProPurchasedButton, style: AppText.button(c.brand).copyWith(fontSize: 15)),
            )
          else
            PrimaryButton(
              label: busy ? l10n.planProcessing : l10n.planUnlockPro,
              onPressed: busy ? null : onUnlock,
            ),
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
