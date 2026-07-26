import 'package:collection/collection.dart';

import '../../../core/data/in_memory_database.dart';
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

  String get label {
    if (onlyVaccines) return 'Solo vacunas';
    if (from != null || to != null) return 'Rango de fechas';
    return 'Historial completo';
  }
}

/// Resultado de generar el reporte, con un mensaje ya listo para la UI.
class PetReportResult {
  const PetReportResult._(this.ok, this.message);
  factory PetReportResult.success(String? path) => PetReportResult._(
        true,
        path == null
            ? 'Reporte PDF descargado (revisa tus descargas).'
            : 'Reporte guardado en: $path',
      );
  factory PetReportResult.failure(String message) =>
      PetReportResult._(false, message);

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

  Future<PetReportResult> generate(String petId,
      {ReportOptions options = ReportOptions.full}) async {
    final pet = _db.pets.firstWhereOrNull((p) => p.id == petId);
    if (pet == null) {
      return PetReportResult.failure('No encontramos la mascota.');
    }
    final data = _collect(pet, options);
    final bytes = await buildPetReportPdf(data);
    final path =
        await _files.saveBytes(_fileName(pet), bytes, mime: 'application/pdf');
    return PetReportResult.success(path);
  }

  PetReportData _collect(Pet pet, ReportOptions options) {
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
      generatedAtText: 'Generado el ${AppDates.longDate(DateTime.now())}',
      petName: pet.name,
      speciesLabel: pet.species.label,
      breed: pet.breed,
      ageText: pet.ageText,
      weightText: pet.weight == null
          ? null
          : '${_trim(pet.weight!)} ${pet.weightUnit.label}',
      diagnoses: [
        for (final d in diagnoses)
          ReportDiagnosis(
              d.condition, d.status.label, AppDates.shortDateYear(d.date)),
      ],
      visits: [
        for (final v in visits)
          ReportVisit(
            AppDates.shortDateYear(v.date),
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
            AppDates.shortDateYear(v.appliedDate),
            v.nextDoseDate == null
                ? ''
                : AppDates.shortDateYear(v.nextDoseDate!),
            v.clinic ?? '',
          ),
      ],
      weights: [
        for (final w in weights)
          ReportWeight(
            AppDates.shortDateYear(w.date),
            '${_fmtWeight(w)} ${w.unit.label}',
            w.note ?? '',
          ),
      ],
      cares: [
        for (final s in cares)
          ReportCare(
            s.name,
            s.frequency.label,
            AppDates.shortDateYear(s.nextDate),
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
