import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
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

  static double _toKg(double v, WeightUnit u) =>
      u == WeightUnit.lb ? v * 0.453592 : v;

  /// Aviso informativo (no diagnóstico) ante una variación >10% (RF-23).
  String? _variationNotice(double newValue) {
    final previous = ref
        .read(clinicalRepositoryProvider)
        .weightsForPet(widget.petId)
        .where((w) => w.value > 0 && w.id != widget.recordId)
        .toList();
    if (previous.isEmpty) return null;
    final prev = previous.last; // ordenado ascendente por fecha
    final prevKg = _toKg(prev.value, prev.unit);
    final newKg = _toKg(newValue, _unit);
    if (prevKg <= 0) return null;
    final delta = (newKg - prevKg) / prevKg;
    if (delta.abs() < 0.10) return null;
    final pct = (delta.abs() * 100).round();
    final dir = delta > 0 ? 'subió' : 'bajó';
    return 'El peso $dir ~$pct% respecto al registro anterior. '
        'Es un aviso informativo, no un diagnóstico.';
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
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
          content: Text(notice ?? (_isEdit ? 'Peso actualizado' : 'Peso registrado'))));
  }

  void _delete() {
    ref.read(clinicalRepositoryProvider).deleteWeight(widget.recordId!);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(content: Text('Registro de peso eliminado')));
  }

  @override
  Widget build(BuildContext context) {
    final pet = ref.watch(petByIdProvider(widget.petId));
    if (!_initialized && pet != null) {
      _unit = pet.weightUnit;
      _initialized = true;
    }

    return ModalFormScaffold(
      title: _isEdit ? 'Editar peso' : 'Registrar peso',
      saveLabel: _isEdit ? 'Guardar cambios' : 'Guardar',
      onSave: _valid ? _save : null,
      header: pet == null
          ? null
          : PetFormHeader(emoji: pet.species.emoji, name: pet.name),
      children: [
        const FieldLabel('Peso'),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: _value,
                hint: 'valor',
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
        const FieldLabel('Fecha'),
        AppDateField(value: _date, onChanged: (d) => setState(() => _date = d)),
        const SizedBox(height: 16),
        const FieldLabel('Nota (opcional)'),
        AppMultilineField(controller: _note, hint: 'Añade una nota…', minLines: 2),
        const SizedBox(height: 18),
        const InfoNote(
          'Ante un cambio de peso notable, te lo señalamos como aviso informativo, no diagnóstico.',
        ),
        if (_isEdit) RecordDeleteButton(label: 'Eliminar registro', onDelete: _delete),
      ],
    );
  }
}
