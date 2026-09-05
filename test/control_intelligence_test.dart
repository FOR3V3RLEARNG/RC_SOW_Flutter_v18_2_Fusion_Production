import 'package:flutter_test/flutter_test.dart';
import 'package:rc_sow_connected/core/construction_schedule_intelligence.dart';

void main() {
  test('beneficiary GPS parser accepts latitude longitude pairs', () {
    final point = parseBeneficiaryGps('18.4102, -78.1315');
    expect(point, isNotNull);
    expect(point!.latitude, closeTo(18.4102, 0.000001));
    expect(point.longitude, closeTo(-78.1315, 0.000001));
  });

  test('beneficiary GPS parser rejects invalid coordinates', () {
    expect(parseBeneficiaryGps(''), isNull);
    expect(parseBeneficiaryGps('not gps'), isNull);
    expect(parseBeneficiaryGps('100, -78'), isNull);
  });

  test('proximity suggestion honors a valid starting house', () {
    const locations = <ScheduleLocation>[
      ScheduleLocation(code: 'H1', gps: '18.4000, -78.1000'),
      ScheduleLocation(code: 'H2', gps: '18.4010, -78.1010'),
      ScheduleLocation(code: 'H3', gps: '18.4500, -78.1500'),
    ];

    final ordered = suggestProximityOrder(locations, startCode: 'H2');

    expect(ordered.first, 'H2');
    expect(ordered[1], 'H1');
    expect(ordered.toSet(), <String>{'H1', 'H2', 'H3'});
  });

  test('houses without GPS remain available for manual ordering', () {
    const locations = <ScheduleLocation>[
      ScheduleLocation(code: 'H1', gps: '18.4000, -78.1000'),
      ScheduleLocation(code: 'H2', gps: ''),
      ScheduleLocation(code: 'H3', gps: '18.4010, -78.1010'),
    ];

    final ordered = suggestProximityOrder(locations, startCode: 'H1');

    expect(ordered, <String>['H1', 'H3', 'H2']);
  });

  test('distance calculation produces a positive route distance', () {
    final distance = distanceBetweenGps(
      '18.4000, -78.1000',
      '18.4100, -78.1100',
    );
    expect(distance, isNotNull);
    expect(distance!, greaterThan(0));
  });
}
