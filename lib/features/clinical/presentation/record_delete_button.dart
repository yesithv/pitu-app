import 'package:flutter/material.dart';
import 'package:pitu_app/l10n/app_localizations.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';

/// Botón de eliminación con confirmación para registros clínicos ya insertados.
class RecordDeleteButton extends StatelessWidget {
  const RecordDeleteButton({
    super.key,
    required this.label,
    required this.onDelete,
  });
  final String label;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Center(
        child: TextButton.icon(
          onPressed: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (d) => AlertDialog(
                title: Text(label),
                content: Text(AppLocalizations.of(context)!.recordDeleteMessage),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.of(d).pop(false),
                      child: Text(AppLocalizations.of(context)!.commonCancel)),
                  TextButton(
                      onPressed: () => Navigator.of(d).pop(true),
                      child: Text(AppLocalizations.of(context)!.commonDelete)),
                ],
              ),
            );
            if (ok == true) onDelete();
          },
          icon: Icon(Icons.delete_outline, size: 18, color: c.over),
          label: Text(label, style: AppText.button(c.over).copyWith(fontSize: 14)),
        ),
      ),
    );
  }
}
