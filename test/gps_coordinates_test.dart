import 'package:flutter_test/flutter_test.dart';
import 'package:rc_sow_flutter/core/gps_coordinates.dart';

void main() {
  test('parses beneficiary decimal GPS pair', () {
    final point = rcParseGpsPoint('18.409876, -78.132456');

    expect(point, isNotNull);
    expect(point!.latitude, closeTo(18.409876, 0.000001));
    expect(point.longitude, closeTo(-78.132456, 0.000001));
  });

  test('parses Google Maps query coordinates', () {
    final point = rcParseGpsPoint(
      'https://www.google.com/maps/search/?api=1&query=18.4,-78.1',
    );

    expect(point, isNotNull);
    expect(point!.latitude, closeTo(18.4, 0.000001));
    expect(point.longitude, closeTo(-78.1, 0.000001));
  });

  test('applies N and W hemisphere markers', () {
    final point = rcParseGpsPoint('18.4 N, 78.1 W');

    expect(point, isNotNull);
    expect(point!.latitude, greaterThan(0));
    expect(point.longitude, lessThan(0));
  });

  test('rejects non-coordinate GPS text', () {
    expect(rcParseGpsPoint('GPS not recorded'), isNull);
  });
}
