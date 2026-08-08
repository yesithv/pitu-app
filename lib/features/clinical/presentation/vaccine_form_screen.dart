import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:pitu_app/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/domain/sync_metadata.dart';
import '../../../core/utils/form_limits.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/form_fields.dart';
import '../../../core/widgets/modal_form_scaffold.dart';
import '../../pets/presentation/pets_providers.dart';
import '../domain/entities/vaccine.dart';
import '../../attachments/presentation/attachment_add_button.dart';
import 'record_delete_button.dart';

/// Registrar vacuna (RF-19) y editarla/eliminarla una vez insertada.
class VaccineFormScreen extends ConsumerStatefulWidget {
  const VaccineFormScreen({super.key, required this.petId, this.recordId});
  final String petId;
  final String? recordId;

  static Future<void> open(BuildContext context, String petId) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => VaccineFormScreen(petId: petId)),
    );
  }

  static Future<void> openEdit(
      BuildContext context, String petId, String recordId) {
    return Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => VaccineFormScreen(petId: petId, recordId: recordId)),
    );
  }

  @override
  ConsumerState<VaccineFormScreen> createState() => _VaccineFormScreenState();
}

class _VaccineFormScreenState extends ConsumerState<VaccineFormScreen> {
  final _type = TextEditingController();
  final _clinic = TextEditingController();
  DateTime _applied = DateTime.now();
  late DateTime _nextDose;
  bool _nextEditedManually = false;
  Vaccine? _existing;

  bool get _isEdit => widget.recordId != null;

  @override
  void initState() {
    super.initState();
    if (widget.recordId != null) {
      final rec = ref
          .read(clinicalRepositoryProvider)
          .vaccinesForPet(widget.petId)
          .firstWhereOrNull((v) => v.id == widget.recordId);
      if (rec != null) {
        _existing = rec;
        _type.text = rec.type;
        _clinic.text = rec.clinic ?? '';
        _applied = rec.appliedDate;
        _nextDose = rec.nextDoseDate ?? _suggestNext(rec.appliedDate);
        _nextEditedManually = true;
        return;
      }
    }
    _nextDose = _suggestNext(_applied);
  }

  static DateTime _suggestNext(DateTime from) =>
      DateTime(from.year + 1, from.month, from.day);

  @override
  void dispose() {
    _type.dispose();
    _clinic.dispose();
    super.dispose();
  }

  bool get _valid => _type.text.trim().isNotEmpty;

  void _save() {
    final now = ref.read(clockProvider).now();
    final repo = ref.read(clinicalRepositoryProvider);
    final clinic = _clinic.text.trim().isEmpty ? null : _clinic.text.trim();

    if (_isEdit && _existing != null) {
      repo.updateVaccine(Vaccine(
        meta: _existing!.meta.touched(now),
        petId: _existing!.petId,
        type: _type.text.trim(),
        appliedDate: _applied,
        nextDoseDate: _nextDose,
        clinic: clinic,
        attachment: _existing!.attachment,
      ));
    } else {
      repo.addVaccine(Vaccine(
        meta: SyncMetadata.create(id: ref.read(idGeneratorProvider).newId(), now: now),
        petId: widget.petId,
        type: _type.text.trim(),
        appliedDate: _applied,
        nextDoseDate: _nextDose,
        clinic: clinic,
      ));
    }
    final l10n = AppLocalizations.of(context)!;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
          content: Text(_isEdit ? l10n.vaccineUpdated : l10n.vaccineSaved)));
  }

  void _delete() {
    final l10n = AppLocalizations.of(context)!;
    ref.read(clinicalRepositoryProvider).deleteVaccine(widget.recordId!);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(l10n.vaccineDeleted)));
  }

  @override
  Widget build(BuildContext context) {
    final pet = ref.watch(petByIdProvider(widget.petId));

    final l10n = AppLocalizations.of(context)!;
    return ModalFormScaffold(
      title: _isEdit ? l10n.vaccineFormEditTitle : l10n.vaccineFormNewTitle,
      saveLabel: _isEdit ? l10n.commonSaveChanges : l10n.vaccineFormSave,
      onSave: _valid ? _save : null,
      header: pet == null
          ? null
          : PetFormHeader(emoji: pet.species.emoji, name: pet.name),
      children: [
        FieldLabel(l10n.vaccineFormType),
        AppTextField(
          controller: _type,
          hint: l10n.vaccineFormTypeHint,
          maxLength: FormLimits.shortText,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        FieldLabel(l10n.vaccineFormApplied),
        AppDateField(
          value: _applied,
          onChanged: (d) => setState(() {
            _applied = d;
            if (!_nextEditedManually) _nextDose = _suggestNext(d);
          }),
        ),
        const SizedBox(height: 16),
        FieldLabel(l10n.vaccineFormNext),
        AppDateField(
          value: _nextDose,
          allowFuture: true,
          todayLabel: false,
          onChanged: (d) => setState(() {
            _nextDose = d;
            _nextEditedManually = true;
          }),
        ),
        const SizedBox(height: 16),
        FieldLabel(l10n.vaccineFormClinic),
        AppTextField(
            controller: _clinic,
            hint: l10n.vaccineFormClinicHint,
            maxLength: FormLimits.shortText),
        const SizedBox(height: 18),
        InfoNote(l10n.vaccineFormNote),
        const SizedBox(height: 16),
        FieldLabel(l10n.vaccineFormDocs),
        const SizedBox(height: 4),
        AttachmentAddButton(petId: widget.petId, source: l10n.attachmentSourceVaccine),
        if (_isEdit) RecordDeleteButton(label: l10n.vaccineFormDelete, onDelete: _delete),
      ],
    );
  }
}
