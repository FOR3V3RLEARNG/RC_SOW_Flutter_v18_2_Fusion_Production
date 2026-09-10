import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:excel/excel.dart';

class AgreementImportResult {
  const AgreementImportResult({
    required this.text,
    required this.sourceType,
    required this.automaticExtraction,
  });

  final String text;
  final String sourceType;
  final bool automaticExtraction;
}

class AgreementImportService {
  const AgreementImportService._();

  static AgreementImportResult parse(Uint8List bytes, String fileName) {
    final extension = _extension(fileName);

    return switch (extension) {
      'xlsx' => AgreementImportResult(
        text: _xlsx(bytes),
        sourceType: 'Excel XLSX',
        automaticExtraction: true,
      ),
      'docx' => AgreementImportResult(
        text: _docx(bytes),
        sourceType: 'Word DOCX',
        automaticExtraction: true,
      ),
      'txt' || 'md' || 'csv' => AgreementImportResult(
        text: _plain(bytes),
        sourceType: extension.toUpperCase(),
        automaticExtraction: true,
      ),
      'rtf' => AgreementImportResult(
        text: _rtf(bytes),
        sourceType: 'RTF',
        automaticExtraction: true,
      ),
      _ => AgreementImportResult(
        text: '',
        sourceType: extension.isEmpty ? 'Document' : extension.toUpperCase(),
        automaticExtraction: false,
      ),
    };
  }

  static String _extension(String name) {
    final dot = name.lastIndexOf('.');
    if (dot < 0 || dot == name.length - 1) return '';
    return name.substring(dot + 1).trim().toLowerCase();
  }

  static String _plain(Uint8List bytes) =>
      utf8.decode(bytes, allowMalformed: true).trim();

  static String _xlsx(Uint8List bytes) {
    final workbook = Excel.decodeBytes(bytes);
    final sections = <String>[];

    for (final entry in workbook.tables.entries) {
      final lines = <String>[];
      for (final row in entry.value.rows) {
        final values = row
            .map((cell) => cell?.value?.toString().trim() ?? '')
            .where((value) => value.isNotEmpty)
            .toList();
        if (values.isNotEmpty) lines.add(values.join(' '));
      }
      if (lines.isNotEmpty) {
        if (workbook.tables.length > 1) {
          sections.add('[${entry.key}]\n${lines.join('\n')}');
        } else {
          sections.add(lines.join('\n'));
        }
      }
    }

    final result = sections.join('\n\n').trim();
    if (result.isEmpty) {
      throw const FormatException('No agreement text was found in the Excel file.');
    }
    return result;
  }

  static String _docx(Uint8List bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);
    ArchiveFile? document;
    for (final file in archive.files) {
      if (file.name == 'word/document.xml') {
        document = file;
        break;
      }
    }
    if (document == null) {
      throw const FormatException('This DOCX does not contain word/document.xml.');
    }

    final raw = document.content;
    final data = raw is Uint8List
        ? raw
        : Uint8List.fromList(List<int>.from(raw as List));
    var xml = utf8.decode(data, allowMalformed: true);

    xml = xml
        .replaceAll(RegExp(r'</w:p>'), '\n')
        .replaceAll(RegExp(r'<w:tab[^>]*/>'), '\t')
        .replaceAll(RegExp(r'<w:br[^>]*/>'), '\n')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'");

    final result = _cleanLines(xml);
    if (result.isEmpty) {
      throw const FormatException('No readable agreement text was found in the DOCX.');
    }
    return result;
  }

  static String _rtf(Uint8List bytes) {
    var text = latin1.decode(bytes, allowInvalid: true);
    text = text
        .replaceAll(RegExp(r'\\par[d]?\s*'), '\n')
        .replaceAll(RegExp(r'\\tab\s*'), '\t')
        .replaceAll(RegExp(r"\\'[0-9a-fA-F]{2}"), ' ')
        .replaceAll(RegExp(r'\\[a-zA-Z]+-?\d*\s?'), '')
        .replaceAll(RegExp(r'[{}]'), '');
    return _cleanLines(text);
  }

  static String _cleanLines(String text) => text
      .split('\n')
      .map((line) => line.replaceAll(RegExp(r'\s+'), ' ').trim())
      .where((line) => line.isNotEmpty)
      .join('\n')
      .trim();
}
