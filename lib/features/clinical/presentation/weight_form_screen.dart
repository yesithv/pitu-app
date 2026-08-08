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
import '../../pets/domain/entities/pet.dart';
import '../../pets/presentation/pets_providers.dart';
import '../domain/entities/weight_record.dart';
import '../domain/services/weight_analysis.dart';
import 'record_delete_button.dart';

/// Registrar peso (RF-22) y editarlo/eliminarlo una vez insertado.
class WeightFormScreen extends ConsumerStatefulWidget {
  const WeightFormScreen({super.key, required this.petId, this.recordId});
  final String petId;
  final String? recordId;

  static Future<void> open(BuildContext context, String petId) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => WeightFormScreen(petId: petId)),
    );
  }

  static Future<void> openEdit(
      BuildContext context, String petId, String recordId) {
    return Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => WeightFormScreen(petId: petId, recordId: recordId)),
    );
  }

  @override
  ConsumerState<WeightFormScreen> createState() => _WeightFormScreenState();
}

class _WeightFormScreenState extends ConsumerState<WeightFormScreen> {
  final _value = TextEditingController();
  DateTime _date = DateTime.now();
  WeightUnit _unit = WeightUnit.kg;
  final _note = TextEditingController();
  bool _initialized = false;
  WeightRecord? _existing;

  bool get _isEdit => widget.recordId != null;

  @override
  void initState() {
    super.initState();
    if (widget.recordId != null) {
      final rec = ref
          .read(clinicalRepositoryProvider)
          .weightsForPet(widget.petId)
          .firstWhereOrNull((w) => w.id == widget.recordId);
      if (rec != null) {
        _existing = rec;
        _initialized = true;
        _unit = rec.unit;
        _date = rec.date;
        _note.text = rec.note ?? '';
        _value.text = rec.value == rec.value.roundToDouble()
            ? rec.value.toInt().toString()
            : rec.value.toString();
      }
    }
  }

  @override
  void dispose() {
    _value.dispose();
    _note.dispose();
    super.dispose();
  }

  double? get _parsed => double.tryParse(_value.text.replaceAll(',', '.'));
  bool get _valid =>
      _parsed != null && _parsed! > 0 && _parsed! <= FormLimits.maxWeight;

  /// Aviso informativo (no diagnóstico) ante una variación >10% (RF-23). La
  /// decisión numérica vive en `weightVariation` (dominio, con pruebas); aquí
  /// solo se arma el texto localizado.
  String? _variationNotice(double newValue) {
    final previous = ref
        .read(clinicalRepositoryProvider)
        .weightsForPet(widget.petId)
        .where((w) => w.value > 0 && w.id != widget.recordId)
        .toList();
    if (previous.isEmpty) return null;
    final prev = previous.last; // ordenado ascendente por fecha
    final variation = weightVariation(
      previousValue: prev.value,
      previousUnit: prev.unit,
      newValue: newValue,
      newUnit: _unit,
    );
    if (variation == null) return null;
    final l10n = AppLocalizations.of(context)!;
    final dir = variation.trend == WeightTrend.up
        ? l10n.weightDirectionUp
        : l10n.weightDirectionDown;
    return l10n.weightVariationNotice(dir, variation.percent);
  }

  void _save() {
    final now = ref.read(clockProvider).now();
    final notice = _variationNotice(_parsed!);
    final repo = ref.read(clinicalRepositoryProvider);
    final note = _note.text.trim().isEmpty ? null : _note.text.trim();

    if (_isEdit && _existing != null) {
      repo.updateWeight(WeightRecord(
        meta: _existing!.meta.touched(now),
        petId: _existing!.petId,
        value: _parsed!,
        unit: _unit,
        date: _date,
        note: note,
      ));
    } else {
      repo.addWeight(WeightRecord(
        meta: SyncMetadata.create(id: ref.read(idGeneratorProvider).newId(), now: now),
        petId: widget.petId,
        value: _parsed!,
        unit: _unit,
        date: _date,
        note: note,
      ));
    }
    final l10n = AppLocalizations.of(context)!;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
          content: Text(notice ?? (_isEdit ? l10n.weightUpdated : l10n.weightSaved))));
  }

  void _delete() {
    final l10n = AppLocalizations.of(context)!;
    ref.read(clinicalRepositoryProvider).deleteWeight(widget.recordId!);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(l10n.weightDeleted)));
  }

  @override
  Widget build(BuildContext context) {
    final pet = ref.watch(petByIdProvider(widget.petId));
    if (!_initialized && pet != null) {
      _unit = pet.weightUnit;
      _initialized = true;
    }

    final l10n = AppLocalizations.of(context)!;
    return ModalFormScaffold(
      title: _isEdit ? l10n.weightFormEditTitle : l10n.weightFormNewTitle,
      saveLabel: _isEdit ? l10n.commonSaveChanges : l10n.commonSave,
      onSave: _valid ? _save : null,
      header: pet == null
          ? null
          : PetFormHeader(emoji: pet.species.emoji, name: pet.name),
      children: [
        FieldLabel(l10n.weightFormLabel),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: _value,
                hint: l10n.weightFormValueHint,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textCapitalization: TextCapitalization.none,
                inputFormatters: FormLimits.weight,
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 10),
            WeightUnitToggle(
              unit: _unit,
              onChanged: (u) => setState(() => _unit = u),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FieldLabel(l10n.weightFormDate),
        AppDateField(value: _date, onChanged: (d) => setState(() => _date = d)),
        const SizedBox(height: 16),
        FieldLabel(l10n.weightFormNote),
        AppMultilineField(controller: _note, hint: l10n.commonAddNotePlaceholder, minLines: 2),
        const SizedBox(height: 18),
        InfoNote(l10n.weightFormInfo),
        if (_isEdit) RecordDeleteButton(label: l10n.weightFormDelete, onDelete: _delete),
      ],
    );
  }
}
