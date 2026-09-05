import 'dart:math' as math;

class GeoPoint {
  const GeoPoint({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

class ScheduleLocation {
  const ScheduleLocation({
    required this.code,
    required this.gps,
  });

  final String code;
  final String gps;
}

GeoPoint? parseBeneficiaryGps(String raw) {
  final cleaned = raw.trim();
  if (cleaned.isEmpty) return null;

  final parts = cleaned
      .replaceAll(';', ',')
      .split(',')
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList();

  if (parts.length < 2) return null;

  final latitude = double.tryParse(parts[0]);
  final longitude = double.tryParse(parts[1]);
  if (latitude == null || longitude == null) return null;
  if (latitude < -90 || latitude > 90) return null;
  if (longitude < -180 || longitude > 180) return null;

  return GeoPoint(latitude: latitude, longitude: longitude);
}

double geoDistanceKm(GeoPoint a, GeoPoint b) {
  const earthRadiusKm = 6371.0088;
  final lat1 = _radians(a.latitude);
  final lat2 = _radians(b.latitude);
  final deltaLat = _radians(b.latitude - a.latitude);
  final deltaLon = _radians(b.longitude - a.longitude);

  final rawH = math.pow(math.sin(deltaLat / 2), 2) +
      math.cos(lat1) *
          math.cos(lat2) *
          math.pow(math.sin(deltaLon / 2), 2);
  final h = rawH.toDouble().clamp(0.0, 1.0);
  final arc = 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
  return earthRadiusKm * arc;
}

List<String> suggestProximityOrder(
  List<ScheduleLocation> locations, {
  String? startCode,
}) {
  if (locations.length <= 1) {
    return locations.map((item) => item.code).toList();
  }

  final points = <String, GeoPoint>{};
  final missing = <String>[];

  for (final location in locations) {
    final point = parseBeneficiaryGps(location.gps);
    if (point == null) {
      missing.add(location.code);
    } else {
      points[location.code] = point;
    }
  }

  if (points.isEmpty) {
    return locations.map((item) => item.code).toList();
  }

  final remaining = points.keys.toSet();
  final first = startCode != null && remaining.contains(startCode)
      ? startCode
      : points.keys.first;

  final ordered = <String>[first];
  remaining.remove(first);

  while (remaining.isNotEmpty) {
    final currentPoint = points[ordered.last]!;
    String? nearest;
    var nearestDistance = double.infinity;

    for (final candidate in remaining) {
      final distance = geoDistanceKm(currentPoint, points[candidate]!);
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearest = candidate;
      }
    }

    ordered.add(nearest!);
    remaining.remove(nearest);
  }

  ordered.addAll(missing);
  return ordered;
}

double? distanceBetweenGps(String fromGps, String toGps) {
  final from = parseBeneficiaryGps(fromGps);
  final to = parseBeneficiaryGps(toGps);
  if (from == null || to == null) return null;
  return geoDistanceKm(from, to);
}

double _radians(double value) => value * math.pi / 180;
