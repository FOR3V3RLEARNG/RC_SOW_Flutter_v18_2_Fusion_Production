import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../features/admin/admin_screen.dart';
import '../features/live/live_tracker_screen.dart';
import '../features/messages/messages_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/users/active_users_screen.dart';
import 'design_tokens.dart';

enum RcDestination { dashboard, scope, control, houses, more }

extension RcDestinationX on RcDestination {
  int get index => RcDestination.values.indexOf(this);
  String get label => switch (this) {
    RcDestination.dashboard => 'Dashboard',
    RcDestination.scope => 'Scope',
    RcDestination.control => 'Control',
    RcDestination.houses => 'Houses',
    RcDestination.more => 'More',
  };

  IconData get icon => switch (this) {
    RcDestination.dashboard => Icons.dashboard_outlined,
    RcDestination.scope => Icons.assignment_outlined,
    RcDestination.control => Icons.construction_outlined,
    RcDestination.houses => Icons.home_work_outlined,
    RcDestination.more => Icons.more_horiz,
  };

  IconData get selectedIcon => switch (this) {
    RcDestination.dashboard => Icons.dashboard_rounded,
    RcDestination.scope => Icons.assignment_rounded,
    RcDestination.control => Icons.construction_rounded,
    RcDestination.houses => Icons.home_work_rounded,
    RcDestination.more => Icons.more_horiz,
  };
}

abstract final class RcNavigator {
  static PageRoute<void> _route(Widget page, {required String name}) {
    return PageRouteBuilder<void>(
      settings: RouteSettings(name: name),
      transitionDuration: RcMotion.medium,
      reverseTransitionDuration: RcMotion.quick,
      pageBuilder: (_, animation, __) => page,
      transitionsBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: RcMotion.expressiveCurve,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(.025, .015),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  static Future<void> messages(BuildContext context, AppState state) =>
      Navigator.of(
        context,
      ).push(_route(MessagesScreen(state: state), name: '/messages'));

  static Future<void> liveTracker(
    BuildContext context,
    AppState state, {
    bool mapFirst = false,
  }) => Navigator.of(context).push(
    _route(
      LiveTrackerScreen(state: state, showMapFirst: mapFirst),
      name: mapFirst ? '/field-map' : '/live-tracker',
    ),
  );

  static Future<void> activeUsers(BuildContext context, AppState state) =>
      Navigator.of(
        context,
      ).push(_route(ActiveUsersScreen(state: state), name: '/active-users'));

  static Future<void> settings(BuildContext context, AppState state) =>
      Navigator.of(
        context,
      ).push(_route(SettingsScreen(state: state), name: '/settings'));

  static Future<void> admin(BuildContext context, AppState state) =>
      Navigator.of(
        context,
      ).push(_route(AdminScreen(state: state), name: '/admin'));
}
