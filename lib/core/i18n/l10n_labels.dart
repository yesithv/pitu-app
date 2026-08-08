import 'package:flutter/widgets.dart';
import 'package:pitu_app/l10n/app_localizations.dart';

import '../../features/attachments/domain/entities/attachment.dart';
import '../../features/care/domain/entities/care_frequency.dart';
import '../../features/care/domain/entities/care_kind.dart';
import '../../features/clinical/domain/entities/diagnosis.dart';
import '../../features/clinical/domain/entities/timeline_entry.dart';
import '../../features/pets/domain/entities/pet.dart';
import '../../features/pets/domain/entities/species.dart';

/// Acceso corto a las localizaciones desde un [BuildContext].
AppLocalizations l10nOf(BuildContext context) => AppLocalizations.of(context)!;

/// Etiquetas localizadas para enums y valores de dominio. Los datos persistidos
/// (nombres de cuidados sembrados, nombres personalizados, etc.) no se traducen;
/// se resuelve la etiqueta a partir del enum estable.
// Nota: los métodos se llaman `localized(...)` (no `label`) para no chocar con
// los campos `label`/`singular`/`plural` que ya existen en algunos enums; una
// extensión no puede sobrescribir un miembro de instancia existente.
extension SpeciesL10n on Species {
  String localized(AppLocalizations l10n) => switch (this) {
        Species.dog => l10n.speciesDog,
        Species.cat => l10n.speciesCat,
        Species.other => l10n.speciesOther,
      };
}

extension CareKindL10n on CareKind {
  /// Nombre del catálogo localizado por tipo. Para [CareKind.custom] no hay
  /// nombre fijo; usa [careDisplayName] con el nombre almacenado.
  String localized(AppLocalizations l10n) => switch (this) {
        CareKind.vaccine => l10n.careVaccine,
        CareKind.deworming => l10n.careDeworming,
        CareKind.dental => l10n.careDental,
        CareKind.bath => l10n.careBath,
        CareKind.nails => l10n.careNails,
        CareKind.weight => l10n.careWeightControl,
        CareKind.vetVisit => l10n.careVetVisit,
        CareKind.medication => l10n.careMedication,
        CareKind.birthday => l10n.careBirthday,
        CareKind.custom => l10n.careCustom,
      };
}

/// Nombre visible de un cuidado: localizado por tipo salvo cuando es
/// personalizado, en cuyo caso se respeta el nombre escrito por el usuario.
String careDisplayName(AppLocalizations l10n, CareKind kind, String storedName) {
  return kind == CareKind.custom ? storedName : kind.localized(l10n);
}

extension DiagnosisStatusL10n on DiagnosisStatus {
  String localized(AppLocalizations l10n) => switch (this) {
        DiagnosisStatus.active => l10n.dxStatusActive,
        DiagnosisStatus.treatment => l10n.dxStatusTreatment,
        DiagnosisStatus.chronic => l10n.dxStatusChronic,
        DiagnosisStatus.resolved => l10n.dxStatusResolved,
      };
}

extension ArchiveReasonL10n on ArchiveReason {
  String localized(AppLocalizations l10n) => switch (this) {
        ArchiveReason.deceased => l10n.archiveReasonDeceased,
        ArchiveReason.rehomed => l10n.archiveReasonRehomed,
        ArchiveReason.other => l10n.archiveReasonOther,
      };
}

extension AttachmentKindL10n on AttachmentKind {
  String localized(AppLocalizations l10n) => switch (this) {
        AttachmentKind.image => l10n.attachmentKindImage,
        AttachmentKind.pdf => l10n.attachmentKindPdf,
        AttachmentKind.other => l10n.attachmentKindOther,
      };
}

extension FrequencyUnitL10n on FrequencyUnit {
  String singularName(AppLocalizations l10n) => switch (this) {
        FrequencyUnit.days => l10n.freqUnitSingularDay,
        FrequencyUnit.weeks => l10n.freqUnitSingularWeek,
        FrequencyUnit.months => l10n.freqUnitSingularMonth,
        FrequencyUnit.years => l10n.freqUnitSingularYear,
      };

  String pluralName(AppLocalizations l10n) => switch (this) {
        FrequencyUnit.days => l10n.freqUnitPluralDays,
        FrequencyUnit.weeks => l10n.freqUnitPluralWeeks,
        FrequencyUnit.months => l10n.freqUnitPluralMonths,
        FrequencyUnit.years => l10n.freqUnitPluralYears,
      };

  /// Etiqueta para el selector de unidades del formulario de cuidado.
  String pickerLabel(AppLocalizations l10n) => switch (this) {
        FrequencyUnit.days => l10n.freqUnitDays,
        FrequencyUnit.weeks => l10n.freqUnitWeeks,
        FrequencyUnit.months => l10n.freqUnitMonths,
        FrequencyUnit.years => l10n.freqUnitYears,
      };
}

/// Construye los textos localizados para la línea de tiempo del historial.
TimelineLabels timelineLabels(AppLocalizations l10n) => TimelineLabels(
      visit: l10n.timelineVisit,
      visitWithReason: (r) => l10n.timelineVisitReason(r),
      weightLogged: (v, u) => l10n.timelineWeightLogged(v, u),
      statusChange: (c) => l10n.timelineStatusChange(c),
      statusTransition: (f, t) => l10n.timelineStatusTransition(f, t),
      diagnosisStatusLabel: (s) => s.localized(l10n),
    );

/// "Cada 6 meses" / "Cada mes" localizado.
String careFrequencyLabel(AppLocalizations l10n, CareFrequency f) {
  if (f.every == 1) return l10n.freqEverySingular(f.unit.singularName(l10n));
  return l10n.freqEveryPlural(f.every, f.unit.pluralName(l10n));
}

/// Texto relativo del estado a partir de los días hasta la próxima fecha.
String relativeLabelFor(AppLocalizations l10n, int daysUntil) {
  if (daysUntil < 0) {
    final d = -daysUntil;
    return d == 1 ? l10n.relativeOverdueYesterday : l10n.relativeOverdueDays(d);
  }
  if (daysUntil == 0) return l10n.relativeToday;
  if (daysUntil == 1) return l10n.relativeTomorrow;
  return l10n.relativeInDays(daysUntil);
}

String _trimWeight(double w) =>
    w == w.roundToDouble() ? w.toInt().toString() : w.toString();

/// Subtítulo de la mascota: "Perro · Labrador · 4 años · 28 kg".
String petSubtitle(AppLocalizations l10n, Pet pet) {
  final parts = <String>[pet.species.localized(l10n)];
  if (pet.breed != null && pet.breed!.isNotEmpty) parts.add(pet.breed!);
  if (pet.ageText != null && pet.ageText!.isNotEmpty) parts.add(pet.ageText!);
  if (pet.weight != null) {
    parts.add('${_trimWeight(pet.weight!)} ${pet.weightUnit.label}');
  }
  return parts.join(' · ');
}

/// Subtítulo corto para listas (sin peso).
String petShortSubtitle(AppLocalizations l10n, Pet pet) {
  final parts = <String>[pet.species.localized(l10n)];
  if (pet.breed != null && pet.breed!.isNotEmpty) parts.add(pet.breed!);
  if (pet.ageText != null && pet.ageText!.isNotEmpty) parts.add(pet.ageText!);
  return parts.join(' · ');
}
