import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/l10n_labels.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text.dart';
import '../../core/utils/app_dates.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/care_icons.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/status_pill.dart';
import '../care/presentation/care_providers.dart';
import '../care/presentation/schedule_view.dart';
import '../pets/presentation/pet_detail_screen.dart';
import '../pets/presentation/pets_providers.dart';
import '../pets/presentation/widgets/pet_chips.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final filter = ref.watch(petFilterProvider);
    final all = ref.watch(scheduleViewsForActiveProvider);
    final views =
        filter == null ? all : all.where((v) => v.pet.id == filter).toList();

    final overdue = views.where((v) => v.daysUntil < 0).toList();
    final today = views.where((v) => v.daysUntil == 0).toList();
    final thisWeek =
        views.where((v) => v.daysUntil >= 1 && v.daysUntil <= 7).toList();
    final later = views.where((v) => v.daysUntil > 7).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(Gap.screenH, 8, Gap.screenH, 100),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(l10n.calendarTitle, style: AppText.display(c.text)),
        ),
        const PetChips(),
        const SizedBox(height: 8),
        if (overdue.isNotEmpty) ...[
          SectionHeader(l10n.calendarOverdue(overdue.length), color: c.over),
          for (final v in overdue) _CalRow(view: v, showStatus: true),
        ],
        if (today.isNotEmpty) ...[
          SectionHeader(l10n.calendarToday(today.length)),
          for (final v in today) _CalRow(view: v, showStatus: true),
        ],
        if (thisWeek.isNotEmpty) ...[
          SectionHeader(l10n.calendarThisWeek(thisWeek.length)),
          for (final v in thisWeek) _CalRow(view: v, showStatus: true),
        ],
        if (later.isNotEmpty) ...[
          SectionHeader(l10n.calendarLater(later.length)),
          for (final v in later) _CalRow(view: v, showStatus: false),
        ],
        if (views.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Center(
              child: Text(l10n.calendarEmpty,
                  style: AppText.body(c.text3)),
            ),
          ),
      ],
    );
  }
}

class _CalRow extends StatelessWidget {
  const _CalRow({required this.view, required this.showStatus});
  final ScheduleView view;
  final bool showStatus;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final localeName = Localizations.localeOf(context).toString();
    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.md),
      child: AppCard(
        onTap: () => PetDetailScreen.open(context, view.pet.id),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: c.alt,
                borderRadius: const BorderRadius.all(Radius.circular(9)),
              ),
              child: Icon(iconForCareKind(view.schedule.kind), size: 18, color: c.text2),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(careDisplayName(l10n, view.schedule.kind, view.name),
                      style: AppText.bodyStrong(c.text)),
                  Text('${view.pet.name} · ${AppDates.shortDate(view.schedule.nextDate, localeName)}',
                      style: AppText.meta(c.text3)),
                ],
              ),
            ),
            if (showStatus)
              StatusPill(
                  status: view.status,
                  label: relativeLabelFor(l10n, view.daysUntil))
            else
              Text(AppDates.shortDate(view.schedule.nextDate, localeName),
                  style: AppText.meta(c.text3)),
          ],
        ),
      ),
    );
  }
}
