import 'package:flutter/material.dart';

import '../../core/design_tokens.dart';
import '../../core/rc_components.dart';
import '../../models/app_models.dart';
import '../../state/app_state.dart';

class ControlScreen extends StatefulWidget {
  const ControlScreen({super.key, required this.state});
  final AppState state;

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  late Future<List<ProductionRecord>> future;
  String phase = 'All';

  static const modules = <_ControlModule>[
    _ControlModule('Work Plan', 'workPlan', 'Plan sequence, owners and dates', Icons.calendar_view_week_outlined, 'Plan'),
    _ControlModule('Document Checklist', 'documentChecklist', 'Keep required evidence visible', Icons.task_alt_outlined, 'Plan'),
    _ControlModule('Monitoring Checklist', 'monitoring', 'Quality, safety and progress checks', Icons.fact_check_outlined, 'Quality'),
    _ControlModule('Site Visits', 'siteVisit', 'Record inspection visits and findings', Icons.location_on_outlined, 'Delivery'),
    _ControlModule('Daily Site Log', 'dailyLog', 'Daily work, weather and constraints', Icons.menu_book_outlined, 'Delivery'),
    _ControlModule('Material Request', 'materialRequest', 'Controlled material request and approval', Icons.inventory_2_outlined, 'Delivery'),
    _ControlModule('Consumables Form', 'consumables', 'Track consumable field items', Icons.handyman_outlined, 'Delivery'),
    _ControlModule('Inventory Tracker', 'inventory', 'Issued, on-site and remaining stock', Icons.warehouse_outlined, 'Delivery'),
    _ControlModule('Notice of Completion', 'notice', 'Submit completion evidence for review', Icons.verified_outlined, 'Close-out'),
    _ControlModule('Payment Submission', 'payment', 'Submit the payment package after completion', Icons.payments_outlined, 'Finance'),
  ];

  @override
  void initState() {
    super.initState();
    future = _load();
  }

  Future<List<ProductionRecord>> _load() =>
      widget.state.repository.productionRecords(widget.state.profile!);

  Future<void> _refresh() async {
    setState(() => future = _load());
    await future;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<List<ProductionRecord>>(
        future: future,
        builder: (context, snap) {
          final records = snap.data ?? const <ProductionRecord>[];
          final open = records.where((r) => !r.isClosed).length;
          final attention = records.where((r) => r.needsAttention).length;
          final completed = records.where((r) => r.isClosed).length;
          final filteredModules = phase == 'All'
              ? modules
              : modules.where((m) => m.phase == phase).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 124),
            children: [
              RcPageHeading(
                eyebrow: 'Production management',
                title: 'Control of Works',
                subtitle:
                    'Plan, execute, inspect, close and pay without breaking the evidence chain.',
                trailing: FilledButton.tonalIcon(
                  onPressed: () => _newControl(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('New'),
                ),
              ),
              const SizedBox(height: 18),
              _ControlHero(
                open: open,
                attention: attention,
                completed: completed,
                onCompletion: () => _openModule(context, modules[8]),
                onPayment: () => _openModule(context, modules[9]),
              ),
              const SizedBox(height: 16),
              _PhaseRail(
                selected: phase,
                onSelected: (value) => setState(() => phase = value),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(child: Text('Workflow modules', style: theme.textTheme.titleLarge)),
                  if (snap.connectionState == ConnectionState.waiting)
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 900
                      ? 3
                      : constraints.maxWidth >= 560
                          ? 2
                          : 1;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredModules.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: 11,
                      crossAxisSpacing: 11,
                      childAspectRatio: columns == 1 ? 3.15 : 2.0,
                    ),
                    itemBuilder: (context, index) {
                      final module = filteredModules[index];
                      final count = records
                          .where((r) => r.eventType == module.eventType)
                          .length;
                      return _ModuleTile(
                        module: module,
                        count: count,
                        onTap: () => _openModule(context, module),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 20),
              _RecentActivity(
                records: records.take(8).toList(),
                onOpen: (record) {
                  final module = modules.firstWhere(
                    (m) => m.eventType == record.eventType,
                    orElse: () => modules.first,
                  );
                  _openModule(context, module);
                },
              ),
              if (snap.hasError) ...[
                const SizedBox(height: 14),
                RcExpressiveSurface(
                  tone: theme.colorScheme.errorContainer,
                  child: const Text(
                    'Production records could not be loaded. Pull to refresh after connectivity is restored.',
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _newControl(BuildContext context) async {
    final created = await _showProductionDialog(
      context,
      title: 'New Control of Work',
      eventType: 'controlData',
      initialStatus: 'Draft',
      noteLabel: 'Work summary',
    );
    if (created) await _refresh();
  }

  void _openModule(BuildContext context, _ControlModule module) {
    Navigator.of(context)
        .push(
          PageRouteBuilder<void>(
            settings: RouteSettings(name: '/control/${module.eventType}'),
            transitionDuration:
                widget.state.reduceMotion ? Duration.zero : RcMotion.medium,
            pageBuilder: (_, animation, __) => _ProductionModuleScreen(
              state: widget.state,
              module: module,
            ),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        )
        .then((_) => _refresh());
  }

  Future<bool> _showProductionDialog(
    BuildContext context, {
    required String title,
    required String eventType,
    required String initialStatus,
    required String noteLabel,
  }) async {
    final house = TextEditingController();
    final parish = TextEditingController(
      text: widget.state.profile!.canViewAllParishes
          ? ''
          : widget.state.profile!.parish,
    );
    final note = TextEditingController();
    var status = initialStatus;
    var busy = false;
    String? validation;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: house,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(labelText: 'House Code'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: parish,
                    decoration: const InputDecoration(labelText: 'Parish'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: const [
                      'Draft',
                      'Open',
                      'Submitted',
                      'In Review',
                      'Approved',
                      'Completed',
                      'Blocked',
                    ]
                        .map((x) => DropdownMenuItem(value: x, child: Text(x)))
                        .toList(),
                    onChanged: busy ? null : (v) => status = v!,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: note,
                    maxLines: 4,
                    decoration: InputDecoration(labelText: noteLabel),
                  ),
                  if (validation != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      validation!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: busy ? null : () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      if (house.text.trim().isEmpty || parish.text.trim().isEmpty) {
                        setDialogState(
                          () => validation = 'House Code and Parish are required.',
                        );
                        return;
                      }
                      setDialogState(() {
                        busy = true;
                        validation = null;
                      });
                      try {
                        await widget.state.repository.submitControlEvent(
                          profile: widget.state.profile!,
                          eventType: eventType,
                          houseCode: house.text.trim(),
                          parish: parish.text.trim(),
                          item: {
                            'status': status,
                            'summary': note.text.trim(),
                            'title': title,
                            'createdFrom': 'RC SOW Production Management',
                          },
                        );
                        await widget.state.feedback(strong: true);
                        if (ctx.mounted) Navigator.pop(ctx, true);
                      } catch (_) {
                        setDialogState(() {
                          busy = false;
                          validation = 'Could not save this record. Check connectivity and try again.';
                        });
                      }
                    },
              child: Text(busy ? 'Saving…' : 'Create'),
            ),
          ],
        ),
      ),
    );
    house.dispose();
    parish.dispose();
    note.dispose();
    return result == true;
  }
}

class _ControlHero extends StatelessWidget {
  const _ControlHero({
    required this.open,
    required this.attention,
    required this.completed,
    required this.onCompletion,
    required this.onPayment,
  });
  final int open;
  final int attention;
  final int completed;
  final VoidCallback onCompletion;
  final VoidCallback onPayment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RcExpressiveSurface(
      shape: RcSurfaceShape.hero,
      tone: theme.colorScheme.secondaryContainer.withValues(alpha: .45),
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final metrics = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              RcStatusPill(label: '$open OPEN', icon: Icons.play_arrow_rounded),
              RcStatusPill(
                label: '$attention ATTENTION',
                icon: Icons.priority_high_rounded,
                color: attention > 0 ? RcColors.warning : RcColors.success,
              ),
              RcStatusPill(
                label: '$completed CLOSED',
                icon: Icons.check_rounded,
                color: RcColors.success,
              ),
            ],
          );
          final actions = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: onCompletion,
                icon: const Icon(Icons.verified_outlined),
                label: const Text('Completion'),
              ),
              OutlinedButton.icon(
                onPressed: onPayment,
                icon: const Icon(Icons.payments_outlined),
                label: const Text('Payment'),
              ),
            ],
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Controlled delivery chain',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                'Every field action remains traceable to a house, parish, status and production stage.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              metrics,
              const SizedBox(height: 15),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _PhaseRail extends StatelessWidget {
  const _PhaseRail({required this.selected, required this.onSelected});
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    const phases = ['All', 'Plan', 'Delivery', 'Quality', 'Close-out', 'Finance'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<String>(
        segments: phases
            .map((x) => ButtonSegment<String>(value: x, label: Text(x)))
            .toList(),
        selected: {selected},
        showSelectedIcon: false,
        onSelectionChanged: (value) => onSelected(value.first),
        style: const ButtonStyle(visualDensity: VisualDensity.compact),
      ),
    );
  }
}

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({required this.module, required this.count, required this.onTap});
  final _ControlModule module;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final closeOut = module.phase == 'Close-out' || module.phase == 'Finance';
    return RcExpressiveSurface(
      shape: closeOut ? RcSurfaceShape.hero : RcSurfaceShape.offset,
      onTap: onTap,
      semanticLabel: module.title,
      tone: closeOut
          ? theme.colorScheme.primaryContainer.withValues(alpha: .34)
          : theme.colorScheme.surface,
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: closeOut
                  ? theme.colorScheme.primary.withValues(alpha: .12)
                  : theme.colorScheme.secondary.withValues(alpha: .10),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(10),
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Icon(
              module.icon,
              color: closeOut ? theme.colorScheme.primary : theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(module.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(
                  module.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('$count', style: theme.textTheme.titleLarge),
              Text('records', style: theme.textTheme.labelSmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecentActivity extends StatelessWidget {
  const _RecentActivity({required this.records, required this.onOpen});
  final List<ProductionRecord> records;
  final ValueChanged<ProductionRecord> onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent production activity', style: theme.textTheme.titleLarge),
        const SizedBox(height: 9),
        if (records.isEmpty)
          const RcExpressiveSurface(
            child: Text('No production activity is visible yet.'),
          )
        else
          RcExpressiveSurface(
            shape: RcSurfaceShape.hero,
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Column(
              children: records
                  .map(
                    (r) => ListTile(
                      leading: Icon(
                        r.needsAttention ? Icons.warning_amber_rounded : Icons.history_rounded,
                        color: r.needsAttention ? RcColors.warning : theme.colorScheme.primary,
                      ),
                      title: Text(
                        '${r.houseCode} • ${r.title}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text('${r.parish} • ${r.status}'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => onOpen(r),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }
}

class _ProductionModuleScreen extends StatefulWidget {
  const _ProductionModuleScreen({
    super.key,
    required this.state,
    required this.module,
  });
  final AppState state;
  final _ControlModule module;

  @override
  State<_ProductionModuleScreen> createState() => _ProductionModuleScreenState();
}

class _ProductionModuleScreenState extends State<_ProductionModuleScreen> {
  late Future<List<ProductionRecord>> future;

  @override
  void initState() {
    super.initState();
    future = _load();
  }

  Future<List<ProductionRecord>> _load() async {
    final records = await widget.state.repository.productionRecords(widget.state.profile!);
    return records.where((r) => r.eventType == widget.module.eventType).toList();
  }

  Future<void> _refresh() async {
    setState(() => future = _load());
    await future;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(widget.module.title)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add record'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<ProductionRecord>>(
          future: future,
          builder: (context, snap) {
            final records = snap.data ?? const <ProductionRecord>[];
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 110),
              children: [
                RcExpressiveSurface(
                  shape: RcSurfaceShape.hero,
                  tone: theme.colorScheme.secondaryContainer.withValues(alpha: .35),
                  child: Row(
                    children: [
                      Icon(widget.module.icon, size: 34, color: theme.colorScheme.secondary),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.module.phase.toUpperCase(), style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1.1)),
                            const SizedBox(height: 3),
                            Text(widget.module.subtitle, style: theme.textTheme.bodyMedium),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: Text('${records.length} records', style: theme.textTheme.titleLarge)),
                    if (snap.connectionState == ConnectionState.waiting)
                      const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4)),
                  ],
                ),
                const SizedBox(height: 9),
                if (records.isEmpty && snap.connectionState != ConnectionState.waiting)
                  const RcExpressiveSurface(child: Text('No records in this module yet.')),
                ...records.map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: RcExpressiveSurface(
                      shape: RcSurfaceShape.offset,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${r.houseCode} • ${r.parish}', style: theme.textTheme.titleMedium),
                                if (r.summary.isNotEmpty) ...[
                                  const SizedBox(height: 5),
                                  Text(r.summary, style: theme.textTheme.bodyMedium),
                                ],
                                const SizedBox(height: 8),
                                Text(
                                  _formatDate(r.updatedAt),
                                  style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          RcStatusPill(
                            label: r.status.toUpperCase(),
                            color: r.needsAttention
                                ? RcColors.warning
                                : r.isClosed
                                    ? RcColors.success
                                    : theme.colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (snap.hasError)
                  RcExpressiveSurface(
                    tone: theme.colorScheme.errorContainer,
                    child: const Text('Could not load this module. Check connectivity and retry.'),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _add() async {
    final house = TextEditingController();
    final parish = TextEditingController(
      text: widget.state.profile!.canViewAllParishes ? '' : widget.state.profile!.parish,
    );
    final note = TextEditingController();
    var status = widget.module.eventType == 'notice' || widget.module.eventType == 'payment'
        ? 'Submitted'
        : 'Open';
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          4,
          18,
          18 + MediaQuery.viewInsetsOf(ctx).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Add ${widget.module.title}', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 14),
              TextField(controller: house, decoration: const InputDecoration(labelText: 'House Code')),
              const SizedBox(height: 10),
              TextField(controller: parish, decoration: const InputDecoration(labelText: 'Parish')),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const ['Open', 'Draft', 'Submitted', 'In Review', 'Approved', 'Completed', 'Blocked']
                    .map((x) => DropdownMenuItem(value: x, child: Text(x)))
                    .toList(),
                onChanged: (v) => status = v!,
              ),
              const SizedBox(height: 10),
              TextField(controller: note, maxLines: 4, decoration: const InputDecoration(labelText: 'Field note / evidence summary')),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () async {
                  if (house.text.trim().isEmpty || parish.text.trim().isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('House Code and Parish are required.')));
                    return;
                  }
                  try {
                    await widget.state.repository.submitControlEvent(
                      profile: widget.state.profile!,
                      eventType: widget.module.eventType,
                      houseCode: house.text.trim(),
                      parish: parish.text.trim(),
                      item: {
                        'status': status,
                        'title': widget.module.title,
                        'summary': note.text.trim(),
                        'phase': widget.module.phase,
                      },
                    );
                    await widget.state.feedback(strong: true);
                    if (ctx.mounted) Navigator.pop(ctx, true);
                  } catch (_) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Could not save. Check connectivity and try again.')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save production record'),
              ),
            ],
          ),
        ),
      ),
    );
    house.dispose();
    parish.dispose();
    note.dispose();
    if (saved == true) await _refresh();
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year} • ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}

class _ControlModule {
  const _ControlModule(this.title, this.eventType, this.subtitle, this.icon, this.phase);
  final String title;
  final String eventType;
  final String subtitle;
  final IconData icon;
  final String phase;
}
