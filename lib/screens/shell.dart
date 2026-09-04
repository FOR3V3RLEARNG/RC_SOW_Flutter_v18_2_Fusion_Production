import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/control_modules.dart';
import '../core/models.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import 'scope_screens.dart';

class AppShell extends StatefulWidget {
  const AppShell({this.initialIndex = 0, super.key});

  final int initialIndex;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _index = widget.initialIndex;

  static const _destinations = <NavigationDestination>[
    NavigationDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ),
    NavigationDestination(
      icon: Icon(Icons.architecture_outlined),
      selectedIcon: Icon(Icons.architecture),
      label: 'Scope',
    ),
    NavigationDestination(
      icon: Icon(Icons.fact_check_outlined),
      selectedIcon: Icon(Icons.fact_check),
      label: 'Control',
    ),
    NavigationDestination(
      icon: Icon(Icons.holiday_village_outlined),
      selectedIcon: Icon(Icons.holiday_village),
      label: 'Houses',
    ),
    NavigationDestination(
      icon: Icon(Icons.more_horiz),
      selectedIcon: Icon(Icons.more),
      label: 'More',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final pages = <Widget>[
      DashboardScreen(onDestination: _select),
      const ScopeWorkspace(),
      const ControlOfWorksScreen(),
      const HousesScreen(),
      const MoreScreen(),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final appBar = AppBar(
          automaticallyImplyLeading: false,
          titleSpacing: wide ? 24 : 16,
          title: Row(
            children: <Widget>[
              RcBrand(compact: !wide && constraints.maxWidth < 420),
              if (constraints.maxWidth >= 420) ...<Widget>[
                const SizedBox(width: 14),
                Container(
                  width: 1,
                  height: 28,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                const SizedBox(width: 14),
                Flexible(
                  child: Text(
                    '${state.role} • ${state.selectedParish}',
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              ],
            ],
          ),
          actions: <Widget>[
            IconButton(
              tooltip: 'Operational map',
              onPressed: () =>
                  Navigator.pushNamed(context, RcRoutes.operationalMap),
              icon: const Icon(Icons.map_outlined),
            ),
            IconButton(
              tooltip:
                  '${state.team.where((person) => person.online).length} users online',
              onPressed: () =>
                  Navigator.pushNamed(context, RcRoutes.usersOnline),
              icon: _CountedIcon(
                icon: Icons.group_outlined,
                count: state.team.where((person) => person.online).length,
                useBrand: false,
              ),
            ),
            IconButton(
              tooltip: 'Messages',
              onPressed: () => Navigator.pushNamed(context, RcRoutes.messages),
              icon: const Icon(Icons.chat_bubble_outline),
            ),
            IconButton(
              tooltip: 'Notifications',
              onPressed: () =>
                  Navigator.pushNamed(context, RcRoutes.notifications),
              icon: _CountedIcon(
                icon: Icons.notifications_outlined,
                count: state.unreadNotifications,
              ),
            ),
            IconButton(
              tooltip: 'Settings',
              onPressed: () => Navigator.pushNamed(context, RcRoutes.settings),
              icon: const Icon(Icons.settings_outlined),
            ),
            const SizedBox(width: 6),
          ],
        );

        final content = Column(
          children: <Widget>[
            const RcSyncBanner(),
            Expanded(
              child: IndexedStack(index: _index, children: pages),
            ),
          ],
        );

        if (!wide) {
          return Scaffold(
            appBar: appBar,
            body: content,
            floatingActionButton: _FieldCommsDock(
              onlineCount: state.team.where((person) => person.online).length,
            ),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.endFloat,
            bottomNavigationBar: NavigationBar(
              selectedIndex: _index,
              destinations: _destinations,
              onDestinationSelected: _select,
            ),
          );
        }

        return Scaffold(
          appBar: appBar,
          body: Row(
            children: <Widget>[
              NavigationRail(
                selectedIndex: _index,
                onDestinationSelected: _select,
                labelType: NavigationRailLabelType.all,
                groupAlignment: -.7,
                leading: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: IconButton.filled(
                    tooltip: 'New control',
                    onPressed: () =>
                        Navigator.pushNamed(context, RcRoutes.newControl),
                    icon: const Icon(Icons.add),
                  ),
                ),
                destinations: _destinations
                    .map(
                      (item) => NavigationRailDestination(
                        icon: item.icon,
                        selectedIcon: item.selectedIcon,
                        label: Text(item.label),
                      ),
                    )
                    .toList(),
              ),
              VerticalDivider(
                width: 1,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              Expanded(child: content),
            ],
          ),
        );
      },
    );
  }

  void _select(int index) => setState(() => _index = index);
}

class _CountedIcon extends StatelessWidget {
  const _CountedIcon({
    required this.icon,
    required this.count,
    this.useBrand = true,
  });

  final IconData icon;
  final int count;
  final bool useBrand;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Icon(icon),
        if (count > 0)
          Positioned(
            top: -7,
            right: -9,
            child: Container(
              constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: useBrand
                    ? Theme.of(context).colorScheme.primary
                    : RcColors.success,
                borderRadius: BorderRadius.circular(99),
              ),
              alignment: Alignment.center,
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 9,
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _FieldCommsDock extends StatelessWidget {
  const _FieldCommsDock({required this.onlineCount});

  final int onlineCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        ActionChip(
          avatar: const Icon(Icons.circle, size: 10, color: RcColors.success),
          label: Text('$onlineCount users online'),
          onPressed: () => Navigator.pushNamed(context, RcRoutes.usersOnline),
        ),
        const SizedBox(height: 8),
        FloatingActionButton.small(
          heroTag: 'field-comms',
          tooltip: 'Open field communications',
          onPressed: () => Navigator.pushNamed(context, RcRoutes.messages),
          child: const Icon(Icons.chat_bubble_outline),
        ),
      ],
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({required this.onDestination, super.key});

  final ValueChanged<int> onDestination;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final completedHouses =
        state.houses.where((house) => house.progress >= 1).length;
    final closureRatio = state.houses.isEmpty
        ? 0.0
        : completedHouses / state.houses.length;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[
                      colorScheme.primaryContainer,
                      dark
                          ? Color.alphaBlend(
                              RcColors.sunshine.withOpacity(.18),
                              colorScheme.surface,
                            )
                          : RcColors.sunshineSoft,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(38),
                    topRight: Radius.circular(22),
                    bottomLeft: Radius.circular(22),
                    bottomRight: Radius.circular(38),
                  ),
                  border: Border.all(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(.15),
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final copy = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const RcStatusChip(
                          label: 'LIVE PRODUCTION',
                          icon: Icons.bolt,
                          tone: RcStatusTone.brand,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'From assessment to paid completion',
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${state.activeHouses} active houses • ${state.attentionHouses} need attention. Keep approvals, field evidence, materials, completion and payment connected.',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                        ),
                        const SizedBox(height: 18),
                        FilledButton.icon(
                          onPressed: () => onDestination(2),
                          icon: const Icon(Icons.construction_outlined),
                          label: const Text('OPEN PRODUCTION CONTROL'),
                        ),
                      ],
                    );
                    final progress = _DashboardProgressOrb(
                      value: closureRatio,
                      complete: completedHouses,
                      total: state.houses.length,
                    );
                    if (constraints.maxWidth < 720) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          copy,
                          const SizedBox(height: 18),
                          Align(
                            alignment: Alignment.centerRight,
                            child: progress,
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: <Widget>[
                        Expanded(child: copy),
                        const SizedBox(width: 28),
                        progress,
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  ActionChip(
                    avatar: const Icon(Icons.architecture_outlined, size: 18),
                    label: const Text('Scope'),
                    onPressed: () => onDestination(1),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.fact_check_outlined, size: 18),
                    label: const Text('Control'),
                    onPressed: () => onDestination(2),
                  ),
                  ActionChip(
                    avatar: const Icon(
                      Icons.holiday_village_outlined,
                      size: 18,
                    ),
                    label: const Text('Houses'),
                    onPressed: () => onDestination(3),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.edit_note_outlined, size: 18),
                    label: const Text('Work logs'),
                    onPressed: () =>
                        Navigator.pushNamed(context, RcRoutes.workLogs),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.space_dashboard_outlined, size: 18),
                    label: const Text('Production board'),
                    onPressed: () => Navigator.pushNamed(
                      context,
                      RcRoutes.productionBoard,
                    ),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.swap_horiz_outlined, size: 18),
                    label: Text('Transfers (${state.pendingTransfers})'),
                    onPressed: () =>
                        Navigator.pushNamed(context, RcRoutes.transfers),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.diversity_3_outlined, size: 18),
                    label: const Text('Team community'),
                    onPressed: () =>
                        Navigator.pushNamed(context, RcRoutes.teamCommunity),
                  ),
                  ActionChip(
                    avatar:
                        const Icon(Icons.account_balance_outlined, size: 18),
                    label: const Text('HQ command'),
                    onPressed: () =>
                        Navigator.pushNamed(context, RcRoutes.hqCommand),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const RcSectionHeader(
                title: 'Operational pulse',
                subtitle: 'The items that need a decision or field action now.',
              ),
              const SizedBox(height: 12),
              RcResponsiveGrid(
                minItemWidth: 160,
                childAspectRatio: 1.05,
                children: <Widget>[
                  RcMetricTile(
                    label: 'Active houses',
                    value: '${state.activeHouses}',
                    icon: Icons.house_outlined,
                    color: RcColors.brand,
                    onTap: () => onDestination(3),
                  ),
                  RcMetricTile(
                    label: 'Needs attention',
                    value: '${state.attentionHouses}',
                    icon: Icons.warning_amber_rounded,
                    color: RcColors.warning,
                    onTap: () => onDestination(2),
                  ),
                  RcMetricTile(
                    label: 'Ready for close-out',
                    value: '${state.closeOutReady}',
                    icon: Icons.task_alt_outlined,
                    color: RcColors.success,
                    onTap: () =>
                        Navigator.pushNamed(context, RcRoutes.completion),
                  ),
                  RcMetricTile(
                    label: 'Payments pending',
                    value: '${state.paymentsPending}',
                    icon: Icons.payments_outlined,
                    color: RcColors.info,
                    onTap: () => Navigator.pushNamed(context, RcRoutes.payment),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              RcSectionHeader(
                title: 'Recent houses',
                subtitle:
                    'Continue the most recently active operational records.',
                trailing: TextButton(
                  onPressed: () => onDestination(3),
                  child: const Text('VIEW ALL'),
                ),
              ),
              const SizedBox(height: 12),
              RcResponsiveGrid(
                minItemWidth: 300,
                childAspectRatio: 1.5,
                children: state.houses.take(3).map((house) {
                  return RcHouseCard(
                    house: house,
                    onOpen: () {
                      state.selectHouse(house.code);
                      Navigator.pushNamed(context, RcRoutes.houseCommand);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),
              RcSectionHeader(
                title: 'Recent activity',
                trailing: TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, RcRoutes.activity),
                  child: const Text('FULL HISTORY'),
                ),
              ),
              const SizedBox(height: 10),
              Card(
                child: Column(
                  children: state.activities.take(3).map((entry) {
                    return ListTile(
                      leading: CircleAvatar(child: Icon(entry.icon, size: 20)),
                      title: Text('${entry.houseCode} • ${entry.title}'),
                      subtitle: Text(entry.detail),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        state.selectHouse(entry.houseCode);
                        Navigator.pushNamed(context, RcRoutes.activity);
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardProgressOrb extends StatelessWidget {
  const _DashboardProgressOrb({
    required this.value,
    required this.complete,
    required this.total,
  });

  final double value;
  final int complete;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final reducedMotion = AppScope.of(context).reducedMotion;
    return Semantics(
      label: '$complete of $total houses complete',
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: value),
        duration: Duration(milliseconds: reducedMotion ? 0 : 750),
        curve: Curves.easeOutCubic,
        builder: (context, animatedValue, _) {
          return SizedBox(
            width: 116,
            height: 116,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: animatedValue.clamp(0, 1).toDouble(),
                    strokeWidth: 11,
                    strokeCap: StrokeCap.round,
                    color: colorScheme.primary,
                    backgroundColor: colorScheme.primary.withOpacity(.14),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      '${(animatedValue * 100).round()}%',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    Text(
                      'closed',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class ControlOfWorksScreen extends StatefulWidget {
  const ControlOfWorksScreen({super.key});

  @override
  State<ControlOfWorksScreen> createState() => _ControlOfWorksScreenState();
}

class _ControlOfWorksScreenState extends State<ControlOfWorksScreen> {
  LifecyclePhase? _filter;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final modulesById = <String, ControlModuleDefinition>{
      for (final module in ControlModules.all) module.id: module,
    };
    final modules = state.controlTileOrder
        .where(modulesById.containsKey)
        .map((id) => modulesById[id]!)
        .where((module) => !state.hiddenControlTiles.contains(module.id))
        .where((module) => _filter == null || module.phase == _filter)
        .toList();
    if (state.controlGrouping == 'Priority') {
      modules.sort((a, b) => a.priority.compareTo(b.priority));
    }
    final compact = state.controlDensity == 'Compact';
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              RcPageHeading(
                eyebrow: 'Control / Production',
                title: 'Control of Works',
                description:
                    'Plan, deliver, inspect, close and pay while preserving a complete evidence trail.',
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  FilledButton.icon(
                    onPressed: () =>
                        Navigator.pushNamed(context, RcRoutes.newControl),
                    icon: const Icon(Icons.add),
                    label: const Text('NEW CONTROL'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () =>
                        Navigator.pushNamed(context, RcRoutes.controlLayout),
                    icon: const Icon(Icons.dashboard_customize_outlined),
                    label: const Text('CUSTOMIZE DIVISIONS & TILES'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (state.controlShowHero) ...<Widget>[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: <Color>[
                        colorScheme.primaryContainer,
                        dark
                            ? Color.alphaBlend(
                                RcColors.sunshine.withOpacity(.18),
                                colorScheme.surface,
                              )
                            : RcColors.sunshineSoft,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(34),
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(34),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Controlled delivery chain',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Every field action remains traceable to a house, parish, status and production stage.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 20),
                      const RcLifecycleRail(phase: LifecyclePhase.delivery),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],
              if (state.controlShowInsights) ...<Widget>[
                RcResponsiveGrid(
                  minItemWidth: 160,
                  childAspectRatio: 1.05,
                  children: <Widget>[
                    RcMetricTile(
                      label: 'Open production',
                      value: '${state.activeHouses}',
                      icon: Icons.home_work_outlined,
                      color: RcColors.brand,
                      onTap: () =>
                          Navigator.pushNamed(context, RcRoutes.houses),
                    ),
                    RcMetricTile(
                      label: 'Needs attention',
                      value: '${state.attentionHouses}',
                      icon: Icons.report_problem_outlined,
                      color: RcColors.warning,
                      onTap: () => Navigator.pushNamed(
                        context,
                        RcRoutes.productionCommand,
                      ),
                    ),
                    RcMetricTile(
                      label: 'Pending transfers',
                      value: '${state.pendingTransfers}',
                      icon: Icons.swap_horiz_outlined,
                      color: RcColors.info,
                      onTap: () =>
                          Navigator.pushNamed(context, RcRoutes.transfers),
                    ),
                    RcMetricTile(
                      label: 'Crews deployed',
                      value: '${state.crewsDeployed}',
                      icon: Icons.groups_2_outlined,
                      color: RcColors.success,
                      onTap: () => Navigator.pushNamed(
                        context,
                        RcRoutes.teamResources,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
              ],
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  ChoiceChip(
                    label: const Text('All'),
                    selected: _filter == null,
                    onSelected: (_) => setState(() => _filter = null),
                  ),
                  for (final phase in LifecyclePhase.values)
                    ChoiceChip(
                      avatar: Icon(phase.icon, size: 17),
                      label: Text(phase.label),
                      selected: _filter == phase,
                      onSelected: (_) => setState(() => _filter = phase),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              RcSectionHeader(
                title: switch (state.controlGrouping) {
                  'Priority' => 'Priority workflow',
                  'Custom' => 'Custom tile sequence',
                  _ => 'Lifecycle divisions',
                },
                subtitle:
                    '${modules.length} visible connected operational modules • ${state.controlDensity.toLowerCase()}',
                trailing: TextButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, RcRoutes.controlLayout),
                  icon: const Icon(Icons.tune_outlined),
                  label: const Text('EDIT'),
                ),
              ),
              const SizedBox(height: 12),
              if (modules.isEmpty)
                RcEmptyState(
                  icon: Icons.dashboard_customize_outlined,
                  title: 'No visible modules in this division',
                  message:
                      'Adjust the phase filter or restore tiles in Customize Control.',
                  action: FilledButton.tonal(
                    onPressed: () =>
                        Navigator.pushNamed(context, RcRoutes.controlLayout),
                    child: const Text('CUSTOMIZE CONTROL'),
                  ),
                )
              else if (state.controlGrouping == 'Lifecycle' &&
                  _filter == null)
                for (final phase in LifecyclePhase.values)
                  if (modules.any((module) => module.phase == phase)) ...<Widget>[
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 10),
                      child: RcSectionHeader(
                        title: phase.label,
                        subtitle:
                            '${modules.where((module) => module.phase == phase).length} modules',
                      ),
                    ),
                    RcResponsiveGrid(
                      minItemWidth: compact ? 260 : 320,
                      childAspectRatio: compact ? 2.05 : 1.65,
                      children: modules
                          .where((module) => module.phase == phase)
                          .map(
                            (module) => _ControlModuleCard(
                              module: module,
                              compact: compact,
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                  ]
              else
                RcResponsiveGrid(
                  minItemWidth: compact ? 260 : 320,
                  childAspectRatio: compact ? 2.05 : 1.65,
                  children: modules
                      .map(
                        (module) => _ControlModuleCard(
                          module: module,
                          compact: compact,
                        ),
                      )
                      .toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ControlModuleCard extends StatelessWidget {
  const _ControlModuleCard({required this.module, required this.compact});

  final ControlModuleDefinition module;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final moduleColor = switch (module.phase) {
      LifecyclePhase.scope => RcColors.brand,
      LifecyclePhase.plan => RcColors.plum,
      LifecyclePhase.delivery => RcColors.info,
      LifecyclePhase.quality => RcColors.mint,
      LifecyclePhase.closeOut => RcColors.success,
      LifecyclePhase.finance => RcColors.sunshine,
    };
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, module.route),
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: moduleColor.withOpacity(.13),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(10),
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.circular(18),
                  ),
                ),
                child: Icon(
                  module.icon,
                  color: moduleColor,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    RcStatusChip(
                      label: module.phase.label.toUpperCase(),
                      compact: true,
                      tone: RcStatusTone.info,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      module.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (!compact) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        module.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward, size: 19),
            ],
          ),
        ),
      ),
    );
  }
}

class HousesScreen extends StatefulWidget {
  const HousesScreen({super.key});

  @override
  State<HousesScreen> createState() => _HousesScreenState();
}

class _HousesScreenState extends State<HousesScreen> {
  final _searchController = TextEditingController();
  LifecyclePhase? _phase;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final query = _searchController.text.toLowerCase().trim();
    final houses = state.houses.where((house) {
      final matchesQuery = query.isEmpty ||
          house.code.toLowerCase().contains(query) ||
          house.beneficiary.toLowerCase().contains(query) ||
          house.community.toLowerCase().contains(query);
      return matchesQuery && (_phase == null || house.phase == _phase);
    }).toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const RcPageHeading(
                eyebrow: 'Production Records',
                title: 'Houses',
                description:
                    'One operational truth for every beneficiary house, lifecycle state and evidence chain.',
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Search house, beneficiary or community',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: query.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.close),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: <Widget>[
                    ChoiceChip(
                      label: const Text('All phases'),
                      selected: _phase == null,
                      onSelected: (_) => setState(() => _phase = null),
                    ),
                    const SizedBox(width: 8),
                    for (final phase in LifecyclePhase.values) ...<Widget>[
                      ChoiceChip(
                        label: Text(phase.label),
                        selected: _phase == phase,
                        onSelected: (_) => setState(() => _phase = phase),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              RcSectionHeader(
                title: '${houses.length} house${houses.length == 1 ? '' : 's'}',
                subtitle: '${state.selectedParish} operational scope',
              ),
              const SizedBox(height: 12),
              if (houses.isEmpty)
                const RcEmptyState(
                  icon: Icons.search_off,
                  title: 'No matching houses',
                  message:
                      'Adjust the search or lifecycle filter. No records were changed.',
                )
              else
                RcResponsiveGrid(
                  minItemWidth: 300,
                  childAspectRatio: 1.48,
                  children: houses.map((house) {
                    return RcHouseCard(
                      house: house,
                      onOpen: () {
                        state.selectHouse(house.code);
                        Navigator.pushNamed(context, RcRoutes.houseCommand);
                      },
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final groups = <_MoreGroup>[
      const _MoreGroup('Field operations', <_MoreItem>[
        _MoreItem('Work Logs', Icons.edit_note_outlined, RcRoutes.workLogs),
        _MoreItem(
          'Work Projection Log',
          Icons.trending_up_outlined,
          RcRoutes.workProjections,
        ),
        _MoreItem(
          'Production Command Board',
          Icons.space_dashboard_outlined,
          RcRoutes.productionBoard,
        ),
        _MoreItem(
          'Transfer Management',
          Icons.swap_horiz_outlined,
          RcRoutes.transfers,
        ),
        _MoreItem(
          'Construction Schedule',
          Icons.event_available_outlined,
          RcRoutes.schedule,
        ),
        _MoreItem(
          'Live Team Briefing',
          Icons.video_camera_front_outlined,
          RcRoutes.liveBriefing,
        ),
        _MoreItem(
          'Inventory Tracker',
          Icons.inventory_2_outlined,
          RcRoutes.inventory,
        ),
        _MoreItem(
          'Parish / House Stock Transfer',
          Icons.move_down_outlined,
          RcRoutes.inventoryTransfer,
        ),
        _MoreItem(
          'Evidence Viewer',
          Icons.photo_library_outlined,
          RcRoutes.evidence,
        ),
        _MoreItem(
          'Operational Map',
          Icons.map_outlined,
          RcRoutes.operationalMap,
        ),
      ]),
      const _MoreGroup('Communication', <_MoreItem>[
        _MoreItem('Messages', Icons.forum_outlined, RcRoutes.messages),
        _MoreItem(
          'Notifications',
          Icons.notifications_outlined,
          RcRoutes.notifications,
        ),
        _MoreItem('Users Online', Icons.group_outlined, RcRoutes.usersOnline),
        _MoreItem('Gmail', Icons.mail_outline, RcRoutes.gmail),
      ]),
      const _MoreGroup('Team and community', <_MoreItem>[
        _MoreItem(
          'Team Excellence Community',
          Icons.diversity_3_outlined,
          RcRoutes.teamCommunity,
        ),
        _MoreItem(
          'Team Performance',
          Icons.insights_outlined,
          RcRoutes.teamPerformance,
        ),
        _MoreItem(
          'Team Resource Manager',
          Icons.groups_2_outlined,
          RcRoutes.teamResources,
        ),
        _MoreItem(
          'Promotion Routing',
          Icons.military_tech_outlined,
          RcRoutes.promotionRouting,
        ),
      ]),
      const _MoreGroup('Command and review', <_MoreItem>[
        _MoreItem(
          'Production Command',
          Icons.precision_manufacturing_outlined,
          RcRoutes.productionCommand,
        ),
        _MoreItem(
          'Finance Command',
          Icons.account_balance_wallet_outlined,
          RcRoutes.financeCommand,
        ),
        _MoreItem(
          'Connected Approval Queue',
          Icons.approval_outlined,
          RcRoutes.approvalQueue,
        ),
        _MoreItem(
          'HQ Command Centre',
          Icons.account_balance_outlined,
          RcRoutes.hqCommand,
        ),
        _MoreItem(
          'Institutional Report',
          Icons.summarize_outlined,
          RcRoutes.institutionalReport,
        ),
        _MoreItem(
          'Production Analytics',
          Icons.analytics_outlined,
          RcRoutes.analytics,
        ),
        _MoreItem('Activity History', Icons.history, RcRoutes.activity),
      ]),
      const _MoreGroup('Administration', <_MoreItem>[
        _MoreItem(
          'Offline Sync Monitor',
          Icons.sync_outlined,
          RcRoutes.syncMonitor,
        ),
        _MoreItem(
          'Image & Legacy Import',
          Icons.auto_awesome_outlined,
          RcRoutes.scopeImport,
        ),
        _MoreItem(
          'Administration Command',
          Icons.settings_suggest_outlined,
          RcRoutes.adminCommand,
        ),
        _MoreItem(
          'Control Layout',
          Icons.dashboard_customize_outlined,
          RcRoutes.controlLayout,
        ),
        _MoreItem(
          'Transfer Logic',
          Icons.alt_route_outlined,
          RcRoutes.transferAutomation,
        ),
        _MoreItem(
          'Awards & Incentives',
          Icons.workspace_premium_outlined,
          RcRoutes.awardsIncentives,
        ),
        _MoreItem(
          'User Access',
          Icons.admin_panel_settings_outlined,
          RcRoutes.adminUsers,
        ),
        _MoreItem(
          'Templates',
          Icons.dashboard_customize_outlined,
          RcRoutes.adminTemplates,
        ),
      ]),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              RcPageHeading(
                eyebrow: state.role,
                title: 'More operations',
                description:
                    'Collaboration, review, administration and account controls.',
              ),
              const SizedBox(height: 20),
              for (final group in groups) ...<Widget>[
                RcSectionHeader(title: group.title),
                const SizedBox(height: 10),
                Card(
                  child: Column(
                    children: group.items.map((item) {
                      return Material(
                        color: Colors.transparent,
                        child: ListTile(
                          minLeadingWidth: 34,
                          leading: Icon(
                            item.icon,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: Text(
                            item.label,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.pushNamed(context, item.route),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 22),
              ],
              FilledButton.tonalIcon(
                onPressed: () =>
                    Navigator.pushNamed(context, RcRoutes.settings),
                icon: const Icon(Icons.settings_outlined),
                label: const Text('SETTINGS & ACCESSIBILITY'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreGroup {
  const _MoreGroup(this.title, this.items);
  final String title;
  final List<_MoreItem> items;
}

class _MoreItem {
  const _MoreItem(this.label, this.icon, this.route);
  final String label;
  final IconData icon;
  final String route;
}
