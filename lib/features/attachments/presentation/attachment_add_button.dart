import 'package:flutter/material.dart';
import 'package:pitu_app/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_buttons.dart';
import '../../plan/application/entitlement_controller.dart';
import '../../plan/presentation/plans_screen.dart';
import '../application/attachment_service.dart';
import '../application/attachments_providers.dart';

/// Botón reutilizable para adjuntar un documento a una mascota, con la etiqueta
/// de origen del registro (RF-26) y control del límite por plan (RN-04).
class AttachmentAddButton extends ConsumerWidget {
  const AttachmentAddButton({
    super.key,
    required this.petId,
    this.source,
    this.label,
  });
  final String petId;
  final String? source;

  /// Etiqueta del botón; si es `null` usa "Adjuntar documento" localizado.
  final String? label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return DashedActionButton(
        label: label ?? l10n.attachmentAdd,
        onPressed: () => _add(context, ref));
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final service = ref.read(attachmentServiceProvider);
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    if (!service.canAdd) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(l10n.attachmentWebOnly)));
      return;
    }
    final max = ref.read(entitlementProvider).limits.maxAttachmentsPerPet;
    final count = ref.read(attachmentRepositoryProvider).countForPet(petId);
    if (max != null && count >= max) {
      PlansScreen.open(context, blockedFeature: l10n.docsBlockedFeature);
      return;
    }
    final result = await service.pickAndAdd(petId,
        source: source ?? l10n.attachmentDefaultSource);
    switch (result.status) {
      case AddAttachmentStatus.success:
        messenger
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(l10n.attachmentAdded)));
      case AddAttachmentStatus.tooLarge:
        messenger
          ..clearSnackBars()
          ..showSnackBar(SnackBar(
              content: Text(l10n.attachmentTooLarge(AttachmentService.maxLabel))));
      case AddAttachmentStatus.quota:
        messenger
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(l10n.attachmentNoSpace)));
      case AddAttachmentStatus.cancelled:
        break;
    }
  }
}
