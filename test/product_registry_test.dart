import 'package:flutter_test/flutter_test.dart';
import 'package:rc_sow_flutter/core/product_registry.dart';
import 'package:rc_sow_flutter/models/app_models.dart';

UserProfile profile(String role, {String parish = 'Hanover'}) => UserProfile(
      userId: role,
      email: '${role.toLowerCase().replaceAll(' ', '.')}@example.org',
      role: role,
      parish: parish,
      approved: true,
      privileges: const {},
    );

void main() {
  test('crew experience exposes only field-owned production forms', () {
    final experience = RcProductRegistry.experience(profile('Carpenter'));
    expect(experience.allowedRecordTypes, contains('crewAttendance'));
    expect(experience.allowedRecordTypes, contains('materialRequest'));
    expect(experience.allowedRecordTypes, isNot(contains('payment')));
    expect(experience.showPaymentDue, isFalse);
  });

  test('technical and community input roles remain parish/input focused', () {
    final technical = RcProductRegistry.experience(profile('Technical Admin'));
    final community = RcProductRegistry.experience(profile('Community Admin'));
    expect(technical.allowedRecordTypes, contains('monitoring'));
    expect(technical.allowedRecordTypes, isNot(contains('payment')));
    expect(community.communityReadOnly, isTrue);
    expect(community.showPaymentReceived, isFalse);
  });

  test('management experience keeps broad production modules', () {
    final management = RcProductRegistry.experience(
      profile('Regional Supervisor', parish: 'All Parishes'),
    );
    expect(management.allowedRecordTypes, isEmpty);
    expect(management.quickActions, contains(RcQuickActionKey.payment));
    expect(management.showPaymentReceived, isTrue);
  });

  test('custom event type detection is explicit and bounded', () {
    expect(RcProductRegistry.isCustomEventType('custom:roof-audit'), isTrue);
    expect(RcProductRegistry.isCustomEventType('payment'), isFalse);
  });


  test('admin dashboard is governance-first while production remains in chain', () {
    final admin = RcProductRegistry.experience(profile('Admin'));
    expect(admin.quickActions, contains(RcQuickActionKey.adminUsers));
    expect(admin.quickActions, contains(RcQuickActionKey.adminForms));
    expect(admin.quickActions, isNot(contains(RcQuickActionKey.materialRequest)));
  });

  test('site supervisor defaults parish-first and can be explicitly promoted', () {
    final normal = UserProfile(
      userId: 'site',
      email: 'site@example.org',
      role: 'Site Supervisor',
      parish: 'Hanover',
      approved: true,
      privileges: const {'viewAllParishes': false},
    );
    final promoted = UserProfile(
      userId: 'site2',
      email: 'site2@example.org',
      role: 'Site Supervisor',
      parish: 'Hanover',
      approved: true,
      privileges: const {'viewAllParishes': true},
    );
    expect(normal.canViewAllParishes, isFalse);
    expect(promoted.canViewAllParishes, isTrue);
    expect(RcProductRegistry.experience(promoted).heroTitle, contains('Multi-parish'));
  });

}
