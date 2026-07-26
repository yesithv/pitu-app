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

/// Registrar peso (RF-22). Actualiza la curva de peso al instante.
class WeightFormScreen extends ConsumerStatefulWidget {
  const WeightFormScreen({super.key, required this.petId});
  final String petId;

  static Future<void> open(BuildContext context, String petId) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => WeightFormScreen(petId: petId)),
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
        .where((w) => w.value > 0)
        .toList();
    if (previous.isEmpty) return null;
    final prev = previous.last; // ya viene ordenado ascendente por fecha
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
    ref.read(clinicalRepositoryProvider).addWeight(WeightRecord(
          meta: SyncMetadata.create(id: ref.read(idGeneratorProvider).newId(), now: now),
          petId: widget.petId,
          value: _parsed!,
          unit: _unit,
          date: _date,
          note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        ));
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(notice ?? 'Peso registrado')));
  }

  @override
  Widget build(BuildContext context) {
    final pet = ref.watch(petByIdProvider(widget.petId));
    if (!_initialized && pet != null) {
      _unit = pet.weightUnit;
      _initialized = true;
    }

    return ModalFormScaffold(
      title: 'Registrar peso',
      saveLabel: 'Guardar',
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
      ],
    );
  }
}
