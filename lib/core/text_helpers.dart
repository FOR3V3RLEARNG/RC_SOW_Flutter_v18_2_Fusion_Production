String rcTitleCase(String value) {
  const acronyms = <String, String>{
    'rc': 'RC',
    'sow': 'SOW',
    'boq': 'BOQ',
    'gps': 'GPS',
    'gis': 'GIS',
    'jrc': 'JRC',
    'rcc': 'RCC',
    't1-11': 'T1-11',
  };
  String convert(String token) {
    if (token.isEmpty) return token;
    final lower = token.toLowerCase();
    if (acronyms.containsKey(lower)) return acronyms[lower]!;
    return token
        .split('-')
        .map((part) {
          if (part.isEmpty) return part;
          final p = part.toLowerCase();
          if (acronyms.containsKey(p)) return acronyms[p]!;
          return '${p[0].toUpperCase()}${p.substring(1)}';
        })
        .join('-');
  }

  return value
      .trim()
      .split(RegExp(r'\s+'))
      .where((x) => x.isNotEmpty)
      .map(convert)
      .join(' ');
}
