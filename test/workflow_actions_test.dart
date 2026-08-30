import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rc_sow_connected/app.dart';
import 'package:rc_sow_connected/core/app_state.dart';
import 'package:rc_sow_connected/core/models.dart';
import 'package:rc_sow_connected/core/routes.dart';
import 'package:rc_sow_connected/core/theme.dart';

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;

  testWidgets('Evidence capture save and cancel actions update shared state', (
    tester,
  ) async {
    await _usePhoneViewport(tester);
    final state = AppState.seeded();
    final originalCount = state.evidence.length;

    await _pumpRoute(tester, RcRoutes.evidence, state: state);
    await _tapScrollableText(tester, 'CAPTURE / ADD EVIDENCE');
    await tester.enterText(
      _dialogTextField(),
      'Rafter connection photographed',
    );
    await _tapDialogText(tester, 'SAVE ON DEVICE');

    expect(state.evidence, hasLength(originalCount + 1));
    expect(state.evidence.first.caption, 'Rafter connection photographed');
    expect(find.byType(AlertDialog), findsNothing);

    await tester.pump(const Duration(seconds: 5));
    await _tapScrollableText(tester, 'CAPTURE / ADD EVIDENCE');
    await tester.enterText(_dialogTextField(), 'Discard this evidence');
    await _tapDialogText(tester, 'CANCEL');
    expect(state.evidence, hasLength(originalCount + 1));
  });

  testWidgets('Scope Files add-evidence dialog saves to the selected house', (
    tester,
  ) async {
    await _usePhoneViewport(tester);
    final state = AppState.seeded();
    final originalCount = state.evidence.length;

    await _pumpRoute(tester, RcRoutes.scopeFiles, state: state);
    await _tapScrollableText(tester, 'ADD EVIDENCE');
    await tester.enterText(_dialogTextField(), 'Signed beneficiary scope');
    await _tapDialogText(tester, 'SAVE');

    expect(state.evidence, hasLength(originalCount + 1));
    expect(state.evidence.first.houseCode, state.selectedHouseCode);
    expect(state.evidence.first.caption, 'Signed beneficiary scope');
  });

  testWidgets('Admin invite dialog validates and sends an invitation', (
    tester,
  ) async {
    await _usePhoneViewport(tester);
    await _pumpRoute(tester, RcRoutes.adminUsers);
    await _tapScrollableText(tester, 'INVITE');

    await tester.enterText(_dialogTextField(), 'field.user@redcross.org');
    await _tapDialogText(tester, 'SEND INVITE');

    expect(find.byType(AlertDialog), findsNothing);
    expect(
      find.text('Invitation prepared for field.user@redcross.org.'),
      findsOneWidget,
    );
  });

  testWidgets('Monitoring comment dialog persists the inspection comment', (
    tester,
  ) async {
    await _usePhoneViewport(tester);
    final state = AppState.seeded();
    await _pumpRoute(tester, RcRoutes.monitoring, state: state);

    final commentButton = find.byTooltip('Add comment').first;
    await tester.ensureVisible(commentButton);
    await tester.pumpAndSettle();
    await tester.tap(commentButton.hitTestable());
    await tester.pumpAndSettle();
    await tester.enterText(_dialogTextField(), 'Connection requires recheck');
    await _tapDialogText(tester, 'SAVE');

    expect(
      state.monitoringComments['H12']?['Wall Plate'],
      'Connection requires recheck',
    );
  });

  testWidgets('Users Online sheet call and message actions both respond', (
    tester,
  ) async {
    await _usePhoneViewport(tester);
    await _pumpRoute(tester, RcRoutes.usersOnline);

    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('CALL').hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('Call request prepared.'), findsOneWidget);

    final observer = _RecordingNavigatorObserver();
    await _pumpRoute(
      tester,
      RcRoutes.usersOnline,
      observer: observer,
    );
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('MESSAGE').hitTestable());
    await tester.pumpAndSettle();
    expect(observer.lastName, RcRoutes.messages);
  });

  testWidgets('Gmail compose draft, attachment and send actions are connected',
      (
    tester,
  ) async {
    await _usePhoneViewport(tester);

    await _pumpRoute(tester, RcRoutes.gmail);
    await tester.tap(find.text('COMPOSE').hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('Compose message'), findsOneWidget);
    await _tapScrollableText(tester, 'SAVE DRAFT');
    expect(find.text('Inbox'), findsOneWidget);

    final attachmentObserver = _RecordingNavigatorObserver();
    await _pumpRoute(
      tester,
      RcRoutes.gmail,
      observer: attachmentObserver,
    );
    await tester.tap(find.text('COMPOSE').hitTestable());
    await tester.pumpAndSettle();
    await _tapScrollableText(tester, 'ATTACH HOUSE FILE');
    expect(attachmentObserver.lastName, RcRoutes.evidence);

    await _pumpRoute(tester, RcRoutes.gmail);
    await tester.tap(find.text('COMPOSE').hitTestable());
    await tester.pumpAndSettle();
    await _tapScrollableText(tester, 'SEND');
    expect(find.text('Inbox'), findsOneWidget);
    expect(
      find.text('Institutional email queued for delivery.'),
      findsOneWidget,
    );
  });

  testWidgets('New Control valid form creates, selects and opens Scope', (
    tester,
  ) async {
    await _usePhoneViewport(tester);
    final state = AppState.seeded();
    final originalCount = state.houses.length;
    final observer = _RecordingNavigatorObserver();
    await _pumpRoute(
      tester,
      RcRoutes.newControl,
      state: state,
      observer: observer,
    );

    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(4));
    await tester.enterText(fields.at(0), 'h99');
    await tester.enterText(fields.at(1), 'Test Beneficiary');
    await tester.enterText(fields.at(2), 'Test Community');
    await tester.enterText(fields.at(3), 'Cluster Z');
    await _tapScrollableText(tester, 'CREATE & START SCOPE');

    expect(state.houses, hasLength(originalCount + 1));
    expect(state.selectedHouseCode, 'H99');
    expect(state.selectedHouse.phase, LifecyclePhase.scope);
    expect(observer.lastName, RcRoutes.scopeHouse);
  });

  testWidgets('Inventory selection enables and saves reconciliation', (
    tester,
  ) async {
    await _usePhoneViewport(tester);
    final state = AppState.seeded();
    final activityCount = state.activities.length;
    final itemName = state.inventory.first.name;
    await _pumpRoute(tester, RcRoutes.addInventory, state: state);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(itemName).last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '99');
    await _tapScrollableText(tester, 'SAVE RECONCILIATION');

    expect(state.inventory.first.delivered, 99);
    expect(state.activities, hasLength(activityCount + 1));
    expect(state.activities.first.title, 'Inventory reconciled');
  });

  testWidgets('Message send button adds the typed reply', (tester) async {
    await _usePhoneViewport(tester);
    await _pumpRoute(tester, RcRoutes.messages);

    await tester.enterText(find.byType(TextField), 'Status confirmed');
    await tester.tap(find.byIcon(Icons.send).hitTestable());
    await tester.pumpAndSettle();

    expect(find.text('Status confirmed'), findsOneWidget);
  });

  testWidgets('Final inspection approval enables after all checks pass', (
    tester,
  ) async {
    await _usePhoneViewport(tester);
    final state = AppState.seeded();
    await _pumpRoute(tester, RcRoutes.finalInspection, state: state);

    const criteria = <String>[
      'Structural timber and connections',
      'Roof angle and drainage',
      'Zinc, ridge cap and flashing',
      'Hurricane straps and fasteners',
      'Fascia, overhang and gutters',
      'Site cleared and safe',
    ];
    for (final criterion in criteria) {
      final tile = find.widgetWithText(CheckboxListTile, criterion);
      await tester.ensureVisible(tile);
      await tester.pumpAndSettle();
      await tester.tap(tile.hitTestable());
      await tester.pumpAndSettle();
    }
    await _tapScrollableText(tester, 'APPROVE FINAL INSPECTION');

    expect(state.formDrafts['H12:Final Inspection'], hasLength(6));
    expect(state.activities.first.title, 'Final Inspection submitted');
  });

  testWidgets('Completion submission enables after every readiness check', (
    tester,
  ) async {
    await _usePhoneViewport(tester);
    final state = AppState.seeded()..selectHouse('H2');
    await _pumpRoute(tester, RcRoutes.completion, state: state);

    for (var index = 1; index < 4; index++) {
      final checkbox = find.byType(Checkbox).at(index);
      await tester.ensureVisible(checkbox);
      await tester.pumpAndSettle();
      await tester.tap(checkbox.hitTestable());
      await tester.pumpAndSettle();
    }
    await _tapScrollableText(tester, 'SUBMIT COMPLETION');

    final house = state.houseByCode('H2');
    expect(house.progress, 1);
    expect(house.status, RecordStatus.submitted);
    expect(state.activities.first.title, 'Notice of Completion submitted');
  });

  testWidgets('Ready payment submission updates finance state', (tester) async {
    await _usePhoneViewport(tester);
    final state = AppState.seeded()..selectHouse('H1');
    await _pumpRoute(tester, RcRoutes.payment, state: state);

    await _tapScrollableText(tester, 'SUBMIT PAYMENT');

    expect(state.houseByCode('H1').phase, LifecyclePhase.finance);
    expect(state.houseByCode('H1').status, RecordStatus.submitted);
    expect(state.activities.first.title, 'Payment submitted');
  });

  testWidgets('Settings sign out clears auth and returns to login', (
    tester,
  ) async {
    await _usePhoneViewport(tester);
    final state = AppState.seeded()..login(selectedRole: 'Site Supervisor');
    final observer = _RecordingNavigatorObserver();
    await _pumpRoute(
      tester,
      RcRoutes.settings,
      state: state,
      observer: observer,
    );

    await _tapScrollableText(tester, 'SIGN OUT');

    expect(state.authenticated, isFalse);
    expect(observer.lastName, RcRoutes.login);
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('Work Log valid entry saves and appears in recent logs', (
    tester,
  ) async {
    await _usePhoneViewport(tester);
    final state = AppState.seeded();
    final originalCount = state.workLogs.length;
    await _pumpRoute(tester, RcRoutes.workLogs, state: state);

    await tester.enterText(
      find.byType(TextField).last,
      'Verified zinc delivery and updated quantities',
    );
    await _tapScrollableText(tester, 'SAVE WORK LOG');

    expect(state.workLogs, hasLength(originalCount + 1));
    expect(
      state.workLogs.first.detail,
      'Verified zinc delivery and updated quantities',
    );
    expect(
      find.textContaining('Verified zinc delivery and updated quantities'),
      findsOneWidget,
    );
  });
}

Future<void> _usePhoneViewport(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Future<void> _pumpRoute(
  WidgetTester tester,
  String routeName, {
  AppState? state,
  _RecordingNavigatorObserver? observer,
}) async {
  await tester.pumpWidget(
    KeyedSubtree(
      key: UniqueKey(),
      child: AppScope(
        state: state ?? AppState.seeded(),
        child: MaterialApp(
          theme: RcTheme.light(),
          darkTheme: RcTheme.dark(),
          navigatorObservers: <NavigatorObserver>[
            if (observer != null) observer,
          ],
          onGenerateRoute: buildRcRoute,
          initialRoute: routeName,
          onGenerateInitialRoutes: (_) => <Route<dynamic>>[
            buildRcRoute(RouteSettings(name: routeName)),
          ],
        ),
      ),
    ),
  );
  await tester.pump();
}

Finder _dialogTextField() => find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );

Future<void> _tapDialogText(WidgetTester tester, String text) async {
  final target = find.descendant(
    of: find.byType(AlertDialog),
    matching: find.text(text),
  );
  expect(target, findsOneWidget, reason: text);
  await tester.tap(target.hitTestable());
  await tester.pumpAndSettle();
}

Future<void> _tapScrollableText(WidgetTester tester, String text) async {
  final target = find.text(text);
  expect(target, findsOneWidget, reason: text);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target.hitTestable());
  await tester.pumpAndSettle();
}

class _RecordingNavigatorObserver extends NavigatorObserver {
  final List<String> routeNames = <String>[];

  String? get lastName => routeNames.isEmpty ? null : routeNames.last;

  void _record(Route<dynamic>? route) {
    final name = route?.settings.name;
    if (name != null) routeNames.add(name);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _record(route);
    super.didPush(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _record(newRoute);
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}
