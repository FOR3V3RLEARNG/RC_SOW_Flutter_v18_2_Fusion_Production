import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rc_sow_flutter/core/design_tokens.dart';
import 'package:rc_sow_flutter/core/rc_policy.dart';
import 'package:rc_sow_flutter/models/app_models.dart';
import 'package:rc_sow_flutter/services/document_service.dart';

void main() {
  test('all Jamaican parishes are available', () {
    expect(RcPolicy.parishes.length, 14);
    expect(RcPolicy.parishes, containsAll(['Hanover', 'Kingston', 'St. Thomas']));
  });

  test('theme builder supports light and dark design profiles', () {
    final light = buildRcTheme(
      brightness: Brightness.light,
      designStyle: RcDesignStyle.materialExpressive,
    );
    final dark = buildRcTheme(
      brightness: Brightness.dark,
      designStyle: RcDesignStyle.shadcnSaas,
    );
    expect(light.useMaterial3, isTrue);
    expect(dark.useMaterial3, isTrue);
    expect(light.brightness, Brightness.light);
    expect(dark.brightness, Brightness.dark);
  });

  test('every production module resolves a document template', () {
    const eventTypes = [
      'workPlan',
      'monitoring',
      'siteVisit',
      'dailyLog',
      'documentChecklist',
      'materialRequest',
      'consumables',
      'inventory',
      'notice',
      'payment',
      'scope',
    ];
    for (final eventType in eventTypes) {
      expect(RcTemplates.forEventType(eventType), isNotNull, reason: eventType);
    }
  });

  test('presence record distinguishes online from approved/offline', () {
    final online = ActiveUserRecord.fromMap({
      'user_id': '1',
      'email': 'online@example.org',
      'full_name': 'Online User',
      'role': 'Site Supervisor',
      'parish': 'Hanover',
      'active': true,
    });
    final offline = ActiveUserRecord.fromMap({
      'user_id': '2',
      'email': 'offline@example.org',
      'full_name': 'Offline User',
      'role': 'Site Supervisor',
      'parish': 'Hanover',
      'active': false,
    });
    expect(online.online, isTrue);
    expect(offline.online, isFalse);
  });
}
