import 'package:collection/collection.dart';
import 'package:pitu_app/l10n/app_localizations.dart';

import '../../../core/data/in_memory_database.dart';
import '../../../core/i18n/l10n_labels.dart';
import '../../../core/utils/app_dates.dart';
import '../../backup/data/file_transfer.dart';
import '../../care/domain/repositories/care_repository.dart';
import '../../clinical/domain/entities/weight_record.dart';
import '../../clinical/domain/repositories/clinical_repository.dart';
import '../../pets/domain/entities/pet.dart';
import '../data/pet_report_pdf.dart';

/// Alcance del reporte (RF-38): historial completo, solo vacunas o un rango de
/// fechas.
class ReportOptions {
  const ReportOptions({this.onlyVaccines = false, this.from, this.to});
  final bool onlyVaccines;
  final DateTime? from;
  final DateTime? to;

  static const ReportOptions full = ReportOptions();

  bool includes(DateTime date) {
    if (from != null && date.isBefore(from!)) return false;
    if (to != null && date.isAfter(to!)) return false;
    return true;
  }
}

/// Resultado de generar el reporte, con un mensaje ya listo para la UI.
class PetReportResult {
  const PetReportResult._(this.ok, this.message);
  factory PetReportResult.of(bool ok, String message) =>
      PetReportResult._(ok, message);

  final bool ok;
  final String message;
}

/// Arma el reporte veterinario en PDF de una mascota (RF-38/39, función Pro).
class PetReportService {
  PetReportService(this._db, this._clinical, this._care, this._files);

  final InMemoryDatabase _db;
  final ClinicalRepository _clinical;
  final CareRepository _care;
  final FileTransfer _files;

  Future<PetReportResult> generate(
    String petId, {
    ReportOptions options = ReportOptions.full,
    required AppLocalizations l10n,
    required String localeName,
  }) async {
    final pet = _db.pets.firstWhereOrNull((p) => p.id == petId);
    if (pet == null) {
      return PetReportResult.of(false, l10n.reportPetNotFound);
    }
    final data = _collect(pet, options, l10n, localeName);
    final bytes = await buildPetReportPdf(data, _strings(l10n));
    final path =
        await _files.saveBytes(_fileName(pet), bytes, mime: 'application/pdf');
    return PetReportResult.of(
      true,
      path == null ? l10n.reportDownloaded : l10n.reportSavedTo(path),
    );
  }

  PetReportStrings _strings(AppLocalizations l10n) => PetReportStrings(
        title: l10n.reportTitle,
        guardian: l10n.reportGuardian(_db.ownerName),
        footer: (page, total) => l10n.reportFooter(page, total),
        sectionDiagnoses: l10n.reportSectionDiagnoses,
        sectionVisits: l10n.reportSectionVisits,
        sectionVaccines: l10n.reportSectionVaccines,
        sectionWeights: l10n.reportSectionWeights,
        sectionCares: l10n.reportSectionCares,
        emptyDiagnoses: l10n.reportEmptyDiagnoses,
        emptyVisits: l10n.reportEmptyVisits,
        emptyVaccines: l10n.reportEmptyVaccines,
        emptyWeights: l10n.reportEmptyWeights,
        emptyCares: l10n.reportEmptyCares,
        colCondition: l10n.reportColCondition,
        colStatus: l10n.reportColStatus,
        colSince: l10n.reportColSince,
        colDate: l10n.reportColDate,
        colReason: l10n.reportColReason,
        colClinic: l10n.reportColClinic,
        colDiagnosis: l10n.reportColDiagnosis,
        colTreatment: l10n.reportColTreatment,
        colVaccine: l10n.reportColVaccine,
        colApplied: l10n.reportColApplied,
        colNext: l10n.reportColNext,
        colWeight: l10n.reportColWeight,
        colNote: l10n.reportColNote,
        colCare: l10n.reportColCare,
        colFrequency: l10n.reportColFrequency,
        colUpcoming: l10n.reportColUpcoming,
      );

  PetReportData _collect(
      Pet pet, ReportOptions options, AppLocalizations l10n, String localeName) {
    final onlyVac = options.onlyVaccines;
    final vaccines = _clinical
        .vaccinesForPet(pet.id)
        .where((v) => options.includes(v.appliedDate))
        .toList()
      ..sort((a, b) => b.appliedDate.compareTo(a.appliedDate));
    final diagnoses = _clinical
        .diagnosesForPet(pet.id)
        .where((d) => !onlyVac && options.includes(d.date))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final visits = _clinical
        .visitsForPet(pet.id)
        .where((v) => !onlyVac && options.includes(v.date))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    // weightsForPet ya viene ordenado ascendente; lo mostramos reciente primero.
    final weights = _clinical
        .weightsForPet(pet.id)
        .where((w) => !onlyVac && options.includes(w.date))
        .toList()
        .reversed
        .toList();
    final cares = _care
        .schedulesForPet(pet.id)
        .where((s) => s.isActive && !onlyVac)
        .toList()
      ..sort((a, b) => a.nextDate.compareTo(b.nextDate));

    return PetReportData(
      ownerName: _db.ownerName,
      generatedAtText:
          l10n.reportGeneratedOn(AppDates.longDate(DateTime.now(), localeName)),
      petName: pet.name,
      speciesLabel: pet.species.localized(l10n),
      breed: pet.breed,
      ageText: pet.ageText,
      weightText: pet.weight == null
          ? null
          : '${_trim(pet.weight!)} ${pet.weightUnit.label}',
      diagnoses: [
        for (final d in diagnoses)
          ReportDiagnosis(d.condition, d.status.localized(l10n),
              AppDates.shortDateYear(d.date, localeName)),
      ],
      visits: [
        for (final v in visits)
          ReportVisit(
            AppDates.shortDateYear(v.date, localeName),
            v.reason ?? '',
            v.clinic ?? '',
            v.diagnosis ?? '',
            v.treatment ?? '',
          ),
      ],
      vaccines: [
        for (final v in vaccines)
          ReportVaccine(
            v.type,
            AppDates.shortDateYear(v.appliedDate, localeName),
            v.nextDoseDate == null
                ? ''
                : AppDates.shortDateYear(v.nextDoseDate!, localeName),
            v.clinic ?? '',
          ),
      ],
      weights: [
        for (final w in weights)
          ReportWeight(
            AppDates.shortDateYear(w.date, localeName),
            '${_fmtWeight(w)} ${w.unit.label}',
            w.note ?? '',
          ),
      ],
      cares: [
        for (final s in cares)
          ReportCare(
            careDisplayName(l10n, s.kind, s.name),
            careFrequencyLabel(l10n, s.frequency),
            AppDates.shortDateYear(s.nextDate, localeName),
          ),
      ],
    );
  }

  String _fileName(Pet pet) {
    final slug = pet.name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'(^-|-$)'), '');
    final safe = slug.isEmpty ? 'mascota' : slug;
    return 'pitu-reporte-$safe.pdf';
  }

  static String _trim(double w) =>
      w == w.roundToDouble() ? w.toInt().toString() : w.toString();

  static String _fmtWeight(WeightRecord w) => _trim(w.value);
}
