import 'package:excel/excel.dart';

class ShelterImportResult {
  const ShelterImportResult({
    required this.rows,
    required this.sheetName,
    required this.headerRow,
    required this.sourceColumnCount,
  });
  final List<Map<String, dynamic>> rows;
  final String sheetName;
  final int headerRow;
  final int sourceColumnCount;
}

abstract final class ShelterImportService {
  static ShelterImportResult parse({
    required List<int> bytes,
    required String sourceName,
    required String fallbackParish,
  }) {
    final workbook = Excel.decodeBytes(bytes);
    if (workbook.tables.isEmpty) {
      throw const FormatException('The workbook has no worksheets.');
    }

    Sheet? selected;
    String selectedName = '';
    int bestScore = -1;
    for (final entry in workbook.tables.entries) {
      final table = entry.value;
      var score = 0;
      for (final row in table.rows.take(12)) {
        final line = row.map(_cellText).join(' | ').toLowerCase();
        if (line.contains('parish')) score += 3;
        if (line.contains('first name')) score += 2;
        if (line.contains('gps')) score += 2;
        if (line.contains('community')) score += 2;
        if (line.contains('roof')) score += 1;
      }
      if (score > bestScore) {
        selected = table;
        selectedName = entry.key;
        bestScore = score;
      }
    }
    final table = selected!;
    final rows = table.rows;
    if (rows.isEmpty) {
      throw const FormatException('The selected worksheet is empty.');
    }

    var headerIndex = 0;
    var headerScore = -1;
    for (var i = 0; i < rows.length && i < 15; i++) {
      final texts = rows[i].map(_cellText).map((x) => x.toLowerCase()).toList();
      var score = 0;
      for (final text in texts) {
        if (text.contains('parish')) score += 3;
        if (text.contains('community')) score += 2;
        if (text.contains('gps')) score += 2;
        if (text.contains('first name')) score += 2;
        if (text.contains('beneficiary')) score += 1;
      }
      if (score > headerScore) {
        headerScore = score;
        headerIndex = i;
      }
    }

    final rawHeaders = rows[headerIndex].map(_cellText).toList();
    final headers = <String>[];
    final duplicates = <String, int>{};
    for (var i = 0; i < rawHeaders.length; i++) {
      var header = rawHeaders[i].trim();
      if (header.isEmpty) header = 'column_${i + 1}';
      final seen = duplicates[header] ?? 0;
      duplicates[header] = seen + 1;
      if (seen > 0) header = '${header}_${seen + 1}';
      headers.add(header);
    }

    final maps = <Map<String, dynamic>>[];
    for (var rowIndex = headerIndex + 1; rowIndex < rows.length; rowIndex++) {
      final row = rows[rowIndex];
      if (row.every((cell) => _cellText(cell).trim().isEmpty)) continue;
      final raw = <String, dynamic>{};
      for (var c = 0; c < headers.length; c++) {
        final value = c < row.length ? _cellText(row[c]).trim() : '';
        if (value.isNotEmpty) raw[headers[c]] = value;
      }
      if (raw.isEmpty) continue;

      final houseCode = _houseCode(row, raw);
      final first = _find(raw, ['first name', 'firstname']);
      final middle = _find(raw, ['middle name', 'middlename']);
      final last = _find(raw, ['last name', 'lastname', 'surname']);
      var name = [
        first,
        middle,
        last,
      ].where((x) => x.isNotEmpty).join(' ').trim();
      if (name.isEmpty) {
        name = _find(raw, [
          'beneficiary name',
          'name of beneficiary',
          'full name',
        ]);
      }
      final parish = _find(raw, ['parish']).isEmpty
          ? fallbackParish
          : _find(raw, ['parish']);
      final community = _find(raw, ['community', 'village', 'cluster']);
      final gps = _find(raw, ['gps', 'gis']);
      final latitude = _number(_find(raw, ['latitude', 'lat']));
      final longitude = _number(_find(raw, ['longitude', 'long', 'lng']));
      final phone = _find(raw, ['phone', 'mobile', 'contact number']);

      if (houseCode.isEmpty || name.isEmpty) continue;
      maps.add({
        'house_code': houseCode.toUpperCase(),
        'beneficiary_name': name,
        'parish': parish,
        'cluster': community,
        'phone': phone,
        'gps': gps,
        'latitude': latitude,
        'longitude': longitude,
        'source_name': sourceName,
        'source_row': rowIndex + 1,
        'raw': raw,
        'roof_type': _find(raw, ['roof type', 'type of roof']),
        'roof_length': _number(
          _find(raw, ['roof length', 'length of roof', 'length']),
        ),
        'roof_width': _number(
          _find(raw, ['roof width', 'width of roof', 'width']),
        ),
        'wall_height': _number(_find(raw, ['wall height', 'height of wall'])),
        'building_type': _find(raw, ['building type', 'structure type']),
        'damage_extent': _find(raw, ['extent of damage', 'damage']),
      });
    }

    return ShelterImportResult(
      rows: maps,
      sheetName: selectedName,
      headerRow: headerIndex + 1,
      sourceColumnCount: headers.length,
    );
  }

  static String _cellText(Data? cell) => cell?.value?.toString() ?? '';

  static String _find(Map<String, dynamic> raw, List<String> needles) {
    for (final needle in needles) {
      for (final entry in raw.entries) {
        if (entry.key.toLowerCase().contains(needle)) {
          final value = '${entry.value}'.trim();
          if (value.isNotEmpty) return value;
        }
      }
    }
    return '';
  }

  static String _houseCode(List<Data?> row, Map<String, dynamic> raw) {
    final byHeader = _find(raw, [
      'house code',
      'house number',
      'beneficiary code',
      'beneficiary id',
    ]);
    if (RegExp(
      r'^[A-Za-z]{1,5}[A-Za-z0-9-]*\d+[A-Za-z0-9-]*$',
    ).hasMatch(byHeader.replaceAll(' ', ''))) {
      return byHeader.replaceAll(' ', '');
    }
    for (var i = 0; i < row.length; i++) {
      final value = _cellText(row[i]).trim().replaceAll(' ', '');
      if (RegExp(
            r'^[A-Za-z]{1,5}[A-Za-z0-9-]*\d+[A-Za-z0-9-]*$',
          ).hasMatch(value) &&
          value.length <= 16) {
        return value;
      }
    }
    return '';
  }

  static double? _number(String value) {
    if (value.trim().isEmpty) return null;
    final match = RegExp(
      r'-?\d+(?:\.\d+)?',
    ).firstMatch(value.replaceAll(',', ''));
    return match == null ? null : double.tryParse(match.group(0)!);
  }
}
