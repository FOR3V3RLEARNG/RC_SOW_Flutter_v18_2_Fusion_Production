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
    return ColoredBox(
      color: _ControlWorksPalette.pageBackground,
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<ProductionRecord>>(
          future: future,
          builder: (context, snap) {
            final records = snap.data ?? const <ProductionRecord>[];
            final modules = phase == 'All'
                ? visibleSchemas
                : visibleSchemas.where((s) => s.phase == phase).toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 124),
              children: [
                _ControlWorksHeader(onNew: () => _showNewMenu(records)),
                const SizedBox(height: 24),
                _ProductionChain(
                  records: records,
                  onPhase: (value) => setState(() => phase = value),
                ),
                const SizedBox(height: 28),
                _PhaseRail(
                  selected: phase,
                  onSelected: (value) => setState(() => phase = value),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Workflow modules',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: _ControlWorksPalette.textPrimary,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -.35,
                        ),
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
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 980
                        ? 3
                        : constraints.maxWidth >= 540
                        ? 2
                        : 1;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: modules.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: columns == 1 ? 3.15 : 2.03,
                      ),
                      itemBuilder: (_, index) {
                        final schema = modules[index];
                        final count = records
                            .where((r) => r.eventType == schema.eventType)
                            .length;
                        return _ModuleTile(
                          state: widget.state,
                          schema: schema,
                          count: count,
                          onTap: () => _openModule(schema),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Recent operational records',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: _ControlWorksPalette.textPrimary,
                          fontWeight: FontWeight.w900,
                        ),
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
                const SizedBox(height: 10),
                if (records.isEmpty &&
                    snap.connectionState != ConnectionState.waiting)
                  const _ReferenceEmptyState()
                else
                  ...records
                      .take(10)
                      .map(
                        (record) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _ReferenceRecordTile(
                            record: record,
                            onTap: () => _openRecord(record),
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
      ),
    );
  }

  Future<void> _showNewMenu(List<ProductionRecord> records) async {
    final schemas = visibleSchemas;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: _ControlWorksPalette.surface,
      builder: (sheetContext) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * .78,
            ),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
              children: [
                Text(
                  'Create production record',
                  style: Theme.of(sheetContext).textTheme.headlineSmall
                      ?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: _ControlWorksPalette.textPrimary,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Choose the Control of Works module for the new record.',
                  style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                    color: _ControlWorksPalette.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                ...schemas.map(
                  (schema) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: const BorderSide(
                          color: _ControlWorksPalette.border,
                        ),
                      ),
                      tileColor: _ControlWorksPalette.surface,
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _ControlWorksPalette.iconWell,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          widget.state.uiIcon(
                            'module.${schema.eventType}',
                            schema.icon,
                          ),
                          color: _ControlWorksPalette.moduleBlue,
                        ),
                      ),
                      title: Text(
                        schema.title,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(schema.phase),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        WidgetsBinding.instance.addPostFrameCallback(
                          (_) => _openModule(schema),
                        );
                      },
                    ),
                  ),
                ),
                if (widget.state.profile!.canExportData) ...[
                  const SizedBox(height: 8),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.file_download_outlined),
                    title: const Text('Export visible production table'),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      RcExportService.shareProductionTable(
                        title: 'RC_SOW_Production',
                        records: records,
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
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
    this.initialHouse,
  });
  final AppState state;
  final RcRecordSchema schema;
  final HouseRecord? initialHouse;

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
    if (widget.schema.eventType == 'dailyLog') {
      return profile.hasPrivilege('uploadEvidence');
    }
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
        houseCode: widget.initialHouse?.code,
      );
  Future<void> refresh() async {
    setState(() => future = _load());
    await future;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initialHouse == null
              ? widget.schema.title
              : '${widget.initialHouse!.code} • ${widget.schema.title}',
        ),
      ),
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
        builder: (_) => RecordFormScreen(
          state: widget.state,
          schema: widget.schema,
          initialHouse: widget.initialHouse,
        ),
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
    final open = records.where((r) => !r.isClosed).length;
    final attention = records.where((r) => r.needsAttention).length;
    final closed = records.where((r) => r.isClosed).length;

    return Container(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 26),
      decoration: BoxDecoration(
        color: _ControlWorksPalette.hero,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _ControlWorksPalette.heroBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Controlled delivery chain',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: _ControlWorksPalette.textPrimary,
              fontWeight: FontWeight.w900,
              letterSpacing: -.45,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Every field action remains traceable to a house, parish, status and production stage.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: _ControlWorksPalette.textSecondary,
              height: 1.48,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _StatusBadge(
                icon: Icons.play_arrow_rounded,
                label: '$open OPEN',
                foreground: _ControlWorksPalette.primary,
                background: _ControlWorksPalette.openChip,
              ),
              _StatusBadge(
                icon: Icons.priority_high_rounded,
                label: '$attention ATTENTION',
                foreground: _ControlWorksPalette.success,
                background: _ControlWorksPalette.successChip,
              ),
              _StatusBadge(
                icon: Icons.check_rounded,
                label: '$closed CLOSED',
                foreground: _ControlWorksPalette.success,
                background: _ControlWorksPalette.closedChip,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                height: 58,
                child: FilledButton.icon(
                  onPressed: () => onPhase('Close-out'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _ControlWorksPalette.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: const Icon(Icons.verified_outlined, size: 22),
                  label: const Text(
                    'Completion',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                ),
              ),
              SizedBox(
                height: 58,
                child: OutlinedButton.icon(
                  onPressed: () => onPhase('Finance'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _ControlWorksPalette.primary,
                    backgroundColor: _ControlWorksPalette.hero,
                    side: const BorderSide(
                      color: _ControlWorksPalette.paymentBorder,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: const Icon(Icons.payments_outlined, size: 22),
                  label: const Text(
                    'Payment',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ControlWorksHeader extends StatelessWidget {
  const _ControlWorksHeader({required this.onNew});

  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final heading = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PRODUCTION MANAGEMENT',
              style: theme.textTheme.labelLarge?.copyWith(
                color: _ControlWorksPalette.primary,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.35,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Control of Works',
              style: theme.textTheme.displaySmall?.copyWith(
                color: _ControlWorksPalette.textPrimary,
                fontWeight: FontWeight.w900,
                height: .98,
                letterSpacing: -1.0,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Plan, execute, inspect, close and pay without breaking the evidence chain.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: _ControlWorksPalette.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        );

        final newButton = SizedBox(
          height: 58,
          child: FilledButton.icon(
            onPressed: onNew,
            style: FilledButton.styleFrom(
              backgroundColor: _ControlWorksPalette.newButton,
              foregroundColor: _ControlWorksPalette.textPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 22),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text(
              'New',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ),
        );

        if (constraints.maxWidth < 520) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(alignment: Alignment.centerRight, child: newButton),
              const SizedBox(height: 8),
              heading,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: heading),
            const SizedBox(width: 18),
            newButton,
          ],
        );
      },
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.icon,
    required this.label,
    required this.foreground,
    required this.background,
  });

  final IconData icon;
  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 39,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: foreground, size: 18),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontWeight: FontWeight.w900,
              letterSpacing: .2,
              fontSize: 13,
            ),
          ),
        ],
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth < 600 ? 600.0 : constraints.maxWidth;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: width,
            height: 52,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: _ControlWorksPalette.surface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: _ControlWorksPalette.border),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Row(
                  children: [
                    for (
                      var i = 0;
                      i < _ControlScreenState.phases.length;
                      i++
                    ) ...[
                      Expanded(
                        child: _PhaseTab(
                          label: _ControlScreenState.phases[i],
                          selected: selected == _ControlScreenState.phases[i],
                          onTap: () =>
                              onSelected(_ControlScreenState.phases[i]),
                        ),
                      ),
                      if (i < _ControlScreenState.phases.length - 1)
                        const VerticalDivider(
                          width: 1,
                          thickness: 1,
                          color: _ControlWorksPalette.border,
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PhaseTab extends StatelessWidget {
  const _PhaseTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? _ControlWorksPalette.selectedTab
          : _ControlWorksPalette.surface,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Text(
            label,
            maxLines: 1,
            style: TextStyle(
              color: _ControlWorksPalette.textPrimary,
              fontWeight: selected ? FontWeight.w900 : FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({
    required this.state,
    required this.schema,
    required this.count,
    required this.onTap,
  });

  final AppState state;
  final RcRecordSchema schema;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final description = schema.description.isEmpty
        ? 'Structured ${schema.phase.toLowerCase()} production record.'
        : schema.description;

    return Material(
      color: _ControlWorksPalette.surface,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 20, 18, 20),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: _ControlWorksPalette.cardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: _ControlWorksPalette.iconWell,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Icon(
                  state.uiIcon('module.${schema.eventType}', schema.icon),
                  color: _ControlWorksPalette.moduleBlue,
                  size: RcIconSize.lg,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      schema.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: _ControlWorksPalette.textPrimary,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _ControlWorksPalette.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 58,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$count',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: _ControlWorksPalette.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Text(
                      'records',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _ControlWorksPalette.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReferenceRecordTile extends StatelessWidget {
  const _ReferenceRecordTile({required this.record, required this.onTap});

  final ProductionRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = record.needsAttention
        ? RcColors.warning
        : record.isClosed
        ? RcColors.success
        : _ControlWorksPalette.primary;

    return Material(
      color: _ControlWorksPalette.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            border: Border.all(color: _ControlWorksPalette.cardBorder),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${record.houseCode} • ${record.title}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: _ControlWorksPalette.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${record.parish} • ${record.summary.isEmpty ? 'Updated production record' : record.summary}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ControlWorksPalette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              RcStatusPill(
                label: record.status.toUpperCase(),
                color: statusColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReferenceEmptyState extends StatelessWidget {
  const _ReferenceEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _ControlWorksPalette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _ControlWorksPalette.cardBorder),
      ),
      child: const Text(
        'No production records are visible for this account yet.',
        style: TextStyle(color: _ControlWorksPalette.textSecondary),
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
    final onColor =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black87;
    return RcExpressiveSurface(
      shape: RcSurfaceShape.offset,
      tone: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: RcIconSize.sm, color: onColor),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: onColor,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: onColor,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

abstract final class _ControlWorksPalette {
  static const pageBackground = Color(0xFFF4F7FC);
  static const surface = Color(0xFFFFFFFF);
  static const hero = Color(0xFFF9EBEB);
  static const heroBorder = Color(0xFFF1DCDD);
  static const primary = Color(0xFFC91F2C);
  static const textPrimary = Color(0xFF241B1C);
  static const textSecondary = Color(0xFF665B5D);
  static const newButton = Color(0xFFFEDBD9);
  static const selectedTab = Color(0xFFFEDBD9);
  static const border = Color(0xFFDDE1E8);
  static const cardBorder = Color(0xFFE2E5EA);
  static const iconWell = Color(0xFFEEF4FF);
  static const moduleBlue = Color(0xFF2D69C4);
  static const openChip = Color(0xFFF8D9DC);
  static const successChip = Color(0xFFE6EFEA);
  static const closedChip = Color(0xFFE8F1EC);
  static const success = Color(0xFF2E7A60);
  static const paymentBorder = Color(0xFFE7C7CA);
}
