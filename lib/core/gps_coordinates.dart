class RcGpsPoint {
  const RcGpsPoint(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  bool get isValid =>
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;

  String get searchUrl =>
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';

  String get directionsUrl =>
      'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude';
}

RcGpsPoint? rcGpsPoint(double? latitude, double? longitude) {
  if (latitude == null || longitude == null) return null;

  var lat = latitude;
  var lon = longitude;

  if (lat.abs() > 90 && lon.abs() <= 90) {
    final swap = lat;
    lat = lon;
    lon = swap;
  }

  final point = RcGpsPoint(lat, lon);
  return point.isValid ? point : null;
}

RcGpsPoint? rcParseGpsPoint(Object? raw) {
  final text = '${raw ?? ''}'.trim();
  if (text.isEmpty) return null;

  final urlPair = RegExp(
    r'(?:query=|destination=|@)\s*([-+]?\d{1,2}(?:\.\d+)?)\s*[,;]\s*([-+]?\d{1,3}(?:\.\d+)?)',
    caseSensitive: false,
  ).firstMatch(text);

  if (urlPair != null) {
    return rcGpsPoint(
      double.tryParse(urlPair.group(1)!),
      double.tryParse(urlPair.group(2)!),
    );
  }

  final pair = RegExp(
    r'([-+]?\d{1,2}(?:\.\d+)?)\s*°?\s*([NS])?\s*[,;/]\s*([-+]?\d{1,3}(?:\.\d+)?)\s*°?\s*([EW])?',
    caseSensitive: false,
  ).firstMatch(text);

  if (pair != null) {
    var lat = double.tryParse(pair.group(1)!);
    var lon = double.tryParse(pair.group(3)!);
    if (lat == null || lon == null) return null;

    final northSouth = pair.group(2)?.toUpperCase();
    final eastWest = pair.group(4)?.toUpperCase();

    if (northSouth == 'S') lat = -lat.abs();
    if (northSouth == 'N') lat = lat.abs();
    if (eastWest == 'W') lon = -lon.abs();
    if (eastWest == 'E') lon = lon.abs();

    return rcGpsPoint(lat, lon);
  }

  final spacedHemisphere = RegExp(
    r'([-+]?\d{1,2}(?:\.\d+)?)\s*°?\s*([NS])\s+([-+]?\d{1,3}(?:\.\d+)?)\s*°?\s*([EW])',
    caseSensitive: false,
  ).firstMatch(text);

  if (spacedHemisphere != null) {
    var lat = double.tryParse(spacedHemisphere.group(1)!);
    var lon = double.tryParse(spacedHemisphere.group(3)!);
    if (lat == null || lon == null) return null;

    if (spacedHemisphere.group(2)!.toUpperCase() == 'S') {
      lat = -lat.abs();
    }
    if (spacedHemisphere.group(4)!.toUpperCase() == 'W') {
      lon = -lon.abs();
    }

    return rcGpsPoint(lat, lon);
  }

  final signedSpacePair = RegExp(
    r'([-+]?\d{1,2}(?:\.\d+)?)\s+([-+]?\d{1,3}(?:\.\d+)?)',
  ).firstMatch(text);

  if (signedSpacePair != null) {
    return rcGpsPoint(
      double.tryParse(signedSpacePair.group(1)!),
      double.tryParse(signedSpacePair.group(2)!),
    );
  }

  return null;
}
