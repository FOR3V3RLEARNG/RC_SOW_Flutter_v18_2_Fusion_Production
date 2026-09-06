import 'package:flutter_test/flutter_test.dart';
import 'package:rc_sow_flutter/core/product_registry.dart';
import 'package:rc_sow_flutter/models/app_models.dart';

UserProfile profile(String role, String parish, Map<String, dynamic> privileges) => UserProfile(
      userId: 'test-$role',
      email: '${role.toLowerCase().replaceAll(' ', '.')}@example.invalid',
      role: role,
      parish: parish,
      approved: true,
      privileges: privileges,
    );

void main() {
  test('crew sees only field-safe production schemas', () {
    final carpenter = profile('Carpenter', 'Hanover', const {
      'viewAssignedHouses': true,
      'editOwnAttendance': true,
      'submitFieldRequests': true,
      'uploadEvidence': true,
    });
    final types = RcProductRegistry.visibleSchemas(carpenter).map((e) => e.eventType).toSet();
    expect(types, RcProductRegistry.crewRecordTypes);
    expect(types.contains('payment'), isFalse);
    expect(types.contains('workProjection'), isFalse);
  });

  test('technical and community input roles remain parish-input focused', () {
    for (final role in ['Technical Admin', 'Community Admin']) {
      final user = profile(role, 'Hanover', const {'exportData': true});
      final types = RcProductRegistry.visibleSchemas(user).map((e) => e.eventType).toSet();
      expect(types, RcProductRegistry.inputRoleRecordTypes);
      expect(RcProductRegistry.experience(user).communityReadOnly, isTrue);
    }
  });

  test('management retains complete production schema visibility', () {
    final regional = profile('Regional Supervisor', 'All Parishes', const {
      'viewAllParishes': true,
      'editControl': true,
    });
    expect(RcProductRegistry.experience(regional).allowedRecordTypes, isEmpty);
    expect(regional.canViewAllParishes, isTrue);
  });
}
