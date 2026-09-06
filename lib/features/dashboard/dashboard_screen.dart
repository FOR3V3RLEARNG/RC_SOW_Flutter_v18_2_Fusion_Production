import 'package:flutter/material.dart';

import '../../core/design_tokens.dart';
import '../../core/record_schemas.dart';
import '../../core/product_registry.dart';
import '../../core/rc_components.dart';
import '../../models/app_models.dart';
import '../../state/app_state.dart';
import '../admin/admin_screen.dart';
import '../control/control_screen.dart';
import '../messages/messages_screen.dart';
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
      widget.state.repository.messages(profile, limit: 12),
    ]);
    return _DashboardData(
      houses: data[0] as List<HouseRecord>,
      records: data[1] as List<ProductionRecord>,
      messages: data[2] as List<MessageRecord>,
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
          final unread = data.messages.where((m) => m.unread).length;
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
                title: 'Good day, ${profile.displayName}',
                subtitle: experience.subtitle,
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
                onControl: () => widget.state.selectTab(2),
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
                  unread,
                  paymentsDue.length,
                  actionRequired.length,
                ),
              ),
              const SizedBox(height: 20),
              _MessagePreview(
                messages: data.messages,
                onOpen: () => showMessageDrawer(context, widget.state),
                onCompose: () => showComposeMessage(context, widget.state),
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
    int unread,
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
      RcDashboardMetricKey.unreadMessages => _Metric(
        'Unread messages',
        '$unread',
        Icons.mark_email_unread_outlined,
        theme.colorScheme.secondary,
        () => showMessageDrawer(context, widget.state),
      ),
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
    return experience.metrics.map(buildMetric).toList();
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
  });
  final List<HouseRecord> houses;
  final List<ProductionRecord> records;
  final List<MessageRecord> messages;
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
          if (constraints.maxWidth < 560) {
            return Column(
              children: [
                Align(alignment: Alignment.centerLeft, child: text),
                const SizedBox(height: 16),
                RcProgressOrb(value: progress, label: 'closed', size: 105),
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: text),
              const SizedBox(width: 20),
              RcProgressOrb(value: progress, label: 'closed', size: 115),
            ],
          );
        },
      ),
    );
  }
}

class _ProductionChainNav extends StatelessWidget {
  const _ProductionChainNav({required this.onOpenPhase});
  final ValueChanged<String> onOpenPhase;

  @override
  Widget build(BuildContext context) {
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => onOpenPhase(items[i].$1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  child: Column(
                    children: [
                      Icon(items[i].$2, size: RcIconSize.sm),
                      const SizedBox(height: 4),
                      Text(
                        items[i].$1,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (i < items.length - 1)
                const Icon(Icons.chevron_right_rounded, size: 16),
            ],
          ],
        ),
      ),
    );
  }
}

class _MessagePreview extends StatelessWidget {
  const _MessagePreview({
    required this.messages,
    required this.onOpen,
    required this.onCompose,
  });
  final List<MessageRecord> messages;
  final VoidCallback onOpen;
  final VoidCallback onCompose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RcExpressiveSurface(
      shape: RcSurfaceShape.offset,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.forum_outlined,
                size: RcIconSize.sm,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Messages', style: theme.textTheme.titleLarge),
              ),
              IconButton(
                onPressed: onCompose,
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                onPressed: onOpen,
                icon: const Icon(Icons.expand_more_rounded),
              ),
            ],
          ),
          if (messages.isEmpty)
            const Text('No recent messages.')
          else
            ...messages
                .take(3)
                .map(
                  (m) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: Icon(
                      m.unread
                          ? Icons.mark_email_unread_outlined
                          : Icons.mail_outline,
                    ),
                    title: Text(
                      m.subject,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${m.sender} • ${m.body}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: onOpen,
                  ),
                ),
        ],
      ),
    );
  }
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
