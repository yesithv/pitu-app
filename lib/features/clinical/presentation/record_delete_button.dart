import 'package:flutter/material.dart';

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
                content: const Text(
                    'Se eliminará este registro. Esta acción no se puede deshacer.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.of(d).pop(false),
                      child: const Text('Cancelar')),
                  TextButton(
                      onPressed: () => Navigator.of(d).pop(true),
                      child: const Text('Eliminar')),
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
