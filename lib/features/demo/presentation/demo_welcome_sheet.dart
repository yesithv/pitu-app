import 'package:flutter/material.dart';
import 'package:pitu_app/l10n/app_localizations.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/common.dart';

/// Abre la hoja de bienvenida del demo (una sola vez por sesión de demo).
///
/// Recoge el enfoque de `docs/DEMO_ENFOQUE.md` §3.1: en los primeros segundos el
/// visitante debe entender **qué hace la app** y **qué desbloquea el Pro**, en vez
/// de caer directo al dashboard sin contexto. Presenta las funciones estrella
/// (marcando con `ProBadge` las exclusivas de Pro) y apunta al conmutador
/// Free↔Pro visible en la barra del demo (§3.3).
Future<void> showDemoWelcomeSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => const DemoWelcomeSheet(),
  );
}

class DemoWelcomeSheet extends StatelessWidget {
  const DemoWelcomeSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.demoWelcomeTitle, style: AppText.title1(c.text)),
              const SizedBox(height: 6),
              Text(l10n.demoWelcomeSubtitle, style: AppText.body(c.text2)),
              const SizedBox(height: 16),
              _FeatureRow(
                icon: Icons.favorite_border,
                text: l10n.demoWelcomeFeatureHistory,
              ),
              _FeatureRow(
                icon: Icons.picture_as_pdf_outlined,
                text: l10n.demoWelcomeFeaturePdf,
                pro: true,
              ),
              _FeatureRow(
                icon: Icons.notifications_active_outlined,
                text: l10n.demoWelcomeFeatureReminders,
                pro: true,
              ),
              _FeatureRow(
                icon: Icons.cloud_upload_outlined,
                text: l10n.demoWelcomeFeatureBackup,
              ),
              _FeatureRow(
                icon: Icons.pets_outlined,
                text: l10n.demoWelcomeMultiPet,
              ),
              const SizedBox(height: 14),
              InfoNote(l10n.demoWelcomeProHint, icon: Icons.workspace_premium_outlined),
              const SizedBox(height: 18),
              PrimaryButton(
                label: l10n.demoWelcomeExplore,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fila de función estrella: ícono en pastilla de marca + texto, con `ProBadge`
/// opcional para las funciones exclusivas de Pro (identidad §10: nunca solo color).
class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.icon, required this.text, this.pro = false});
  final IconData icon;
  final String text;
  final bool pro;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.brandSoft,
              borderRadius: Radii.fieldAll,
            ),
            child: Icon(icon, color: c.brand, size: 21),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(text, style: AppText.body(c.text)),
            ),
          ),
          if (pro) ...[
            const SizedBox(width: 8),
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: ProBadge(),
            ),
          ],
        ],
      ),
    );
  }
}
