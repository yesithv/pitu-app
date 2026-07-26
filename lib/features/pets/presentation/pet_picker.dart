import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/common.dart';
import 'pets_providers.dart';

/// Devuelve el id de la mascota elegida. Si solo hay una activa, la usa
/// directamente; si hay varias, muestra un selector; si no hay ninguna, avisa.
Future<String?> pickPetId(BuildContext context, WidgetRef ref) async {
  final pets = ref.read(petViewsProvider);
  if (pets.isEmpty) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(content: Text('Primero agrega una mascota')));
    return null;
  }
  if (pets.length == 1) return pets.first.pet.id;

  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      final c = sheetContext.colors;
      return SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
              child: Text('¿Para cuál mascota?', style: AppText.title2(c.text)),
            ),
            for (final pv in pets)
              ListTile(
                leading: PetAvatar(emoji: pv.pet.species.emoji, photoBase64: pv.pet.photoBase64, size: 40),
                title: Text(pv.pet.name,
                    style: AppText.cardTitle(c.text).copyWith(fontSize: 16)),
                subtitle: Text(pv.pet.shortSubtitle, style: AppText.meta(c.text3)),
                trailing: Icon(Icons.chevron_right, color: c.text3),
                onTap: () => Navigator.of(sheetContext).pop(pv.pet.id),
              ),
            const SizedBox(height: Gap.sm),
          ],
        ),
      );
    },
  );
}
