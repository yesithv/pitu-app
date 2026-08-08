import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/i18n/l10n_labels.dart';
import 'schedule_view.dart';

/// Marca un cuidado como realizado y ofrece "Deshacer" (RF-14, RF-16).
/// Operación local-first: instantánea, sin spinner ni posibilidad de fallo.
void markCareDone(BuildContext context, WidgetRef ref, ScheduleView view) {
  final repo = ref.read(careRepositoryProvider);
  final execution = repo.markDone(view.schedule.id);
  final l10n = AppLocalizations.of(context)!;
  final careName = careDisplayName(l10n, view.schedule.kind, view.name);

  final messenger = ScaffoldMessenger.of(context);
  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      content: Text(l10n.careDoneSnack(careName, view.pet.name)),
      duration: const Duration(seconds: 4),
      action: SnackBarAction(
        label: l10n.careUndo,
        onPressed: () => repo.undo(execution.id),
      ),
    ),
  );
}
