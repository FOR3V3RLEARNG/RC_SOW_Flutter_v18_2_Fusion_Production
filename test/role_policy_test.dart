import 'package:flutter_test/flutter_test.dart';
import 'package:rc_sow_flutter/models/app_models.dart';

UserProfile p(String role, Map<String, dynamic> privileges) => UserProfile(
  userId: '1', email: 'x@example.com', role: role, parish: 'All Parishes', approved: true, privileges: privileges,
);

void main() {
  test('Admin Dashboard is Admin-only even if a non-admin payload is stale', () {
    expect(p('Admin', {'viewAdmin': true}).canViewAdmin, isTrue);
    expect(p('Regional Supervisor', {'viewAdmin': true, 'viewAllParishes': true}).canViewAdmin, isFalse);
    expect(p('Construction Specialist', {'viewAdmin': true, 'viewAllParishes': true}).canViewAdmin, isFalse);
  });

  test('Regional Supervisor and Construction Specialist can retain all-parish view', () {
    expect(p('Regional Supervisor', {'viewAllParishes': true}).canViewAllParishes, isTrue);
    expect(p('Construction Specialist', {'viewAllParishes': true}).canViewAllParishes, isTrue);
  });
  test('Site Supervisor production edit follows Admin-managed privilege', () {
    expect(p('Site Supervisor', {'editControl': true}).canEditProduction, isTrue);
    expect(p('Site Supervisor', {'editControl': false}).canEditProduction, isFalse);
  });

  test('Community publishing is Admin-only and privilege controlled', () {
    expect(p('Admin', {'manageCommunity': true}).canCreateCommunityEvent, isTrue);
    expect(p('Admin', {'manageCommunity': false}).canCreateCommunityEvent, isFalse);
    expect(p('Regional Supervisor', {'manageCommunity': true}).canCreateCommunityEvent, isFalse);
    expect(p('Site Supervisor', {'manageCommunity': true}).canCreateCommunityEvent, isFalse);
  });
}
