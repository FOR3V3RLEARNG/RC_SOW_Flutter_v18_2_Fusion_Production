import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../models/app_models.dart';

abstract final class RcExportService {
  static Future<void> shareRecordPdf({
    required String title,
    required Map<String, dynamic> data,
    Uint8List? signature,
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (_) => [
          pw.Text('JAMAICA RED CROSS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
          pw.SizedBox(height: 8),
          pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 22)),
          pw.SizedBox(height: 18),
          pw.TableHelper.fromTextArray(
            headers: const ['Field', 'Value'],
            data: data.entries
                .where((entry) => entry.value != null && '${entry.value}'.trim().isNotEmpty)
                .map((entry) => [entry.key, _display(entry.value)])
                .toList(),
          ),
          if (signature != null) ...[
            pw.SizedBox(height: 18),
            pw.Text('Digital signature', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Image(pw.MemoryImage(signature), height: 80),
          ],
        ],
      ),
    );
    await Printing.sharePdf(bytes: await doc.save(), filename: '${_safe(title)}.pdf');
  }

  static Future<void> shareRecordXlsx({required String title, required Map<String, dynamic> data}) async {
    final excel = Excel.createExcel();
    final sheet = excel['Record'];
    sheet.appendRow([TextCellValue(title)]);
    sheet.appendRow([TextCellValue('Field'), TextCellValue('Value')]);
    for (final entry in data.entries) {
      sheet.appendRow([TextCellValue(entry.key), TextCellValue(_display(entry.value))]);
    }
    final bytes = excel.encode();
    if (bytes == null) throw StateError('Could not create Excel export.');
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${_safe(title)}.xlsx');
    await file.writeAsBytes(bytes, flush: true);
    await SharePlus.instance.share(
      ShareParams(
        text: title,
        files: [XFile(file.path, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
      ),
    );
  }

  static Future<void> shareProductionTable({required String title, required List<ProductionRecord> records}) async {
    final excel = Excel.createExcel();
    final sheet = excel['Production'];
    sheet.appendRow([
      TextCellValue('House'),
      TextCellValue('Parish'),
      TextCellValue('Record'),
      TextCellValue('Status'),
      TextCellValue('Updated'),
      TextCellValue('Summary'),
    ]);
    for (final record in records) {
      sheet.appendRow([
        TextCellValue(record.houseCode),
        TextCellValue(record.parish),
        TextCellValue(record.title),
        TextCellValue(record.status),
        TextCellValue(record.updatedAt.toIso8601String()),
        TextCellValue(record.summary),
      ]);
    }
    final bytes = excel.encode();
    if (bytes == null) throw StateError('Could not create Excel export.');
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${_safe(title)}.xlsx');
    await file.writeAsBytes(bytes, flush: true);
    await SharePlus.instance.share(ShareParams(text: title, files: [XFile(file.path)]));
  }

  static String _display(Object? value) {
    if (value is List) return value.map(_display).join('\n');
    if (value is Map) return value.entries.map((e) => '${e.key}: ${_display(e.value)}').join('\n');
    return '${value ?? ''}';
  }

  static String _safe(String value) => value.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
}
