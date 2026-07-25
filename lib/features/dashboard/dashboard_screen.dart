import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
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
    final upcoming =
        views.where((v) => v.daysUntil > 3 && v.daysUntil <= 7).toList();

    final focus = filter == null
        ? petViews.firstOrNull
        : petViews.firstWhereOrNull((p) => p.pet.id == filter);

    return ListView(
      padding: const EdgeInsets.fromLTRB(Gap.screenH, 6, Gap.screenH, 100),
      children: [
        _Header(owner: owner, date: AppDates.longWeekday(now)),
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
          const SectionHeader('Hoy'),
          for (final v in pending)
            TaskCard(
              view: v,
              showPet: filter == null,
              onMarkDone: () => markCareDone(context, ref, v),
              onTap: () => CareRegisterScreen.open(
                context,
                scheduleId: v.schedule.id,
                careName: v.name,
                petName: v.pet.name,
                petEmoji: v.pet.species.emoji,
              ),
            ),
        ] else ...[
          const SectionHeader('Hoy'),
          _AllClearCard(),
        ],
        if (upcoming.isNotEmpty) ...[
          const SectionHeader('Próximos 7 días'),
          for (final v in upcoming) _UpcomingRow(view: v),
        ],
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.owner, required this.date});
  final String owner;
  final String date;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(date, style: AppText.meta(c.text3)),
              Text('Hola, $owner', style: AppText.title1(c.text)),
            ],
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: Icon(Icons.notifications_none, color: c.text2),
          tooltip: 'Notificaciones',
        ),
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: c.brandSoft, shape: BoxShape.circle),
          child: const Text('🧑', style: TextStyle(fontSize: 18)),
        ),
      ],
    );
  }
}

class _ComplianceCard extends StatelessWidget {
  const _ComplianceCard({required this.view});
  final PetView view;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final comp = view.compliance;
    final title = comp.isAllUpToDate
        ? '${view.pet.name} está al día'
        : '${view.pet.name}: ${comp.overdue} atrasado${comp.overdue == 1 ? '' : 's'}';
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
          Text('${comp.upToDate} de ${comp.total} cuidados',
              style: AppText.meta(c.brand).copyWith(color: c.brand.withOpacity(0.85))),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: Radii.pillAll,
            child: LinearProgressIndicator(
              value: comp.ratio,
              minHeight: 8,
              backgroundColor: c.brand.withOpacity(0.18),
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
                Text('Panel de cumplimiento', style: AppText.cardTitle(c.text).copyWith(fontSize: 15)),
                const SizedBox(height: 2),
                Text('Compara lo recomendado con lo realizado',
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
            child: Text('Todo al día por hoy. ¡Buen trabajo! 🐾',
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
                  Text(view.name, style: AppText.bodyStrong(c.text)),
                  Text(view.pet.name, style: AppText.meta(c.text3)),
                ],
              ),
            ),
            Text(AppDates.weekdayShort(view.schedule.nextDate),
                style: AppText.meta(c.text3)),
          ],
        ),
      ),
    );
  }
}
