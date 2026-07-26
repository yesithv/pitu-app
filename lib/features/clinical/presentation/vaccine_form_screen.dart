import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/domain/sync_metadata.dart';
import '../../../core/utils/form_limits.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/form_fields.dart';
import '../../../core/widgets/modal_form_scaffold.dart';
import '../../pets/presentation/pets_providers.dart';
import '../domain/entities/vaccine.dart';

/// Registrar vacuna (RF-19): tipo, fecha, próxima dosis autosugerida (editable).
class VaccineFormScreen extends ConsumerStatefulWidget {
  const VaccineFormScreen({super.key, required this.petId});
  final String petId;

  static Future<void> open(BuildContext context, String petId) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => VaccineFormScreen(petId: petId)),
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

  @override
  void initState() {
    super.initState();
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
    ref.read(clinicalRepositoryProvider).addVaccine(Vaccine(
          meta: SyncMetadata.create(id: ref.read(idGeneratorProvider).newId(), now: now),
          petId: widget.petId,
          type: _type.text.trim(),
          appliedDate: _applied,
          nextDoseDate: _nextDose,
          clinic: _clinic.text.trim().isEmpty ? null : _clinic.text.trim(),
        ));
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(content: Text('Vacuna registrada')));
  }

  @override
  Widget build(BuildContext context) {
    final pet = ref.watch(petByIdProvider(widget.petId));

    return ModalFormScaffold(
      title: 'Vacuna',
      saveLabel: 'Guardar vacuna',
      onSave: _valid ? _save : null,
      header: pet == null
          ? null
          : PetFormHeader(emoji: pet.species.emoji, name: pet.name),
      children: [
        const FieldLabel('Tipo de vacuna'),
        AppTextField(
          controller: _type,
          hint: 'Ej. Antirrábica',
          maxLength: FormLimits.shortText,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        const FieldLabel('Fecha de aplicación'),
        AppDateField(
          value: _applied,
          onChanged: (d) => setState(() {
            _applied = d;
            if (!_nextEditedManually) _nextDose = _suggestNext(d);
          }),
        ),
        const SizedBox(height: 16),
        const FieldLabel('Próxima dosis (autosugerida)'),
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
        const FieldLabel('Veterinario / clínica (opcional)'),
        AppTextField(controller: _clinic, hint: 'Ej. Clínica Veterinaria del Norte', maxLength: FormLimits.shortText),
        const SizedBox(height: 18),
        const InfoNote(
            'Sugerimos la próxima dosis a un año; ajústala según la indicación del veterinario.'),
      ],
    );
  }
}
