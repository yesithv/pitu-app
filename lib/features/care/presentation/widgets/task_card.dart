import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../../core/i18n/l10n_labels.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/widgets/care_icons.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../domain/entities/care_kind.dart';
import '../schedule_view.dart';

/// Tarjeta de tarea (identidad §9): franja de estado a la izquierda, ícono del
/// cuidado, nombre + mascota, chip de estado y acción "Marcar como hecha".
class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.view,
    required this.onMarkDone,
    this.onTap,
    this.showPet = true,
  });

  final ScheduleView view;
  final VoidCallback onMarkDone;
  final VoidCallback? onTap;
  final bool showPet;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final style = complianceStyle(context, view.status);

    return Container(
      margin: const EdgeInsets.only(bottom: Gap.md),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: Radii.cardAll,
        border: Border.all(color: c.border),
        boxShadow: [
          BoxShadow(color: c.shadowRest, blurRadius: 3, offset: const Offset(0, 1)),
        ],
      ),
      child: ClipRRect(
        borderRadius: Radii.cardAll,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 4, color: style.color),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _CareIconBox(kind: view.schedule.kind),
                              const SizedBox(width: Gap.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        careDisplayName(
                                            l10n, view.schedule.kind, view.name),
                                        style: AppText.cardTitle(c.text)),
                                    if (showPet) ...[
                                      const SizedBox(height: 2),
                                      Text(view.pet.name, style: AppText.meta(c.text3)),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          StatusPill(
                              status: view.status,
                              label: relativeLabelFor(l10n, view.daysUntil)),
                          const SizedBox(height: 14),
                          _MarkDoneButton(onPressed: onMarkDone),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CareIconBox extends StatelessWidget {
  const _CareIconBox({required this.kind});
  final CareKind kind;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: c.alt,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: Icon(iconForCareKind(kind), size: 20, color: c.text2),
    );
  }
}

class _MarkDoneButton extends StatelessWidget {
  const _MarkDoneButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        borderRadius: Radii.fieldAll,
        child: InkWell(
          borderRadius: Radii.fieldAll,
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 11),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: Radii.fieldAll,
              border: Border.all(color: c.borderStrong),
            ),
            child: Text(AppLocalizations.of(context)!.careMarkDone,
                style: AppText.button(c.text).copyWith(fontSize: 15)),
          ),
        ),
      ),
    );
  }
}
