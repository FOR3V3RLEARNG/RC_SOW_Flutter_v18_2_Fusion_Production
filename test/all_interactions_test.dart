import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rc_sow_connected/app.dart';
import 'package:rc_sow_connected/core/app_state.dart';
import 'package:rc_sow_connected/core/routes.dart';
import 'package:rc_sow_connected/core/theme.dart';

void main() {
  final routes = RcRoutes.all.where((route) => route != RcRoutes.splash);

  for (final routeName in routes) {
    testWidgets('$routeName enabled interactions execute without errors', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpRoute(tester, routeName);
      _expectNoExceptions(tester, '$routeName initial render');
      final expectedActions = _collectActions(tester);

      for (var index = 0; index < expectedActions.length; index++) {
        await _pumpRoute(tester, routeName);
        _expectNoExceptions(tester, '$routeName reset before action $index');

        final actions = _collectActions(tester);
        expect(
          actions.length,
          expectedActions.length,
          reason: '$routeName action inventory changed after a clean reset',
        );
        final action = actions[index];

        Object? synchronousError;
        try {
          action.invoke();
        } on Object catch (error) {
          synchronousError = error;
        }
        expect(
          synchronousError,
          isNull,
          reason:
              '$routeName action $index (${action.label}) threw immediately',
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        _expectNoExceptions(
          tester,
          '$routeName action $index (${action.label})',
        );
        expect(
          find.byType(UnknownRouteScreen),
          findsNothing,
          reason:
              '$routeName action $index (${action.label}) opened an unknown route',
        );
      }
    });
  }
}

Future<void> _pumpRoute(WidgetTester tester, String routeName) async {
  await tester.pumpWidget(
    KeyedSubtree(
      key: UniqueKey(),
      child: _RouteHarness(routeName: routeName, state: AppState.seeded()),
    ),
  );
  await tester.pump();
}

void _expectNoExceptions(WidgetTester tester, String context) {
  final exceptions = <Object>[];
  Object? exception;
  while ((exception = tester.takeException()) != null) {
    exceptions.add(exception!);
  }
  expect(exceptions, isEmpty, reason: '$context produced framework exceptions');
}

List<_UiAction> _collectActions(WidgetTester tester) {
  final actions = <_UiAction>[];

  for (final element in tester.allElements) {
    final widget = element.widget;

    if (widget is ButtonStyleButton && widget.onPressed != null) {
      actions.add(_UiAction('${widget.runtimeType}', widget.onPressed!));
      continue;
    }
    if (widget is IconButton && widget.onPressed != null) {
      actions.add(
        _UiAction(
          'IconButton(${widget.tooltip ?? widget.icon.runtimeType})',
          widget.onPressed!,
        ),
      );
      continue;
    }
    if (widget is FloatingActionButton && widget.onPressed != null) {
      actions.add(_UiAction('FloatingActionButton', widget.onPressed!));
      continue;
    }
    if (widget is ActionChip && widget.onPressed != null) {
      actions.add(_UiAction('ActionChip', widget.onPressed!));
      continue;
    }
    if (widget is ChoiceChip && widget.onSelected != null) {
      actions.add(
        _UiAction('ChoiceChip', () => widget.onSelected!(!widget.selected)),
      );
      continue;
    }
    if (widget is FilterChip && widget.onSelected != null) {
      actions.add(
        _UiAction('FilterChip', () => widget.onSelected!(!widget.selected)),
      );
      continue;
    }
    if (widget is CheckboxListTile && widget.onChanged != null) {
      actions.add(
        _UiAction(
          'CheckboxListTile',
          () => widget.onChanged!(!(widget.value ?? false)),
        ),
      );
      continue;
    }
    if (widget is SwitchListTile && widget.onChanged != null) {
      actions.add(
        _UiAction(
          'SwitchListTile',
          () => widget.onChanged!(!widget.value),
        ),
      );
      continue;
    }
    if (widget is SegmentedButton) {
      final dynamic segmentedButton = widget;
      final dynamic callback = segmentedButton.onSelectionChanged;
      final dynamic selected = segmentedButton.selected;
      if (callback == null) continue;
      actions.add(
        _UiAction(
          'SegmentedButton',
          () => callback(selected),
        ),
      );
      continue;
    }
    if (widget is DropdownButton) {
      final dynamic dropdown = widget;
      final dynamic callback = dropdown.onChanged;
      final dynamic items = dropdown.items;
      if (callback == null || items == null || items.isEmpty) continue;
      final dynamic next = items.first.value;
      actions.add(
        _UiAction('DropdownButton', () => callback(next)),
      );
      continue;
    }
    if (widget is NavigationBar && widget.onDestinationSelected != null) {
      for (var index = 0; index < widget.destinations.length; index++) {
        actions.add(
          _UiAction(
            'NavigationBar destination $index',
            () => widget.onDestinationSelected!(index),
          ),
        );
      }
      continue;
    }
    if (widget is NavigationRail && widget.onDestinationSelected != null) {
      for (var index = 0; index < widget.destinations.length; index++) {
        actions.add(
          _UiAction(
            'NavigationRail destination $index',
            () => widget.onDestinationSelected!(index),
          ),
        );
      }
      continue;
    }
    if (widget is ListTile &&
        widget.onTap != null &&
        !_hasHandledAncestor(element)) {
      actions.add(_UiAction('ListTile', widget.onTap!));
      continue;
    }
    if (widget is InkWell &&
        widget.onTap != null &&
        !_hasHandledAncestor(element)) {
      actions.add(_UiAction('InkWell', widget.onTap!));
    }
  }

  return actions;
}

bool _hasHandledAncestor(Element element) {
  var found = false;
  element.visitAncestorElements((ancestor) {
    final widget = ancestor.widget;
    if (widget is ButtonStyleButton ||
        widget is IconButton ||
        widget is FloatingActionButton ||
        widget is ActionChip ||
        widget is ChoiceChip ||
        widget is FilterChip ||
        widget is CheckboxListTile ||
        widget is SwitchListTile ||
        widget is SegmentedButton ||
        widget is DropdownButton ||
        widget is NavigationBar ||
        widget is NavigationRail ||
        widget is ListTile) {
      found = true;
      return false;
    }
    return true;
  });
  return found;
}

class _UiAction {
  const _UiAction(this.label, this.invoke);

  final String label;
  final VoidCallback invoke;
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
