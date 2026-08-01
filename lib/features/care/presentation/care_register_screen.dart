import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/form_fields.dart';
import '../../../core/widgets/modal_form_scaffold.dart';
import '../../attachments/presentation/attachment_add_button.dart';

/// Registro detallado de un cuidado (RF-15): fecha (no futura), notas y, al
/// guardar, recálculo automático de la próxima fecha. El registro rápido de un
/// toque sigue disponible desde la tarjeta.
class CareRegisterScreen extends ConsumerStatefulWidget {
  const CareRegisterScreen({
    super.key,
    required this.scheduleId,
    required this.petId,
    required this.careName,
    required this.petName,
    required this.petEmoji,
  });

  final String scheduleId;
  final String petId;
  final String careName;
  final String petName;
  final String petEmoji;

  static Future<void> open(
    BuildContext context, {
    required String scheduleId,
    required String petId,
    required String careName,
    required String petName,
    required String petEmoji,
  }) {
    return Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CareRegisterScreen(
        scheduleId: scheduleId,
        petId: petId,
        careName: careName,
        petName: petName,
        petEmoji: petEmoji,
      ),
    ));
  }

  @override
  ConsumerState<CareRegisterScreen> createState() => _CareRegisterScreenState();
}

class _CareRegisterScreenState extends ConsumerState<CareRegisterScreen> {
  DateTime _date = DateTime.now();
  final _notes = TextEditingController();

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  void _save() {
    final repo = ref.read(careRepositoryProvider);
    final execution = repo.markDone(
      widget.scheduleId,
      date: _date,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    );
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('${widget.careName} registrado'),
        action: SnackBarAction(
          label: 'Deshacer',
          onPressed: () => repo.undo(execution.id),
        ),
      ));
  }

  @override
  Widget build(BuildContext context) {
    return ModalFormScaffold(
      title: 'Registrar cuidado',
      saveLabel: 'Guardar',
      onSave: _save,
      header: PetFormHeader(
        emoji: widget.petEmoji,
        name: '${widget.careName} · ${widget.petName}',
      ),
      children: [
        const FieldLabel('Fecha'),
        AppDateField(value: _date, onChanged: (d) => setState(() => _date = d)),
        const SizedBox(height: 16),
        const FieldLabel('Notas (opcional)'),
        AppMultilineField(controller: _notes, hint: 'Añade una nota…'),
        const SizedBox(height: 16),
        const FieldLabel('Documentos (opcional)'),
        AttachmentAddButton(
          petId: widget.petId,
          source: 'Cuidado: ${widget.careName}',
        ),
        const SizedBox(height: 18),
        const InfoNote(
            'Al guardar, calcularemos la próxima fecha automáticamente.'),
      ],
    );
  }
}
