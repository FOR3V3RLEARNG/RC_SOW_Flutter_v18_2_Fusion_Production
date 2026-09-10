import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/design_tokens.dart';
import '../../core/navigation.dart';
import '../../core/rc_components.dart';
import '../../core/text_helpers.dart';
import '../../state/app_state.dart';
import '../admin/admin_screen.dart';
import '../admin/operations_admin_screen.dart';
import '../beneficiaries/beneficiary_search_screen.dart';
import '../community/community_screen.dart';
import '../control/control_screen.dart';
import '../control/house_operations_control_screen.dart';
import '../live/interactive_house_map_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../houses/houses_screen.dart';
import '../messages/messages_screen.dart';
import '../scope/scope_screen.dart';
import '../settings/settings_screen.dart';
import '../users/active_users_screen.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final profile = state.profile;
    if (profile == null || !profile.approved || !profile.active) {
      return _ApprovalGate(state: state);
    }

    final pages = <Widget>[
      DashboardScreen(state: state),
      ScopeScreen(state: state),
      HouseOperationsControlScreen(state: state),
      HousesScreen(state: state),
      CommunityScreen(state: state),
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
                  begin: const Offset(.012, 0),
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
      bottomNavigationBar: wide ? null : _SlidingNavigationIsland(state: state),
      floatingActionButton: _OnlineUsersFab(state: state),
    );
  }
}

class _ApprovalGate extends StatelessWidget {
  const _ApprovalGate({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final profile = state.profile;
    final restricted =
        profile != null &&
        (!profile.active ||
            const {
              'blocked',
              'suspended',
            }.contains(profile.registrationStatus));
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
                    restricted
                        ? Icons.block_outlined
                        : Icons.hourglass_top_rounded,
                    size: 56,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    restricted
                        ? 'Account access restricted'
                        : 'Account approval required',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    restricted
                        ? 'An Admin has suspended or blocked this account. Contact an RC SOW administrator for access review.'
                        : 'This signed-in account is awaiting administrator approval or an assigned RC SOW role.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: state.refreshProfile,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Check access status'),
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
      width: 116,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          const SizedBox(height: 14),
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
          const SizedBox(height: 8),
          Expanded(
            child: NavigationRail(
              selectedIndex: state.selectedTab,
              onDestinationSelected: state.selectTab,
              labelType: NavigationRailLabelType.all,
              groupAlignment: -.18,
              destinations: RcDestination.values
                  .map(
                    (d) => NavigationRailDestination(
                      icon: Icon(
                        state.uiIcon('nav.${d.name}', d.icon),
                        size: RcIconSize.sm,
                      ),
                      selectedIcon: Icon(
                        state.uiIcon('nav.${d.name}', d.selectedIcon),
                        size: RcIconSize.sm,
                      ),
                      label: Text(d.label),
                    ),
                  )
                  .toList(),
            ),
          ),
          IconButton(
            tooltip: 'More',
            onPressed: () => showRcMoreMenu(context, state),
            icon: const Icon(Icons.apps_outlined, size: RcIconSize.sm),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => SettingsScreen(state: state)),
            ),
            icon: Icon(
              state.uiIcon('header.settings', Icons.settings_outlined),
              size: RcIconSize.sm,
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _SlidingNavigationIsland extends StatelessWidget {
  const _SlidingNavigationIsland({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: .97),
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final itemCount = RcDestination.values.length + 3;
            final canSpread = constraints.maxWidth >= itemCount * 62;
            final buttonWidth = canSpread
                ? (constraints.maxWidth - 10) / itemCount
                : 70.0;

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: Row(
                  mainAxisAlignment: canSpread
                      ? MainAxisAlignment.spaceEvenly
                      : MainAxisAlignment.start,
                  children: [
                    ...RcDestination.values.map(
                      (d) => _NavButton(
                        width: buttonWidth,
                        label: d.label,
                        icon: state.uiIcon('nav.${d.name}', d.icon),
                        selectedIcon: state.uiIcon(
                          'nav.${d.name}',
                          d.selectedIcon,
                        ),
                        selected: state.selectedTab == d.index,
                        onTap: () => state.selectTab(d.index),
                      ),
                    ),
                    _NavButton(
                      width: buttonWidth,
                      label: 'Map',
                      icon: state.uiIcon('nav.map', Icons.map_outlined),
                      selected: false,
                      onTap: () async {
                        final result = await Navigator.of(context).push<String>(
                          MaterialPageRoute(
                            builder: (_) =>
                                InteractiveHouseMapScreen(state: state),
                          ),
                        );
                        if (result == 'tracker' && context.mounted) {
                          RcNavigator.liveTracker(context, state);
                        }
                      },
                    ),
                    _NavButton(
                      width: buttonWidth,
                      label: 'Tracker',
                      icon: state.uiIcon(
                        'nav.tracker',
                        Icons.location_searching,
                      ),
                      selected: false,
                      onTap: () => RcNavigator.liveTracker(context, state),
                    ),
                    _NavButton(
                      width: buttonWidth,
                      label: 'More',
                      icon: Icons.more_horiz,
                      selected: false,
                      onTap: () => showRcMoreMenu(context, state),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    this.label,
    this.icon,
    this.selectedIcon,
    this.width = 76,
    required this.selected,
    required this.onTap,
  }) : destination = null;
  final RcDestination? destination;
  final String? label;
  final IconData? icon;
  final IconData? selectedIcon;
  final double width;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final d = destination;
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: width,
        margin: const EdgeInsets.symmetric(horizontal: 1, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primaryContainer
              : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected
                  ? (selectedIcon ?? d?.selectedIcon ?? icon)
                  : (d?.icon ?? icon),
              size: RcIconSize.sm,
              color: selected
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 3),
            Text(
              d?.label ?? label ?? '',
              maxLines: 1,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ],
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
            color: theme.colorScheme.surface.withValues(alpha: .9),
            border: Border(
              bottom: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            children: [
              InkWell(
                onTap: () => state.selectTab(0),
                borderRadius: BorderRadius.circular(16),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(9),
                    bottomLeft: Radius.circular(9),
                    bottomRight: Radius.circular(16),
                  ),
                  child: Image.asset(
                    'assets/brand/rc_sow_house_icon.png',
                    width: 44,
                    height: 44,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.uiText('appTitle', 'Red Cross Scope Of Work'),
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Text(
                      'Welcome, ${rcTitleCase(p.displayName)} • '
                      '${rcTitleCase(p.canViewAllParishes ? 'All Parishes' : p.parish)} • '
                      '${rcTitleCase(p.role)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'IA Shelter beneficiary data',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BeneficiarySearchScreen(state: state),
                  ),
                ),
                icon: const Icon(
                  Icons.auto_awesome_outlined,
                  size: RcIconSize.sm,
                ),
              ),
              IconButton(
                tooltip: 'Field map',
                onPressed: () async {
                  final result = await Navigator.of(context).push<String>(
                    MaterialPageRoute(
                      builder: (_) => InteractiveHouseMapScreen(state: state),
                    ),
                  );
                  if (result == 'tracker' && context.mounted) {
                    RcNavigator.liveTracker(context, state);
                  }
                },
                icon: Icon(
                  state.uiIcon('nav.map', Icons.map_outlined),
                  size: RcIconSize.sm,
                ),
              ),
              IconButton(
                tooltip: 'Live Tracker',
                onPressed: () => RcNavigator.liveTracker(context, state),
                icon: Icon(
                  state.uiIcon('nav.tracker', Icons.location_searching),
                  size: RcIconSize.sm,
                ),
              ),
              IconButton.filledTonal(
                tooltip: 'Notification Centre',
                onPressed: () => showNotificationCentre(context, state),
                icon: Badge(
                  child: Icon(
                    state.uiIcon(
                      'header.notifications',
                      Icons.notifications_active_rounded,
                    ),
                    size: RcIconSize.md,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Settings',
                onPressed: () => RcNavigator.settings(context, state),
                icon: Icon(
                  state.uiIcon('header.settings', Icons.settings_outlined),
                  size: RcIconSize.sm,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showRcMoreMenu(
  BuildContext context,
  AppState state,
) async {
  final profile = state.profile!;
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'More',
    barrierColor: Colors.black.withValues(alpha: .14),
    transitionDuration: state.reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 190),
    pageBuilder: (context, animation, secondaryAnimation) {
      final media = MediaQuery.of(context);
      final menuWidth = (media.size.width - 20).clamp(286.0, 356.0).toDouble();
      final menuHeight = (media.size.height * .62).clamp(360.0, 590.0);

      void closeThen(VoidCallback action) {
        Navigator.pop(context);
        Future<void>.delayed(Duration.zero, action);
      }

      return Align(
        alignment: Alignment.topRight,
        child: SafeArea(
          minimum: const EdgeInsets.fromLTRB(8, 64, 8, 8),
          child: Material(
            color: Colors.transparent,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: menuWidth,
                maxWidth: menuWidth,
                maxHeight: menuHeight,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                      color: Theme.of(context)
                          .colorScheme
                          .shadow
                          .withValues(alpha: .15),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                    shrinkWrap: true,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(7, 5, 4, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'More quick actions',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w900),
                                  ),
                                  Text(
                                    profile.role,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                      ),
                      _CompactMoreAction(
                        icon: Icons.notifications_active_outlined,
                        label: 'Notifications',
                        onTap: () => closeThen(
                          () => showNotificationCentre(context, state),
                        ),
                      ),
                      _CompactMoreAction(
                        icon: Icons.visibility_outlined,
                        label: 'Presence / online users',
                        onTap: () => closeThen(
                          () => showUsersOnlinePanel(context, state),
                        ),
                      ),
                      _CompactMoreAction(
                        icon: Icons.location_searching,
                        label: 'Live tracker',
                        onTap: () => closeThen(
                          () => RcNavigator.liveTracker(context, state),
                        ),
                      ),
                      _CompactMoreAction(
                        icon: Icons.storage_outlined,
                        label: 'Production database',
                        onTap: () => closeThen(
                          () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  ProductionDatabaseScreen(state: state),
                            ),
                          ),
                        ),
                      ),
                      _CompactMoreAction(
                        icon: Icons.settings_outlined,
                        label: 'Settings',
                        onTap: () => closeThen(
                          () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SettingsScreen(state: state),
                            ),
                          ),
                        ),
                      ),
                      if (profile.canViewAdmin) ...[
                        const Divider(height: 16),
                        _CompactMoreAction(
                          icon: Icons.tune_rounded,
                          label: 'Operations Admin',
                          admin: true,
                          onTap: () => closeThen(
                            () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    OperationsAdminScreen(state: state),
                              ),
                            ),
                          ),
                        ),
                        _CompactMoreAction(
                          icon: Icons.admin_panel_settings_outlined,
                          label: 'Admin Control Centre',
                          admin: true,
                          onTap: () => closeThen(
                            () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AdminScreen(state: state),
                              ),
                            ),
                          ),
                        ),
                      ],
                      const Divider(height: 16),
                      _CompactMoreAction(
                        icon: Icons.logout_rounded,
                        label: 'Sign out',
                        destructive: true,
                        onTap: () => closeThen(
                          () => Supabase.instance.client.auth.signOut(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (_, animation, __, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          alignment: Alignment.topRight,
          scale: Tween<double>(begin: .96, end: 1).animate(curved),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(.05, -.04),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        ),
      );
    },
  );
}

class _CompactMoreAction extends StatelessWidget {
  const _CompactMoreAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.admin = false,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool admin;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = destructive
        ? theme.colorScheme.error
        : admin
            ? theme.colorScheme.secondary
            : theme.colorScheme.primary;

    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(vertical: -2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(17),
      ),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: .10),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, size: 19, color: accent),
      ),
      title: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: destructive ? theme.colorScheme.error : null,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, size: 18),
      onTap: onTap,
    );
  }
}


class _MoreTile extends StatelessWidget {
  const _MoreTile(this.label, this.icon, this.onTap);
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => RcExpressiveSurface(
    shape: RcSurfaceShape.offset,
    onTap: onTap,
    child: Row(
      children: [
        RcIconWell(
          icon: icon,
          color: Theme.of(context).colorScheme.primary,
          size: 44,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.titleMedium),
        ),
        const Icon(Icons.chevron_right),
      ],
    ),
  );
}

class _OnlineUsersFab extends StatefulWidget {
  const _OnlineUsersFab({required this.state});
  final AppState state;

  @override
  State<_OnlineUsersFab> createState() => _OnlineUsersFabState();
}

class _OnlineUsersFabState extends State<_OnlineUsersFab> {
  Timer? timer;
  int count = 0;

  @override
  void initState() {
    super.initState();
    _refresh();
    timer = Timer.periodic(const Duration(seconds: 30), (_) => _refresh());
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final users = await widget.state.repository.activeUsers();
      if (mounted && users.length != count) {
        setState(() => count = users.length);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    return FloatingActionButton.extended(
      heroTag: 'users-online-popup',
      onPressed: () async {
        widget.state.feedback();
        await showUsersOnlinePanel(context, widget.state);
        await _refresh();
      },
      icon: const Icon(Icons.group_outlined, size: RcIconSize.sm),
      label: Text('$count online'),
      backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
      foregroundColor: Theme.of(context).colorScheme.onTertiaryContainer,
    );
  }
}
