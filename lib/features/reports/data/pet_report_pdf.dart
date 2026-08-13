import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
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
    this.birthDateText,
    this.weightText,
    this.photoBase64,
    this.diagnoses = const [],
    this.weights = const [],
    this.vaccines = const [],
    this.visits = const [],
    this.cares = const [],
    this.careHistory = const [],
  });

  final String ownerName;
  final String generatedAtText;
  final String petName;
  final String speciesLabel;
  final String? breed;
  final String? ageText;
  final String? birthDateText;
  final String? weightText;

  /// Foto de la mascota en base64 (sin prefijo `data:`), si existe.
  final String? photoBase64;

  final List<ReportDiagnosis> diagnoses;
  final List<ReportWeight> weights;
  final List<ReportVaccine> vaccines;
  final List<ReportVisit> visits;
  final List<ReportCare> cares;
  final List<ReportCareDone> careHistory;
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

/// Cuidado ya realizado (entrada del historial).
class ReportCareDone {
  const ReportCareDone(this.name, this.date);
  final String name;
  final String date;
}

/// Etiquetas ya localizadas para el PDF (secciones, columnas, vacíos, pie).
class PetReportStrings {
  const PetReportStrings({
    required this.title,
    required this.guardian,
    required this.footer,
    required this.footerTagline,
    required this.birthDateLabel,
    required this.statWeight,
    required this.statVaccines,
    required this.statVisits,
    required this.statNextCare,
    required this.sectionDiagnoses,
    required this.sectionVisits,
    required this.sectionVaccines,
    required this.sectionWeights,
    required this.sectionCares,
    required this.sectionCareHistory,
    required this.emptyDiagnoses,
    required this.emptyVisits,
    required this.emptyVaccines,
    required this.emptyWeights,
    required this.emptyCares,
    required this.emptyCareHistory,
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

  /// Línea cálida del pie, p. ej. "Hecho con cariño para Pitufo".
  final String footerTagline;
  final String birthDateLabel;
  final String statWeight;
  final String statVaccines;
  final String statVisits;
  final String statNextCare;
  final String sectionDiagnoses;
  final String sectionVisits;
  final String sectionVaccines;
  final String sectionWeights;
  final String sectionCares;
  final String sectionCareHistory;
  final String emptyDiagnoses;
  final String emptyVisits;
  final String emptyVaccines;
  final String emptyWeights;
  final String emptyCares;
  final String emptyCareHistory;
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
const _tealSoft = PdfColor(0xE7 / 255, 0xF0 / 255, 0xF0 / 255);
const _onBand = PdfColor(1, 1, 1);
const _onBandSoft = PdfColor(0xCF / 255, 0xE2 / 255, 0xE3 / 255);

/// Construye el PDF del reporte veterinario y devuelve sus bytes (RF-38/39).
///
/// Embebe la fuente Nunito (la de la marca) para que todos los signos
/// tipográficos —incluido el guion largo "—"— se rendericen; la fuente
/// integrada del paquete `pdf` (Helvetica) no cubre esos glifos.
Future<Uint8List> buildPetReportPdf(PetReportData d, PetReportStrings s) async {
  final regular = pw.Font.ttf(await rootBundle.load('assets/fonts/Nunito-Regular.ttf'));
  final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/Nunito-Bold.ttf'));

  final doc = pw.Document(
    title: '${s.title} — ${d.petName}',
    theme: pw.ThemeData.withFont(base: regular, bold: bold),
  );

  final photo = _decodePhoto(d.photoBase64);

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(34, 34, 34, 40),
      build: (context) => [
        _header(d, s, photo),
        pw.SizedBox(height: 16),
        _summaryRow(d, s),
        pw.SizedBox(height: 20),
        _diagnosesSection(d.diagnoses, s),
        _visitsSection(d.visits, s),
        _vaccinesSection(d.vaccines, s),
        _weightsSection(d.weights, s),
        _careHistorySection(d.careHistory, s),
        _caresSection(d.cares, s),
      ],
      footer: (context) => pw.Container(
        margin: const pw.EdgeInsets.only(top: 10),
        padding: const pw.EdgeInsets.only(top: 6),
        decoration: const pw.BoxDecoration(
          border: pw.Border(top: pw.BorderSide(color: _line, width: .6)),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(s.footerTagline,
                style: const pw.TextStyle(color: _teal, fontSize: 8.5)),
            pw.Text(
              s.footer(context.pageNumber, context.pagesCount),
              style: const pw.TextStyle(color: _muted, fontSize: 8),
            ),
          ],
        ),
      ),
    ),
  );

  return doc.save();
}

pw.MemoryImage? _decodePhoto(String? base64Str) {
  if (base64Str == null || base64Str.isEmpty) return null;
  try {
    return pw.MemoryImage(base64Decode(base64Str));
  } catch (_) {
    return null;
  }
}

/// Encabezado emotivo: banda con color de marca, avatar de la mascota (foto o
/// inicial), nombre, atributos y datos de generación.
pw.Widget _header(PetReportData d, PetReportStrings s, pw.MemoryImage? photo) {
  final chips = <String>[
    d.speciesLabel,
    if (d.breed != null && d.breed!.isNotEmpty) d.breed!,
    if (d.ageText != null && d.ageText!.isNotEmpty) d.ageText!,
    if (d.weightText != null && d.weightText!.isNotEmpty) d.weightText!,
  ];

  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.all(20),
    decoration: pw.BoxDecoration(
      color: _teal,
      borderRadius: pw.BorderRadius.circular(16),
    ),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _avatar(d.petName, photo),
        pw.SizedBox(width: 16),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('PituApp',
                  style: const pw.TextStyle(
                      color: _onBandSoft,
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: .5)),
              pw.SizedBox(height: 3),
              pw.Text(d.petName,
                  style: const pw.TextStyle(
                      color: _onBand, fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text(chips.join('   ·   '),
                  style: const pw.TextStyle(color: _onBandSoft, fontSize: 10.5)),
              if (d.birthDateText != null && d.birthDateText!.isNotEmpty) ...[
                pw.SizedBox(height: 3),
                pw.Text('${s.birthDateLabel}: ${d.birthDateText}',
                    style: const pw.TextStyle(color: _onBandSoft, fontSize: 9.5)),
              ],
            ],
          ),
        ),
        pw.SizedBox(width: 12),
        pw.SizedBox(
          width: 130,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(s.title,
                  textAlign: pw.TextAlign.right,
                  style: const pw.TextStyle(
                      color: _onBand, fontSize: 11, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.Text(d.generatedAtText,
                  textAlign: pw.TextAlign.right,
                  style: const pw.TextStyle(color: _onBandSoft, fontSize: 9)),
              pw.SizedBox(height: 2),
              pw.Text(s.guardian,
                  textAlign: pw.TextAlign.right,
                  style: const pw.TextStyle(color: _onBandSoft, fontSize: 9)),
            ],
          ),
        ),
      ],
    ),
  );
}

pw.Widget _avatar(String name, pw.MemoryImage? photo) {
  const size = 58.0;
  if (photo != null) {
    return pw.Container(
      width: size,
      height: size,
      decoration: pw.BoxDecoration(
        shape: pw.BoxShape.circle,
        border: pw.Border.all(color: _onBand, width: 2),
      ),
      child: pw.ClipOval(
        child: pw.Image(photo, width: size, height: size, fit: pw.BoxFit.cover),
      ),
    );
  }
  final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
  return pw.Container(
    width: size,
    height: size,
    alignment: pw.Alignment.center,
    decoration: pw.BoxDecoration(
      shape: pw.BoxShape.circle,
      color: _onBand,
      border: pw.Border.all(color: _onBandSoft, width: 2),
    ),
    child: pw.Text(initial,
        style: const pw.TextStyle(
            color: _teal, fontSize: 26, fontWeight: pw.FontWeight.bold)),
  );
}

pw.Widget _summaryRow(PetReportData d, PetReportStrings s) {
  final nextCare = d.cares.isEmpty ? '—' : d.cares.first.name;
  final nextCareDate = d.cares.isEmpty ? '' : d.cares.first.next;
  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      _statCard(s.statWeight, d.weightText ?? '—'),
      pw.SizedBox(width: 10),
      _statCard(s.statVaccines, '${d.vaccines.length}'),
      pw.SizedBox(width: 10),
      _statCard(s.statVisits, '${d.visits.length}'),
      pw.SizedBox(width: 10),
      _statCard(s.statNextCare, nextCare, sub: nextCareDate),
    ],
  );
}

pw.Widget _statCard(String label, String value, {String sub = ''}) {
  return pw.Expanded(
    child: pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: pw.BoxDecoration(
        color: _tealSoft,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label.toUpperCase(),
              style: const pw.TextStyle(
                  color: _teal, fontSize: 7.5, letterSpacing: .5)),
          pw.SizedBox(height: 3),
          pw.Text(value,
              maxLines: 1,
              style: const pw.TextStyle(
                  color: _ink, fontSize: 12, fontWeight: pw.FontWeight.bold)),
          if (sub.isNotEmpty) ...[
            pw.SizedBox(height: 1),
            pw.Text(sub, style: const pw.TextStyle(color: _muted, fontSize: 8)),
          ],
        ],
      ),
    ),
  );
}

pw.Widget _section(String title, pw.Widget child) {
  return pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 16),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Container(
              width: 4,
              height: 14,
              decoration: pw.BoxDecoration(
                color: _teal,
                borderRadius: pw.BorderRadius.circular(2),
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Text(title,
                style: const pw.TextStyle(
                    color: _teal, fontSize: 13, fontWeight: pw.FontWeight.bold)),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: pw.BoxDecoration(
            color: _soft,
            borderRadius: pw.BorderRadius.circular(10),
          ),
          child: child,
        ),
      ],
    ),
  );
}

pw.Widget _empty(String text) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Text(text, style: const pw.TextStyle(color: _muted, fontSize: 10)),
    );

pw.Widget _table(List<int> flex, List<String> headers,
    List<List<String>> rows) {
  pw.Widget cell(String text, {bool head = false}) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: pw.Text(
          text.isEmpty ? '—' : text,
          style: pw.TextStyle(
            color: head ? _teal : _ink,
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

pw.Widget _careHistorySection(List<ReportCareDone> items, PetReportStrings s) {
  return _section(
    s.sectionCareHistory,
    items.isEmpty
        ? _empty(s.emptyCareHistory)
        : _table(
            [6, 4],
            [s.colCare, s.colDate],
            [for (final c in items) [c.name, c.date]],
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
