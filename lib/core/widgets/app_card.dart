import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

/// Superficie base de datos: `surface/card`, radio 16, borde suave y sombra
/// en reposo cálida (identidad §5, §9).
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Gap.lg),
    this.onTap,
    this.color,
    this.clip = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final decoration = BoxDecoration(
      color: color ?? c.card,
      borderRadius: Radii.cardAll,
      border: Border.all(color: c.border),
      boxShadow: [
        BoxShadow(color: c.shadowRest, blurRadius: 3, offset: const Offset(0, 1)),
      ],
    );

    Widget content = Padding(padding: padding, child: child);
    if (clip) {
      content = ClipRRect(borderRadius: Radii.cardAll, child: content);
    }

    if (onTap == null) {
      return DecoratedBox(decoration: decoration, child: content);
    }
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: decoration,
        child: InkWell(
          borderRadius: Radii.cardAll,
          onTap: onTap,
          child: content,
        ),
      ),
    );
  }
}
