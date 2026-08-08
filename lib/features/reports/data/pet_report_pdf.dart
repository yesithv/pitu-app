import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Datos ya formateados para el reporte veterinario. La capa de aplicación los
/// arma desde el dominio; este archivo solo sabe de composición de PDF, para
/// que la dependencia de `pdf` no se filtre al resto de la app.
class PetReportData {
  const PetReportData({
    required this.ownerName,
    required this.generatedAtText,
    required this.petName,
    required this.speciesLabel,
    this.breed,
    this.ageText,
    this.weightText,
    this.diagnoses = const [],
    this.weights = const [],
    this.vaccines = const [],
    this.visits = const [],
    this.cares = const [],
  });

  final String ownerName;
  final String generatedAtText;
  final String petName;
  final String speciesLabel;
  final String? breed;
  final String? ageText;
  final String? weightText;

  final List<ReportDiagnosis> diagnoses;
  final List<ReportWeight> weights;
  final List<ReportVaccine> vaccines;
  final List<ReportVisit> visits;
  final List<ReportCare> cares;
}

class ReportDiagnosis {
  const ReportDiagnosis(this.condition, this.status, this.since);
  final String condition;
  final String status;
  final String since;
}

class ReportWeight {
  const ReportWeight(this.date, this.value, this.note);
  final String date;
  final String value;
  final String note;
}

class ReportVaccine {
  const ReportVaccine(this.type, this.applied, this.next, this.clinic);
  final String type;
  final String applied;
  final String next;
  final String clinic;
}

class ReportVisit {
  const ReportVisit(this.date, this.reason, this.clinic, this.diagnosis,
      this.treatment);
  final String date;
  final String reason;
  final String clinic;
  final String diagnosis;
  final String treatment;
}

class ReportCare {
  const ReportCare(this.name, this.frequency, this.next);
  final String name;
  final String frequency;
  final String next;
}

/// Etiquetas ya localizadas para el PDF (secciones, columnas, vacíos, pie).
class PetReportStrings {
  const PetReportStrings({
    required this.title,
    required this.guardian,
    required this.footer,
    required this.sectionDiagnoses,
    required this.sectionVisits,
    required this.sectionVaccines,
    required this.sectionWeights,
    required this.sectionCares,
    required this.emptyDiagnoses,
    required this.emptyVisits,
    required this.emptyVaccines,
    required this.emptyWeights,
    required this.emptyCares,
    required this.colCondition,
    required this.colStatus,
    required this.colSince,
    required this.colDate,
    required this.colReason,
    required this.colClinic,
    required this.colDiagnosis,
    required this.colTreatment,
    required this.colVaccine,
    required this.colApplied,
    required this.colNext,
    required this.colWeight,
    required this.colNote,
    required this.colCare,
    required this.colFrequency,
    required this.colUpcoming,
  });

  final String title;
  final String guardian;
  final String Function(int page, int total) footer;
  final String sectionDiagnoses;
  final String sectionVisits;
  final String sectionVaccines;
  final String sectionWeights;
  final String sectionCares;
  final String emptyDiagnoses;
  final String emptyVisits;
  final String emptyVaccines;
  final String emptyWeights;
  final String emptyCares;
  final String colCondition;
  final String colStatus;
  final String colSince;
  final String colDate;
  final String colReason;
  final String colClinic;
  final String colDiagnosis;
  final String colTreatment;
  final String colVaccine;
  final String colApplied;
  final String colNext;
  final String colWeight;
  final String colNote;
  final String colCare;
  final String colFrequency;
  final String colUpcoming;
}

// Paleta alineada con la identidad visual de PituApp. Se usa el constructor
// const de PdfColor (fromInt no es const) para poder marcar los estilos const.
const _teal = PdfColor(0x14 / 255, 0x59 / 255, 0x5F / 255);
const _ink = PdfColor(0x2B / 255, 0x2B / 255, 0x2B / 255);
const _muted = PdfColor(0x7A / 255, 0x7A / 255, 0x7A / 255);
const _line = PdfColor(0xE3 / 255, 0xE0 / 255, 0xD8 / 255);
const _soft = PdfColor(0xF3 / 255, 0xF1 / 255, 0xEA / 255);

/// Construye el PDF del reporte veterinario y devuelve sus bytes (RF-38/39).
Future<Uint8List> buildPetReportPdf(PetReportData d, PetReportStrings s) async {
  final doc = pw.Document(title: '${s.title} — ${d.petName}');

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(36, 40, 36, 44),
      build: (context) => [
        _header(d, s),
        pw.SizedBox(height: 16),
        _petCard(d),
        pw.SizedBox(height: 20),
        _diagnosesSection(d.diagnoses, s),
        _visitsSection(d.visits, s),
        _vaccinesSection(d.vaccines, s),
        _weightsSection(d.weights, s),
        _caresSection(d.cares, s),
      ],
      footer: (context) => pw.Container(
        alignment: pw.Alignment.centerRight,
        margin: const pw.EdgeInsets.only(top: 8),
        child: pw.Text(
          s.footer(context.pageNumber, context.pagesCount),
          style: const pw.TextStyle(color: _muted, fontSize: 8),
        ),
      ),
    ),
  );

  return doc.save();
}

pw.Widget _header(PetReportData d, PetReportStrings s) {
  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('PituApp',
              style: const pw.TextStyle(
                  color: _teal, fontSize: 22, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 2),
          pw.Text(s.title,
              style: const pw.TextStyle(color: _muted, fontSize: 11)),
        ],
      ),
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text(s.guardian,
              style: const pw.TextStyle(color: _ink, fontSize: 10)),
          pw.SizedBox(height: 2),
          pw.Text(d.generatedAtText,
              style: const pw.TextStyle(color: _muted, fontSize: 9)),
        ],
      ),
    ],
  );
}

pw.Widget _petCard(PetReportData d) {
  final chips = <String>[
    d.speciesLabel,
    if (d.breed != null && d.breed!.isNotEmpty) d.breed!,
    if (d.ageText != null && d.ageText!.isNotEmpty) d.ageText!,
    if (d.weightText != null && d.weightText!.isNotEmpty) d.weightText!,
  ];
  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.all(16),
    decoration: pw.BoxDecoration(
      color: _soft,
      borderRadius: pw.BorderRadius.circular(12),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(d.petName,
            style: const pw.TextStyle(
                color: _ink, fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Text(chips.join('  ·  '),
            style: const pw.TextStyle(color: _muted, fontSize: 11)),
      ],
    ),
  );
}

pw.Widget _section(String title, pw.Widget child) {
  return pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 18),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title,
            style: const pw.TextStyle(
                color: _teal, fontSize: 13, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 2),
        pw.Divider(color: _line, thickness: .8, height: 10),
        pw.SizedBox(height: 4),
        child,
      ],
    ),
  );
}

pw.Widget _empty(String text) =>
    pw.Text(text, style: const pw.TextStyle(color: _muted, fontSize: 10));

pw.Widget _table(List<int> flex, List<String> headers,
    List<List<String>> rows) {
  pw.Widget cell(String text, {bool head = false}) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 4),
        child: pw.Text(
          text.isEmpty ? '—' : text,
          style: pw.TextStyle(
            color: head ? _muted : _ink,
            fontSize: 9.5,
            fontWeight: head ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      );

  final columnWidths = <int, pw.TableColumnWidth>{
    for (var i = 0; i < flex.length; i++)
      i: pw.FlexColumnWidth(flex[i].toDouble()),
  };

  return pw.Table(
    columnWidths: columnWidths,
    border: const pw.TableBorder(
      horizontalInside: pw.BorderSide(color: _line, width: .5),
    ),
    children: [
      pw.TableRow(
        children: [for (final h in headers) cell(h, head: true)],
      ),
      for (final r in rows)
        pw.TableRow(children: [for (final v in r) cell(v)]),
    ],
  );
}

pw.Widget _diagnosesSection(List<ReportDiagnosis> items, PetReportStrings s) {
  return _section(
    s.sectionDiagnoses,
    items.isEmpty
        ? _empty(s.emptyDiagnoses)
        : _table(
            [5, 3, 3],
            [s.colCondition, s.colStatus, s.colSince],
            [for (final d in items) [d.condition, d.status, d.since]],
          ),
  );
}

pw.Widget _visitsSection(List<ReportVisit> items, PetReportStrings s) {
  return _section(
    s.sectionVisits,
    items.isEmpty
        ? _empty(s.emptyVisits)
        : _table(
            [3, 4, 4, 4, 4],
            [s.colDate, s.colReason, s.colClinic, s.colDiagnosis, s.colTreatment],
            [
              for (final v in items)
                [v.date, v.reason, v.clinic, v.diagnosis, v.treatment]
            ],
          ),
  );
}

pw.Widget _vaccinesSection(List<ReportVaccine> items, PetReportStrings s) {
  return _section(
    s.sectionVaccines,
    items.isEmpty
        ? _empty(s.emptyVaccines)
        : _table(
            [5, 3, 3, 4],
            [s.colVaccine, s.colApplied, s.colNext, s.colClinic],
            [
              for (final v in items) [v.type, v.applied, v.next, v.clinic]
            ],
          ),
  );
}

pw.Widget _weightsSection(List<ReportWeight> items, PetReportStrings s) {
  return _section(
    s.sectionWeights,
    items.isEmpty
        ? _empty(s.emptyWeights)
        : _table(
            [3, 3, 6],
            [s.colDate, s.colWeight, s.colNote],
            [for (final w in items) [w.date, w.value, w.note]],
          ),
  );
}

pw.Widget _caresSection(List<ReportCare> items, PetReportStrings s) {
  return _section(
    s.sectionCares,
    items.isEmpty
        ? _empty(s.emptyCares)
        : _table(
            [5, 4, 3],
            [s.colCare, s.colFrequency, s.colUpcoming],
            [for (final ca in items) [ca.name, ca.frequency, ca.next]],
          ),
  );
}
