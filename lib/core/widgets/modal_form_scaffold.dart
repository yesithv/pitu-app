import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'app_buttons.dart';

/// Estructura común de las pantallas de registro/edición: cabecera con
/// "Cancelar" + título, cuerpo desplazable y barra inferior con el CTA guardar.
class ModalFormScaffold extends StatelessWidget {
  const ModalFormScaffold({
    super.key,
    required this.title,
    required this.children,
    required this.saveLabel,
    required this.onSave,
    this.header,
  });

  final String title;
  final List<Widget> children;
  final String saveLabel;

  /// `null` deshabilita el botón guardar (validación no cumplida).
  final VoidCallback? onSave;

  /// Widget opcional fijo bajo la cabecera (p. ej. la mascota destino).
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: Text('Cancelar', style: AppText.button(c.brand).copyWith(fontSize: 15)),
                  ),
                  Expanded(
                    child: Text(title,
                        textAlign: TextAlign.center,
                        style: AppText.cardTitle(c.text).copyWith(fontSize: 16)),
                  ),
                  const SizedBox(width: 60),
                ],
              ),
            ),
            if (header != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: header!,
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: children,
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
              decoration: BoxDecoration(
                color: c.bg,
                border: Border(top: BorderSide(color: c.border)),
              ),
              child: PrimaryButton(label: saveLabel, onPressed: onSave),
            ),
          ],
        ),
      ),
    );
  }
}

/// Encabezado de mascota destino para los formularios (chip con avatar + nombre).
class PetFormHeader extends StatelessWidget {
  const PetFormHeader({super.key, required this.emoji, required this.name});
  final String emoji;
  final String name;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: c.alt,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: c.brandSoft, shape: BoxShape.circle),
            child: Text(emoji, style: const TextStyle(fontSize: 17)),
          ),
          const SizedBox(width: 12),
          Text(name, style: AppText.cardTitle(c.text).copyWith(fontSize: 15)),
        ],
      ),
    );
  }
}
