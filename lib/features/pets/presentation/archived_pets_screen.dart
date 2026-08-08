import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/i18n/l10n_labels.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/common.dart';
import '../domain/entities/pet.dart';
import 'pet_detail_screen.dart';
import 'pets_providers.dart';

/// Lista de mascotas archivadas (RF-07), en modo lectura, con acciones de
/// desarchivar (RF-05) y eliminar definitivamente (RF-06).
class ArchivedPetsScreen extends ConsumerWidget {
  const ArchivedPetsScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ArchivedPetsScreen()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final archived = ref.watch(archivedPetsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.archivedTitle)),
      body: SafeArea(
        top: false,
        child: archived.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(l10n.archivedEmpty,
                      style: AppText.body(c.text3)),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(Gap.screenH, 12, Gap.screenH, 40),
                children: [
                  for (final pet in archived) ...[
                    _ArchivedRow(pet: pet),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
      ),
    );
  }
}

class _ArchivedRow extends ConsumerWidget {
  const _ArchivedRow({required this.pet});
  final Pet pet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      onTap: () => PetDetailScreen.open(context, pet.id),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          PetAvatar(
              emoji: pet.species.emoji, photoBase64: pet.photoBase64, size: 52),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pet.name, style: AppText.title2(c.text)),
                Text(
                  [
                    petShortSubtitle(l10n, pet),
                    if (pet.archiveReason != null)
                      pet.archiveReason!.localized(l10n),
                  ].join(' · '),
                  style: AppText.meta(c.text3),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: c.text3),
            onSelected: (v) {
              if (v == 'unarchive') _unarchive(context, ref);
              if (v == 'delete') _confirmDelete(context, ref);
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'unarchive', child: Text(l10n.petMenuUnarchive)),
              PopupMenuItem(value: 'delete', child: Text(l10n.petMenuDeleteForever)),
            ],
          ),
        ],
      ),
    );
  }

  void _unarchive(BuildContext context, WidgetRef ref) {
    ref.read(petRepositoryProvider).unarchive(pet.id);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
          content: Text(
              AppLocalizations.of(context)!.archivedReactivated(pet.name))));
  }

  /// Doble confirmación (RF-06): acción destructiva, sin oferta comercial (RN-11).
  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final first = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(l10n.archivedDeleteTitle),
        content: Text(l10n.archivedDeleteMessage(pet.name)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(d).pop(false),
              child: Text(l10n.commonCancel)),
          TextButton(
              onPressed: () => Navigator.of(d).pop(true),
              child: Text(l10n.commonContinue)),
        ],
      ),
    );
    if (first != true || !context.mounted) return;

    final second = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(l10n.archivedDeleteConfirmTitle(pet.name)),
        content: Text(l10n.archivedDeleteConfirmMessage),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(d).pop(false),
              child: Text(l10n.commonCancel)),
          TextButton(
              onPressed: () => Navigator.of(d).pop(true),
              child: Text(l10n.commonDelete)),
        ],
      ),
    );
    if (second != true) return;

    ref.read(petRepositoryProvider).softDelete(pet.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(l10n.archivedDeleted)));
    }
  }
}
