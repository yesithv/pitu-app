import 'package:flutter/material.dart';

import '../../features/pets/domain/entities/pet.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text.dart';

/// Encabezado de sección (Título 2), separación superior 22 / inferior 10.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.text, {super.key, this.color});
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 10),
      child: Text(text, style: AppText.title2(color ?? context.colors.text)),
    );
  }
}

/// Encabezado de grupo en mayúsculas (Ajustes).
class GroupHeader extends StatelessWidget {
  const GroupHeader(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: AppText.label(context.colors.text3),
      ),
    );
  }
}

/// Nota informativa: fondo `alt`, borde izquierdo de marca (identidad §9).
class InfoNote extends StatelessWidget {
  const InfoNote(this.text, {super.key, this.icon = Icons.info_outline, this.accent});
  final String text;
  final IconData icon;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final a = accent ?? c.brand;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: c.alt,
        borderRadius: Radii.fieldAll,
        border: Border(left: BorderSide(color: a, width: 3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: a),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: AppText.meta(c.text2))),
        ],
      ),
    );
  }
}

/// Avatar circular de mascota (emoji sobre `brand/soft`).
class PetAvatar extends StatelessWidget {
  const PetAvatar({super.key, required this.emoji, this.size = 60, this.dashed = true});
  final String emoji;
  final double size;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.brandSoft,
        shape: BoxShape.circle,
        border: dashed
            ? Border.all(color: c.brand.withOpacity(0.30))
            : null,
      ),
      child: Text(emoji, style: TextStyle(fontSize: size * 0.46)),
    );
  }
}

/// Etiqueta pequeña de plan de pago ("PRO"), acento cálido (identidad §9.1).
class ProBadge extends StatelessWidget {
  const ProBadge({super.key, this.label = 'Pro'});
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.accent.withOpacity(0.22),
        borderRadius: Radii.pillAll,
      ),
      child: Text(label.toUpperCase(), style: AppText.label(c.accentInk)),
    );
  }
}

/// Campo de solo lectura con estilo de formulario (para pantallas de detalle).
class ReadonlyField extends StatelessWidget {
  const ReadonlyField({
    super.key,
    required this.value,
    this.trailing,
    this.placeholder = false,
  });
  final String value;
  final IconData? trailing;
  final bool placeholder;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: c.alt,
        borderRadius: Radii.fieldAll,
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value,
              style: AppText.body(placeholder ? c.text3 : c.text),
            ),
          ),
          if (trailing != null) Icon(trailing, size: 18, color: c.text3),
        ],
      ),
    );
  }
}

/// Etiqueta de campo de formulario.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: AppText.metaStrong(context.colors.text2)),
    );
  }
}
