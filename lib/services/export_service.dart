// lib/services/export_service.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart';
import 'package:share_plus/share_plus.dart';
import '../models/user_model.dart';
import '../services/admin_service.dart';
import 'package:open_file/open_file.dart';

class ExportService {
  static final _dateFormat = DateFormat('dd MMM yyyy', 'id_ID');
  static final _fileDate = DateFormat('yyyyMMdd_HHmmss');

  static String _subjectLabel(String key) {
    switch (key) {
      case 'matematika':
        return 'Matematika';
      case 'bahasa':
        return 'B. Indonesia';
      case 'ipa':
        return 'IPA';
      case 'ips':
        return 'IPS';
      default:
        return key;
    }
  }

  // ═══════════════════════════════════════════
  // EXPORT PDF
  // ═══════════════════════════════════════════

  static Future<void> exportUsersPdf(BuildContext context) async {
    // Ambil data
    final users = await AdminService.getAllUsers();
    final stats = await AdminService.getDashboardStats();

    final pdf = pw.Document();
    final now = DateTime.now();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (ctx) => _buildPdfHeader(ctx, now),
        footer: (ctx) => _buildPdfFooter(ctx),
        build: (ctx) => [
          // Ringkasan Stats
          pw.Text('Ringkasan Statistik',
              style:
                  pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          _buildStatsRow(stats),
          pw.SizedBox(height: 20),

          // Tabel Siswa
          pw.Text('Data Seluruh Siswa',
              style:
                  pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          _buildUsersTable(users),
        ],
      ),
    );

    // Preview / print / share
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Laporan_Siswa_${_fileDate.format(now)}.pdf',
    );
  }

  static pw.Widget _buildPdfHeader(pw.Context ctx, DateTime now) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('LAPORAN DATA SISWA',
                    style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#6C63FF'))),
                pw.Text('Aplikasi Gamifikasi Edukatif',
                    style:
                        pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Tanggal Cetak:',
                    style: const pw.TextStyle(fontSize: 9)),
                pw.Text(_dateFormat.format(now),
                    style: pw.TextStyle(
                        fontSize: 9, fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ],
        ),
        pw.Divider(color: PdfColor.fromHex('#6C63FF'), thickness: 2),
        pw.SizedBox(height: 4),
      ],
    );
  }

  static pw.Widget _buildPdfFooter(pw.Context ctx) {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey300),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Aplikasi Gamifikasi Edukatif - Laporan Admin',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
            pw.Text('Halaman ${ctx.pageNumber} dari ${ctx.pagesCount}',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildStatsRow(Map<String, dynamic> stats) {
    final bySubject = Map<String, int>.from(stats['questionsBySubject'] ?? {});

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F3F0FF'),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _statBox('Total Siswa', '${stats['totalUsers'] ?? 0}'),
          _statBox('Total Soal', '${stats['totalQuestions'] ?? 0}'),
          _statBox('Mata Pelajaran', '${bySubject.length}'),
          _statBox('Tingkat Level', '12'),
        ],
      ),
    );
  }

  static pw.Widget _statBox(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(value,
            style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#6C63FF'))),
        pw.Text(label,
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
      ],
    );
  }

  static pw.Widget _buildUsersTable(List<UserModel> users) {
    const headers = [
      'No',
      'Username',
      'Level',
      'Total Poin',
      'Streak',
      'Matematika',
      'B.Indo',
      'IPA',
      'IPS'
    ];

    final rows = users.asMap().entries.map((e) {
      final i = e.key;
      final u = e.value;
      return [
        '${i + 1}',
        u.username,
        '${u.level}',
        '${u.totalPoints}',
        '${u.streakDays}',
        '${u.subjectProgress['matematika'] ?? 0}',
        '${u.subjectProgress['bahasa'] ?? 0}',
        '${u.subjectProgress['ipa'] ?? 0}',
        '${u.subjectProgress['ips'] ?? 0}',
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      headerStyle: pw.TextStyle(
          fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.white),
      headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#6C63FF')),
      cellStyle: const pw.TextStyle(fontSize: 8),
      rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
      oddRowDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#F8F7FF')),
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(24),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(3),
        3: const pw.FixedColumnWidth(32),
        4: const pw.FixedColumnWidth(48),
        5: const pw.FixedColumnWidth(36),
        6: const pw.FixedColumnWidth(52),
        7: const pw.FixedColumnWidth(40),
        8: const pw.FixedColumnWidth(32),
        9: const pw.FixedColumnWidth(32),
      },
    );
  }

  // ═══════════════════════════════════════════
  // EXPORT EXCEL
  // ═══════════════════════════════════════════

  static Future<void> exportUsersExcel(BuildContext context) async {
    final users = await AdminService.getAllUsers();
    final stats = await AdminService.getDashboardStats();
    final now = DateTime.now();

    final excel = Excel.createExcel();

    // ── Sheet 1: Data Siswa ──
    final sheet1 = excel['Data Siswa'];
    excel.setDefaultSheet('Data Siswa');

    // Header styling
    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#6C63FF'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Center,
    );

    final headers = [
      'No',
      'Username',
      'Level',
      'Total Poin',
      'Streak (Hari)',
      'Matematika',
      'B. Indonesia',
      'IPA',
      'IPS',
      'Badges',
      'Tanggal Daftar'
    ];

    // Set header row
    for (var i = 0; i < headers.length; i++) {
      final cell =
          sheet1.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }

    // Set column widths
    sheet1.setColumnWidth(0, 6);
    sheet1.setColumnWidth(1, 20);
    sheet1.setColumnWidth(2, 28);
    sheet1.setColumnWidth(3, 10);
    sheet1.setColumnWidth(4, 14);
    sheet1.setColumnWidth(5, 16);
    sheet1.setColumnWidth(6, 14);
    sheet1.setColumnWidth(7, 16);
    sheet1.setColumnWidth(8, 12);
    sheet1.setColumnWidth(9, 12);
    sheet1.setColumnWidth(10, 20);
    sheet1.setColumnWidth(11, 18);

    // Zebra row style
    final zebraStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#F3F0FF'),
    );

    // Data rows
    for (var i = 0; i < users.length; i++) {
      final u = users[i];
      final row = i + 1;
      final isZebra = i % 2 == 1;

      void setCell(int col, CellValue val) {
        final cell = sheet1
            .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
        cell.value = val;
        if (isZebra) cell.cellStyle = zebraStyle;
      }

      setCell(0, IntCellValue(i + 1));
      setCell(1, TextCellValue(u.username));
      setCell(2, IntCellValue(u.level));
      setCell(3, IntCellValue(u.totalPoints));
      setCell(4, IntCellValue(u.streakDays));
      setCell(5, IntCellValue(u.subjectProgress['matematika'] ?? 0));
      setCell(6, IntCellValue(u.subjectProgress['bahasa'] ?? 0));
      setCell(7, IntCellValue(u.subjectProgress['ipa'] ?? 0));
      setCell(8, IntCellValue(u.subjectProgress['ips'] ?? 0));
      setCell(9, TextCellValue(u.badges.join(', ')));
      setCell(
          10,
          TextCellValue(
              u.createdAt != null ? _dateFormat.format(u.createdAt!) : '-'));
    }

    // ── Sheet 2: Rekap per Mapel ──
    final sheet2 = excel['Rekap Mapel'];
    final subjects = ['matematika', 'bahasa', 'ipa', 'ips'];

    // Header
    final recapHeaders = [
      'Mata Pelajaran',
      'Rata-rata Poin',
      'Poin Tertinggi',
      'Poin Terendah',
      'Jumlah Aktif'
    ];
    for (var i = 0; i < recapHeaders.length; i++) {
      final cell =
          sheet2.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(recapHeaders[i]);
      cell.cellStyle = headerStyle;
    }
    sheet2.setColumnWidth(0, 20);
    sheet2.setColumnWidth(1, 18);
    sheet2.setColumnWidth(2, 18);
    sheet2.setColumnWidth(3, 18);
    sheet2.setColumnWidth(4, 16);

    for (var i = 0; i < subjects.length; i++) {
      final subj = subjects[i];
      final points = users
          .map((u) => u.subjectProgress[subj] ?? 0)
          .where((p) => p > 0)
          .toList();

      final avg = points.isEmpty
          ? 0
          : (points.reduce((a, b) => a + b) / points.length).round();
      final max = points.isEmpty ? 0 : points.reduce((a, b) => a > b ? a : b);
      final min = points.isEmpty ? 0 : points.reduce((a, b) => a < b ? a : b);

      void setCell2(int col, CellValue val) {
        sheet2
            .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: i + 1))
          ..value = val;
      }

      setCell2(0, TextCellValue(_subjectLabel(subj)));
      setCell2(1, IntCellValue(avg));
      setCell2(2, IntCellValue(max));
      setCell2(3, IntCellValue(min));
      setCell2(4, IntCellValue(points.length));
    }

    // Simpan & buka langsung
    final bytes = excel.save()!;
    final dir = await getTemporaryDirectory();
    final fileName = 'Laporan_Siswa_${_fileDate.format(now)}.xlsx';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);

// Coba buka langsung dengan app yang tersedia
    final result = await OpenFile.open(file.path);
    print('OpenFile result: ${result.type} - ${result.message}');

// Fallback ke share kalau tidak ada app yang bisa buka
    if (result.type != ResultType.done) {
      await Share.shareXFiles(
        [
          XFile(file.path,
              mimeType:
                  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
        ],
        subject: 'Laporan Data Siswa - ${_dateFormat.format(now)}',
      );
    }
  }
}
