import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:pitu_app/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/l10n_labels.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text.dart';
import '../../core/utils/app_dates.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/care_icons.dart';
import '../../core/widgets/common.dart';
import '../../core/di/providers.dart';
import '../care/presentation/care_actions.dart';
import '../care/presentation/care_providers.dart';
import '../care/presentation/care_register_screen.dart';
import '../care/presentation/schedule_view.dart';
import '../care/presentation/widgets/task_card.dart';
import '../pets/presentation/pet_view.dart';
import '../pets/presentation/pets_providers.dart';
import '../pets/presentation/widgets/pet_chips.dart';
import '../plan/application/entitlement_controller.dart';
import '../plan/presentation/plans_screen.dart';
import '../settings/profile_edit_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final localeName = Localizations.localeOf(context).toString();
    final owner = ref.watch(ownerNameProvider);
    final petViews = ref.watch(petViewsProvider);
    final filter = ref.watch(petFilterProvider);
    final now = ref.read(clockProvider).now();
    final isPro = ref.watch(entitlementProvider).isPro;

    final all = ref.watch(scheduleViewsForActiveProvider);
    final views = filter == null
        ? all
        : all.where((v) => v.pet.id == filter).toList();
    final pending = views.where((v) => v.isPending).toList();
    final overdueCount = views.where((v) => v.daysUntil < 0).length;
    final upcoming =
        views.where((v) => v.daysUntil > 3 && v.daysUntil <= 7).toList();

    final focus = filter == null
        ? petViews.firstOrNull
        : petViews.firstWhereOrNull((p) => p.pet.id == filter);

    return ListView(
      padding: const EdgeInsets.fromLTRB(Gap.screenH, 6, Gap.screenH, 100),
      children: [
        _Header(
          owner: owner,
          date: AppDates.longWeekday(now, localeName),
          pendingCount: pending.length,
          overdueCount: overdueCount,
          onEditProfile: () => ProfileEditScreen.open(context),
          onBell: () => _showRemindersInfo(context),
        ),
        const SizedBox(height: 14),
        const PetChips(),
        const SizedBox(height: 16),
        if (focus != null)
          isPro
              ? _ComplianceCard(view: focus)
              : _ComplianceTeaser(
                  onTap: () => PlansScreen.open(context),
                ),
        if (pending.isNotEmpty) ...[
          SectionHeader(l10n.dashboardSectionToday),
          for (final v in pending)
            TaskCard(
              view: v,
              showPet: filter == null,
              onMarkDone: () => markCareDone(context, ref, v),
              onTap: () => CareRegisterScreen.open(
                context,
                scheduleId: v.schedule.id,
                petId: v.pet.id,
                careName: careDisplayName(l10n, v.schedule.kind, v.name),
                petName: v.pet.name,
                petEmoji: v.pet.species.emoji,
              ),
            ),
        ] else ...[
          SectionHeader(l10n.dashboardSectionToday),
          _AllClearCard(),
        ],
        if (upcoming.isNotEmpty) ...[
          SectionHeader(l10n.dashboardSectionUpcoming),
          for (final v in upcoming) _UpcomingRow(view: v),
        ],
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.owner,
    required this.date,
    required this.pendingCount,
    required this.overdueCount,
    required this.onEditProfile,
    required this.onBell,
  });
  final String owner;
  final String date;
  final int pendingCount;
  final int overdueCount;
  final VoidCallback onEditProfile;
  final VoidCallback onBell;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final summary = pendingCount == 0
        ? l10n.dashboardAllClearToday
        : l10n.dashboardPendingCount(pendingCount);
    final summaryColor = overdueCount > 0 ? c.over : c.text3;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(date, style: AppText.meta(c.text3)),
              Text(l10n.dashboardGreeting(owner), style: AppText.title1(c.text)),
              const SizedBox(height: 2),
              Text(summary, style: AppText.meta(summaryColor)),
            ],
          ),
        ),
        IconButton(
          onPressed: onBell,
          icon: Badge(
            isLabelVisible: overdueCount > 0,
            backgroundColor: c.over,
            child: Icon(Icons.notifications_none, color: c.text2),
          ),
          tooltip: l10n.dashboardRemindersTooltip,
        ),
        GestureDetector(
          onTap: onEditProfile,
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration:
                BoxDecoration(color: c.brandSoft, shape: BoxShape.circle),
            child: const Text('🧑', style: TextStyle(fontSize: 18)),
          ),
        ),
      ],
    );
  }
}

void _showRemindersInfo(BuildContext context) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(
      content: Text(AppLocalizations.of(context)!.dashboardRemindersInfo),
    ));
}

class _ComplianceCard extends StatelessWidget {
  const _ComplianceCard({required this.view});
  final PetView view;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final comp = view.compliance;
    final title = comp.isAllUpToDate
        ? l10n.dashboardPetUpToDate(view.pet.name)
        : l10n.dashboardPetOverdue(view.pet.name, comp.overdue);
    return Container(
      padding: const EdgeInsets.all(Gap.lg),
      decoration: BoxDecoration(
        color: c.brandSoft,
        borderRadius: Radii.cardAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: comp.isAllUpToDate ? c.ok : c.due,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(title, style: AppText.cardTitle(c.brand).copyWith(fontSize: 15)),
            ],
          ),
          const SizedBox(height: 4),
          Text(l10n.dashboardCaresRatio(comp.upToDate, comp.total),
              style: AppText.meta(c.brand).copyWith(color: c.brand.withValues(alpha: 0.85))),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: Radii.pillAll,
            child: LinearProgressIndicator(
              value: comp.ratio,
              minHeight: 8,
              backgroundColor: c.brand.withValues(alpha: 0.18),
              valueColor: AlwaysStoppedAnimation(c.brand),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComplianceTeaser extends StatelessWidget {
  const _ComplianceTeaser({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(Icons.insights_outlined, color: c.text2),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.dashboardCompliancePanel, style: AppText.cardTitle(c.text).copyWith(fontSize: 15)),
                const SizedBox(height: 2),
                Text(l10n.dashboardComplianceTeaser,
                    style: AppText.meta(c.text3)),
              ],
            ),
          ),
          const ProBadge(),
        ],
      ),
    );
  }
}

class _AllClearCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: c.ok),
          const SizedBox(width: 12),
          Expanded(
            child: Text(AppLocalizations.of(context)!.dashboardAllClearCard,
                style: AppText.body(c.text2)),
          ),
        ],
      ),
    );
  }
}

class _UpcomingRow extends StatelessWidget {
  const _UpcomingRow({required this.view});
  final ScheduleView view;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final localeName = Localizations.localeOf(context).toString();
    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.md),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: c.alt,
                borderRadius: const BorderRadius.all(Radius.circular(10)),
              ),
              child: Icon(iconForCareKind(view.schedule.kind), size: 20, color: c.text2),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(careDisplayName(l10n, view.schedule.kind, view.name),
                      style: AppText.bodyStrong(c.text)),
                  Text(view.pet.name, style: AppText.meta(c.text3)),
                ],
              ),
            ),
            Text(AppDates.weekdayShort(view.schedule.nextDate, localeName),
                style: AppText.meta(c.text3)),
          ],
        ),
      ),
    );
  }
}
