import 'package:flutter/material.dart';

import '../../core/app_constants.dart';
import '../../core/design_tokens.dart';
import '../../core/record_schemas.dart';
import '../../core/product_registry.dart';
import '../../core/rc_components.dart';
import '../../models/app_models.dart';
import '../../services/export_service.dart';
import '../../state/app_state.dart';
import 'record_form_screen.dart';
import '../workforce/crew_attendance_screen.dart';

class ControlScreen extends StatefulWidget {
  const ControlScreen({
    super.key,
    required this.state,
    this.initialPhase = 'All',
  });
  final AppState state;
  final String initialPhase;

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  late Future<List<ProductionRecord>> future;
  List<RcRecordSchema> customSchemas = const [];
  late String phase;

  static const phases = [
    'All',
    'Plan',
    'Delivery',
    'Quality',
    'Close-out',
    'Finance',
  ];

  @override
  void initState() {
    super.initState();
    phase = phases.contains(widget.initialPhase) ? widget.initialPhase : 'All';
    future = _load();
    _loadCustomSchemas();
  }

  Future<List<ProductionRecord>> _load() =>
      widget.state.repository.productionRecords(widget.state.profile!);

  Future<void> _loadCustomSchemas() async {
    try {
      final rows = await widget.state.repository.customFormTemplates();
      if (!mounted) return;
      setState(() {
        customSchemas = rows.map((row) {
          final map = Map<String, dynamic>.from(row);
          map['eventType'] = map['event_type'];
          map['id'] = map['id'];
          map['iconCodePoint'] = Icons.dynamic_form_outlined.codePoint;
          return RcRecordSchema.fromMap(map);
        }).toList();
      });
    } catch (_) {
      // The built-in production forms remain available if custom forms are not configured yet.
    }
  }

  Future<void> _refresh() async {
    setState(() => future = _load());
    await future;
  }

  List<RcRecordSchema> get visibleSchemas => RcProductRegistry.visibleSchemas(
    widget.state.profile!,
    customSchemas: customSchemas,
  );

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
          final modules = phase == 'All'
              ? visibleSchemas
              : visibleSchemas.where((s) => s.phase == phase).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 124),
            children: [
              RcPageHeading(
                eyebrow: 'Production management',
                title: 'Control of Works',
                subtitle:
                    'Every operational record is connected to a parish, house, owner, status and evidence chain.',
                trailing: widget.state.profile!.canExportData
                    ? IconButton.filledTonal(
                        tooltip: 'Export visible production table',
                        onPressed: () => RcExportService.shareProductionTable(
                          title: 'RC_SOW_Production',
                          records: records,
                        ),
                        icon: const Icon(Icons.file_download_outlined),
                      )
                    : null,
              ),
              const SizedBox(height: 18),
              _ProductionChain(
                records: records,
                onPhase: (value) => setState(() => phase = value),
              ),
              const SizedBox(height: 16),
              RcResponsiveGrid(
                minTileWidth: 170,
                children: [
                  _Pulse(
                    'Open',
                    '$open',
                    Icons.pending_actions_outlined,
                    theme.colorScheme.primary,
                  ),
                  _Pulse(
                    'Need action',
                    '$attention',
                    Icons.warning_amber_rounded,
                    attention == 0 ? RcColors.success : RcColors.warning,
                  ),
                  _Pulse(
                    'Closed',
                    '$completed',
                    Icons.verified_outlined,
                    RcColors.success,
                  ),
                  _Pulse(
                    'Records',
                    '${records.length}',
                    Icons.account_tree_outlined,
                    RcColors.purple,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _PhaseRail(
                selected: phase,
                onSelected: (value) => setState(() => phase = value),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Production modules',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  if (snap.connectionState == ConnectionState.waiting)
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.3),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 1000
                      ? 3
                      : constraints.maxWidth >= 600
                      ? 2
                      : 1;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: modules.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: 11,
                      crossAxisSpacing: 11,
                      childAspectRatio: columns == 1 ? 3.25 : 2.25,
                    ),
                    itemBuilder: (_, index) {
                      final schema = modules[index];
                      final count = records
                          .where((r) => r.eventType == schema.eventType)
                          .length;
                      return _ModuleTile(
                        schema: schema,
                        count: count,
                        onTap: () => _openModule(schema),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Recent operational records',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  if (widget.state.profile!.isManagement)
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              ProductionDatabaseScreen(state: widget.state),
                        ),
                      ),
                      icon: const Icon(Icons.storage_outlined),
                      label: const Text('Database view'),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (records.isEmpty &&
                  snap.connectionState != ConnectionState.waiting)
                const RcExpressiveSurface(
                  child: Text(
                    'No production records are visible for this account yet.',
                  ),
                )
              else
                ...records
                    .take(10)
                    .map(
                      (record) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: RcExpressiveSurface(
                          shape: RcSurfaceShape.offset,
                          onTap: () => _openRecord(record),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${record.houseCode} • ${record.title}',
                                      style: theme.textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${record.parish} • ${record.summary.isEmpty ? 'Updated production record' : record.summary}',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              RcStatusPill(
                                label: record.status.toUpperCase(),
                                color: record.needsAttention
                                    ? RcColors.warning
                                    : record.isClosed
                                    ? RcColors.success
                                    : theme.colorScheme.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
              if (snap.hasError) ...[
                const SizedBox(height: 12),
                RcExpressiveSurface(
                  tone: theme.colorScheme.errorContainer,
                  child: const Text(
                    'Could not load production records. Pull to retry.',
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _openModule(RcRecordSchema schema) async {
    if (schema.eventType == 'crewAttendance') {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CrewAttendanceScreen(state: widget.state),
        ),
      );
    } else {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              ProductionModuleScreen(state: widget.state, schema: schema),
        ),
      );
    }
    await _refresh();
  }

  Future<void> _openRecord(ProductionRecord record) async {
    final schema = RcProductRegistry.resolveSchema(
      record.eventType,
      customSchemas: customSchemas,
    );
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RecordFormScreen(
          state: widget.state,
          schema: schema,
          record: record,
        ),
      ),
    );
    await _refresh();
  }
}

class ProductionModuleScreen extends StatefulWidget {
  const ProductionModuleScreen({
    super.key,
    required this.state,
    required this.schema,
  });
  final AppState state;
  final RcRecordSchema schema;

  @override
  State<ProductionModuleScreen> createState() => _ProductionModuleScreenState();
}

class _ProductionModuleScreenState extends State<ProductionModuleScreen> {
  late Future<List<ProductionRecord>> future;

  @override
  void initState() {
    super.initState();
    future = _load();
  }

  bool get canAdd {
    final profile = widget.state.profile!;
    if (profile.canEditProduction) return true;
    if (!profile.isCrew) return false;
    if (widget.schema.eventType == 'dailyLog')
      return profile.hasPrivilege('uploadEvidence');
    if (widget.schema.eventType == 'materialRequest' ||
        widget.schema.eventType == 'consumables') {
      return profile.hasPrivilege('submitFieldRequests');
    }
    return false;
  }

  Future<List<ProductionRecord>> _load() =>
      widget.state.repository.productionRecords(
        widget.state.profile!,
        eventType: widget.schema.eventType,
      );
  Future<void> refresh() async {
    setState(() => future = _load());
    await future;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(widget.schema.title)),
      floatingActionButton: canAdd
          ? FloatingActionButton.extended(
              onPressed: _add,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add record'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: refresh,
        child: FutureBuilder<List<ProductionRecord>>(
          future: future,
          builder: (_, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 110),
                children: [
                  RcExpressiveSurface(
                    tone: Theme.of(context).colorScheme.errorContainer,
                    child: const Text(
                      'Production records could not be loaded. Your data was not changed. Check the connection and retry.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    onPressed: refresh,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                  ),
                ],
              );
            }
            final records = snap.data ?? const <ProductionRecord>[];
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
              children: [
                RcExpressiveSurface(
                  shape: RcSurfaceShape.hero,
                  tone: theme.colorScheme.secondaryContainer.withValues(
                    alpha: .3,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        widget.schema.icon,
                        size: RcIconSize.lg,
                        color: theme.colorScheme.secondary,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.schema.phase.toUpperCase(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.schema.description.isEmpty
                                  ? 'Structured production record tied to the house lifecycle.'
                                  : widget.schema.description,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${records.length} records',
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    if (widget.state.profile!.canExportData)
                      IconButton(
                        onPressed: () => RcExportService.shareProductionTable(
                          title: widget.schema.title,
                          records: records,
                        ),
                        icon: const Icon(Icons.table_view_outlined),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (records.isEmpty &&
                    snap.connectionState != ConnectionState.waiting)
                  const RcExpressiveSurface(
                    child: Text('No records in this module yet.'),
                  ),
                ...records.map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: RcExpressiveSurface(
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => RecordFormScreen(
                              state: widget.state,
                              schema: widget.schema,
                              record: r,
                            ),
                          ),
                        );
                        await refresh();
                      },
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${r.houseCode} • ${r.parish}',
                                  style: theme.textTheme.titleMedium,
                                ),
                                if (r.summary.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    r.summary,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
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
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _add() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            RecordFormScreen(state: widget.state, schema: widget.schema),
      ),
    );
    if (saved == true) await refresh();
  }
}

class ProductionDatabaseScreen extends StatefulWidget {
  const ProductionDatabaseScreen({super.key, required this.state});
  final AppState state;

  @override
  State<ProductionDatabaseScreen> createState() =>
      _ProductionDatabaseScreenState();
}

class _ProductionDatabaseScreenState extends State<ProductionDatabaseScreen> {
  String? parish;
  String query = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Production Database & Analytics')),
      body: FutureBuilder<List<ProductionRecord>>(
        future: widget.state.repository.productionRecords(
          widget.state.profile!,
          parish: parish,
        ),
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 80),
              children: [
                RcExpressiveSurface(
                  tone: Theme.of(context).colorScheme.errorContainer,
                  child: const Text(
                    'Production analytics could not be loaded. Check the connection and retry.',
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: () => setState(() {}),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            );
          }
          final all = snap.data ?? const <ProductionRecord>[];
          final filtered = query.trim().isEmpty
              ? all
              : all
                    .where(
                      (r) => '${r.houseCode} ${r.title} ${r.status} ${r.parish}'
                          .toLowerCase()
                          .contains(query.toLowerCase()),
                    )
                    .toList();
          final houses = filtered
              .map((r) => r.houseCode)
              .where((x) => x != '—')
              .toSet()
              .length;
          final pendingPayments = filtered
              .where((r) => r.eventType == 'payment' && r.status != 'Paid')
              .length;
          final completions = filtered
              .where((r) => r.eventType == 'notice' && r.isClosed)
              .length;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 80),
            children: [
              RcResponsiveGrid(
                minTileWidth: 170,
                children: [
                  _Pulse(
                    'Houses',
                    '$houses',
                    Icons.home_work_outlined,
                    Theme.of(context).colorScheme.primary,
                  ),
                  _Pulse(
                    'Records',
                    '${filtered.length}',
                    Icons.storage_outlined,
                    RcColors.blue,
                  ),
                  _Pulse(
                    'Payment queue',
                    '$pendingPayments',
                    Icons.payments_outlined,
                    RcColors.warning,
                  ),
                  _Pulse(
                    'Closed-out',
                    '$completions',
                    Icons.verified_outlined,
                    RcColors.success,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  SizedBox(
                    width: 280,
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Search house / record / state',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (v) => setState(() => query = v),
                    ),
                  ),
                  if (widget.state.profile!.canViewAllParishes)
                    SizedBox(
                      width: 220,
                      child: DropdownButtonFormField<String>(
                        initialValue: parish,
                        decoration: const InputDecoration(labelText: 'Parish'),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('All parishes'),
                          ),
                          ...RcApp.parishes.map(
                            (p) => DropdownMenuItem(value: p, child: Text(p)),
                          ),
                        ],
                        onChanged: (v) => setState(() => parish = v),
                      ),
                    ),
                  FilledButton.tonalIcon(
                    onPressed: () => RcExportService.shareProductionTable(
                      title: 'RC_SOW_Production_Export',
                      records: filtered,
                    ),
                    icon: const Icon(Icons.file_download_outlined),
                    label: const Text('Export table'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ...filtered
                  .take(250)
                  .map(
                    (r) => Card(
                      child: ListTile(
                        title: Text('${r.houseCode} • ${r.title}'),
                        subtitle: Text(
                          '${r.parish} • ${r.status} • ${r.summary}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
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

class _ProductionChain extends StatelessWidget {
  const _ProductionChain({required this.records, required this.onPhase});
  final List<ProductionRecord> records;
  final ValueChanged<String> onPhase;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final phases = <(String, IconData)>[
      ('Plan', Icons.assignment_turned_in_outlined),
      ('Delivery', Icons.construction_outlined),
      ('Quality', Icons.fact_check_outlined),
      ('Close-out', Icons.verified_outlined),
      ('Finance', Icons.payments_outlined),
    ];
    return RcExpressiveSurface(
      shape: RcSurfaceShape.hero,
      tone: theme.colorScheme.surfaceContainerLow,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < phases.length; i++) ...[
              InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => onPhase(phases[i].$1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Icon(
                          phases[i].$2,
                          size: RcIconSize.sm,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        phases[i].$1,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (i < phases.length - 1)
                Icon(
                  Icons.arrow_forward_rounded,
                  size: RcIconSize.xs,
                  color: theme.colorScheme.outline,
                ),
            ],
          ],
        ),
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<String>(
        segments: _ControlScreenState.phases
            .map((p) => ButtonSegment(value: p, label: Text(p)))
            .toList(),
        selected: {selected},
        showSelectedIcon: false,
        onSelectionChanged: (selection) => onSelected(selection.first),
      ),
    );
  }
}

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({
    required this.schema,
    required this.count,
    required this.onTap,
  });
  final RcRecordSchema schema;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RcExpressiveSurface(
      shape: RcSurfaceShape.offset,
      onTap: onTap,
      semanticLabel: schema.title,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              schema.icon,
              size: RcIconSize.sm,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(schema.title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 3),
                Text(
                  '${schema.phase} • $count records',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

class _Pulse extends StatelessWidget {
  const _Pulse(this.label, this.value, this.icon, this.color);
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return RcExpressiveSurface(
      shape: RcSurfaceShape.offset,
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
}
