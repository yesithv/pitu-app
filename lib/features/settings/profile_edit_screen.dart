import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../core/utils/form_limits.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/form_fields.dart';
import '../../core/widgets/modal_form_scaffold.dart';

/// Edición del perfil local (RF-01). En la Fase 1 solo guarda el nombre del
/// tutor, que personaliza el saludo; vive en este dispositivo.
class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
    );
  }

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _name = TextEditingController();
  bool _initialized = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _valid => _name.text.trim().isNotEmpty;

  void _save() {
    final db = ref.read(databaseProvider);
    db.ownerName = _name.text.trim();
    db.bump();
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(content: Text('Perfil actualizado')));
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      _name.text = ref.read(databaseProvider).ownerName;
      _initialized = true;
    }

    return ModalFormScaffold(
      title: 'Editar perfil',
      saveLabel: 'Guardar',
      onSave: _valid ? _save : null,
      children: [
        const FieldLabel('Tu nombre'),
        AppTextField(
          controller: _name,
          hint: 'Cómo te llamas',
          maxLength: FormLimits.name,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        const InfoNote(
          'Es solo local y aparece en tu saludo. Se guarda en este dispositivo.',
          icon: Icons.person_outline,
        ),
      ],
    );
  }
}
