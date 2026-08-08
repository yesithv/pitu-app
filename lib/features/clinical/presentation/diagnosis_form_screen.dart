import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:pitu_app/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/i18n/l10n_labels.dart';
import '../../../core/domain/sync_metadata.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/form_limits.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/form_fields.dart';
import '../../../core/widgets/modal_form_scaffold.dart';
import '../../pets/presentation/pets_providers.dart';
import '../domain/entities/diagnosis.dart';
import 'record_delete_button.dart';

/// Alta directa de un diagnóstico con estado (RF-20), edición y eliminación.
class DiagnosisFormScreen extends ConsumerStatefulWidget {
  const DiagnosisFormScreen({super.key, required this.petId, this.recordId});
  final String petId;
  final String? recordId;

  static Future<void> open(BuildContext context, String petId) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DiagnosisFormScreen(petId: petId)),
    );
  }

  static Future<void> openEdit(
      BuildContext context, String petId, String recordId) {
    return Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => DiagnosisFormScreen(petId: petId, recordId: recordId)),
    );
  }

  @override
  ConsumerState<DiagnosisFormScreen> createState() =>
      _DiagnosisFormScreenState();
}

class _DiagnosisFormScreenState extends ConsumerState<DiagnosisFormScreen> {
  final _condition = TextEditingController();
  final _notes = TextEditingController();
  DateTime _date = DateTime.now();
  DiagnosisStatus _status = DiagnosisStatus.active;
  Diagnosis? _existing;

  bool get _isEdit => widget.recordId != null;

  @override
  void initState() {
    super.initState();
    if (widget.recordId != null) {
      final rec = ref
          .read(clinicalRepositoryProvider)
          .diagnosesForPet(widget.petId)
          .firstWhereOrNull((d) => d.id == widget.recordId);
      if (rec != null) {
        _existing = rec;
        _condition.text = rec.condition;
        _notes.text = rec.notes ?? '';
        _date = rec.date;
        _status = rec.status;
      }
    }
  }

  @override
  void dispose() {
    _condition.dispose();
    _notes.dispose();
    super.dispose();
  }

  bool get _valid => _condition.text.trim().isNotEmpty;

  void _save() {
    final now = ref.read(clockProvider).now();
    final repo = ref.read(clinicalRepositoryProvider);
    final notes = _notes.text.trim().isEmpty ? null : _notes.text.trim();

    if (_isEdit && _existing != null) {
      repo.updateDiagnosis(Diagnosis(
        meta: _existing!.meta.touched(now),
        petId: _existing!.petId,
        condition: _condition.text.trim(),
        date: _date,
        status: _status,
        visitId: _existing!.visitId,
        notes: notes,
      ));
    } else {
      repo.addDiagnosis(Diagnosis(
        meta: SyncMetadata.create(id: ref.read(idGeneratorProvider).newId(), now: now),
        petId: widget.petId,
        condition: _condition.text.trim(),
        date: _date,
        status: _status,
        notes: notes,
      ));
    }
    final l10n = AppLocalizations.of(context)!;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
          content:
              Text(_isEdit ? l10n.diagnosisUpdated : l10n.diagnosisSaved)));
  }

  void _delete() {
    final l10n = AppLocalizations.of(context)!;
    ref.read(clinicalRepositoryProvider).deleteDiagnosis(widget.recordId!);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(l10n.diagnosisDeleted)));
  }

  @override
  Widget build(BuildContext context) {
    final pet = ref.watch(petByIdProvider(widget.petId));

    final l10n = AppLocalizations.of(context)!;
    return ModalFormScaffold(
      title: _isEdit ? l10n.diagnosisFormEditTitle : l10n.diagnosisFormNewTitle,
      saveLabel: _isEdit ? l10n.commonSaveChanges : l10n.commonSave,
      onSave: _valid ? _save : null,
      header: pet == null
          ? null
          : PetFormHeader(emoji: pet.species.emoji, name: pet.name),
      children: [
        FieldLabel(l10n.diagnosisFormCondition),
        AppTextField(
          controller: _condition,
          hint: l10n.diagnosisFormConditionHint,
          maxLength: FormLimits.shortText,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        FieldLabel(l10n.diagnosisFormStatus),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in DiagnosisStatus.values)
              _DxChip(
                status: s,
                selected: _status == s,
                onTap: () => setState(() => _status = s),
              ),
          ],
        ),
        const SizedBox(height: 16),
        FieldLabel(l10n.diagnosisFormDate),
        AppDateField(value: _date, onChanged: (d) => setState(() => _date = d)),
        const SizedBox(height: 16),
        FieldLabel(l10n.diagnosisFormNotes),
        AppMultilineField(controller: _notes, hint: l10n.commonAddNotePlaceholder, minLines: 2),
        if (_isEdit)
          RecordDeleteButton(label: l10n.diagnosisFormDelete, onDelete: _delete),
      ],
    );
  }
}

class _DxChip extends StatelessWidget {
  const _DxChip(
      {required this.status, required this.selected, required this.onTap});
  final DiagnosisStatus status;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = switch (status) {
      DiagnosisStatus.active => c.dxActive,
      DiagnosisStatus.treatment => c.dxTreat,
      DiagnosisStatus.chronic => c.dxChronic,
      DiagnosisStatus.resolved => c.dxResolved,
    };
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: Radii.pillAll,
          border: selected ? null : Border.all(color: c.borderStrong),
        ),
        child: Text(status.localized(AppLocalizations.of(context)!),
            style: AppText.metaStrong(selected ? Colors.white : c.text2)),
      ),
    );
  }
}
