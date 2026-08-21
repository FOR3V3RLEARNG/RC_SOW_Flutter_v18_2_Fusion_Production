import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/design_tokens.dart';
import '../../core/navigation.dart';
import '../../core/rc_components.dart';
import '../../state/app_state.dart';
import '../control/control_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../houses/houses_screen.dart';
import '../scope/scope_screen.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final profile = state.profile;
    if (profile == null || !profile.approved) {
      return _ApprovalGate(state: state);
    }

    final pages = [
      DashboardScreen(state: state),
      ScopeScreen(state: state),
      ControlScreen(state: state),
      HousesScreen(state: state),
      MoreScreen(state: state),
    ];
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 960;

    final workspace = Column(
      children: [
        RcHeader(state: state),
        Expanded(
          child: AnimatedSwitcher(
            duration: state.reduceMotion ? Duration.zero : RcMotion.medium,
            switchInCurve: RcMotion.expressiveCurve,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(.015, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: KeyedSubtree(
              key: ValueKey(state.selectedTab),
              child: pages[state.selectedTab],
            ),
          ),
        ),
      ],
    );

    return Scaffold(
      body: SafeArea(
        child: wide
            ? Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 0, 12),
                    child: _NavigationDock(state: state),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: workspace),
                ],
              )
            : workspace,
      ),
      extendBody: !wide,
      bottomNavigationBar: wide ? null : _NavigationIsland(state: state),
      floatingActionButton: width >= 600
          ? FloatingActionButton.extended(
              heroTag: 'active-users',
              onPressed: () {
                state.feedback();
                RcNavigator.activeUsers(context, state);
              },
              icon: const Icon(Icons.group_outlined),
              label: const Text('Users online'),
              backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
              foregroundColor: Theme.of(
                context,
              ).colorScheme.onTertiaryContainer,
            )
          : null,
    );
  }
}

class _ApprovalGate extends StatelessWidget {
  const _ApprovalGate({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RC SOW')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: RcExpressiveSurface(
              shape: RcSurfaceShape.hero,
              padding: const EdgeInsets.all(26),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.hourglass_top_rounded,
                    size: 56,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Account approval required',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This signed-in account is awaiting administrator approval or does not yet have an approved RC SOW profile.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: state.refreshProfile,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Check approval status'),
                  ),
                  TextButton.icon(
                    onPressed: () => Supabase.instance.client.auth.signOut(),
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign out'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavigationDock extends StatelessWidget {
  const _NavigationDock({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 112,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(10),
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(18),
              ),
            ),
            child: Icon(
              Icons.home_repair_service_rounded,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: NavigationRail(
              selectedIndex: state.selectedTab,
              onDestinationSelected: state.selectTab,
              labelType: NavigationRailLabelType.all,
              groupAlignment: -.25,
              destinations: RcDestination.values
                  .map(
                    (d) => NavigationRailDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.selectedIcon),
                      label: Text(d.label),
                    ),
                  )
                  .toList(),
            ),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: () => RcNavigator.settings(context, state),
            icon: const Icon(Icons.settings_outlined),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _NavigationIsland extends StatelessWidget {
  const _NavigationIsland({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: AnimatedContainer(
        duration: state.reduceMotion ? Duration.zero : RcMotion.medium,
        curve: RcMotion.expressiveCurve,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: .96),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: theme.colorScheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: .09),
              blurRadius: 22,
              offset: const Offset(0, 9),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: NavigationBar(
          selectedIndex: state.selectedTab,
          onDestinationSelected: state.selectTab,
          destinations: RcDestination.values
              .map(
                (d) => NavigationDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon),
                  label: d.label,
                  tooltip: d.label,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class RcHeader extends StatelessWidget {
  const RcHeader({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final p = state.profile!;
    final theme = Theme.of(context);
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: .88),
            border: Border(
              bottom: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 560;
              return Row(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(9),
                      bottomLeft: Radius.circular(9),
                      bottomRight: Radius.circular(16),
                    ),
                    child: Image.asset(
                      'assets/brand/rc_sow_house_icon.png',
                      width: 46,
                      height: 46,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'RC SOW',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        Text(
                          '${p.role} • ${p.parish}',
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!compact) ...[
                    IconButton(
                      tooltip: 'Field map',
                      onPressed: () => RcNavigator.liveTracker(
                        context,
                        state,
                        mapFirst: true,
                      ),
                      icon: const Icon(Icons.map_outlined),
                    ),
                    IconButton(
                      tooltip: 'Live Tracker',
                      onPressed: () => RcNavigator.liveTracker(context, state),
                      icon: const Icon(Icons.location_searching),
                    ),
                  ],
                  IconButton(
                    tooltip: 'Messages',
                    onPressed: () => RcNavigator.messages(context, state),
                    icon: const Badge(
                      child: Icon(Icons.notifications_outlined),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Settings',
                    onPressed: () => RcNavigator.settings(context, state),
                    icon: const Icon(Icons.settings_outlined),
                  ),
                  if (compact)
                    PopupMenuButton<String>(
                      tooltip: 'More field actions',
                      onSelected: (value) {
                        if (value == 'map') {
                          RcNavigator.liveTracker(
                            context,
                            state,
                            mapFirst: true,
                          );
                        } else if (value == 'tracker') {
                          RcNavigator.liveTracker(context, state);
                        } else if (value == 'users') {
                          RcNavigator.activeUsers(context, state);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'map', child: Text('Field map')),
                        PopupMenuItem(
                          value: 'tracker',
                          child: Text('Live Tracker'),
                        ),
                        PopupMenuItem(
                          value: 'users',
                          child: Text('Users online'),
                        ),
                      ],
                    ),
                ],
              );
            },
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
    final p = state.profile!;
    final actions = <_MoreAction>[
      _MoreAction(
        'Messages',
        'Team communication and notices',
        Icons.message_outlined,
        () => RcNavigator.messages(context, state),
      ),
      _MoreAction(
        'Live Tracker',
        'Parish tracker resources',
        Icons.location_searching,
        () => RcNavigator.liveTracker(context, state),
      ),
      _MoreAction(
        'Active Users',
        'Who is currently connected',
        Icons.group_outlined,
        () => RcNavigator.activeUsers(context, state),
      ),
      _MoreAction(
        'Settings',
        'Appearance, field tools and diagnostics',
        Icons.settings_outlined,
        () => RcNavigator.settings(context, state),
      ),
    ];
    if (p.canViewAdmin) {
      actions.add(
        _MoreAction(
          'Admin Dashboard',
          'Registration and account governance',
          Icons.admin_panel_settings_outlined,
          () => RcNavigator.admin(context, state),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
      children: [
        const RcPageHeading(
          eyebrow: 'Workspace',
          title: 'More',
          subtitle:
              'Secondary tools stay discoverable without overcrowding field navigation.',
        ),
        const SizedBox(height: 18),
        RcResponsiveGrid(
          minTileWidth: 220,
          children: actions
              .map(
                (a) => RcExpressiveSurface(
                  shape: RcSurfaceShape.offset,
                  onTap: a.onTap,
                  semanticLabel: a.title,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        a.icon,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const Spacer(),
                      Text(
                        a.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        a.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: () => Supabase.instance.client.auth.signOut(),
          icon: const Icon(Icons.logout),
          label: const Text('Sign out'),
        ),
      ],
    );
  }
}

class _MoreAction {
  const _MoreAction(this.title, this.subtitle, this.icon, this.onTap);
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
}
