import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rc_sow_connected/app.dart';
import 'package:rc_sow_connected/core/app_state.dart';

void main() {
  testWidgets('splash, login and dashboard form a connected entry journey', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final state = AppState.seeded();
    await tester.pumpWidget(RcSowApp(state: state));
    expect(find.text('Red Cross Scope of Work'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);

    await tester.tap(find.text('SIGN IN SECURELY'));
    await tester.pumpAndSettle();
    expect(find.text('From assessment to paid completion'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(state.authenticated, isTrue);
  });
}
