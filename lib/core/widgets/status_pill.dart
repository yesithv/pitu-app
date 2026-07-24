import 'package:flutter/material.dart';

import '../../features/care/domain/entities/compliance.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text.dart';

/// Estilo semántico de un estado de cumplimiento (color, fondo suave, ícono).
class ComplianceStyle {
  const ComplianceStyle(this.color, this.soft, this.icon);
  final Color color;
  final Color soft;
  final IconData icon;
}

ComplianceStyle complianceStyle(BuildContext context, ComplianceStatus status) {
  final c = context.colors;
  return switch (status) {
    ComplianceStatus.ok => ComplianceStyle(c.ok, c.okSoft, Icons.check_circle_outline),
    ComplianceStatus.due => ComplianceStyle(c.due, c.dueSoft, Icons.schedule),
    ComplianceStatus.overdue =>
      ComplianceStyle(c.over, c.overSoft, Icons.error_outline),
  };
}

/// Chip de estado: SIEMPRE color + ícono + texto, nunca solo color
/// (accesibilidad, identidad §10).
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.status,
    required this.label,
  });

  final ComplianceStatus status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final s = complianceStyle(context, status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(color: s.soft, borderRadius: Radii.pillAll),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(s.icon, size: 14, color: s.color),
          const SizedBox(width: 5),
          Text(label, style: AppText.metaStrong(s.color)),
        ],
      ),
    );
  }
}
