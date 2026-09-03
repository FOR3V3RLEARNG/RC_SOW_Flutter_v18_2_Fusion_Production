import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rc_sow_connected/app.dart';
import 'package:rc_sow_connected/core/app_state.dart';
import 'package:rc_sow_connected/core/routes.dart';
import 'package:rc_sow_connected/core/theme.dart';

void main() {
  const viewports = <String, Size>{
    'phone': Size(390, 844),
    'desktop': Size(1280, 900),
  };

  for (final viewport in viewports.entries) {
    for (final routeName in RcRoutes.all) {
      testWidgets('$routeName renders on ${viewport.key}', (tester) async {
        await tester.binding.setSurfaceSize(viewport.value);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final originalOnError = FlutterError.onError!;
        FlutterError.onError = (details) {
          FlutterError.dumpErrorToConsole(details);
          originalOnError(details);
        };
        addTearDown(() => FlutterError.onError = originalOnError);

        await tester.pumpWidget(
          _RouteHarness(routeName: routeName, state: AppState.seeded()),
        );
        await tester.pump();

        final exceptions = <Object>[];
        Object? exception;
        while ((exception = tester.takeException()) != null) {
          exceptions.add(exception!);
        }
        expect(
          exceptions,
          isEmpty,
          reason: '$routeName produced framework exceptions on ${viewport.key}',
        );
        expect(find.byType(UnknownRouteScreen), findsNothing);
      });
    }
  }
}

class _RouteHarness extends StatelessWidget {
  const _RouteHarness({required this.routeName, required this.state});

  final String routeName;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: MaterialApp(
        theme: RcTheme.light(),
        darkTheme: RcTheme.dark(),
        onGenerateRoute: buildRcRoute,
        initialRoute: routeName,
        onGenerateInitialRoutes: (_) => <Route<dynamic>>[
          buildRcRoute(RouteSettings(name: routeName)),
        ],
      ),
    );
  }
}
