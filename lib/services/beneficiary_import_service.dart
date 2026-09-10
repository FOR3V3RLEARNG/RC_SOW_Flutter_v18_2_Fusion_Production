import 'dart:typed_data';

import 'package:excel/excel.dart';

class BeneficiaryWorkbookImportResult {
  const BeneficiaryWorkbookImportResult({
    required this.rows,
    required this.sheetNames,
    required this.skippedRows,
  });

  final List<Map<String, dynamic>> rows;
  final List<String> sheetNames;
  final int skippedRows;
}

abstract final class BeneficiaryImportService {
  static BeneficiaryWorkbookImportResult parse(
    Uint8List bytes, {
    required String fileName,
    required String fallbackParish,
  }) {
    if (bytes.isEmpty) {
      throw const FormatException('The selected beneficiary workbook is empty.');
    }

    Excel workbook;
    try {
      workbook = Excel.decodeBytes(bytes);
    } catch (_) {
      final extension = _extension(fileName);
      if (extension == 'xls') {
        throw const FormatException(
          'This appears to be a legacy .xls workbook. Save/export it as .xlsx in Excel, Google Sheets or LibreOffice, then import it again.',
        );
      }
      throw const FormatException(
        'The workbook could not be read. Use a valid Excel .xlsx file.',
      );
    }

    if (workbook.tables.isEmpty) {
      throw const FormatException('The workbook has no worksheets.');
    }

    final imported = <Map<String, dynamic>>[];
    final sheets = <String>[];
    var skipped = 0;

    for (final entry in workbook.tables.entries) {
      final sheetName = entry.key.trim();
      final rows = entry.value.rows;
      if (rows.isEmpty) continue;

      final headerIndex = _findHeaderRow(rows);
      if (headerIndex == null) continue;

      final headers = rows[headerIndex]
          .map(_cell)
          .map(_normalizeHeader)
          .toList();

      int column(List<String> aliases) {
        for (var i = 0; i < headers.length; i++) {
          final header = headers[i];
          for (final alias in aliases) {
            if (header == alias ||
                header.contains(alias) ||
                alias.contains(header) && header.length >= 4) {
              return i;
            }
          }
        }
        return -1;
      }

      final houseCol = column(const [
        'house code',
        'housecode',
        'house id',
        'house no',
        'house number',
        'beneficiary code',
        'code',
      ]);
      final beneficiaryCol = column(const [
        'beneficiary name',
        'beneficiary',
        'name of beneficiary',
        'client name',
        'name',
      ]);

      if (houseCol < 0 || beneficiaryCol < 0) continue;

      final parishCol = column(const ['parish']);
      final clusterCol = column(const [
        'community cluster',
        'community',
        'cluster',
        'location',
        'district',
      ]);
      final phoneCol = column(const [
        'telephone',
        'phone number',
        'phone',
        'contact',
        'contact number',
      ]);
      final gpsCol = column(const [
        'gps coordinates',
        'gps coordinate',
        'gps',
        'coordinates',
        'location gps',
        'geolocation',
      ]);
      final latitudeCol = column(const ['latitude', 'lat']);
      final longitudeCol = column(const ['longitude', 'long', 'lng', 'lon']);
      final beneficiaryNoCol = column(const [
        'beneficiary number',
        'beneficiary no',
        'beneficiary id',
      ]);
      final roofLengthCol = column(const [
        'roof length',
        'length of roof',
        'rooflength',
      ]);
      final roofWidthCol = column(const [
        'roof width',
        'width of roof',
        'roofwidth',
      ]);
      final wallHeightCol = column(const [
        'wall height',
        'height of wall',
        'wallheight',
      ]);
      final roofTypeCol = column(const [
        'roof type',
        'type of roof',
        'rooftype',
      ]);

      String value(List<Data?> row, int index) =>
          index >= 0 && index < row.length ? _cell(row[index]).trim() : '';

      var importedFromSheet = 0;
      for (var rowIndex = headerIndex + 1; rowIndex < rows.length; rowIndex++) {
        final row = rows[rowIndex];
        final houseCode = _cleanHouseCode(value(row, houseCol));
        final beneficiary = value(row, beneficiaryCol);

        if (houseCode.isEmpty && beneficiary.isEmpty) continue;
        if (houseCode.isEmpty || beneficiary.isEmpty) {
          skipped++;
          continue;
        }

        final rowParish = value(row, parishCol);
        final gps = value(row, gpsCol);
        final explicitLat = _number(value(row, latitudeCol));
        final explicitLon = _number(value(row, longitudeCol));
        final parsedPoint = _gpsPoint(gps);

        final clusterValue = value(row, clusterCol);
        final cluster = clusterValue.isNotEmpty
            ? clusterValue
            : _sheetAsCluster(sheetName);

        final raw = <String, dynamic>{};
        for (var col = 0; col < row.length; col++) {
          final header = col < headers.length && headers[col].isNotEmpty
              ? headers[col]
              : 'column_${col + 1}';
          final cell = _cell(row[col]).trim();
          if (cell.isNotEmpty) raw[header] = cell;
        }

        final sourcePayload = <String, dynamic>{
          ...raw,
          if (value(row, roofLengthCol).isNotEmpty)
            'roof_length': value(row, roofLengthCol),
          if (value(row, roofWidthCol).isNotEmpty)
            'roof_width': value(row, roofWidthCol),
          if (value(row, wallHeightCol).isNotEmpty)
            'wall_height': value(row, wallHeightCol),
          if (value(row, roofTypeCol).isNotEmpty)
            'roof_type': value(row, roofTypeCol),
          'source_sheet': sheetName,
          'source_file': fileName,
        };

        imported.add({
          'house_code': houseCode,
          'beneficiary_name': beneficiary,
          'parish': rowParish.isEmpty ? fallbackParish : rowParish,
          'cluster': cluster,
          'phone': value(row, phoneCol),
          'gps': gps,
          if ((explicitLat ?? parsedPoint?.$1) != null)
            'latitude': explicitLat ?? parsedPoint?.$1,
          if ((explicitLon ?? parsedPoint?.$2) != null)
            'longitude': explicitLon ?? parsedPoint?.$2,
          'beneficiary_number': value(row, beneficiaryNoCol),
          'source_name': 'Shelter Roof Repair Assessment',
          'source_row': rowIndex + 1,
          'raw': sourcePayload,
        });
        importedFromSheet++;
      }

      if (importedFromSheet > 0) sheets.add(sheetName);
    }

    final deduplicated = <String, Map<String, dynamic>>{};
    for (final row in imported) {
      final code = '${row['house_code'] ?? ''}'.trim().toUpperCase();
      if (code.isEmpty) continue;
      deduplicated[code] = row;
    }

    if (deduplicated.isEmpty) {
      throw const FormatException(
        'No beneficiary rows were found. The workbook needs columns for House Code and Beneficiary Name.',
      );
    }

    return BeneficiaryWorkbookImportResult(
      rows: deduplicated.values.toList(),
      sheetNames: sheets,
      skippedRows: skipped,
    );
  }

  static int? _findHeaderRow(List<List<Data?>> rows) {
    var bestIndex = -1;
    var bestScore = 0;

    for (var i = 0; i < rows.length && i < 25; i++) {
      final headers = rows[i].map(_cell).map(_normalizeHeader).toList();
      var score = 0;

      for (final header in headers) {
        if (header.contains('house') && header.contains('code')) score += 8;
        if (header == 'code') score += 4;
        if (header.contains('beneficiary')) score += 8;
        if (header == 'name') score += 3;
        if (header.contains('community') || header.contains('cluster')) {
          score += 3;
        }
        if (header.contains('gps') || header.contains('coordinate')) {
          score += 3;
        }
        if (header.contains('parish')) score += 2;
        if (header.contains('phone') || header.contains('contact')) score += 1;
      }

      if (score > bestScore) {
        bestScore = score;
        bestIndex = i;
      }
    }

    return bestScore >= 8 ? bestIndex : null;
  }

  static String _cell(Data? cell) => cell?.value?.toString() ?? '';

  static String _normalizeHeader(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[_\-/]+'), ' ')
      .replaceAll(RegExp(r'[^a-z0-9 ]+'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static String _cleanHouseCode(String value) {
    final cleaned = value
        .trim()
        .toUpperCase()
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(RegExp(r'\.0$'), '');
    return cleaned;
  }

  static String _sheetAsCluster(String name) {
    final normalized = name.trim();
    if (normalized.isEmpty) return '';
    final lower = normalized.toLowerCase();
    if (const {
      'sheet1',
      'sheet 1',
      'data',
      'beneficiary',
      'beneficiaries',
      'shelter',
    }.contains(lower)) {
      return '';
    }
    return normalized;
  }

  static double? _number(String value) {
    if (value.trim().isEmpty) return null;
    final match = RegExp(r'-?\d+(?:\.\d+)?').firstMatch(
      value.replaceAll(',', ''),
    );
    return double.tryParse(match?.group(0) ?? '');
  }

  static (double, double)? _gpsPoint(String value) {
    final matches = RegExp(r'-?\d+(?:\.\d+)?')
        .allMatches(value)
        .map((match) => double.tryParse(match.group(0)!))
        .whereType<double>()
        .toList();
    if (matches.length < 2) return null;

    final lat = matches[0];
    final lon = matches[1];
    if (lat < -90 || lat > 90 || lon < -180 || lon > 180) return null;
    return (lat, lon);
  }

  static String _extension(String fileName) {
    final name = fileName.toLowerCase().trim();
    final dot = name.lastIndexOf('.');
    return dot < 0 ? '' : name.substring(dot + 1);
  }
}
