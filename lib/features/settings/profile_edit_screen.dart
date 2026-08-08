import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
      ..showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!.profileUpdated)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (!_initialized) {
      _name.text = ref.read(databaseProvider).ownerName;
      _initialized = true;
    }

    return ModalFormScaffold(
      title: l10n.profileEditTitle,
      saveLabel: l10n.commonSave,
      onSave: _valid ? _save : null,
      children: [
        FieldLabel(l10n.profileYourName),
        AppTextField(
          controller: _name,
          hint: l10n.profileYourNameHint,
          maxLength: FormLimits.name,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        InfoNote(
          l10n.profileNote,
          icon: Icons.person_outline,
        ),
      ],
    );
  }
}
