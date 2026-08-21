import 'package:flutter/material.dart';

import '../../core/design_tokens.dart';
import '../../core/navigation.dart';
import '../../core/rc_components.dart';
import '../../models/app_models.dart';
import '../../state/app_state.dart';

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
    final p = widget.state.profile!;
    final results = await Future.wait<Object>([
      widget.state.repository.houses(p),
      widget.state.repository.messages(p),
      widget.state.repository.productionRecords(p),
    ]);
    return _DashboardData(
      houses: results[0] as List<HouseRecord>,
      messages: results[1] as List<MessageRecord>,
      records: results[2] as List<ProductionRecord>,
    );
  }

  Future<void> _refresh() async {
    setState(() => future = _load());
    await future;
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.state.profile!;
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<_DashboardData>(
        future: future,
        builder: (context, snap) {
          final data = snap.data ?? const _DashboardData.empty();
          final unread = data.messages.where((m) => m.unread).length;
          final closed = data.records.where((r) => r.isClosed).length;
          final attention = data.records.where((r) => r.needsAttention).length;
          final completion = data.records.isEmpty
              ? 0.0
              : closed / data.records.length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 124),
            children: [
              RcPageHeading(
                eyebrow: 'Production command',
                title:
                    'Good ${DateTime.now().hour < 12
                        ? 'morning'
                        : DateTime.now().hour < 18
                        ? 'afternoon'
                        : 'evening'}, ${p.fullName?.isNotEmpty == true ? p.fullName! : p.role}',
                subtitle:
                    'Move each house from scope through controlled delivery, completion and payment with one visible chain of evidence.',
                trailing: snap.connectionState == ConnectionState.waiting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : RcStatusPill(
                        label: p.canViewAllParishes ? 'ALL PARISHES' : p.parish,
                        icon: Icons.location_on_outlined,
                        color: theme.colorScheme.secondary,
                      ),
              ),
              const SizedBox(height: 18),
              _ProductionHero(
                houses: data.houses,
                records: data.records,
                completion: completion,
                onOpenControl: () => widget.state.selectTab(2),
              ),
              const SizedBox(height: 14),
              _CommandSurface(
                onScope: () => widget.state.selectTab(1),
                onControl: () => widget.state.selectTab(2),
                onHouses: () => widget.state.selectTab(3),
                onMessages: () => RcNavigator.messages(context, widget.state),
              ),
              const SizedBox(height: 20),
              Text('Operational pulse', style: theme.textTheme.titleLarge),
              const SizedBox(height: 10),
              RcResponsiveGrid(
                minTileWidth: 175,
                children: [
                  _MetricTile(
                    label: 'Active houses',
                    value: '${data.houses.length}',
                    icon: Icons.home_work_outlined,
                    color: theme.colorScheme.primary,
                    onTap: () => widget.state.selectTab(3),
                  ),
                  _MetricTile(
                    label: 'Unread messages',
                    value: '$unread',
                    icon: Icons.mark_email_unread_outlined,
                    color: theme.colorScheme.secondary,
                    onTap: () => RcNavigator.messages(context, widget.state),
                  ),
                  _MetricTile(
                    label: 'Needs attention',
                    value: '$attention',
                    icon: Icons.priority_high_rounded,
                    color: attention > 0 ? RcColors.warning : RcColors.success,
                    onTap: () => widget.state.selectTab(2),
                  ),
                  _MetricTile(
                    label: 'Production records',
                    value: '${data.records.length}',
                    icon: Icons.account_tree_outlined,
                    color: RcColors.purple,
                    onTap: () => widget.state.selectTab(2),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _PipelineOverview(records: data.records),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Recent houses',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  TextButton(
                    onPressed: () => widget.state.selectTab(3),
                    child: const Text('View all'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (snap.hasError)
                RcExpressiveSurface(
                  tone: theme.colorScheme.errorContainer,
                  child: const Text(
                    'Some dashboard data could not be loaded. Pull to refresh or check connectivity.',
                  ),
                )
              else if (data.houses.isEmpty &&
                  snap.connectionState != ConnectionState.waiting)
                const RcExpressiveSurface(
                  child: Text('No active houses are visible for this account.'),
                )
              else
                ...data.houses
                    .take(5)
                    .map(
                      (h) => Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: _HouseRow(
                          house: h,
                          onTap: () => widget.state.selectTab(3),
                        ),
                      ),
                    ),
            ],
          );
        },
      ),
    );
  }
}

class _ProductionHero extends StatelessWidget {
  const _ProductionHero({
    required this.houses,
    required this.records,
    required this.completion,
    required this.onOpenControl,
  });

  final List<HouseRecord> houses;
  final List<ProductionRecord> records;
  final double completion;
  final VoidCallback onOpenControl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RcExpressiveSurface(
      shape: RcSurfaceShape.hero,
      tone: theme.colorScheme.primaryContainer.withValues(alpha: .48),
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 580;
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RcStatusPill(
                label: 'LIVE PRODUCTION',
                icon: Icons.bolt_rounded,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 14),
              Text(
                'From assessment to paid completion',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                '${houses.length} active houses • ${records.length} controlled records. Keep approvals, field evidence, materials, completion and payment connected.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: onOpenControl,
                icon: const Icon(Icons.construction_rounded),
                label: const Text('Open production control'),
              ),
            ],
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                copy,
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.center,
                  child: RcProgressOrb(
                    value: completion,
                    label: 'closed',
                    size: 108,
                  ),
                ),
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: copy),
              const SizedBox(width: 24),
              RcProgressOrb(value: completion, label: 'closed', size: 120),
            ],
          );
        },
      ),
    );
  }
}

class _CommandSurface extends StatelessWidget {
  const _CommandSurface({
    required this.onScope,
    required this.onControl,
    required this.onHouses,
    required this.onMessages,
  });
  final VoidCallback onScope;
  final VoidCallback onControl;
  final VoidCallback onHouses;
  final VoidCallback onMessages;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RcExpressiveSurface(
      shape: RcSurfaceShape.pill,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      tone: theme.colorScheme.surfaceContainerLow,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            RcCommandButton(
              icon: Icons.assignment_add,
              label: 'Scope',
              onPressed: onScope,
              emphasized: true,
            ),
            RcCommandButton(
              icon: Icons.fact_check_outlined,
              label: 'Control',
              onPressed: onControl,
            ),
            RcCommandButton(
              icon: Icons.home_work_outlined,
              label: 'Houses',
              onPressed: onHouses,
            ),
            RcCommandButton(
              icon: Icons.forum_outlined,
              label: 'Messages',
              onPressed: onMessages,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RcExpressiveSurface(
      shape: RcSurfaceShape.offset,
      onTap: onTap,
      semanticLabel: '$label $value',
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              const Icon(Icons.arrow_outward_rounded, size: 18),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(color: color),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PipelineOverview extends StatelessWidget {
  const _PipelineOverview({required this.records});
  final List<ProductionRecord> records;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scopes = records.where((r) => r.eventType == 'scope').length;
    final controls = records.where((r) => r.eventType == 'controlData').length;
    final field = records
        .where(
          (r) => const {
            'workPlan',
            'monitoring',
            'siteVisit',
            'dailyLog',
            'materialRequest',
            'consumables',
            'inventory',
          }.contains(r.eventType),
        )
        .length;
    final closeout = records.where((r) => r.eventType == 'notice').length;
    final payment = records.where((r) => r.eventType == 'payment').length;
    final steps = [
      ('Scope', scopes, Icons.assignment_outlined),
      ('Control', controls, Icons.account_tree_outlined),
      ('Delivery', field, Icons.construction_outlined),
      ('Completion', closeout, Icons.verified_outlined),
      ('Payment', payment, Icons.payments_outlined),
    ];
    return RcExpressiveSurface(
      shape: RcSurfaceShape.hero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Production chain', style: theme.textTheme.titleLarge),
          const SizedBox(height: 5),
          Text(
            'A visible workflow preserves orientation: every downstream action belongs to a known house and production stage.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < steps.length; i++) ...[
                  _PipelineStep(
                    label: steps[i].$1,
                    count: steps[i].$2,
                    icon: steps[i].$3,
                  ),
                  if (i != steps.length - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PipelineStep extends StatelessWidget {
  const _PipelineStep({
    required this.label,
    required this.count,
    required this.icon,
  });
  final String label;
  final int count;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 112,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(10),
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 19),
          const SizedBox(height: 10),
          Text('$count', style: theme.textTheme.titleLarge),
          Text(label, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _HouseRow extends StatelessWidget {
  const _HouseRow({required this.house, required this.onTap});
  final HouseRecord house;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RcExpressiveSurface(
      shape: RcSurfaceShape.offset,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: onTap,
      semanticLabel: '${house.code} ${house.beneficiary}',
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.home_work_outlined,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${house.code} • ${house.beneficiary}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${house.parish}${house.cluster.isEmpty ? '' : ' • ${house.cluster}'} • ${house.stage}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          RcStatusPill(
            label: '${house.progress}%',
            color: house.progress >= 80 ? RcColors.success : RcColors.brand,
          ),
        ],
      ),
    );
  }
}

class _DashboardData {
  const _DashboardData({
    required this.houses,
    required this.messages,
    required this.records,
  });

  const _DashboardData.empty()
    : houses = const [],
      messages = const [],
      records = const [];

  final List<HouseRecord> houses;
  final List<MessageRecord> messages;
  final List<ProductionRecord> records;
}
