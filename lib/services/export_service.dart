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
import 'firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ExportService {
  static final _dateFormat = DateFormat('dd MMM yyyy', 'id_ID');
  static final _fileDate = DateFormat('yyyyMMdd_HHmmss');

  static const _namaSekolah = 'SD NEGERI MUSTIKAJAYA VII';
  static const _namaInstansi = 'PEMERINTAH KOTA BEKASI\nDINAS PENDIDIKAN';
  static const _alamat =
      'Perum. Mutiara Gading Timur Blok N 10 RT.11/29 Kel. Mustikajaya Kec. Mustika Jaya – Kota Bekasi';
  static const _email = 'sdnmustikajaya7@gmail.com';
  static const _npsn = '20253870(contoh)';
  static const _namaKepala = 'GIYARTI, M.Pd(contoh)';
  static const _nipKepala = 'NIP. 19740201 200801 2 005(contoh)';
  static const _kotaTanggal = 'Bekasi';

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

  static Future<void> exportUsersPdf(BuildContext context,
      {String? kelas}) async {
    final allUsers = await AdminService.getAllUsers();

    // TAMBAHKAN: Filter berdasarkan kelas
    final users = (kelas == null || kelas == 'Semua Kelas')
        ? allUsers
        : allUsers.where((u) => u.kelas == kelas).toList();

    final now = DateTime.now();
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        header: (ctx) => _buildPdfHeader(ctx, now),
        // ← satu footer saja, TTD hanya di halaman terakhir
        footer: (ctx) {
          final isLastPage = ctx.pageNumber == ctx.pagesCount;
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              if (isLastPage) ...[
                pw.SizedBox(height: 24),
                _buildTtd(now),
                pw.SizedBox(height: 8),
              ],
              pw.Divider(color: PdfColors.grey300),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('$_namaSekolah - Laporan Admin',
                      style: const pw.TextStyle(
                          fontSize: 8, color: PdfColors.grey)),
                  pw.Text('Halaman ${ctx.pageNumber} dari ${ctx.pagesCount}',
                      style: const pw.TextStyle(
                          fontSize: 8, color: PdfColors.grey)),
                ],
              ),
            ],
          );
        },
        build: (ctx) => [
          pw.Text(
              kelas == null || kelas == 'Semua Kelas'
                  ? 'Data Seluruh Siswa'
                  : 'Data Siswa - Kelas $kelas',
              style:
                  pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          _buildUsersTable(users),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Laporan_Siswa_${_fileDate.format(now)}.pdf',
    );
  }

  // ── Kop Surat PDF ──
  static pw.Widget _buildPdfHeader(pw.Context ctx, DateTime now) {
    return pw.Column(
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Container(
              width: 56,
              height: 56,
              decoration: pw.BoxDecoration(
                shape: pw.BoxShape.circle,
                border: pw.Border.all(color: PdfColors.black, width: 2),
              ),
              child: pw.Center(
                child: pw.Text('🏫', style: const pw.TextStyle(fontSize: 22)),
              ),
            ),
            pw.SizedBox(width: 12),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    _namaInstansi,
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                        fontSize: 11, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    _namaSekolah,
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                        fontSize: 14, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    _alamat,
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(
                        fontSize: 8, color: PdfColors.grey700),
                  ),
                  pw.Text(
                    'E-mail: $_email     NPSN: $_npsn',
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(
                        fontSize: 8, color: PdfColors.grey700),
                  ),
                ],
              ),
            ),
            pw.SizedBox(width: 56),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Container(height: 3, color: PdfColors.black),
        pw.SizedBox(height: 1),
        pw.Container(height: 1, color: PdfColors.black),
        pw.SizedBox(height: 10),
        pw.Center(
          child: pw.Text(
            'LAPORAN DATA SISWA',
            style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                decoration: pw.TextDecoration.underline),
          ),
        ),
        pw.SizedBox(height: 10),
      ],
    );
  }

  // ── Tabel Siswa ──
  static pw.Widget _buildUsersTable(List<UserModel> users) {
    const headers = [
      'No',
      'NISN',
      'Nama Siswa',
      'Kelas',
      'Level',
      'Total Poin',
      'Streak',
      'Matematika',
      'B.Indo',
      'IPA',
      'IPS',
      'Nilai Rata-rata',
    ];

    final rows = users.asMap().entries.map((e) {
      final i = e.key;
      final u = e.value;

      final allPoints = [
        u.subjectProgress['matematika'] ?? 0,
        u.subjectProgress['bahasa'] ?? 0,
        u.subjectProgress['ipa'] ?? 0,
        u.subjectProgress['ips'] ?? 0,
      ].where((p) => p > 0).toList();

      final rataRata = allPoints.isEmpty
          ? 0
          : (allPoints.reduce((a, b) => a + b) / allPoints.length).round();

      return [
        '${i + 1}',
        u.nisn ?? '-',
        u.username,
        u.kelas != null && u.kelas!.isNotEmpty ? u.kelas! : '-',
        '${u.level}',
        '${u.totalPoints}',
        '${u.streakDays}',
        '${u.subjectProgress['matematika'] ?? 0}',
        '${u.subjectProgress['bahasa'] ?? 0}',
        '${u.subjectProgress['ipa'] ?? 0}',
        '${u.subjectProgress['ips'] ?? 0}',
        '$rataRata',
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      headerStyle: pw.TextStyle(
          fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.white),
      headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#6C63FF')),
      cellStyle: const pw.TextStyle(fontSize: 8),
      rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
      oddRowDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#F8F7FF')),
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(20),
        1: const pw.FixedColumnWidth(68),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FixedColumnWidth(34),
        4: const pw.FixedColumnWidth(28),
        5: const pw.FixedColumnWidth(46),
        6: const pw.FixedColumnWidth(34),
        7: const pw.FixedColumnWidth(48),
        8: const pw.FixedColumnWidth(40),
        9: const pw.FixedColumnWidth(28),
        10: const pw.FixedColumnWidth(28),
        11: const pw.FixedColumnWidth(50),
      },
    );
  }

  // ── TTD ──
  static pw.Widget _buildTtd(DateTime now) {
    final tanggal =
        '$_kotaTanggal, ${DateFormat('dd MMMM yyyy', 'id_ID').format(now)}';

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(tanggal, style: const pw.TextStyle(fontSize: 10)),
            pw.Text('Kepala Sekolah $_namaSekolah',
                style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 50),
            pw.Text(
              _namaKepala,
              style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  decoration: pw.TextDecoration.underline),
            ),
            pw.Text(_nipKepala, style: const pw.TextStyle(fontSize: 9)),
          ],
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════
  // EXPORT PDF Real Time
  // ═══════════════════════════════════════════

  static Future<void> exportRealtimePdf(
    BuildContext context, {
    required DateTime startDate,
    required DateTime endDate,
    String? kelas,
  }) async {
    var results = await FirebaseService.getQuizResultsByDate(
      startDate: startDate,
      endDate: endDate,
    );
    // Filter by kelas kalau bukan Semua Kelas
    if (kelas != null && kelas != 'Semua Kelas') {
      results = results.where((r) => r['kelas'] == kelas).toList();
    }

    if (results.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Tidak ada data pada rentang tanggal ini')),
      );
      return;
    }

    final now = DateTime.now();
    final pdf = pw.Document();
    final dateRange =
        '${_dateFormat.format(startDate)} - ${_dateFormat.format(endDate)}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        header: (ctx) => _buildPdfHeader(ctx, now),
        footer: (ctx) {
          final isLastPage = ctx.pageNumber == ctx.pagesCount;
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              if (isLastPage) ...[
                pw.SizedBox(height: 24),
                _buildTtd(now),
                pw.SizedBox(height: 8),
              ],
              pw.Divider(color: PdfColors.grey300),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('$_namaSekolah - Laporan Realtime',
                      style: const pw.TextStyle(
                          fontSize: 8, color: PdfColors.grey)),
                  pw.Text('Halaman ${ctx.pageNumber} dari ${ctx.pagesCount}',
                      style: const pw.TextStyle(
                          fontSize: 8, color: PdfColors.grey)),
                ],
              ),
            ],
          );
        },
        build: (ctx) => [
          pw.Text(
              kelas == null || kelas == 'Semua Kelas'
                  ? 'Rekap Hasil Quiz: $dateRange'
                  : 'Rekap Hasil Quiz Kelas $kelas: $dateRange',
              style:
                  pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          _buildRealtimeTable(results),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Laporan_Realtime_${_fileDate.format(now)}.pdf',
    );
  }

  // static pw.Widget _buildRealtimeHeader(
  //     pw.Context ctx, DateTime now, String dateRange) {
  //   return pw.Column(
  //     children: [
  //       // Pakai kop yang sama
  //       ..._buildPdfHeader(ctx, now)
  //           .build(ctx), // tidak bisa langsung, lihat catatan di bawah
  //     ],
  //   );
  // }

  static pw.Widget _buildRealtimeTable(List<Map<String, dynamic>> results) {
    const headers = [
      'No',
      'NISN',
      'Nama Siswa',
      'Kelas',
      'Mata Pelajaran',
      'Benar',
      'Total Soal',
      'Nilai',
      'Poin',
      'Waktu (detik)',
      'Tanggal & Jam',
    ];

    final rows = results.asMap().entries.map((e) {
      final i = e.key;
      final r = e.value;
      final ts = (r['timestamp'] as Timestamp?)?.toDate();
      final waktu =
          ts != null ? DateFormat('dd/MM/yyyy HH:mm', 'id_ID').format(ts) : '-';
      final nilai = r['nilai'] != null
          ? (r['nilai'] as num).toStringAsFixed(0)
          : ((r['correctAnswers'] ?? 0) /
                  (r['totalQuestions'] == 0 ? 1 : r['totalQuestions']) *
                  100)
              .toStringAsFixed(0);

      return [
        '${i + 1}',
        r['nisn'] ?? '-',
        r['username'] ?? '-',
        r['kelas'] ?? '-',
        _subjectLabel(r['subject'] ?? ''),
        '${r['correctAnswers'] ?? 0}',
        '${r['totalQuestions'] ?? 0}',
        '$nilai',
        '${r['score'] ?? 0}',
        '${r['timeTaken'] ?? 0}',
        waktu,
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      headerStyle: pw.TextStyle(
          fontWeight: pw.FontWeight.bold, fontSize: 7, color: PdfColors.white),
      headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#6C63FF')),
      cellStyle: const pw.TextStyle(fontSize: 7),
      rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
      oddRowDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#F8F7FF')),
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(20),
        1: const pw.FixedColumnWidth(60),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FixedColumnWidth(30),
        4: const pw.FixedColumnWidth(60),
        5: const pw.FixedColumnWidth(30),
        6: const pw.FixedColumnWidth(34),
        7: const pw.FixedColumnWidth(30),
        8: const pw.FixedColumnWidth(30),
        9: const pw.FixedColumnWidth(46),
        10: const pw.FixedColumnWidth(70),
      },
    );
  }

  // ═══════════════════════════════════════════
  // EXPORT EXCEL
  // ═══════════════════════════════════════════

  static Future<void> exportUsersExcel(BuildContext context) async {
    final users = await AdminService.getAllUsers();
    final now = DateTime.now();
    final excel = Excel.createExcel();

    // ── Sheet 1: Data Siswa ──
    final sheet1 = excel['Data Siswa'];
    excel.setDefaultSheet('Data Siswa');

    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#6C63FF'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Center,
    );

    // ── Kop surat ──
    sheet1.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value =
        TextCellValue(_namaInstansi.replaceAll('\n', ' '));
    sheet1
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
            .cellStyle =
        CellStyle(bold: true, horizontalAlign: HorizontalAlign.Center);

    sheet1.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1)).value =
        TextCellValue(_namaSekolah);
    sheet1
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1))
        .cellStyle = CellStyle(
      bold: true,
      fontSize: 14,
      horizontalAlign: HorizontalAlign.Center,
    );

    sheet1.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2)).value =
        TextCellValue(_alamat);

    sheet1.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3)).value =
        TextCellValue('Email: $_email   NPSN: $_npsn');

    sheet1.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 5)).value =
        TextCellValue('LAPORAN DATA SISWA');
    sheet1
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 5))
        .cellStyle = CellStyle(
      bold: true,
      underline: Underline.Single,
      horizontalAlign: HorizontalAlign.Center,
    );

    sheet1.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 6)).value =
        TextCellValue('Tanggal Cetak: ${_dateFormat.format(now)}');

    // ── Header tabel mulai row 8 ──
    const headers = [
      'No',
      'NISN',
      'Nama Siswa',
      'Kelas',
      'Level',
      'Total Poin',
      'Streak (Hari)',
      'Matematika',
      'B. Indonesia',
      'IPA',
      'IPS',
      'Badges',
      'Nilai Rata-rata',
      'Tanggal Daftar',
    ];

    const dataStartRow = 8;

    for (var i = 0; i < headers.length; i++) {
      final cell = sheet1.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: dataStartRow));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }

    sheet1.setColumnWidth(0, 6);
    sheet1.setColumnWidth(1, 16);
    sheet1.setColumnWidth(2, 22);
    sheet1.setColumnWidth(3, 10);
    sheet1.setColumnWidth(4, 10);
    sheet1.setColumnWidth(5, 12);
    sheet1.setColumnWidth(6, 14);
    sheet1.setColumnWidth(7, 14);
    sheet1.setColumnWidth(8, 14);
    sheet1.setColumnWidth(9, 10);
    sheet1.setColumnWidth(10, 10);
    sheet1.setColumnWidth(11, 20);
    sheet1.setColumnWidth(12, 18);

    final zebraStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#F3F0FF'),
    );

    // ── Data rows ──
    for (var i = 0; i < users.length; i++) {
      final u = users[i];
      final row = dataStartRow + 1 + i;
      final isZebra = i % 2 == 1;

      void setCell(int col, CellValue val) {
        final cell = sheet1
            .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
        cell.value = val;
        if (isZebra) cell.cellStyle = zebraStyle;
      }

      setCell(0, IntCellValue(i + 1));
      setCell(1, TextCellValue(u.nisn ?? '-'));
      setCell(2, TextCellValue(u.username));
      setCell(
          3,
          TextCellValue(
              u.kelas != null && u.kelas!.isNotEmpty ? u.kelas! : '-'));
      setCell(4, IntCellValue(u.level));
      setCell(5, IntCellValue(u.totalPoints));
      setCell(6, IntCellValue(u.streakDays));
      setCell(7, IntCellValue(u.subjectProgress['matematika'] ?? 0));
      setCell(8, IntCellValue(u.subjectProgress['bahasa'] ?? 0));
      setCell(9, IntCellValue(u.subjectProgress['ipa'] ?? 0));
      setCell(10, IntCellValue(u.subjectProgress['ips'] ?? 0));
      final allPoints = [
        u.subjectProgress['matematika'] ?? 0,
        u.subjectProgress['bahasa'] ?? 0,
        u.subjectProgress['ipa'] ?? 0,
        u.subjectProgress['ips'] ?? 0,
      ].where((p) => p > 0).toList();
      final rataRata = allPoints.isEmpty
          ? 0
          : (allPoints.reduce((a, b) => a + b) / allPoints.length).round();

      setCell(11, IntCellValue(rataRata));
      setCell(12, TextCellValue(u.badges.join(', ')));
      setCell(13, TextCellValue(_dateFormat.format(u.createdAt)));
    }

    // ── TTD (3 baris setelah data terakhir) ──
    final ttdStartRow = dataStartRow + 1 + users.length + 3;
    final tanggal =
        '$_kotaTanggal, ${DateFormat('dd MMMM yyyy', 'id_ID').format(now)}';

    sheet1
        .cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: ttdStartRow))
        .value = TextCellValue(tanggal);

    sheet1
        .cell(CellIndex.indexByColumnRow(
            columnIndex: 9, rowIndex: ttdStartRow + 1))
        .value = TextCellValue('Kepala Sekolah $_namaSekolah');

    sheet1
        .cell(CellIndex.indexByColumnRow(
            columnIndex: 9, rowIndex: ttdStartRow + 5))
        .value = TextCellValue(_namaKepala);
    sheet1
        .cell(CellIndex.indexByColumnRow(
            columnIndex: 9, rowIndex: ttdStartRow + 5))
        .cellStyle = CellStyle(bold: true, underline: Underline.Single);

    sheet1
        .cell(CellIndex.indexByColumnRow(
            columnIndex: 9, rowIndex: ttdStartRow + 6))
        .value = TextCellValue(_nipKepala);

    // ── Sheet 2: Rekap per Mapel ──
    final sheet2 = excel['Rekap Mapel'];
    final subjects = ['matematika', 'bahasa', 'ipa', 'ips'];

    const recapHeaders = [
      'Mata Pelajaran',
      'Rata-rata Poin',
      'Poin Tertinggi',
      'Poin Terendah',
      'Jumlah Aktif',
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
            .value = val;
      }

      setCell2(0, TextCellValue(_subjectLabel(subj)));
      setCell2(1, IntCellValue(avg));
      setCell2(2, IntCellValue(max));
      setCell2(3, IntCellValue(min));
      setCell2(4, IntCellValue(points.length));
    }

    // ── Simpan & buka ──
    final bytes = excel.save()!;
    final dir = await getTemporaryDirectory();
    final fileName = 'Laporan_Siswa_${_fileDate.format(now)}.xlsx';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);

    final result = await OpenFile.open(file.path);

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
