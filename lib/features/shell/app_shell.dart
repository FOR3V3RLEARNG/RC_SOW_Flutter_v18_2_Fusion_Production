import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/design_tokens.dart';
import '../../state/app_state.dart';
import '../admin/admin_screen.dart';
import '../control/control_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../houses/houses_screen.dart';
import '../live/live_tracker_screen.dart';
import '../messages/messages_screen.dart';
import '../scope/scope_screen.dart';
import '../settings/settings_screen.dart';
import '../users/active_users_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.state});
  final AppState state;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  AppState get state => widget.state;

  @override
  Widget build(BuildContext context) {
    final profile = state.profile;
    if (profile == null || !profile.approved || !profile.active) {
      return Scaffold(
        appBar: AppBar(title: const Text('RC SOW')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  profile?.active == false
                      ? Icons.block
                      : Icons.hourglass_top_rounded,
                  size: 52,
                  color: RcColors.brand,
                ),
                const SizedBox(height: 14),
                Text(
                  profile?.active == false
                      ? 'Account suspended'
                      : 'Account approval required',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  profile?.active == false
                      ? 'Contact an RC SOW administrator to restore access.'
                      : 'Your account is awaiting administrator approval.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: state.refreshProfile,
                  child: const Text('Check account status'),
                ),
                TextButton(
                  onPressed: () => Supabase.instance.client.auth.signOut(),
                  child: const Text('Sign out'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final pages = [
      DashboardScreen(state: state),
      ScopeScreen(state: state),
      ControlScreen(state: state),
      HousesScreen(state: state),
      MoreScreen(state: state),
    ];
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final content = Column(
      children: [
        RcHeader(
          state: state,
          onMessages: () => scaffoldKey.currentState?.openEndDrawer(),
        ),
        Expanded(child: pages[state.selectedTab]),
      ],
    );

    return Scaffold(
      key: scaffoldKey,
      endDrawer: MessageDrawerPanel(state: state),
      body: SafeArea(
        child: wide
            ? Row(
                children: [
                  NavigationRail(
                    selectedIndex: state.selectedTab,
                    onDestinationSelected: state.selectTab,
                    labelType: NavigationRailLabelType.all,
                    destinations: const [
                      NavigationRailDestination(
                        icon: Icon(Icons.dashboard_outlined),
                        selectedIcon: Icon(Icons.dashboard),
                        label: Text('Dashboard'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.assignment_outlined),
                        selectedIcon: Icon(Icons.assignment),
                        label: Text('Scope'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.construction_outlined),
                        selectedIcon: Icon(Icons.construction),
                        label: Text('Control'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.home_work_outlined),
                        selectedIcon: Icon(Icons.home_work),
                        label: Text('Houses'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.more_horiz),
                        label: Text('More'),
                      ),
                    ],
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: content),
                ],
              )
            : content,
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: state.selectedTab,
              onDestinationSelected: state.selectTab,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
                NavigationDestination(
                  icon: Icon(Icons.assignment_outlined),
                  selectedIcon: Icon(Icons.assignment),
                  label: 'Scope',
                ),
                NavigationDestination(
                  icon: Icon(Icons.construction_outlined),
                  selectedIcon: Icon(Icons.construction),
                  label: 'Control',
                ),
                NavigationDestination(
                  icon: Icon(Icons.home_work_outlined),
                  selectedIcon: Icon(Icons.home_work),
                  label: 'Houses',
                ),
                NavigationDestination(
                  icon: Icon(Icons.more_horiz),
                  label: 'More',
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showUsers,
        icon: const Icon(Icons.group),
        label: const Text('Users online'),
        backgroundColor: RcColors.success,
        foregroundColor: Colors.white,
      ),
    );
  }

  Future<void> _showUsers() {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black26,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(18),
        alignment: Alignment.bottomRight,
        child: ActiveUsersPopup(state: state),
      ),
    );
  }
}

class RcHeader extends StatelessWidget {
  const RcHeader({super.key, required this.state, required this.onMessages});

  final AppState state;
  final VoidCallback onMessages;

  @override
  Widget build(BuildContext context) {
    final profile = state.profile!;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xF4FFFFFF),
            border: Border(bottom: BorderSide(color: RcColors.line)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  'assets/brand/rc_sow_house_icon.png',
                  width: 48,
                  height: 48,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'RC SOW',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: RcColors.brand,
                      ),
                    ),
                    Text(
                      '${profile.role} • ${profile.parish}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: RcColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'IA Shelter Assessment',
                onPressed: () => state.selectTab(3),
                icon: const Icon(Icons.auto_awesome_outlined),
              ),
              IconButton(
                tooltip: 'Field map',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        LiveTrackerScreen(state: state, showMapFirst: true),
                  ),
                ),
                icon: const Icon(Icons.map_outlined),
              ),
              IconButton(
                tooltip: 'Messages',
                onPressed: onMessages,
                icon: const Badge(child: Icon(Icons.notifications_outlined)),
              ),
              IconButton(
                tooltip: 'Settings',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SettingsScreen(state: state),
                  ),
                ),
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final profile = state.profile!;
    final items = <Widget>[
      ListTile(
        leading: const Icon(Icons.message_outlined),
        title: const Text('Messages'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MessagesScreen(state: state)),
        ),
      ),
      ListTile(
        leading: const Icon(Icons.location_searching),
        title: const Text('Live Tracker'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => LiveTrackerScreen(state: state)),
        ),
      ),
      ListTile(
        leading: const Icon(Icons.group_outlined),
        title: const Text('Active Users'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ActiveUsersScreen(state: state)),
        ),
      ),
      ListTile(
        leading: const Icon(Icons.settings_outlined),
        title: const Text('Settings'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SettingsScreen(state: state)),
        ),
      ),
    ];
    if (profile.canViewAdmin) {
      items.add(
        ListTile(
          leading: const Icon(Icons.admin_panel_settings_outlined),
          title: const Text('Admin Dashboard'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AdminScreen(state: state)),
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'More',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        Card(child: Column(children: items)),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.logout, color: RcColors.danger),
            title: const Text('Sign out'),
            onTap: () => Supabase.instance.client.auth.signOut(),
          ),
        ),
      ],
    );
  }
}
