import 'package:flutter/material.dart';
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
    this.label = 'Adjuntar documento',
  });
  final String petId;
  final String? source;
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DashedActionButton(label: label, onPressed: () => _add(context, ref));
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final service = ref.read(attachmentServiceProvider);
    final messenger = ScaffoldMessenger.of(context);
    if (!service.canAdd) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(
            content: Text(
                'Adjuntar documentos está disponible en la versión web por ahora.')));
      return;
    }
    final max = ref.read(entitlementProvider).limits.maxAttachmentsPerPet;
    final count = ref.read(attachmentRepositoryProvider).countForPet(petId);
    if (max != null && count >= max) {
      PlansScreen.open(context, blockedFeature: 'Documentos ilimitados');
      return;
    }
    final result = await service.pickAndAdd(petId, source: source);
    switch (result.status) {
      case AddAttachmentStatus.success:
        messenger
          ..clearSnackBars()
          ..showSnackBar(const SnackBar(content: Text('Documento adjuntado.')));
      case AddAttachmentStatus.tooLarge:
      case AddAttachmentStatus.quota:
        messenger
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(result.message)));
      case AddAttachmentStatus.cancelled:
        break;
    }
  }
}
