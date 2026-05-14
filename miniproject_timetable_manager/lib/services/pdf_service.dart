// ──────────────────────────────────────────────
// SchedIQ — Smart Timetable Manager V2
// PDF Export Service — matches Excel template format
// ──────────────────────────────────────────────

import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import '../models/class_entry_model.dart';
import '../models/subject_model.dart';
import '../db/database_helper_v2.dart';
import '../utils/constants.dart';
import 'preferences_service.dart';

class PdfService {
  static final PdfService _instance = PdfService._internal();
  factory PdfService() => _instance;
  PdfService._internal();

  // The 9 time slot columns from the Excel template
  static const List<String> _timeSlotHeaders = [
    '08.00 -\n08.50',
    '09.00 -\n09.50',
    '10.00 -\n10.50',
    '11.00 -\n11.50',
    '12.00 -\n12.50',
    '01.20 -\n02.10',
    '02.10 -\n02.50',
    '03.00 -\n03.50',
    '04.00 -\n04.50',
  ];

  // The time slot ranges in 24h minutes for matching classes to slots
  static const List<_TimeRange> _timeRanges = [
    _TimeRange(480, 530),   // 08:00 - 08:50
    _TimeRange(540, 590),   // 09:00 - 09:50
    _TimeRange(600, 650),   // 10:00 - 10:50
    _TimeRange(660, 710),   // 11:00 - 11:50
    _TimeRange(720, 770),   // 12:00 - 12:50
    _TimeRange(800, 850),   // 13:20 - 14:10
    _TimeRange(850, 890),   // 14:10 - 14:50 (adjusted: 14:10 overlap handled)
    _TimeRange(900, 950),   // 15:00 - 15:50
    _TimeRange(960, 1010),  // 16:00 - 16:50
  ];

  // The LUNCH column index (0-based among the 9 slots)
  // Looking at the template: column 5 (11:00-11:50) seems to be where LUNCH sits
  // Actually from the data, LUNCH is at column index 3 (the 4th time slot = 11:00-11:50)
  static const int _lunchSlotIndex = 3;

  /// Generate a PDF matching the Excel template format.
  Future<pw.Document> generateTimetablePdf() async {
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: await PdfGoogleFonts.interRegular(),
        bold: await PdfGoogleFonts.interBold(),
      ),
    );

    final allClasses = await DatabaseHelperV2.instance.getAllClasses();
    final allSubjects = await DatabaseHelperV2.instance.getAllSubjects();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Title row (matches Row 2 of Excel)
              _buildTitle(),
              pw.SizedBox(height: 8),

              // Timetable grid (matches Rows 4-11 of Excel)
              _buildTimetableGrid(allClasses),
              pw.SizedBox(height: 16),

              // Subject legend table (matches Rows 14-20 of Excel)
              _buildSubjectLegend(allSubjects),

              pw.Spacer(),

              // Footer
              _buildFooter(),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  pw.Widget _buildTitle() {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#D9E2F3'),
        border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
      ),
      child: pw.Center(
        child: pw.Text(
          'TIMETABLE ALLOCATION',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#1F3864'),
          ),
        ),
      ),
    );
  }

  pw.Widget _buildTimetableGrid(List<ClassEntry> allClasses) {
    final days = PreferencesService().workingDays; // Only configured working days

    // Group classes by day
    final Map<String, List<ClassEntry>> classesByDay = {};
    for (final day in days) {
      classesByDay[day] = allClasses
          .where((c) => c.day == day)
          .toList()
        ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
    }

    final List<pw.TableRow> rows = [];

    // ── Header row (Day | Time + 9 time slot columns)
    rows.add(pw.TableRow(
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#D9E2F3'),
      ),
      children: [
        _headerCell('Day | Time', width: 55),
        ..._timeSlotHeaders.map((h) => _headerCell(h)),
      ],
    ));

    // ── Day rows
    for (final day in days) {
      final dayClasses = classesByDay[day] ?? [];

      // Build slot cells for this day
      final List<pw.Widget> slotCells = [];
      for (int i = 0; i < _timeRanges.length; i++) {
        if (i == _lunchSlotIndex) {
          // LUNCH column
          slotCells.add(_lunchCell());
          continue;
        }

        // Find a class that fits this time slot
        final matching = _findClassForSlot(dayClasses, i);
        if (matching != null) {
          slotCells.add(_classCell(matching));
        } else {
          slotCells.add(_emptyCell());
        }
      }

      // Check if this day is a holiday (no classes at all)
      final isHolidayDay = dayClasses.isEmpty &&
          (day == 'Sunday' || day == 'Saturday');

      if (isHolidayDay) {
        // Holiday row — merged style
        rows.add(pw.TableRow(
          children: [
            _dayCell(day),
            ...List.generate(9, (_) => _holidayCell()),
          ],
        ));
      } else {
        rows.add(pw.TableRow(
          children: [
            _dayCell(day),
            ...slotCells,
          ],
        ));
      }
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(55),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FlexColumnWidth(0.6),
        5: const pw.FlexColumnWidth(1),
        6: const pw.FlexColumnWidth(1),
        7: const pw.FlexColumnWidth(1),
        8: const pw.FlexColumnWidth(1),
        9: const pw.FlexColumnWidth(1),
      },
      children: rows,
    );
  }

  /// Match a class to a time slot based on its start time.
  ClassEntry? _findClassForSlot(List<ClassEntry> classes, int slotIndex) {
    if (slotIndex < 0 || slotIndex >= _timeRanges.length) return null;
    final range = _timeRanges[slotIndex];

    for (final c in classes) {
      // A class matches if its start time falls within or near this slot
      if (c.startMinutes >= range.start - 10 &&
          c.startMinutes <= range.start + 10) {
        return c;
      }
    }
    return null;
  }

  // ── Cell builders ──

  pw.Widget _headerCell(String text, {double? width}) {
    return pw.Container(
      width: width,
      padding: const pw.EdgeInsets.all(3),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 6.5,
          fontWeight: pw.FontWeight.bold,
          color: PdfColor.fromHex('#1F3864'),
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _dayCell(String day) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      alignment: pw.Alignment.center,
      color: PdfColor.fromHex('#D9E2F3'),
      child: pw.Text(
        day,
        style: pw.TextStyle(
          fontSize: 7,
          fontWeight: pw.FontWeight.bold,
          color: PdfColor.fromHex('#1F3864'),
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _classCell(ClassEntry c) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(2),
      alignment: pw.Alignment.center,
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(
            c.subjectCode ?? '',
            style: pw.TextStyle(
              fontSize: 6,
              fontWeight: pw.FontWeight.bold,
            ),
            textAlign: pw.TextAlign.center,
          ),
          if (c.location.isNotEmpty)
            pw.Text(
              c.location,
              style: const pw.TextStyle(
                fontSize: 5.5,
                color: PdfColors.grey700,
              ),
              textAlign: pw.TextAlign.center,
            ),
        ],
      ),
    );
  }

  pw.Widget _emptyCell() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(2),
      alignment: pw.Alignment.center,
      child: pw.Text('', style: const pw.TextStyle(fontSize: 6)),
    );
  }

  pw.Widget _lunchCell() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(2),
      alignment: pw.Alignment.center,
      color: PdfColor.fromHex('#FFF2CC'),
      child: pw.Text(
        'LUNCH',
        style: pw.TextStyle(
          fontSize: 6,
          fontWeight: pw.FontWeight.bold,
          color: PdfColor.fromHex('#7F6000'),
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _holidayCell() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(2),
      alignment: pw.Alignment.center,
      color: PdfColor.fromHex('#E2EFDA'),
      child: pw.Text(
        'Holiday',
        style: pw.TextStyle(
          fontSize: 6,
          fontWeight: pw.FontWeight.bold,
          color: PdfColor.fromHex('#375623'),
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  // ── Subject Legend ──

  pw.Widget _buildSubjectLegend(List<Subject> subjects) {
    if (subjects.isEmpty) return pw.SizedBox();

    final List<pw.TableRow> rows = [];

    // Legend header
    rows.add(pw.TableRow(
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#D9E2F3'),
      ),
      children: [
        _legendHeaderCell('Subject Code'),
        _legendHeaderCell('Subject Name'),
        _legendHeaderCell('Teacher Name'),
      ],
    ));

    // Subject rows
    for (final s in subjects) {
      rows.add(pw.TableRow(
        children: [
          _legendDataCell(s.code),
          _legendDataCell(s.course),
          _legendDataCell(s.faculty),
        ],
      ));
    }

    return pw.Container(
      child: pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
        columnWidths: const {
          0: pw.FlexColumnWidth(1.2),
          1: pw.FlexColumnWidth(3),
          2: pw.FlexColumnWidth(2),
        },
        children: rows,
      ),
    );
  }

  pw.Widget _legendHeaderCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 7,
          fontWeight: pw.FontWeight.bold,
          color: PdfColor.fromHex('#1F3864'),
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _legendDataCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      alignment: pw.Alignment.centerLeft,
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 7),
      ),
    );
  }

  // ── Footer ──

  pw.Widget _buildFooter() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          'SchedIQ — Smart Timetable Manager',
          style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey500),
        ),
        pw.Text(
          'Generated: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
          style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey500),
        ),
      ],
    );
  }

  /// Save the timetable PDF to local device storage.
  /// Returns the saved file path.
  Future<String> savePdfLocally() async {
    final doc = await generateTimetablePdf();
    final bytes = await doc.save();
    
    Directory? dir;
    if (Platform.isAndroid) {
      // Try to save directly to public Downloads folder on Android
      dir = Directory('/storage/emulated/0/Download');
      if (!await dir.exists()) {
        dir = await getExternalStorageDirectory();
      }
    } else {
      dir = await getDownloadsDirectory();
    }
    
    dir ??= await getApplicationDocumentsDirectory();

    final filename = 'SchedIQ_Timetable_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
    final file = File(p.join(dir.path, filename));
    await file.writeAsBytes(bytes);
    return file.path;
  }

  /// Share or download the timetable PDF.
  Future<void> sharePdf() async {
    final doc = await generateTimetablePdf();
    await Printing.sharePdf(
      bytes: await doc.save(),
      filename:
          'SchedIQ_Timetable_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  /// Show a print preview dialog.
  Future<void> printPdf() async {
    final doc = await generateTimetablePdf();
    await Printing.layoutPdf(onLayout: (format) => doc.save());
  }
}

/// Helper class for time slot ranges (in minutes from midnight).
class _TimeRange {
  final int start;
  final int end;
  const _TimeRange(this.start, this.end);
}
