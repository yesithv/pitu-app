import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/i18n/l10n_labels.dart';
import '../../../core/domain/sync_metadata.dart';
import '../../../core/utils/form_limits.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/form_fields.dart';
import '../../../core/widgets/modal_form_scaffold.dart';
import '../../pets/presentation/pets_providers.dart';
import '../domain/entities/diagnosis.dart';
import '../domain/entities/medical_visit.dart';
import '../../attachments/presentation/attachment_add_button.dart';
import 'record_delete_button.dart';

/// Registrar visita médica (RF-18) con diagnóstico opcional (RF-20); editable y
/// eliminable una vez insertada.
class MedicalVisitFormScreen extends ConsumerStatefulWidget {
  const MedicalVisitFormScreen({super.key, required this.petId, this.recordId});
  final String petId;
  final String? recordId;

  static Future<void> open(BuildContext context, String petId) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MedicalVisitFormScreen(petId: petId)),
    );
  }

  static Future<void> openEdit(
      BuildContext context, String petId, String recordId) {
    return Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) =>
              MedicalVisitFormScreen(petId: petId, recordId: recordId)),
    );
  }

  @override
  ConsumerState<MedicalVisitFormScreen> createState() =>
      _MedicalVisitFormScreenState();
}

class _MedicalVisitFormScreenState
    extends ConsumerState<MedicalVisitFormScreen> {
  DateTime _date = DateTime.now();
  final _clinic = TextEditingController();
  final _reason = TextEditingController();
  final _diagnosis = TextEditingController();
  final _treatment = TextEditingController();
  final _notes = TextEditingController();
  DiagnosisStatus _dxStatus = DiagnosisStatus.active;
  MedicalVisit? _existing;

  bool get _isEdit => widget.recordId != null;

  @override
  void initState() {
    super.initState();
    if (widget.recordId != null) {
      final rec = ref
          .read(clinicalRepositoryProvider)
          .visitsForPet(widget.petId)
          .firstWhereOrNull((v) => v.id == widget.recordId);
      if (rec != null) {
        _existing = rec;
        _date = rec.date;
        _clinic.text = rec.clinic ?? '';
        _reason.text = rec.reason ?? '';
        _diagnosis.text = rec.diagnosis ?? '';
        _treatment.text = rec.treatment ?? '';
        _notes.text = rec.notes ?? '';
      }
    }
  }

  @override
  void dispose() {
    _clinic.dispose();
    _reason.dispose();
    _diagnosis.dispose();
    _treatment.dispose();
    _notes.dispose();
    super.dispose();
  }

  bool get _valid =>
      _reason.text.trim().isNotEmpty || _diagnosis.text.trim().isNotEmpty;

  void _save() {
    final now = ref.read(clockProvider).now();
    final ids = ref.read(idGeneratorProvider);
    final repo = ref.read(clinicalRepositoryProvider);
    final dx = _diagnosis.text.trim();

    if (_isEdit && _existing != null) {
      repo.updateVisit(MedicalVisit(
        meta: _existing!.meta.touched(now),
        petId: _existing!.petId,
        date: _date,
        clinic: _clean(_clinic),
        reason: _clean(_reason),
        diagnosis: dx.isEmpty ? null : dx,
        treatment: _clean(_treatment),
        notes: _clean(_notes),
        attachments: _existing!.attachments,
      ));
    } else {
      final visitId = ids.newId();
      repo.addVisit(MedicalVisit(
        meta: SyncMetadata(id: visitId, createdAt: now, updatedAt: now),
        petId: widget.petId,
        date: _date,
        clinic: _clean(_clinic),
        reason: _clean(_reason),
        diagnosis: dx.isEmpty ? null : dx,
        treatment: _clean(_treatment),
        notes: _clean(_notes),
      ));
      if (dx.isNotEmpty) {
        repo.addDiagnosis(Diagnosis(
          meta: SyncMetadata.create(id: ids.newId(), now: now),
          petId: widget.petId,
          condition: dx,
          date: _date,
          status: _dxStatus,
          visitId: visitId,
        ));
      }
    }

    final l10n = AppLocalizations.of(context)!;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
          content: Text(_isEdit ? l10n.visitUpdated : l10n.visitSaved)));
  }

  void _delete() {
    final l10n = AppLocalizations.of(context)!;
    ref.read(clinicalRepositoryProvider).deleteVisit(widget.recordId!);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(l10n.visitDeleted)));
  }

  String? _clean(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  @override
  Widget build(BuildContext context) {
    final pet = ref.watch(petByIdProvider(widget.petId));

    final l10n = AppLocalizations.of(context)!;
    return ModalFormScaffold(
      title: _isEdit ? l10n.visitFormEditTitle : l10n.visitFormNewTitle,
      saveLabel: _isEdit ? l10n.commonSaveChanges : l10n.visitFormSave,
      onSave: _valid ? _save : null,
      header: pet == null
          ? null
          : PetFormHeader(emoji: pet.species.emoji, name: pet.name),
      children: [
        FieldLabel(l10n.visitFormDate),
        AppDateField(value: _date, onChanged: (d) => setState(() => _date = d)),
        const SizedBox(height: 16),
        FieldLabel(l10n.visitFormClinic),
        AppTextField(
            controller: _clinic,
            hint: l10n.visitFormClinicHint,
            maxLength: FormLimits.shortText),
        const SizedBox(height: 16),
        FieldLabel(l10n.visitFormReason),
        AppTextField(
          controller: _reason,
          hint: l10n.visitFormReasonHint,
          maxLength: FormLimits.shortText,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        FieldLabel(l10n.visitFormDiagnosis),
        AppTextField(
          controller: _diagnosis,
          hint: l10n.visitFormDiagnosisHint,
          maxLength: FormLimits.shortText,
          onChanged: (_) => setState(() {}),
        ),
        if (!_isEdit && _diagnosis.text.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              for (final s in const [
                DiagnosisStatus.active,
                DiagnosisStatus.treatment,
                DiagnosisStatus.chronic,
              ])
                _DxChip(
                  status: s,
                  selected: _dxStatus == s,
                  onTap: () => setState(() => _dxStatus = s),
                ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        FieldLabel(l10n.visitFormTreatment),
        AppMultilineField(controller: _treatment, hint: l10n.visitFormTreatmentHint, minLines: 2),
        const SizedBox(height: 16),
        FieldLabel(l10n.visitFormNotes),
        AppMultilineField(controller: _notes, hint: l10n.commonAddNotePlaceholder, minLines: 2),
        const SizedBox(height: 16),
        FieldLabel(l10n.visitFormDocs),
        const SizedBox(height: 4),
        AttachmentAddButton(petId: widget.petId, source: l10n.attachmentSourceVisit),
        if (_isEdit) RecordDeleteButton(label: l10n.visitFormDelete, onDelete: _delete),
      ],
    );
  }
}

class _DxChip extends StatelessWidget {
  const _DxChip({required this.status, required this.selected, required this.onTap});
  final DiagnosisStatus status;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? c.dxActive : Colors.transparent,
          borderRadius: Radii.pillAll,
          border: selected ? null : Border.all(color: c.borderStrong),
        ),
        child: Text(status.localized(AppLocalizations.of(context)!),
            style: AppText.metaStrong(selected ? Colors.white : c.text2)),
      ),
    );
  }
}
