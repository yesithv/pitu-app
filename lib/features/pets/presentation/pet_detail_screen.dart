import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/app_dates.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/care_icons.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/status_pill.dart';
import '../../attachments/application/attachment_service.dart';
import '../../attachments/application/attachments_providers.dart';
import '../../attachments/domain/entities/attachment.dart';
import '../../care/domain/entities/care_kind.dart';
import '../../care/presentation/care_providers.dart';
import '../../care/presentation/care_schedule_form_screen.dart';
import '../../plan/domain/plan.dart';
import '../../plan/presentation/plans_screen.dart';
import '../../reports/application/reports_providers.dart';
import '../../clinical/domain/entities/diagnosis.dart';
import '../../clinical/domain/entities/timeline_entry.dart';
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

class _PetHeader extends StatelessWidget {
  const _PetHeader({required this.pet});
  final Pet pet;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      child: Column(
        children: [
          PetAvatar(emoji: pet.species.emoji, size: 96),
          const SizedBox(height: 12),
          Text(pet.name, style: AppText.display(c.text)),
          const SizedBox(height: 2),
          Text(pet.subtitle, style: AppText.body(c.text2)),
        ],
      ),
    );
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
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
              onChangeStatus: () => _pickDiagnosisStatus(context, ref, d),
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
Future<void> _pickDiagnosisStatus(
    BuildContext context, WidgetRef ref, Diagnosis diagnosis) {
  final c = context.colors;
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
            child: Text('Estado de "${diagnosis.condition}"',
                style: AppText.title2(c.text)),
          ),
          for (final s in DiagnosisStatus.values)
            ListTile(
              leading: _DxTag(status: s),
              trailing: s == diagnosis.status
                  ? Icon(Icons.check, color: c.brand)
                  : null,
              onTap: () {
                ref
                    .read(clinicalRepositoryProvider)
                    .updateDiagnosisStatus(diagnosis.id, s);
                Navigator.of(sheetContext).pop();
              },
            ),
        ],
      ),
    ),
  );
}

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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
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

class _HistoryTab extends ConsumerWidget {
  const _HistoryTab({required this.petId});
  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    ref.watch(databaseProvider);
    final entries = ref.read(clinicalRepositoryProvider).timelineForPet(petId);
    if (entries.isEmpty) {
      return Center(
        child: Text('Aún no hay registros en el historial.',
            style: AppText.body(c.text3)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      itemCount: entries.length,
      itemBuilder: (context, i) => _TimelineTile(
        entry: entries[i],
        isLast: i == entries.length - 1,
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.entry, required this.isLast});
  final TimelineEntry entry;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.title, style: AppText.bodyStrong(c.text)),
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

class _DocsTab extends ConsumerWidget {
  const _DocsTab({required this.petId});
  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final docs = ref.watch(attachmentsForPetProvider(petId));
    final limits = ref.watch(entitlementProvider).limits;
    final max = limits.maxAttachmentsPerPet;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
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
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              max == null
                  ? '${docs.length} documento(s)'
                  : '${docs.length} de $max documento(s) · plan Free',
              style: AppText.meta(c.text3),
            ),
          ),
          for (final a in docs) ...[
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
                Text('${_kindLabel(attachment.kind)} · ${_size(attachment.sizeBytes)}',
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

  static String _size(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
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
          case 'archive':
            ArchivePetScreen.open(context, petId);
          case 'weight':
            WeightFormScreen.open(context, petId);
          case 'visit':
            MedicalVisitFormScreen.open(context, petId);
          case 'vaccine':
            VaccineFormScreen.open(context, petId);
          case 'share':
            _shareReport(context, ref, petId);
          case 'edit':
            PetFormScreen.openEdit(context, petId);
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'visit', child: Text('Agregar visita médica')),
        PopupMenuItem(value: 'vaccine', child: Text('Registrar vacuna')),
        PopupMenuItem(value: 'weight', child: Text('Registrar peso')),
        PopupMenuItem(value: 'edit', child: Text('Editar')),
        PopupMenuItem(value: 'share', child: Text('Compartir con veterinario')),
        PopupMenuItem(value: 'archive', child: Text('Archivar')),
      ],
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
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..clearSnackBars()
    ..showSnackBar(const SnackBar(content: Text('Generando reporte PDF…')));
  final result = await ref.read(petReportServiceProvider).generate(petId);
  messenger
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(result.message)));
}
