import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/app_dates.dart';
import '../../../core/utils/byte_format.dart';
import '../../../core/utils/image_compressor.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/care_icons.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/status_pill.dart';
import '../../attachments/application/attachment_service.dart';
import '../../attachments/application/attachments_providers.dart';
import '../../attachments/domain/entities/attachment.dart';
import '../../backup/application/backup_providers.dart';
import '../../care/domain/entities/care_kind.dart';
import '../../care/presentation/care_providers.dart';
import '../../care/presentation/care_schedule_form_screen.dart';
import '../../plan/presentation/plans_screen.dart';
import '../../reports/application/pet_report_service.dart';
import '../../reports/application/reports_providers.dart';
import '../../clinical/domain/entities/diagnosis.dart';
import '../../clinical/domain/entities/timeline_entry.dart';
import '../../clinical/presentation/diagnosis_form_screen.dart';
import '../../clinical/presentation/medical_visit_form_screen.dart';
import '../../clinical/presentation/vaccine_form_screen.dart';
import '../../clinical/presentation/weight_form_screen.dart';
import '../../plan/application/entitlement_controller.dart';
import '../domain/entities/pet.dart';
import 'archive_pet_screen.dart';
import 'pet_form_screen.dart';
import 'pets_providers.dart';
import 'widgets/weight_chart.dart';

class PetDetailScreen extends ConsumerWidget {
  const PetDetailScreen({super.key, required this.petId});
  final String petId;

  static Future<void> open(BuildContext context, String petId) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PetDetailScreen(petId: petId)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final pet = ref.watch(petByIdProvider(petId));
    if (pet == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Mascota no encontrada')),
      );
    }

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          actions: [_PetMenu(petId: petId)],
        ),
        // Botón flotante común a las 4 pestañas (misma posición).
        floatingActionButton: _DetailFab(petId: petId),
        body: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverToBoxAdapter(child: _PetHeader(pet: pet)),
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabBarDelegate(
                TabBar(
                  labelColor: c.brand,
                  unselectedLabelColor: c.text3,
                  indicatorColor: c.brand,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: c.border,
                  labelStyle: AppText.button(c.brand).copyWith(fontSize: 14),
                  unselectedLabelStyle: AppText.button(c.text3).copyWith(fontSize: 14),
                  tabs: const [
                    Tab(text: 'Resumen'),
                    Tab(text: 'Cuidados'),
                    Tab(text: 'Historial'),
                    Tab(text: 'Docs'),
                  ],
                ),
                c.bg,
              ),
            ),
          ],
          body: TabBarView(
            children: [
              _SummaryTab(petId: petId),
              _CaresTab(petId: petId),
              _HistoryTab(petId: petId),
              _DocsTab(petId: petId),
            ],
          ),
        ),
      ),
    );
  }
}

class _PetHeader extends ConsumerWidget {
  const _PetHeader({required this.pet});
  final Pet pet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _onTapPhoto(context, ref),
            child: Stack(
              children: [
                PetAvatar(
                    emoji: pet.species.emoji,
                    photoBase64: pet.photoBase64,
                    size: 96),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c.brand,
                      shape: BoxShape.circle,
                      border: Border.all(color: c.bg, width: 2),
                    ),
                    child: Icon(Icons.photo_camera_outlined,
                        size: 16, color: c.onBrand),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(pet.name, style: AppText.display(c.text)),
          const SizedBox(height: 2),
          Text(pet.subtitle, style: AppText.body(c.text2)),
        ],
      ),
    );
  }

  /// Cambiar o quitar la foto de la mascota desde su detalle.
  Future<void> _onTapPhoto(BuildContext context, WidgetRef ref) async {
    final hasPhoto = pet.photoBase64 != null && pet.photoBase64!.isNotEmpty;
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(hasPhoto ? 'Cambiar foto' : 'Agregar foto'),
              onTap: () => Navigator.of(sheet).pop('pick'),
            ),
            if (hasPhoto)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Quitar foto'),
                onTap: () => Navigator.of(sheet).pop('remove'),
              ),
          ],
        ),
      ),
    );
    if (action == null || !context.mounted) return;

    final repo = ref.read(petRepositoryProvider);
    if (action == 'remove') {
      repo.update(pet.copyWith(clearPhoto: true));
      return;
    }

    final files = ref.read(fileTransferProvider);
    final messenger = ScaffoldMessenger.of(context);
    if (!files.canPickFile) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(
            content: Text(
                'Cambiar la foto está disponible en la versión web por ahora.')));
      return;
    }
    final picked = await files.pickBinaryFile(accept: 'image/*');
    if (picked == null) return;
    if (!picked.mimeType.startsWith('image/')) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('Elige una imagen (JPG o PNG).')));
      return;
    }
    final compressed =
        compressImage(picked.bytes, mimeType: picked.mimeType, maxDim: 720);
    const maxBytes = 1536 * 1024; // 1.5 MB
    if (compressed.bytes.length > maxBytes) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(
            content: Text('La imagen es demasiado grande incluso tras comprimir.')));
      return;
    }
    repo.update(pet.copyWith(photoBase64: base64Encode(compressed.bytes)));
    messenger
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(content: Text('Foto actualizada')));
  }
}

class _SummaryTab extends ConsumerWidget {
  const _SummaryTab({required this.petId});
  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final scheduling = ref.read(schedulingServiceProvider);
    final now = ref.read(clockProvider).now();
    final schedules = ref.watch(scheduleViewsForPetProvider(petId));
    final compliance = scheduling.complianceOf(
      schedules.map((v) => v.schedule),
      now,
    );
    final isPro = ref.watch(entitlementProvider).isPro;
    final clinical = ref.read(clinicalRepositoryProvider);
    ref.watch(databaseProvider);
    final diagnoses = clinical.activeDiagnosesForPet(petId);
    final weights = clinical.weightsForPet(petId);
    final nextTasks = schedules.take(3).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
      children: [
        if (isPro)
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Cumplimiento', style: AppText.cardTitle(c.text).copyWith(fontSize: 15)),
                    Text('${compliance.upToDate} de ${compliance.total} al día',
                        style: AppText.meta(c.text2)),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: Radii.pillAll,
                  child: LinearProgressIndicator(
                    value: compliance.ratio,
                    minHeight: 8,
                    backgroundColor: c.alt,
                    valueColor: AlwaysStoppedAnimation(
                        compliance.isAllUpToDate ? c.ok : c.due),
                  ),
                ),
              ],
            ),
          ),
        const SectionHeader('Condiciones activas'),
        if (diagnoses.isEmpty)
          AppCard(
            child: Text('Sin condiciones activas registradas.',
                style: AppText.body(c.text3)),
          )
        else
          for (final d in diagnoses) ...[
            _DiagnosisCard(
              diagnosis: d,
              onChangeStatus: () =>
                  DiagnosisFormScreen.openEdit(context, d.petId, d.id),
            ),
            const SizedBox(height: 10),
          ],
        const SectionHeader('Próximas tareas'),
        AppCard(
          clip: true,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < nextTasks.length; i++)
                Container(
                  decoration: BoxDecoration(
                    border: i == nextTasks.length - 1
                        ? null
                        : Border(bottom: BorderSide(color: c.border)),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: c.alt,
                        borderRadius: const BorderRadius.all(Radius.circular(9)),
                      ),
                      child: Icon(iconForCareKind(nextTasks[i].schedule.kind),
                          size: 18, color: c.text2),
                    ),
                    title: Text(nextTasks[i].name, style: AppText.bodyStrong(c.text)),
                    trailing: Text(
                      nextTasks[i].status.name == 'overdue'
                          ? 'Atrasada'
                          : AppDates.shortDate(nextTasks[i].schedule.nextDate),
                      style: AppText.meta(
                          nextTasks[i].status.name == 'overdue' ? c.over : c.text3),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Peso', style: AppText.title2(c.text)),
            _SmallPillButton(
              label: '+ Registrar',
              onTap: () => WeightFormScreen.open(context, petId),
            ),
          ],
        ),
        const SizedBox(height: 10),
        AppCard(
          child: WeightChart(
            values: [for (final w in weights) w.value],
            labels: [for (final w in weights) AppDates.weekdayShort(w.date)],
          ),
        ),
      ],
    );
  }
}

class _DiagnosisCard extends StatelessWidget {
  const _DiagnosisCard({required this.diagnosis, this.onChangeStatus});
  final Diagnosis diagnosis;
  final VoidCallback? onChangeStatus;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      onTap: onChangeStatus,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          _DxTag(status: diagnosis.status),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(diagnosis.condition, style: AppText.bodyStrong(c.text)),
                Text('desde ${AppDates.shortDateYear(diagnosis.date)}',
                    style: AppText.meta(c.text3)),
              ],
            ),
          ),
          if (onChangeStatus != null)
            Icon(Icons.edit_outlined, size: 18, color: c.text3),
        ],
      ),
    );
  }
}

/// Selector de estado de un diagnóstico (RF-21); el cambio queda en el historial.
Color dxColor(BuildContext context, DiagnosisStatus s) {
  final c = context.colors;
  return switch (s) {
    DiagnosisStatus.active => c.dxActive,
    DiagnosisStatus.treatment => c.dxTreat,
    DiagnosisStatus.chronic => c.dxChronic,
    DiagnosisStatus.resolved => c.dxResolved,
  };
}

class _DxTag extends StatelessWidget {
  const _DxTag({required this.status});
  final DiagnosisStatus status;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final filled =
        status == DiagnosisStatus.active || status == DiagnosisStatus.treatment;
    final color = dxColor(context, status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: filled ? color : Colors.transparent,
        borderRadius: Radii.pillAll,
        border: filled ? null : Border.all(color: c.borderStrong),
      ),
      child: Text(status.label,
          style: AppText.label(filled ? Colors.white : c.text2)
              .copyWith(letterSpacing: 0)),
    );
  }
}

class _CaresTab extends ConsumerWidget {
  const _CaresTab({required this.petId});
  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final schedules = ref.watch(scheduleViewsForPetProvider(petId));
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
      children: [
        for (final v in schedules)
          Padding(
            padding: const EdgeInsets.only(bottom: Gap.md),
            child: AppCard(
              onTap: () => CareScheduleFormScreen.openEdit(
                  context, petId, v.schedule.id),
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
                    child: Icon(iconForCareKind(v.schedule.kind), size: 20, color: c.text2),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(v.name, style: AppText.bodyStrong(c.text)),
                        Text(v.schedule.frequency.label, style: AppText.meta(c.text3)),
                      ],
                    ),
                  ),
                  StatusPill(status: v.status, label: v.relativeLabel),
                ],
              ),
            ),
          ),
        const SizedBox(height: 4),
        DashedActionButton(
          label: 'Agregar cuidado',
          onPressed: () => _onAddCustomCare(context, ref, schedules.length),
        ),
      ],
    );
  }

  void _onAddCustomCare(BuildContext context, WidgetRef ref, int currentCount) {
    final limits = ref.read(entitlementProvider).limits;
    final max = limits.maxCustomCaresPerPet;
    final customCount = ref
        .read(careRepositoryProvider)
        .schedulesForPet(petId)
        .where((s) => s.kind == CareKind.custom)
        .length;
    if (max != null && customCount >= max) {
      PlansScreen.open(context, blockedFeature: 'Cuidados personalizados ilimitados');
      return;
    }
    CareScheduleFormScreen.openCreate(context, petId);
  }
}

class _HistoryTab extends ConsumerStatefulWidget {
  const _HistoryTab({required this.petId});
  final String petId;

  @override
  ConsumerState<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends ConsumerState<_HistoryTab> {
  TimelineKind? _kind; // null = todos
  DateTimeRange? _range;

  static const _filters = <(String, TimelineKind?)>[
    ('Todos', null),
    ('Visitas', TimelineKind.visit),
    ('Vacunas', TimelineKind.vaccine),
    ('Diagnósticos', TimelineKind.diagnosis),
    ('Cuidados', TimelineKind.care),
    ('Peso', TimelineKind.weight),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    ref.watch(databaseProvider);
    final all = ref.read(clinicalRepositoryProvider).timelineForPet(widget.petId);
    final entries = all.where((e) {
      if (_kind != null && e.kind != _kind) return false;
      if (_range != null) {
        final d = DateTime(e.date.year, e.date.month, e.date.day);
        if (d.isBefore(_range!.start) || d.isAfter(_range!.end)) return false;
      }
      return true;
    }).toList();

    return Column(
      children: [
        _FilterBar(
          filters: _filters,
          selected: _kind,
          range: _range,
          onKind: (k) => setState(() => _kind = k),
          onRange: _pickRange,
          onClearRange: () => setState(() => _range = null),
        ),
        Expanded(
          child: entries.isEmpty
              ? Center(
                  child: Text(
                      all.isEmpty
                          ? 'Aún no hay registros en el historial.'
                          : 'Sin registros para este filtro.',
                      style: AppText.body(c.text3)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                  itemCount: entries.length,
                  itemBuilder: (context, i) => _TimelineTile(
                    entry: entries[i],
                    isLast: i == entries.length - 1,
                    onTap: () => _openEntry(entries[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 20),
      lastDate: now,
      initialDateRange: _range,
    );
    if (picked != null) {
      setState(() => _range = DateTimeRange(
            start: DateTime(picked.start.year, picked.start.month, picked.start.day),
            end: DateTime(picked.end.year, picked.end.month, picked.end.day),
          ));
    }
  }

  void _openEntry(TimelineEntry e) {
    final id = e.sourceId;
    if (id == null) return;
    switch (e.kind) {
      case TimelineKind.visit:
        MedicalVisitFormScreen.openEdit(context, widget.petId, id);
      case TimelineKind.vaccine:
        VaccineFormScreen.openEdit(context, widget.petId, id);
      case TimelineKind.weight:
        WeightFormScreen.openEdit(context, widget.petId, id);
      case TimelineKind.diagnosis:
        DiagnosisFormScreen.openEdit(context, widget.petId, id);
      case TimelineKind.care:
        break; // las ejecuciones de cuidado no se editan (se deshacen)
    }
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.filters,
    required this.selected,
    required this.range,
    required this.onKind,
    required this.onRange,
    required this.onClearRange,
  });
  final List<(String, TimelineKind?)> filters;
  final TimelineKind? selected;
  final DateTimeRange? range;
  final ValueChanged<TimelineKind?> onKind;
  final VoidCallback onRange;
  final VoidCallback onClearRange;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            children: [
              for (final f in filters) ...[
                _Chip(
                  label: f.$1,
                  selected: selected == f.$2,
                  onTap: () => onKind(f.$2),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Row(
            children: [
              InkWell(
                onTap: onRange,
                borderRadius: Radii.pillAll,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.date_range_outlined, size: 16, color: c.brand),
                      const SizedBox(width: 6),
                      Text(
                        range == null
                            ? 'Filtrar por fechas'
                            : '${AppDates.shortDate(range!.start)} – ${AppDates.shortDate(range!.end)}',
                        style: AppText.metaStrong(c.brand),
                      ),
                    ],
                  ),
                ),
              ),
              if (range != null)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.close, size: 16, color: c.text3),
                  onPressed: onClearRange,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? c.brand : c.alt,
          borderRadius: Radii.pillAll,
          border: Border.all(color: selected ? c.brand : c.border),
        ),
        child: Text(label,
            style: AppText.metaStrong(selected ? c.onBrand : c.text2)),
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile(
      {required this.entry, required this.isLast, this.onTap});
  final TimelineEntry entry;
  final bool isLast;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final editable = entry.sourceId != null && entry.kind != TimelineKind.care;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(color: c.alt, shape: BoxShape.circle),
                child: Icon(iconForTimelineKind(entry.kind), size: 15, color: c.text2),
              ),
              if (!isLast)
                Expanded(child: Container(width: 2, color: c.border)),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: AppCard(
                onTap: editable ? onTap : null,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(entry.title, style: AppText.bodyStrong(c.text)),
                        ),
                        if (editable)
                          Icon(Icons.edit_outlined, size: 15, color: c.text3),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        AppDates.shortDateYear(entry.date),
                        if (entry.subtitle != null) entry.subtitle!,
                      ].join(' · '),
                      style: AppText.meta(c.text3),
                    ),
                    if (entry.diagnosisLabel != null) ...[
                      const SizedBox(height: 8),
                      _DxTag(status: entry.diagnosisStatus ?? DiagnosisStatus.active),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Filtro de la galería de documentos por tipo (RF-27).
final _docsFilterProvider = StateProvider<AttachmentKind?>((ref) => null);

class _DocsTab extends ConsumerWidget {
  const _DocsTab({required this.petId});
  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final docs = ref.watch(attachmentsForPetProvider(petId));
    final limits = ref.watch(entitlementProvider).limits;
    final max = limits.maxAttachmentsPerPet;
    final filter = ref.watch(_docsFilterProvider);
    final shown =
        filter == null ? docs : docs.where((a) => a.kind == filter).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
      children: [
        if (docs.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 40, bottom: 24),
            child: Column(
              children: [
                Icon(Icons.folder_open_outlined, size: 40, color: c.text3),
                const SizedBox(height: 12),
                Text('Sin documentos todavía',
                    style: AppText.cardTitle(c.text).copyWith(fontSize: 15)),
                const SizedBox(height: 4),
                Text('Adjunta fotos y PDFs de tu mascota (hasta '
                    '${AttachmentService.maxLabel} cada uno).',
                    textAlign: TextAlign.center, style: AppText.meta(c.text3)),
              ],
            ),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              max == null
                  ? '${docs.length} documento(s)'
                  : '${docs.length} de $max documento(s) · plan Free',
              style: AppText.meta(c.text3),
            ),
          ),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final f in const <(String, AttachmentKind?)>[
                  ('Todos', null),
                  ('Imágenes', AttachmentKind.image),
                  ('PDF', AttachmentKind.pdf),
                  ('Otros', AttachmentKind.other),
                ]) ...[
                  _Chip(
                    label: f.$1,
                    selected: filter == f.$2,
                    onTap: () =>
                        ref.read(_docsFilterProvider.notifier).state = f.$2,
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (shown.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text('Sin documentos de este tipo.',
                    style: AppText.meta(c.text3)),
              ),
            ),
          for (final a in shown) ...[
            _DocRow(petId: petId, attachment: a),
            const SizedBox(height: Gap.md),
          ],
        ],
        const SizedBox(height: 4),
        DashedActionButton(
          label: 'Agregar documento',
          onPressed: () => _onAdd(context, ref, docs.length, max),
        ),
      ],
    );
  }

  Future<void> _onAdd(
      BuildContext context, WidgetRef ref, int current, int? max) async {
    final service = ref.read(attachmentServiceProvider);
    if (!service.canAdd) {
      _snack(context,
          'Adjuntar documentos está disponible en la versión web por ahora.');
      return;
    }
    if (max != null && current >= max) {
      PlansScreen.open(context, blockedFeature: 'Documentos ilimitados');
      return;
    }
    final result = await service.pickAndAdd(petId);
    if (!context.mounted) return;
    switch (result.status) {
      case AddAttachmentStatus.success:
        _snack(context, 'Documento agregado.');
      case AddAttachmentStatus.tooLarge:
      case AddAttachmentStatus.quota:
        _snack(context, result.message);
      case AddAttachmentStatus.cancelled:
        break;
    }
  }
}

class _DocRow extends ConsumerWidget {
  const _DocRow({required this.petId, required this.attachment});
  final String petId;
  final Attachment attachment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    return AppCard(
      onTap: () => _open(context, ref),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          _Thumb(attachment: attachment),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(attachment.filename,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.bodyStrong(c.text)),
                const SizedBox(height: 2),
                Text(
                    [
                      if (attachment.source != null &&
                          attachment.source!.isNotEmpty)
                        attachment.source!,
                      _kindLabel(attachment.kind),
                      _size(attachment.sizeBytes),
                    ].join(' · '),
                    style: AppText.meta(c.text3)),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: c.text3),
            onSelected: (v) {
              if (v == 'open') _open(context, ref);
              if (v == 'delete') _confirmDelete(context, ref);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'open', child: Text('Abrir / Descargar')),
              PopupMenuItem(value: 'delete', child: Text('Eliminar')),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    if (attachment.kind == AttachmentKind.image) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => Dialog(
          insetPadding: const EdgeInsets.all(16),
          backgroundColor: Colors.black,
          child: Stack(
            children: [
              InteractiveViewer(
                child: Center(
                  child: Image.memory(base64Decode(attachment.dataBase64)),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }
    await ref.read(attachmentServiceProvider).download(attachment);
    if (!context.mounted) return;
    _snack(context, 'Descargando ${attachment.filename}…');
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar documento'),
        content: Text('Se eliminará "${attachment.filename}" de este '
            'dispositivo. Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      ref.read(attachmentRepositoryProvider).remove(attachment.id);
    }
  }

  static String _kindLabel(AttachmentKind k) => switch (k) {
        AttachmentKind.image => 'Imagen',
        AttachmentKind.pdf => 'PDF',
        AttachmentKind.other => 'Archivo',
      };

  static String _size(int bytes) => formatBytes(bytes);
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.attachment});
  final Attachment attachment;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (attachment.kind == AttachmentKind.image) {
      return ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        child: Image.memory(
          base64Decode(attachment.dataBase64),
          width: 46,
          height: 46,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        ),
      );
    }
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: c.alt,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: Icon(
        attachment.kind == AttachmentKind.pdf
            ? Icons.picture_as_pdf_outlined
            : Icons.insert_drive_file_outlined,
        color: c.text2,
        size: 22,
      ),
    );
  }
}

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(message)));
}

class _PetMenu extends ConsumerWidget {
  const _PetMenu({required this.petId});
  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_horiz),
      onSelected: (value) {
        switch (value) {
          case 'edit':
            PetFormScreen.openEdit(context, petId);
          case 'share':
            _shareReport(context, ref, petId);
          case 'archive':
            ArchivePetScreen.open(context, petId);
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'edit', child: Text('Editar')),
        PopupMenuItem(value: 'share', child: Text('Compartir con veterinario')),
        PopupMenuItem(value: 'archive', child: Text('Archivar')),
      ],
    );
  }
}

/// Botón flotante del detalle: concentra las acciones de "agregar registro".
/// Se muestra igual en las cuatro pestañas.
class _DetailFab extends StatelessWidget {
  const _DetailFab({required this.petId});
  final String petId;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return FloatingActionButton(
      onPressed: () => _showAddSheet(context, petId),
      backgroundColor: c.brand,
      foregroundColor: c.onBrand,
      elevation: 4,
      shape: const CircleBorder(),
      child: const Icon(Icons.add, size: 26),
    );
  }
}

/// Hoja de acciones para registrar información clínica de la mascota.
void _showAddSheet(BuildContext context, String petId) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheet) => SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AddSheetItem(
            icon: Icons.monitor_weight_outlined,
            label: 'Registrar peso',
            onTap: () => WeightFormScreen.open(context, petId),
          ),
          _AddSheetItem(
            icon: Icons.vaccines_outlined,
            label: 'Registrar vacuna',
            onTap: () => VaccineFormScreen.open(context, petId),
          ),
          _AddSheetItem(
            icon: Icons.medical_services_outlined,
            label: 'Agregar visita médica',
            onTap: () => MedicalVisitFormScreen.open(context, petId),
          ),
          _AddSheetItem(
            icon: Icons.coronavirus_outlined,
            label: 'Agregar diagnóstico',
            onTap: () => DiagnosisFormScreen.open(context, petId),
          ),
        ],
      ),
    ),
  );
}

class _AddSheetItem extends StatelessWidget {
  const _AddSheetItem(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ListTile(
      leading: Icon(icon, color: c.brand),
      title: Text(label, style: AppText.body(c.text)),
      onTap: () {
        Navigator.of(context).pop();
        onTap();
      },
    );
  }
}

class _SmallPillButton extends StatelessWidget {
  const _SmallPillButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.brandSoft,
      borderRadius: Radii.pillAll,
      child: InkWell(
        borderRadius: Radii.pillAll,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          child: Text(label, style: AppText.metaStrong(c.brand)),
        ),
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  _TabBarDelegate(this.tabBar, this.background);
  final TabBar tabBar;
  final Color background;

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: background, child: tabBar);
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) =>
      oldDelegate.background != background;
}

/// Genera y comparte el reporte veterinario en PDF (RF-38/39). Es una función
/// Pro: en plan Free abre el paywall. En web el PDF se descarga; en móvil se
/// guarda como archivo (pendiente de validación en dispositivo).
Future<void> _shareReport(
    BuildContext context, WidgetRef ref, String petId) async {
  final isPro = ref.read(entitlementProvider).isPro;
  if (!isPro) {
    PlansScreen.open(context, blockedFeature: 'Reporte para el veterinario (PDF)');
    return;
  }
  final options = await _pickReportScope(context);
  if (options == null || !context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..clearSnackBars()
    ..showSnackBar(const SnackBar(content: Text('Generando reporte PDF…')));
  final result =
      await ref.read(petReportServiceProvider).generate(petId, options: options);
  messenger
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(result.message)));
}

/// Selector de alcance del reporte (RF-38): completo, solo vacunas o rango.
Future<ReportOptions?> _pickReportScope(BuildContext context) async {
  final choice = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Historial completo'),
            onTap: () => Navigator.of(sheetContext).pop('full'),
          ),
          ListTile(
            leading: const Icon(Icons.vaccines_outlined),
            title: const Text('Solo vacunas'),
            onTap: () => Navigator.of(sheetContext).pop('vac'),
          ),
          ListTile(
            leading: const Icon(Icons.date_range_outlined),
            title: const Text('Rango de fechas'),
            onTap: () => Navigator.of(sheetContext).pop('range'),
          ),
        ],
      ),
    ),
  );
  switch (choice) {
    case 'full':
      return ReportOptions.full;
    case 'vac':
      return const ReportOptions(onlyVaccines: true);
    case 'range':
      if (!context.mounted) return null;
      final now = DateTime.now();
      final range = await showDateRangePicker(
        context: context,
        firstDate: DateTime(now.year - 20),
        lastDate: now,
        initialDateRange: DateTimeRange(
          start: DateTime(now.year, now.month, now.day)
              .subtract(const Duration(days: 180)),
          end: now,
        ),
      );
      if (range == null) return null;
      return ReportOptions(
        from: DateTime(range.start.year, range.start.month, range.start.day),
        to: DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59),
      );
    default:
      return null;
  }
}
