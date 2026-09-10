import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/design_tokens.dart';
import '../../core/record_schemas.dart';
import '../../core/product_registry.dart';
import '../../core/rc_components.dart';
import '../../core/text_helpers.dart';
import '../../models/app_models.dart';
import '../../state/app_state.dart';
import '../admin/admin_screen.dart';
import '../admin/operations_admin_screen.dart';
import '../beneficiaries/beneficiary_search_screen.dart';
import '../control/control_screen.dart';
import '../messages/messages_screen.dart';
import '../settings/settings_screen.dart';
import '../workforce/crew_attendance_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.state});
  final AppState state;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<_DashboardData> future;

  @override
  void initState() {
    super.initState();
    future = _load();
  }

  Future<_DashboardData> _load() async {
    final profile = widget.state.profile!;
    final data = await Future.wait([
      widget.state.repository.houses(profile),
      widget.state.repository.productionRecords(profile),
    ]);

    var messages = const <MessageRecord>[];
    var community = const <ProductionRecord>[];

    try {
      messages = await widget.state.repository.messages(profile, limit: 20);
    } catch (_) {
      // Dashboard still loads if notification retrieval is temporarily unavailable.
    }

    try {
      community = await widget.state.repository.communityRecords(
        profile,
        limit: 20,
      );
    } catch (_) {
      // Community ticker is optional and must never block field operations.
    }

    return _DashboardData(
      houses: data[0] as List<HouseRecord>,
      records: data[1] as List<ProductionRecord>,
      messages: messages,
      community: community,
    );
  }

  Future<void> refresh() async {
    setState(() => future = _load());
    await future;
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.state.profile!;
    final experience = RcProductRegistry.experience(profile);
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: refresh,
      child: FutureBuilder<_DashboardData>(
        future: future,
        builder: (_, snap) {
          final data = snap.data ?? const _DashboardData();
          final paymentsDue = data.records
              .where((r) => r.eventType == 'payment' && r.status != 'Paid')
              .toList();
          final paymentsPaid = data.records
              .where((r) => r.eventType == 'payment' && r.status == 'Paid')
              .toList();
          final actionRequired = data.records
              .where(
                (r) =>
                    r.needsAttention ||
                    const {
                      'Submitted',
                      'In Review',
                      'Pending',
                    }.contains(r.status),
              )
              .toList();
          final recentHouse = data.houses.isEmpty ? null : data.houses.first;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 124),
            children: [
              RcPageHeading(
                eyebrow: experience.eyebrow,
                title: 'Welcome, ${rcTitleCase(profile.displayName)}',
                subtitle:
                    '${rcTitleCase(profile.canViewAllParishes ? 'All Parishes' : profile.parish)} • '
                    '${rcTitleCase(profile.role)}\n${experience.subtitle}',
                trailing: RcStatusPill(
                  label: profile.canViewAllParishes
                      ? 'ALL PARISHES'
                      : profile.parish.toUpperCase(),
                  icon: Icons.location_on_outlined,
                  color: theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 16),
              _RoleHero(
                profile: profile,
                experience: experience,
                data: data,
                onControl: () => widget.state.selectTab(3),
              ),
              const SizedBox(height: 14),
              _ProductionChainNav(onOpenPhase: _openPhase),
              const SizedBox(height: 18),
              Text('Operational pulse', style: theme.textTheme.titleLarge),
              const SizedBox(height: 10),
              RcResponsiveGrid(
                minTileWidth: 190,
                childAspectRatio: 2.05,
                children: _metrics(
                  profile,
                  data,
                  paymentsDue.length,
                  actionRequired.length,
                ),
              ),
              const SizedBox(height: 16),
              _DashboardCommandStrip(
                profile: profile,
                onSettings: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SettingsScreen(state: widget.state),
                  ),
                ),
                onNotifications: () =>
                    showNotificationCentre(context, widget.state),
                onBeneficiaries: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        BeneficiarySearchScreen(state: widget.state),
                  ),
                ),
                onLiveTracker: () => widget.state.selectTab(2),
                onAdmin: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AdminScreen(state: widget.state),
                  ),
                ),
                onOperationsAdmin: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => OperationsAdminScreen(state: widget.state),
                  ),
                ),
                onControl: () => widget.state.selectTab(3),
                onHouses: () => widget.state.selectTab(4),
                canManageCrew: profile.hasPrivilege('manageCrew'),
              ),
              if (recentHouse != null) ...[
                const SizedBox(height: 18),
                _RecentHouseCard(
                  house: recentHouse,
                  onTap: () => widget.state.selectTab(3),
                ),
              ],
              if (widget.state.showPaymentDue &&
                  experience.showPaymentDue &&
                  paymentsDue.isNotEmpty) ...[
                const SizedBox(height: 18),
                _QueueCard(
                  title: 'Payment due / required action',
                  icon: Icons.payments_outlined,
                  color: RcColors.warning,
                  records: paymentsDue.take(4).toList(),
                  onOpen: () => _openModule('payment'),
                ),
              ],
              if (widget.state.showPaymentReceived &&
                  experience.showPaymentReceived &&
                  paymentsPaid.isNotEmpty) ...[
                const SizedBox(height: 18),
                _QueueCard(
                  title: 'Payment received',
                  icon: Icons.price_check_outlined,
                  color: RcColors.success,
                  records: paymentsPaid.take(4).toList(),
                  onOpen: () => _openModule('payment'),
                ),
              ],
              if (experience.showActionQueue && actionRequired.isNotEmpty) ...[
                const SizedBox(height: 18),
                _QueueCard(
                  title: 'Action queue',
                  icon: Icons.notification_important_outlined,
                  color: RcColors.warning,
                  records: actionRequired.take(5).toList(),
                  onOpen: () => widget.state.selectTab(2),
                ),
              ],
              const SizedBox(height: 20),
              _RoleActions(
                state: widget.state,
                profile: profile,
                experience: experience,
              ),
              if (snap.hasError) ...[
                const SizedBox(height: 14),
                RcExpressiveSurface(
                  tone: theme.colorScheme.errorContainer,
                  child: const Text(
                    'Some dashboard data could not be loaded. Pull to refresh.',
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  List<Widget> _metrics(
    UserProfile profile,
    _DashboardData data,
    int paymentDue,
    int actions,
  ) {
    final theme = Theme.of(context);
    final experience = RcProductRegistry.experience(profile);
    Widget buildMetric(RcDashboardMetricKey key) => switch (key) {
      RcDashboardMetricKey.activeHouses => _Metric(
        'Active houses',
        '${data.houses.length}',
        Icons.home_work_outlined,
        theme.colorScheme.primary,
        () => widget.state.selectTab(3),
      ),
      RcDashboardMetricKey.unreadMessages => const SizedBox.shrink(),
      RcDashboardMetricKey.attendance => _Metric(
        'Attendance',
        '${data.records.where((r) => r.eventType == 'crewAttendance').length}',
        Icons.how_to_reg_outlined,
        RcColors.success,
        () => _openModule('crewAttendance'),
      ),
      RcDashboardMetricKey.fieldRequests => _Metric(
        'Field requests',
        '${data.records.where((r) => r.eventType == 'materialRequest' || r.eventType == 'consumables').length}',
        Icons.inventory_2_outlined,
        RcColors.blue,
        () => _openModule('materialRequest'),
      ),
      RcDashboardMetricKey.parishInputs => _Metric(
        'My / parish inputs',
        '${data.records.length}',
        Icons.edit_note_outlined,
        RcColors.blue,
        () => widget.state.selectTab(2),
      ),
      RcDashboardMetricKey.actionRequired => _Metric(
        'Action required',
        '$actions',
        Icons.priority_high_rounded,
        actions == 0 ? RcColors.success : RcColors.warning,
        () => widget.state.selectTab(2),
      ),
      RcDashboardMetricKey.paymentQueue => _Metric(
        'Payment queue',
        '$paymentDue',
        Icons.payments_outlined,
        RcColors.warning,
        () => _openModule('payment'),
      ),
    };
    return experience.metrics
        .where((key) => key != RcDashboardMetricKey.unreadMessages)
        .map(buildMetric)
        .toList();
  }

  void _openPhase(String phase) {
    if (phase == 'Scope') {
      widget.state.selectTab(1);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ControlScreen(state: widget.state, initialPhase: phase),
      ),
    );
  }

  Future<void> _openModule(String eventType) async {
    if (eventType == 'crewAttendance') {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CrewAttendanceScreen(state: widget.state),
        ),
      );
    } else {
      final schema = RcRecordSchemas.byEventType(eventType);
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              ProductionModuleScreen(state: widget.state, schema: schema),
        ),
      );
    }
    await refresh();
  }
}

class _DashboardData {
  const _DashboardData({
    this.houses = const [],
    this.records = const [],
    this.messages = const [],
    this.community = const [],
  });

  final List<HouseRecord> houses;
  final List<ProductionRecord> records;
  final List<MessageRecord> messages;
  final List<ProductionRecord> community;
}

class _DashboardActivity {
  const _DashboardActivity({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.color,
  });

  final String kind;
  final String title;
  final String subtitle;
  final DateTime time;
  final IconData icon;
  final Color color;
}

List<_DashboardActivity> _dashboardActivity(_DashboardData data) {
  final items = <_DashboardActivity>[];

  for (final message in data.messages.take(10)) {
    items.add(
      _DashboardActivity(
        kind: message.unread ? 'NEW NOTIFICATION' : 'NOTIFICATION',
        title: message.subject,
        subtitle:
            '${message.category}${message.houseCode == null ? '' : ' • ${message.houseCode}'}',
        time: message.createdAt,
        icon: message.unread
            ? Icons.notifications_active_rounded
            : Icons.notifications_none_rounded,
        color: message.priority.toLowerCase().contains('urgent')
            ? RcColors.danger
            : RcColors.blue,
      ),
    );
  }

  for (final record
      in data.records
          .where((record) => record.eventType != 'communityPost')
          .take(14)) {
    items.add(
      _DashboardActivity(
        kind: 'STATUS CHANGE',
        title: '${record.houseCode} • ${record.title}',
        subtitle: '${record.status} • ${record.parish}',
        time: record.updatedAt,
        icon: record.needsAttention
            ? Icons.warning_amber_rounded
            : Icons.sync_alt_rounded,
        color: record.needsAttention ? RcColors.warning : RcColors.success,
      ),
    );
  }

  for (final record
      in data.community
          .where((record) => record.eventType == 'communityPost')
          .take(10)) {
    final start = DateTime.tryParse('${record.item['eventStart'] ?? ''}');
    final upcoming = start != null && start.isAfter(DateTime.now());
    final title = '${record.item['title'] ?? record.summary}'.trim();

    items.add(
      _DashboardActivity(
        kind: upcoming ? 'UPCOMING' : 'COMMUNITY',
        title: title.isEmpty ? 'Community update' : title,
        subtitle: upcoming
            ? '${record.parish} • ${start.toLocal()}'
            : record.parish,
        time: upcoming ? start : record.updatedAt,
        icon: upcoming
            ? Icons.event_available_rounded
            : Icons.groups_2_outlined,
        color: upcoming ? RcColors.purple : RcColors.teal,
      ),
    );
  }

  items.sort((a, b) => b.time.compareTo(a.time));
  return items.take(18).toList();
}

class _RoleHero extends StatelessWidget {
  const _RoleHero({
    required this.profile,
    required this.experience,
    required this.data,
    required this.onControl,
  });
  final UserProfile profile;
  final RcRoleExperience experience;
  final _DashboardData data;
  final VoidCallback onControl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final closed = data.records.where((r) => r.isClosed).length;
    final progress = data.records.isEmpty ? 0.0 : closed / data.records.length;
    final activity = _dashboardActivity(data);
    return RcExpressiveSurface(
      shape: RcSurfaceShape.hero,
      tone: theme.colorScheme.primaryContainer.withValues(alpha: .42),
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        builder: (_, constraints) {
          final text = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RcStatusPill(
                label: profile.role.toUpperCase(),
                icon: Icons.verified_user_outlined,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                experience.heroTitle,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${data.houses.length} visible houses • ${data.records.length} controlled records',
              ),
              const SizedBox(height: 14),
              FilledButton.tonalIcon(
                onPressed: onControl,
                icon: const Icon(Icons.construction_outlined),
                label: const Text('Open production control'),
              ),
            ],
          );
          if (constraints.maxWidth < 820) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(alignment: Alignment.centerLeft, child: text),
                const SizedBox(height: 14),
                _DashboardActivityTicker(items: activity),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: RcProgressOrb(
                    value: progress,
                    label: 'closed',
                    size: 105,
                  ),
                ),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(flex: 5, child: text),
              const SizedBox(width: 16),
              SizedBox(
                width: 330,
                child: _DashboardActivityTicker(items: activity),
              ),
              const SizedBox(width: 16),
              Align(
                alignment: Alignment.center,
                child: RcProgressOrb(
                  value: progress,
                  label: 'closed',
                  size: 108,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DashboardActivityTicker extends StatefulWidget {
  const _DashboardActivityTicker({required this.items});
  final List<_DashboardActivity> items;

  @override
  State<_DashboardActivityTicker> createState() =>
      _DashboardActivityTickerState();
}

class _DashboardActivityTickerState extends State<_DashboardActivityTicker> {
  Timer? timer;
  int index = 0;

  @override
  void initState() {
    super.initState();
    _restart();
  }

  @override
  void didUpdateWidget(covariant _DashboardActivityTicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items.length != widget.items.length) {
      index = 0;
      _restart();
    }
  }

  void _restart() {
    timer?.cancel();
    if (widget.items.length <= 1) return;
    timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || widget.items.isEmpty) return;
      setState(() => index = (index + 1) % widget.items.length);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  String _age(DateTime time) {
    final now = DateTime.now();
    if (time.isAfter(now)) {
      final future = time.difference(now);
      if (future.inDays > 0) return 'in ${future.inDays}d';
      if (future.inHours > 0) return 'in ${future.inHours}h';
      return 'upcoming';
    }
    final difference = now.difference(time);
    if (difference.inDays > 0) return '${difference.inDays}d ago';
    if (difference.inHours > 0) return '${difference.inHours}h ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
    return 'now';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.items.isEmpty) {
      return RcExpressiveSurface(
        shape: RcSurfaceShape.offset,
        tone: theme.colorScheme.surface.withValues(alpha: .72),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline_rounded, color: RcColors.success),
            const SizedBox(width: 9),
            const Expanded(
              child: Text('You are up to date. No recent activity to show.'),
            ),
          ],
        ),
      );
    }

    if (index >= widget.items.length) index = 0;
    final item = widget.items[index];

    return RcExpressiveSurface(
      shape: RcSurfaceShape.offset,
      tone: theme.colorScheme.surface.withValues(alpha: .82),
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(
                Icons.dynamic_feed_outlined,
                size: 17,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'WHAT’S HAPPENING',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: .7,
                  ),
                ),
              ),
              Text(
                '${index + 1}/${widget.items.length}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            child: Row(
              key: ValueKey('${item.kind}-${item.title}-${item.time}'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: .11),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(item.icon, size: 19, color: item.color),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.kind,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: item.color,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${item.subtitle} • ${_age(item.time)}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductionChainNav extends StatelessWidget {
  const _ProductionChainNav({required this.onOpenPhase});
  final ValueChanged<String> onOpenPhase;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = <(String, IconData)>[
      ('Scope', Icons.assignment_outlined),
      ('Plan', Icons.calendar_month_outlined),
      ('Delivery', Icons.construction_outlined),
      ('Quality', Icons.fact_check_outlined),
      ('Close-out', Icons.verified_outlined),
      ('Finance', Icons.payments_outlined),
    ];

    return RcExpressiveSurface(
      shape: RcSurfaceShape.pill,
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
      child: Semantics(
        label: 'Project lifecycle from Scope through Finance',
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < items.length; i++) ...[
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(15),
                  onTap: () => onOpenPhase(items[i].$1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 5,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          items[i].$2,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            items[i].$1,
                            maxLines: 1,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              fontSize: 10.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (i < items.length - 1)
                Container(
                  width: 1,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  color: theme.colorScheme.outlineVariant,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DashboardCommandStrip extends StatelessWidget {
  const _DashboardCommandStrip({
    required this.profile,
    required this.onSettings,
    required this.onNotifications,
    required this.onBeneficiaries,
    required this.onLiveTracker,
    required this.onAdmin,
    required this.onOperationsAdmin,
    required this.onControl,
    required this.onHouses,
    required this.canManageCrew,
  });

  final UserProfile profile;
  final VoidCallback onSettings;
  final VoidCallback onNotifications;
  final VoidCallback onBeneficiaries;
  final VoidCallback onLiveTracker;
  final VoidCallback onAdmin;
  final VoidCallback onOperationsAdmin;
  final VoidCallback onControl;
  final VoidCallback onHouses;
  final bool canManageCrew;

  @override
  Widget build(BuildContext context) => RcExpressiveSurface(
    shape: RcSurfaceShape.offset,
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ActionChip(
          avatar: const Icon(Icons.notifications_none_rounded),
          label: const Text('Notifications'),
          onPressed: onNotifications,
        ),
        ActionChip(
          avatar: const Icon(Icons.home_work_outlined),
          label: const Text('Beneficiaries'),
          onPressed: onBeneficiaries,
        ),
        ActionChip(
          avatar: const Icon(Icons.location_searching),
          label: const Text('Live Tracker'),
          onPressed: onLiveTracker,
        ),
        ActionChip(
          avatar: const Icon(Icons.settings_outlined),
          label: const Text('Account & Settings'),
          onPressed: onSettings,
        ),
        ActionChip(
          avatar: Icon(
            canManageCrew ? Icons.groups_2_outlined : Icons.home_work_outlined,
          ),
          label: Text(canManageCrew ? 'Crew Assignment' : 'My Houses'),
          onPressed: canManageCrew ? onControl : onHouses,
        ),
        if (profile.canViewAdmin)
          ActionChip(
            avatar: const Icon(Icons.tune_rounded),
            label: const Text('Operations Admin'),
            onPressed: onOperationsAdmin,
          ),
        if (profile.canViewAdmin)
          ActionChip(
            avatar: const Icon(Icons.admin_panel_settings_outlined),
            label: const Text('Admin Centre'),
            onPressed: onAdmin,
          ),
      ],
    ),
  );
}

class _RecentHouseCard extends StatelessWidget {
  const _RecentHouseCard({required this.house, required this.onTap});
  final HouseRecord house;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return RcExpressiveSurface(
      shape: RcSurfaceShape.hero,
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(radius: 27, child: Text('${house.progress}%')),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recently active house',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                Text(
                  '${house.code} • ${house.beneficiary}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text('${house.parish} • ${house.cluster} • ${house.stage}'),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

class _QueueCard extends StatelessWidget {
  const _QueueCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.records,
    required this.onOpen,
  });
  final String title;
  final IconData icon;
  final Color color;
  final List<ProductionRecord> records;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return RcExpressiveSurface(
      shape: RcSurfaceShape.offset,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: RcIconSize.sm, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              TextButton(onPressed: onOpen, child: const Text('Open')),
            ],
          ),
          ...records.map(
            (r) => ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text('${r.houseCode} • ${r.title}'),
              subtitle: Text('${r.parish} • ${r.status}'),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleActions extends StatelessWidget {
  const _RoleActions({
    required this.state,
    required this.profile,
    required this.experience,
  });
  final AppState state;
  final UserProfile profile;
  final RcRoleExperience experience;

  @override
  Widget build(BuildContext context) {
    final actions = experience.quickActions.map((key) {
      return switch (key) {
        RcQuickActionKey.workProjection => _Action(
          'Work projection',
          Icons.view_timeline_outlined,
          () => _module(context, 'workProjection'),
        ),
        RcQuickActionKey.constructionSchedule => _Action(
          'Construction schedule',
          Icons.event_note_outlined,
          () => _module(context, 'constructionSchedule'),
        ),
        RcQuickActionKey.crewAttendance => _Action(
          profile.isCrew ? 'Sign daily attendance' : 'Crew attendance',
          Icons.how_to_reg_outlined,
          () => _module(context, 'crewAttendance'),
        ),
        RcQuickActionKey.payment => _Action(
          'Payment',
          Icons.payments_outlined,
          () => _module(context, 'payment'),
        ),
        RcQuickActionKey.materialRequest => _Action(
          'Material request',
          Icons.inventory_2_outlined,
          () => _module(context, 'materialRequest'),
        ),
        RcQuickActionKey.consumables => _Action(
          'Consumable request',
          Icons.handyman_outlined,
          () => _module(context, 'consumables'),
        ),
        RcQuickActionKey.dailyLog => _Action(
          profile.isCrew ? 'Add field log / photo' : 'Daily site log',
          Icons.menu_book_outlined,
          () => _module(context, 'dailyLog'),
        ),
        RcQuickActionKey.monitoring => _Action(
          'Monitoring',
          Icons.fact_check_outlined,
          () => _module(context, 'monitoring'),
        ),
        RcQuickActionKey.adminUsers => _Action(
          'Users & privileges',
          Icons.manage_accounts_outlined,
          () => _admin(context, 0),
        ),
        RcQuickActionKey.beneficiarySources => _Action(
          'Beneficiary sources',
          Icons.home_work_outlined,
          () => _admin(context, 1),
        ),
        RcQuickActionKey.adminTemplates => _Action(
          'Document templates',
          Icons.description_outlined,
          () => _admin(context, 2),
        ),
        RcQuickActionKey.adminForms => _Action(
          'Form Studio',
          Icons.dynamic_form_outlined,
          () => _admin(context, 3),
        ),
      };
    }).toList();
    if (actions.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick actions', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        RcResponsiveGrid(
          minTileWidth: 210,
          childAspectRatio: 2.25,
          children: actions,
        ),
      ],
    );
  }

  Future<void> _admin(BuildContext context, int initialTab) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminScreen(state: state, initialTab: initialTab),
      ),
    );
  }

  Future<void> _module(BuildContext context, String type) async {
    if (type == 'crewAttendance') {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => CrewAttendanceScreen(state: state)),
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductionModuleScreen(
          state: state,
          schema: RcRecordSchemas.byEventType(type),
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action(this.label, this.icon, this.onTap);
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
        const Icon(Icons.arrow_outward_rounded, size: 18),
      ],
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value, this.icon, this.color, this.onTap);
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => RcExpressiveSurface(
    shape: RcSurfaceShape.offset,
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: RcIconSize.sm, color: color),
        const Spacer(),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(color: color),
        ),
        Text(label),
      ],
    ),
  );
}
