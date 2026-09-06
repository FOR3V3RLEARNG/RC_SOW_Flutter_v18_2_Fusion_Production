import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/design_tokens.dart';
import '../../core/navigation.dart';
import '../../core/rc_components.dart';
import '../../state/app_state.dart';
import '../admin/admin_screen.dart';
import '../beneficiaries/beneficiary_search_screen.dart';
import '../community/community_screen.dart';
import '../control/control_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../gmail/gmail_screen.dart';
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
    if (profile == null || !profile.approved || !profile.active)
      return _ApprovalGate(state: state);

    final pages = <Widget>[
      DashboardScreen(state: state),
      ScopeScreen(state: state),
      ControlScreen(state: state),
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
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'users-online-popup',
        onPressed: () {
          state.feedback();
          showUsersOnlinePanel(context, state);
        },
        icon: const Icon(Icons.group_outlined, size: RcIconSize.sm),
        label: width < 420 ? const Text('Online') : const Text('Users online'),
        backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onTertiaryContainer,
      ),
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
                      icon: Icon(d.icon, size: RcIconSize.sm),
                      selectedIcon: Icon(d.selectedIcon, size: RcIconSize.sm),
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
            icon: const Icon(Icons.settings_outlined, size: RcIconSize.sm),
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
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Row(
            children: [
              ...RcDestination.values.map(
                (d) => _NavButton(
                  destination: d,
                  selected: state.selectedTab == d.index,
                  onTap: () => state.selectTab(d.index),
                ),
              ),
              _NavButton(
                label: 'More',
                icon: Icons.more_horiz,
                selected: false,
                onTap: () => showRcMoreMenu(context, state),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    this.destination,
    this.label,
    this.icon,
    required this.selected,
    required this.onTap,
  });
  final RcDestination? destination;
  final String? label;
  final IconData? icon;
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
        width: 76,
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
              selected ? (d?.selectedIcon ?? icon) : (d?.icon ?? icon),
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
              ClipRRect(
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
              const SizedBox(width: 9),
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
                      '${p.role} • ${p.canViewAllParishes ? 'All Parishes' : p.parish}',
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
                onPressed: () =>
                    RcNavigator.liveTracker(context, state, mapFirst: true),
                icon: const Icon(Icons.map_outlined, size: RcIconSize.sm),
              ),
              IconButton(
                tooltip: 'Messages',
                onPressed: () => showMessageDrawer(context, state),
                icon: const Badge(
                  child: Icon(Icons.forum_outlined, size: RcIconSize.sm),
                ),
              ),
              if (MediaQuery.sizeOf(context).width >= 650)
                IconButton(
                  tooltip: 'Settings',
                  onPressed: () => RcNavigator.settings(context, state),
                  icon: const Icon(
                    Icons.settings_outlined,
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

Future<void> showRcMoreMenu(BuildContext context, AppState state) async {
  final profile = state.profile!;
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => FractionallySizedBox(
      heightFactor: .72,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: ListView(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'More',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        'Secondary commands remain discoverable without crowding field navigation.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
            RcResponsiveGrid(
              minTileWidth: 180,
              children: [
                _MoreTile('Messages', Icons.forum_outlined, () {
                  Navigator.pop(context);
                  showMessageDrawer(context, state);
                }),
                _MoreTile('Users online', Icons.group_outlined, () {
                  Navigator.pop(context);
                  showUsersOnlinePanel(context, state);
                }),
                _MoreTile('Gmail', Icons.mail_outline, () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => GmailScreen(state: state),
                    ),
                  );
                }),
                _MoreTile('Live tracker', Icons.location_searching, () {
                  Navigator.pop(context);
                  RcNavigator.liveTracker(context, state);
                }),
                _MoreTile('Production database', Icons.storage_outlined, () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProductionDatabaseScreen(state: state),
                    ),
                  );
                }),
                _MoreTile('Settings', Icons.settings_outlined, () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SettingsScreen(state: state),
                    ),
                  );
                }),
                if (profile.canViewAdmin)
                  _MoreTile(
                    'Admin Control Centre',
                    Icons.admin_panel_settings_outlined,
                    () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AdminScreen(state: state),
                        ),
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => Supabase.instance.client.auth.signOut(),
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
            ),
          ],
        ),
      ),
    ),
  );
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
        Icon(
          icon,
          size: RcIconSize.sm,
          color: Theme.of(context).colorScheme.primary,
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
