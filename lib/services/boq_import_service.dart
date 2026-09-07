import 'package:excel/excel.dart';

class BoqImportResult {
  const BoqImportResult({
    required this.items,
    required this.sheetName,
    required this.headerRow,
  });
  final List<Map<String, dynamic>> items;
  final String sheetName;
  final int headerRow;
}

abstract final class BoqImportService {
  static BoqImportResult parse(List<int> bytes) {
    final workbook = Excel.decodeBytes(bytes);
    if (workbook.tables.isEmpty) {
      throw const FormatException('The BOQ workbook has no worksheets.');
    }

    Sheet? selected;
    String selectedName = '';
    var bestScore = -1;
    for (final entry in workbook.tables.entries) {
      var score = 0;
      for (final row in entry.value.rows.take(12)) {
        final line = row.map(_cell).join(' | ').toLowerCase();
        if (line.contains('description')) score += 4;
        if (line.contains('material')) score += 3;
        if (line.contains('quantity') || line.contains('qty')) score += 4;
        if (line.contains('unit')) score += 2;
      }
      if (score > bestScore) {
        selected = entry.value;
        selectedName = entry.key;
        bestScore = score;
      }
    }

    final rows = selected!.rows;
    if (rows.isEmpty) throw const FormatException('The BOQ sheet is empty.');

    var headerIndex = 0;
    var headerScore = -1;
    for (var i = 0; i < rows.length && i < 18; i++) {
      final cells = rows[i].map(_cell).map((v) => v.toLowerCase()).toList();
      var score = 0;
      for (final cell in cells) {
        if (cell.contains('description')) score += 4;
        if (cell.contains('material') || cell == 'item') score += 3;
        if (cell.contains('quantity') || cell.contains('qty')) score += 4;
        if (cell.contains('unit')) score += 2;
        if (cell.contains('size')) score += 1;
        if (cell.contains('length')) score += 1;
      }
      if (score > headerScore) {
        headerScore = score;
        headerIndex = i;
      }
    }

    final headers = rows[headerIndex]
        .map(_cell)
        .map((v) => v.trim().toLowerCase())
        .toList();

    int col(List<String> names) {
      for (var i = 0; i < headers.length; i++) {
        for (final name in names) {
          if (headers[i] == name || headers[i].contains(name)) return i;
        }
      }
      return -1;
    }

    final codeCol = col(['item code', 'code', 'item no', 'item #']);
    final descCol = col([
      'description',
      'material',
      'item description',
      'item',
    ]);
    final unitCol = col(['unit']);
    final qtyCol = col(['quantity', 'qty', 'boq qty', 'boq quantity']);
    final sizeCol = col(['size']);
    final lengthCol = col(['length']);
    final categoryCol = col(['category', 'section', 'trade']);
    if (descCol < 0) {
      throw const FormatException(
        'Could not identify a material/description column.',
      );
    }

    String value(List<Data?> row, int i) =>
        i >= 0 && i < row.length ? _cell(row[i]).trim() : '';

    final items = <Map<String, dynamic>>[];
    for (var i = headerIndex + 1; i < rows.length; i++) {
      final row = rows[i];
      final description = value(row, descCol);
      if (description.isEmpty) continue;
      final q = value(row, qtyCol).replaceAll(',', '');
      final match = RegExp(r'-?\d+(?:\.\d+)?').firstMatch(q);
      items.add({
        'itemCode': value(row, codeCol),
        'description': description,
        'category': value(row, categoryCol),
        'unit': value(row, unitCol),
        'size': value(row, sizeCol),
        'length': value(row, lengthCol),
        'boqQuantity': double.tryParse(match?.group(0) ?? '') ?? 0,
      });
    }
    if (items.isEmpty)
      throw const FormatException('No BOQ material rows were found.');
    return BoqImportResult(
      items: items,
      sheetName: selectedName,
      headerRow: headerIndex + 1,
    );
  }

  static String _cell(Data? cell) => cell?.value?.toString() ?? '';
}
