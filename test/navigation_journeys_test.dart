import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rc_sow_connected/app.dart';
import 'package:rc_sow_connected/core/app_state.dart';
import 'package:rc_sow_connected/core/routes.dart';
import 'package:rc_sow_connected/core/theme.dart';
import 'package:rc_sow_connected/core/widgets.dart';

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;

  testWidgets('bottom navigation destinations respond to real taps', (
    tester,
  ) async {
    await _useViewport(tester, const Size(390, 844));
    await _pumpRoute(tester, RcRoutes.home);

    const destinations = <String, String>{
      'Scope': 'House information',
      'Control': 'Control of Works',
      'Houses': 'PRODUCTION RECORDS',
      'More': 'More operations',
      'Dashboard': 'From assessment to paid completion',
    };

    for (final destination in destinations.entries) {
      await _tapBottomDestination(tester, destination.key);
      expect(find.text(destination.value), findsOneWidget);
    }
  });

  testWidgets('dashboard controls navigate through real hit targets', (
    tester,
  ) async {
    await _useViewport(tester, const Size(390, 844));

    await _pumpRoute(tester, RcRoutes.home);
    await tester.tap(find.text('OPEN PRODUCTION CONTROL'));
    await tester.pumpAndSettle();
    expect(find.text('Control of Works'), findsOneWidget);

    final workLogObserver = _RecordingNavigatorObserver();
    await _pumpRoute(tester, RcRoutes.home, observer: workLogObserver);
    await tester.tap(find.text('Work logs').hitTestable());
    await tester.pumpAndSettle();
    expect(workLogObserver.lastName, RcRoutes.workLogs);

    final houseObserver = _RecordingNavigatorObserver();
    await _pumpRoute(tester, RcRoutes.home, observer: houseObserver);
    final houseCard = find.byType(RcHouseCard).first;
    await tester.ensureVisible(houseCard);
    await tester.pumpAndSettle();
    await tester.tap(houseCard);
    await tester.pumpAndSettle();
    expect(houseObserver.lastName, RcRoutes.houseCommand);
  });

  testWidgets('app-bar actions and desktop settings push named routes', (
    tester,
  ) async {
    await _useViewport(tester, const Size(390, 844));
    final state = AppState.seeded();
    final onlineCount = state.team.where((person) => person.online).length;
    final mobileActions = <String, String>{
      'Operational map': RcRoutes.operationalMap,
      '$onlineCount users online': RcRoutes.usersOnline,
      'Notifications': RcRoutes.notifications,
    };

    for (final action in mobileActions.entries) {
      final observer = _RecordingNavigatorObserver();
      await _pumpRoute(
        tester,
        RcRoutes.home,
        observer: observer,
        state: AppState.seeded(),
      );
      await tester.tap(find.byTooltip(action.key));
      await tester.pumpAndSettle();
      expect(observer.lastName, action.value);
    }

    await _useViewport(tester, const Size(1280, 900));
    final desktopObserver = _RecordingNavigatorObserver();
    await _pumpRoute(
      tester,
      RcRoutes.home,
      observer: desktopObserver,
    );
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(desktopObserver.lastName, RcRoutes.settings);
  });

  testWidgets('every Control module opens its registered route by tap', (
    tester,
  ) async {
    await _useViewport(tester, const Size(390, 844));
    const modules = <String, String>{
      'Work Plan': RcRoutes.workPlan,
      'Document Checklist': RcRoutes.documentChecklist,
      'Site Visits': RcRoutes.siteVisits,
      'Daily Site Log': RcRoutes.dailyLog,
      'Material Request': RcRoutes.materialRequest,
      'Consumables': RcRoutes.consumableRequest,
      'Inventory Reconciliation': RcRoutes.inventory,
      'Monitoring Checklist': RcRoutes.monitoring,
      'Final Inspection': RcRoutes.finalInspection,
      'Notice of Completion': RcRoutes.completion,
      'Payment Submission': RcRoutes.payment,
    };

    for (final module in modules.entries) {
      final observer = _RecordingNavigatorObserver();
      await _pumpRoute(tester, RcRoutes.control, observer: observer);
      await _tapScrollableText(tester, module.key);
      expect(observer.lastName, module.value, reason: module.key);
    }
  });

  testWidgets('every More link opens its registered route by tap', (
    tester,
  ) async {
    await _useViewport(tester, const Size(390, 844));
    const links = <String, String>{
      'Work Logs': RcRoutes.workLogs,
      'Inventory Tracker': RcRoutes.inventory,
      'Evidence Viewer': RcRoutes.evidence,
      'Operational Map': RcRoutes.operationalMap,
      'Messages': RcRoutes.messages,
      'Notifications': RcRoutes.notifications,
      'Users Online': RcRoutes.usersOnline,
      'Gmail': RcRoutes.gmail,
      'Production Analytics': RcRoutes.analytics,
      'Activity History': RcRoutes.activity,
      'User Access': RcRoutes.adminUsers,
      'Templates': RcRoutes.adminTemplates,
      'SETTINGS & ACCESSIBILITY': RcRoutes.settings,
    };

    for (final link in links.entries) {
      final observer = _RecordingNavigatorObserver();
      await _pumpRoute(tester, RcRoutes.home, observer: observer);
      await _tapBottomDestination(tester, 'More');
      await _tapScrollableText(tester, link.key);
      expect(observer.lastName, link.value, reason: link.key);
    }
  });

  testWidgets('House Command links keep the selected house context', (
    tester,
  ) async {
    await _useViewport(tester, const Size(390, 844));
    const links = <String, String>{
      'RESOLVE': RcRoutes.materialRequest,
      'Evidence readiness': RcRoutes.evidence,
      'Documents complete': RcRoutes.documentChecklist,
      'Assigned team': RcRoutes.usersOnline,
      'Material lines': RcRoutes.inventory,
      'Scope & roof drawing': RcRoutes.scopeHouse,
      'Work Plan': RcRoutes.workPlan,
      'Site Visits & Daily Logs': RcRoutes.siteVisits,
      'Technical Quality': RcRoutes.monitoring,
      'Close-out & Payment': RcRoutes.completion,
    };

    for (final link in links.entries) {
      final observer = _RecordingNavigatorObserver();
      await _pumpRoute(tester, RcRoutes.houseCommand, observer: observer);
      await _tapScrollableText(tester, link.key);
      expect(observer.lastName, link.value, reason: link.key);
    }

    for (final action in <String, String>{
      'Messages': RcRoutes.messages,
      'Activity': RcRoutes.activity,
    }.entries) {
      final observer = _RecordingNavigatorObserver();
      await _pumpRoute(tester, RcRoutes.houseCommand, observer: observer);
      await tester.tap(find.byTooltip(action.key));
      await tester.pumpAndSettle();
      expect(observer.lastName, action.value);
    }

    final nextObserver = _RecordingNavigatorObserver();
    await _pumpRoute(tester, RcRoutes.houseCommand, observer: nextObserver);
    final nextAction = find.descendant(
      of: find.byType(RcNextActionCard),
      matching: find.byType(IconButton),
    );
    await tester.ensureVisible(nextAction);
    await tester.pumpAndSettle();
    await tester.tap(nextAction.hitTestable());
    await tester.pumpAndSettle();
    expect(nextObserver.lastName, RcRoutes.dailyLog);
  });

  testWidgets('Scope continue, back and completion controls are connected', (
    tester,
  ) async {
    await _useViewport(tester, const Size(390, 844));
    final observer = _RecordingNavigatorObserver();
    await _pumpRoute(tester, RcRoutes.scopeHouse, observer: observer);

    expect(find.text('House information'), findsOneWidget);
    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Roof drawing'), findsOneWidget);

    await tester.tap(find.text('BACK'));
    await tester.pumpAndSettle();
    expect(find.text('House information'), findsOneWidget);

    for (final expected in <String>[
      'Roof drawing',
      'Beneficiary printout',
      'Files & evidence',
    ]) {
      await tester.tap(find.text('CONTINUE'));
      await tester.pumpAndSettle();
      expect(find.textContaining(expected), findsOneWidget);
    }

    await tester.tap(find.text('OPEN HOUSE COMMAND'));
    await tester.pumpAndSettle();
    expect(observer.lastName, RcRoutes.houseCommand);
  });

  final shellRoutes = <String>{
    RcRoutes.splash,
    RcRoutes.login,
    RcRoutes.home,
    RcRoutes.dashboard,
    RcRoutes.control,
    RcRoutes.houses,
  };
  for (final routeName in RcRoutes.all.where(
    (route) => !shellRoutes.contains(route),
  )) {
    testWidgets('$routeName app-bar back button returns to dashboard', (
      tester,
    ) async {
      await _useViewport(tester, const Size(390, 844));
      await _pumpRouteStack(tester, routeName);

      final backButton = find.byType(BackButton).hitTestable();
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();
      expect(find.text('From assessment to paid completion'), findsOneWidget);
    });
  }
}

Future<void> _useViewport(WidgetTester tester, Size size) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Future<void> _pumpRoute(
  WidgetTester tester,
  String routeName, {
  _RecordingNavigatorObserver? observer,
  AppState? state,
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

Future<void> _pumpRouteStack(WidgetTester tester, String routeName) async {
  await tester.pumpWidget(
    AppScope(
      state: AppState.seeded(),
      child: MaterialApp(
        theme: RcTheme.light(),
        darkTheme: RcTheme.dark(),
        onGenerateRoute: buildRcRoute,
        initialRoute: routeName,
        onGenerateInitialRoutes: (_) => <Route<dynamic>>[
          buildRcRoute(const RouteSettings(name: RcRoutes.home)),
          buildRcRoute(RouteSettings(name: routeName)),
        ],
      ),
    ),
  );
  await tester.pump();
}

Future<void> _tapBottomDestination(
  WidgetTester tester,
  String label,
) async {
  final target = find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text(label),
  );
  expect(target, findsOneWidget);
  await tester.tap(target);
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
  final List<String> pushedNames = <String>[];

  String? get lastName => pushedNames.isEmpty ? null : pushedNames.last;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final name = route.settings.name;
    if (name != null) pushedNames.add(name);
    super.didPush(route, previousRoute);
  }
}
