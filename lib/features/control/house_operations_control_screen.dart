import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_constants.dart';
import '../../core/design_tokens.dart';
import '../../core/product_registry.dart';
import '../../core/rc_components.dart';
import '../../core/record_schemas.dart';
import '../../core/text_helpers.dart';
import '../../models/app_models.dart';
import '../../services/boq_import_service.dart';
import '../../state/app_state.dart';
import '../roof/technical_roof_draft.dart';
import '../workforce/crew_assignment_panel.dart';
import '../workforce/crew_attendance_screen.dart';
import 'control_screen.dart';

enum RcControlView { houses, modules }

const rcHouseStages = <String, int>{
  'Not Started': 0,
  'Site Preparation': 5,
  'Demolition': 15,
  'Wall Plate': 30,
  'Rafters / Collars': 45,
  'Battens': 58,
  'Roof Sheeting': 72,
  'Fascia & Blocking': 84,
  'Finishing': 92,
  'Final Inspection': 97,
  'Completed': 100,
};

class HouseOperationsControlScreen extends StatefulWidget {
  const HouseOperationsControlScreen({super.key, required this.state});
  final AppState state;

  @override
  State<HouseOperationsControlScreen> createState() =>
      _HouseOperationsControlScreenState();
}

class _HouseOperationsControlScreenState
    extends State<HouseOperationsControlScreen> {
  late Future<_ControlData> future;
  late RcControlView view;
  String query = '';
  String? parish;
  int? columnsOverride;

  int get columns =>
      (columnsOverride ?? widget.state.controlColumns).clamp(1, 3);

  @override
  void initState() {
    super.initState();
    view = widget.state.controlDefaultView == 'modules'
        ? RcControlView.modules
        : RcControlView.houses;
    future = _load();
  }

  Future<_ControlData> _load() async {
    final profile = widget.state.profile!;
    final result = await Future.wait([
      widget.state.repository.houses(profile),
      widget.state.repository.productionRecords(profile),
    ]);
    return _ControlData(
      houses: result[0] as List<HouseRecord>,
      records: result[1] as List<ProductionRecord>,
    );
  }

  Future<void> _refresh() async {
    await widget.state.refreshUiConfig();
    setState(() {
      columnsOverride = null;
      future = _load();
    });
    await future;
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.state.profile!;
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<_ControlData>(
        future: future,
        builder: (context, snap) {
          final data = snap.data ?? const _ControlData();
          final houses = data.houses.where((house) {
            final parishOk =
                parish == null || parish!.isEmpty || house.parish == parish;
            final q = query.trim().toLowerCase();
            final queryOk =
                q.isEmpty ||
                '${house.code} ${house.beneficiary} ${house.parish} ${house.cluster}'
                    .toLowerCase()
                    .contains(q);
            return parishOk && queryOk;
          }).toList();

          final open = data.records.where((r) => !r.isClosed).length;
          final attention = data.records.where((r) => r.needsAttention).length;
          final completion = data.records
              .where((r) => r.eventType == 'notice')
              .length;
          final payment = data.records
              .where((r) => r.eventType == 'payment' && r.status != 'Paid')
              .length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
            children: [
              RcPageHeading(
                eyebrow: 'House-centred production',
                title: widget.state.uiText('controlTitle', 'Control Of Works'),
                subtitle: widget.state.uiText(
                  'controlSubtitle',
                  'Switch between house-code control and production-module control. Both views read the same live records.',
                ),
                trailing: PopupMenuButton<int>(
                  tooltip: 'Tile layout',
                  initialValue: columns,
                  onSelected: (value) =>
                      setState(() => columnsOverride = value),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 1, child: Text('1 column')),
                    PopupMenuItem(value: 2, child: Text('2 columns')),
                    PopupMenuItem(value: 3, child: Text('3 columns')),
                  ],
                  icon: const Icon(Icons.grid_view_rounded),
                ),
              ),
              const SizedBox(height: 14),
              _ControlColumnsGrid(
                columns: columns,
                children: [
                  _PulseTile(
                    label: widget.state.uiText('openLabel', 'Open'),
                    value: '$open',
                    icon: Icons.folder_open_outlined,
                    color: theme.colorScheme.primary,
                    onTap: () {},
                  ),
                  _PulseTile(
                    label: widget.state.uiText(
                      'needActionLabel',
                      'Need Attention',
                    ),
                    value: '$attention',
                    icon: Icons.priority_high_rounded,
                    color: attention == 0 ? RcColors.success : RcColors.warning,
                    onTap: () {},
                  ),
                  _PulseTile(
                    label: widget.state.uiText('completionLabel', 'Completion'),
                    value: '$completion',
                    icon: Icons.verified_outlined,
                    color: RcColors.success,
                    onTap: () => _openModule('notice'),
                  ),
                  _PulseTile(
                    label: widget.state.uiText('paymentLabel', 'Payment'),
                    value: '$payment',
                    icon: Icons.payments_outlined,
                    color: RcColors.warning,
                    onTap: () => _openModule('payment'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SegmentedButton<RcControlView>(
                segments: const [
                  ButtonSegment(
                    value: RcControlView.houses,
                    icon: Icon(Icons.home_work_outlined),
                    label: Text('House Codes'),
                  ),
                  ButtonSegment(
                    value: RcControlView.modules,
                    icon: Icon(Icons.dashboard_customize_outlined),
                    label: Text('Production Modules'),
                  ),
                ],
                selected: {view},
                showSelectedIcon: false,
                onSelectionChanged: (selected) =>
                    setState(() => view = selected.first),
              ),
              const SizedBox(height: 12),
              if (view == RcControlView.houses) ...[
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    SizedBox(
                      width: 300,
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Search house / beneficiary',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (value) =>
                            setState(() => query = value.trim()),
                      ),
                    ),
                    if (profile.canViewAllParishes)
                      SizedBox(
                        width: 220,
                        child: DropdownButtonFormField<String?>(
                          initialValue: parish,
                          decoration: const InputDecoration(
                            labelText: 'Parish',
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('All Parishes'),
                            ),
                            ...RcApp.parishes.map(
                              (p) => DropdownMenuItem<String?>(
                                value: p,
                                child: Text(p),
                              ),
                            ),
                          ],
                          onChanged: (value) => setState(() => parish = value),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (houses.isEmpty &&
                    snap.connectionState != ConnectionState.waiting)
                  const RcExpressiveSurface(
                    child: Text('No houses match this selection.'),
                  ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final effective = columns.clamp(1, 3);
                    final gap = 10.0;
                    final width =
                        (constraints.maxWidth - gap * (effective - 1)) /
                        effective;
                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: houses
                          .map(
                            (house) => SizedBox(
                              width: width,
                              child: _HouseTile(
                                house: house,
                                recordCount: data.records
                                    .where(
                                      (record) =>
                                          record.houseCode == house.code,
                                    )
                                    .length,
                                onTap: () => _openHouse(house),
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
              ] else
                _ModuleGrid(
                  state: widget.state,
                  records: data.records,
                  columns: columns,
                  onOpenBoq: _openBoqDirectory,
                  onOpenModule: _openModule,
                ),
              if (snap.hasError) ...[
                const SizedBox(height: 12),
                RcExpressiveSurface(
                  tone: theme.colorScheme.errorContainer,
                  child: const Text(
                    'Some Control of Works data could not be loaded. Pull to refresh.',
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _openHouse(HouseRecord house) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            HouseControlWorkspaceScreen(state: widget.state, house: house),
      ),
    );
    await _refresh();
  }

  Future<void> _openModule(String eventType) async {
    final schema = RcRecordSchemas.byEventType(eventType);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ProductionModuleScreen(state: widget.state, schema: schema),
      ),
    );
    await _refresh();
  }

  Future<void> _openBoqDirectory() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HouseBoqDirectoryScreen(state: widget.state),
      ),
    );
    await _refresh();
  }
}

class HouseControlWorkspaceByCodeScreen extends StatefulWidget {
  const HouseControlWorkspaceByCodeScreen({
    super.key,
    required this.state,
    required this.houseCode,
  });
  final AppState state;
  final String houseCode;

  @override
  State<HouseControlWorkspaceByCodeScreen> createState() =>
      _HouseControlWorkspaceByCodeScreenState();
}

class _HouseControlWorkspaceByCodeScreenState
    extends State<HouseControlWorkspaceByCodeScreen> {
  late Future<HouseRecord?> future;

  @override
  void initState() {
    super.initState();
    future = _load();
  }

  Future<HouseRecord?> _load() async {
    final houses = await widget.state.repository.houses(widget.state.profile!);
    for (final house in houses) {
      if (house.code.toUpperCase() == widget.houseCode.toUpperCase()) {
        return house;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<HouseRecord?>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final house = snap.data;
        if (house == null) {
          return Scaffold(
            appBar: AppBar(title: Text(widget.houseCode)),
            body: const Center(
              child: Text(
                'This house is not available in your current parish or assignment scope.',
              ),
            ),
          );
        }
        return HouseControlWorkspaceScreen(state: widget.state, house: house);
      },
    );
  }
}

class HouseControlWorkspaceScreen extends StatefulWidget {
  const HouseControlWorkspaceScreen({
    super.key,
    required this.state,
    required this.house,
  });
  final AppState state;
  final HouseRecord house;

  @override
  State<HouseControlWorkspaceScreen> createState() =>
      _HouseControlWorkspaceScreenState();
}

class _HouseControlWorkspaceScreenState
    extends State<HouseControlWorkspaceScreen> {
  late Future<_HouseWorkspaceData> future;
  final note = TextEditingController();
  final redoStages = <String>[];
  bool busy = false;

  UserProfile get profile => widget.state.profile!;

  @override
  void initState() {
    super.initState();
    future = _load();
  }

  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  Future<_HouseWorkspaceData> _load() async {
    final result = await Future.wait([
      widget.state.repository.productionRecords(
        profile,
        houseCode: widget.house.code,
      ),
      widget.state.repository.houseBoq(widget.house.code),
      widget.state.repository.houseInventory(widget.house.code),
      widget.state.repository.houseProgressHistory(widget.house.code),
    ]);
    return _HouseWorkspaceData(
      records: result[0] as List<ProductionRecord>,
      boq: result[1] as Map<String, dynamic>?,
      inventory: result[2] as Map<String, dynamic>?,
      history: result[3] as List<Map<String, dynamic>>,
    );
  }

  Future<void> _refresh() async {
    setState(() => future = _load());
    await future;
  }

  Future<void> _setStage(String stage, {bool clearRedo = true}) async {
    setState(() => busy = true);
    try {
      await widget.state.repository.setHouseConstructionStage(
        houseCode: widget.house.code,
        stage: stage,
      );
      if (clearRedo) redoStages.clear();
      await widget.state.feedback(strong: true);
      await _refresh();
    } catch (_) {
      _snack('Construction stage could not be updated.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _undo(_HouseWorkspaceData data, String currentStage) async {
    String? previous;
    for (final row in data.history) {
      final stage = '${row['stage'] ?? ''}';
      if (stage.isNotEmpty && stage != currentStage) {
        previous = stage;
        break;
      }
    }
    if (previous == null) return;
    redoStages.add(currentStage);
    await _setStage(previous, clearRedo: false);
  }

  Future<void> _redo() async {
    if (redoStages.isEmpty) return;
    final stage = redoStages.removeLast();
    await _setStage(stage, clearRedo: false);
  }

  Future<void> _saveNote() async {
    if (note.text.trim().isEmpty) return;
    setState(() => busy = true);
    try {
      await widget.state.repository.submitControlEvent(
        profile: profile,
        eventType: 'workLog',
        houseCode: widget.house.code,
        parish: widget.house.parish,
        item: {
          'title': 'House Notepad',
          'recordKind': 'houseNote',
          'status': 'Open',
          'note': note.text.trim(),
          'summary': note.text.trim(),
        },
      );
      note.clear();
      await _refresh();
    } catch (_) {
      _snack('Note could not be saved.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('${widget.house.code} • Control Of Works')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<_HouseWorkspaceData>(
          future: future,
          builder: (context, snap) {
            final data = snap.data ?? const _HouseWorkspaceData();
            final latest = data.history.isEmpty ? null : data.history.first;
            final historyStage = '${latest?['stage'] ?? ''}';
            final normalizedStage = rcHouseStages.containsKey(historyStage)
                ? historyStage
                : rcHouseStages.containsKey(widget.house.stage)
                ? widget.house.stage
                : 'Not Started';
            final progress =
                (latest?['progress'] as num?)?.toInt() ??
                rcHouseStages[normalizedStage] ??
                widget.house.progress;
            final canStage =
                profile.isCarpenter ||
                profile.hasPrivilege('editControl') ||
                profile.hasPrivilege('reviewControl');
            final notes = data.records
                .where(
                  (r) =>
                      r.eventType == 'workLog' &&
                      r.item['recordKind'] == 'houseNote',
                )
                .toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
              children: [
                RcPageHeading(
                  eyebrow:
                      '${rcTitleCase(widget.house.parish)} • ${rcTitleCase(widget.house.cluster)}',
                  title:
                      '${widget.house.code} • ${rcTitleCase(widget.house.beneficiary)}',
                  subtitle:
                      '${rcTitleCase(normalizedStage)} • $progress% complete • ${data.records.length} controlled records',
                ),
                const SizedBox(height: 14),
                RcExpressiveSurface(
                  shape: RcSurfaceShape.hero,
                  tone: theme.colorScheme.primaryContainer.withValues(
                    alpha: .30,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Automatic House Status',
                              style: theme.textTheme.titleLarge,
                            ),
                          ),
                          Text(
                            '$progress%',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(value: progress / 100),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: normalizedStage,
                        decoration: const InputDecoration(
                          labelText: 'Roof framing / construction stage',
                        ),
                        items: rcHouseStages.entries
                            .map(
                              (entry) => DropdownMenuItem(
                                value: entry.key,
                                child: Text('${entry.key} • ${entry.value}%'),
                              ),
                            )
                            .toList(),
                        onChanged: !canStage || busy
                            ? null
                            : (v) => _setStage(v!),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          IconButton.filledTonal(
                            tooltip: 'Undo stage',
                            onPressed: busy || data.history.length < 2
                                ? null
                                : () => _undo(data, normalizedStage),
                            icon: const Icon(Icons.undo_rounded),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filledTonal(
                            tooltip: 'Redo stage',
                            onPressed: busy || redoStages.isEmpty
                                ? null
                                : _redo,
                            icon: const Icon(Icons.redo_rounded),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              canStage
                                  ? 'Assigned carpenters update stage; supervisors retain oversight.'
                                  : 'Stage is read-only for this role.',
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                RcResponsiveGrid(
                  minTileWidth: 150,
                  childAspectRatio: 1.55,
                  children: [
                    _ActionTile(
                      'BOQ',
                      Icons.receipt_long_outlined,
                      data.boq == null ? 'Not attached' : 'Attached',
                      _openBoq,
                    ),
                    _ActionTile(
                      'House Inventory',
                      Icons.inventory_2_outlined,
                      data.inventory == null
                          ? 'No delivery record'
                          : 'BOQ comparison',
                      _openInventory,
                    ),
                    _ActionTile(
                      'Completion',
                      Icons.verified_outlined,
                      '${data.records.where((r) => r.eventType == 'notice').length} records',
                      () => _openModule('notice'),
                    ),
                    _ActionTile(
                      'Payment',
                      Icons.payments_outlined,
                      '${data.records.where((r) => r.eventType == 'payment').length} records',
                      () => _openModule('payment'),
                    ),
                    _ActionTile(
                      'Attendance',
                      Icons.how_to_reg_outlined,
                      'Crew sign in / verify',
                      _openAttendance,
                    ),
                    _ActionTile(
                      'Roof Draft',
                      Icons.architecture_outlined,
                      'Stable framing calculator',
                      _openRoofDraft,
                    ),
                  ],
                ),
                if (profile.hasPrivilege('manageCrew')) ...[
                  const SizedBox(height: 14),
                  CrewAssignmentPanel(
                    state: widget.state,
                    initialHouseCode: widget.house.code,
                    compact: true,
                  ),
                ],
                const SizedBox(height: 14),
                RcExpressiveSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('House Notepad', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 8),
                      TextField(
                        controller: note,
                        minLines: 2,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Site note / issue / reminder',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.tonalIcon(
                          onPressed: busy ? null : _saveNote,
                          icon: const Icon(Icons.note_add_outlined),
                          label: const Text('Add Note'),
                        ),
                      ),
                      if (notes.isNotEmpty) ...[
                        const Divider(height: 24),
                        ...notes
                            .take(8)
                            .map(
                              (record) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(
                                  Icons.sticky_note_2_outlined,
                                ),
                                title: Text(record.summary),
                                subtitle: Text(
                                  record.updatedAt
                                      .toLocal()
                                      .toString()
                                      .split('.')
                                      .first,
                                ),
                              ),
                            ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text('House Records', style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                if (data.records.isEmpty)
                  const RcExpressiveSurface(
                    child: Text('No production records for this house yet.'),
                  ),
                ...data.records
                    .take(80)
                    .map(
                      (record) => Card(
                        child: ListTile(
                          leading: Icon(_iconFor(record.eventType)),
                          title: Text(record.title),
                          subtitle: Text(
                            '${record.status}${record.summary.isEmpty ? '' : ' • ${record.summary}'}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _openModule(record.eventType),
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

  Future<void> _openBoq() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            HouseBoqScreen(state: widget.state, house: widget.house),
      ),
    );
    await _refresh();
  }

  Future<void> _openInventory() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            HouseInventoryScreen(state: widget.state, house: widget.house),
      ),
    );
    await _refresh();
  }

  Future<void> _openModule(String eventType) async {
    final schema = RcRecordSchemas.byEventType(eventType);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ProductionModuleScreen(state: widget.state, schema: schema),
      ),
    );
    await _refresh();
  }

  Future<void> _openAttendance() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CrewAttendanceScreen(
          state: widget.state,
          initialHouseCode: widget.house.code,
        ),
      ),
    );
    await _refresh();
  }

  Future<void> _openRoofDraft() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TechnicalRoofDraftScreen(
          initialMeasurements: const RoofMeasurements(
            widthFt: 0,
            lengthFt: 0,
            wallHeightFt: 0,
            pitchRisePer12: 4,
          ),
          initialRoofType: 'Gable',
        ),
      ),
    );
  }

  IconData _iconFor(String eventType) => switch (eventType) {
    'notice' => Icons.verified_outlined,
    'payment' => Icons.payments_outlined,
    'crewAttendance' => Icons.how_to_reg_outlined,
    'inventory' => Icons.inventory_2_outlined,
    'monitoring' => Icons.fact_check_outlined,
    'siteVisit' => Icons.location_on_outlined,
    'dailyLog' => Icons.menu_book_outlined,
    'workLog' => Icons.edit_note_outlined,
    _ => Icons.description_outlined,
  };
}

class HouseBoqDirectoryScreen extends StatelessWidget {
  const HouseBoqDirectoryScreen({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('House BOQs')),
      body: FutureBuilder<List<HouseRecord>>(
        future: state.repository.houses(state.profile!),
        builder: (context, snap) {
          final houses = snap.data ?? const <HouseRecord>[];
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
            children: [
              const RcPageHeading(
                eyebrow: 'Bill of Quantities',
                title: 'BOQ By House',
                subtitle:
                    'Every house can carry a live BOQ that feeds House Inventory comparison.',
              ),
              const SizedBox(height: 12),
              ...houses.map(
                (house) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.receipt_long_outlined),
                    title: Text('${house.code} • ${house.beneficiary}'),
                    subtitle: Text('${house.parish} • ${house.cluster}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            HouseBoqScreen(state: state, house: house),
                      ),
                    ),
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

class HouseBoqScreen extends StatefulWidget {
  const HouseBoqScreen({super.key, required this.state, required this.house});
  final AppState state;
  final HouseRecord house;

  @override
  State<HouseBoqScreen> createState() => _HouseBoqScreenState();
}

class _HouseBoqScreenState extends State<HouseBoqScreen> {
  late Future<Map<String, dynamic>?> future;
  List<Map<String, dynamic>> items = [];
  String? sourceFile;
  bool loaded = false;
  bool busy = false;

  bool get canEdit =>
      widget.state.profile!.hasPrivilege('editControl') ||
      widget.state.profile!.hasPrivilege('reviewControl') ||
      widget.state.profile!.canViewAdmin;

  @override
  void initState() {
    super.initState();
    future = widget.state.repository.houseBoq(widget.house.code);
  }

  void _loadFrom(Map<String, dynamic>? row) {
    if (loaded) return;
    loaded = true;
    sourceFile = row?['source_file_name']?.toString();
    items = (row?['items'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<void> _import() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    if (!mounted) return;

    try {
      final parsed = BoqImportService.parse(bytes);
      setState(() {
        items = parsed.items;
        sourceFile = file.name;
      });
    } catch (error) {
      _snack('BOQ import failed: $error');
    }
  }

  Future<void> _save() async {
    setState(() => busy = true);
    try {
      await widget.state.repository.saveHouseBoq(
        houseCode: widget.house.code,
        parish: widget.house.parish,
        items: items,
        sourceFileName: sourceFile,
      );
      _snack('BOQ saved for ${widget.house.code}.');
      setState(() {
        loaded = false;
        future = widget.state.repository.houseBoq(widget.house.code);
      });
    } catch (_) {
      _snack('BOQ could not be saved.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.house.code} • BOQ')),
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              onPressed: busy ? null : () => _editItem(),
              icon: const Icon(Icons.add),
              label: const Text('Item'),
            )
          : null,
      body: FutureBuilder<Map<String, dynamic>?>(
        future: future,
        builder: (context, snap) {
          _loadFrom(snap.data);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            children: [
              RcPageHeading(
                eyebrow: '${widget.house.parish} • ${widget.house.code}',
                title: 'Bill Of Quantities',
                subtitle:
                    '${items.length} material items${sourceFile == null ? '' : ' • $sourceFile'}',
              ),
              const SizedBox(height: 12),
              if (canEdit)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: busy ? null : _import,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Import Excel BOQ'),
                    ),
                    FilledButton.icon(
                      onPressed: busy ? null : _save,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Save BOQ'),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              if (items.isEmpty)
                const RcExpressiveSurface(
                  child: Text(
                    'No BOQ has been attached. Import an XLSX BOQ or add material rows manually.',
                  ),
                ),
              ...items.asMap().entries.map(
                (entry) => Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text('${entry.key + 1}')),
                    title: Text('${entry.value['description'] ?? 'Material'}'),
                    subtitle: Text(
                      '${entry.value['itemCode'] ?? ''} • ${entry.value['size'] ?? ''} ${entry.value['length'] ?? ''}\n'
                      'BOQ ${_num(entry.value['boqQuantity'])} ${entry.value['unit'] ?? ''}',
                    ),
                    isThreeLine: true,
                    trailing: canEdit
                        ? PopupMenuButton<String>(
                            onSelected: (action) {
                              if (action == 'edit') {
                                _editItem(index: entry.key);
                              } else if (action == 'delete') {
                                setState(() => items.removeAt(entry.key));
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'edit', child: Text('Edit')),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                          )
                        : null,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _editItem({int? index}) async {
    final original = index == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(items[index]);
    final code = TextEditingController(text: '${original['itemCode'] ?? ''}');
    final description = TextEditingController(
      text: '${original['description'] ?? ''}',
    );
    final unit = TextEditingController(text: '${original['unit'] ?? ''}');
    final size = TextEditingController(text: '${original['size'] ?? ''}');
    final length = TextEditingController(text: '${original['length'] ?? ''}');
    final quantity = TextEditingController(
      text: '${original['boqQuantity'] ?? ''}',
    );
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(index == null ? 'Add BOQ Item' : 'Edit BOQ Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: code,
                decoration: const InputDecoration(labelText: 'Item code'),
              ),
              TextField(
                controller: description,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextField(
                controller: unit,
                decoration: const InputDecoration(labelText: 'Unit'),
              ),
              TextField(
                controller: size,
                decoration: const InputDecoration(labelText: 'Size'),
              ),
              TextField(
                controller: length,
                decoration: const InputDecoration(labelText: 'Length'),
              ),
              TextField(
                controller: quantity,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'BOQ quantity'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (saved == true && description.text.trim().isNotEmpty) {
      final item = {
        'itemCode': code.text.trim(),
        'description': description.text.trim(),
        'unit': unit.text.trim(),
        'size': size.text.trim(),
        'length': length.text.trim(),
        'boqQuantity': double.tryParse(quantity.text.trim()) ?? 0,
      };
      setState(() {
        if (index == null) {
          items.add(item);
        } else {
          items[index] = item;
        }
      });
    }
    for (final c in [code, description, unit, size, length, quantity]) {
      c.dispose();
    }
  }

  String _num(Object? raw) {
    final v = raw is num ? raw.toDouble() : double.tryParse('$raw') ?? 0;
    return v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
  }
}

class HouseInventoryScreen extends StatefulWidget {
  const HouseInventoryScreen({
    super.key,
    required this.state,
    required this.house,
  });
  final AppState state;
  final HouseRecord house;

  @override
  State<HouseInventoryScreen> createState() => _HouseInventoryScreenState();
}

class _HouseInventoryScreenState extends State<HouseInventoryScreen> {
  late Future<_InventoryData> future;
  List<Map<String, dynamic>> rows = [];
  bool loaded = false;
  bool busy = false;

  bool get canEdit =>
      widget.state.profile!.hasPrivilege('editControl') ||
      widget.state.profile!.hasPrivilege('reviewControl') ||
      widget.state.profile!.canViewAdmin;

  @override
  void initState() {
    super.initState();
    future = _load();
  }

  Future<_InventoryData> _load() async {
    final result = await Future.wait([
      widget.state.repository.houseBoq(widget.house.code),
      widget.state.repository.houseInventory(widget.house.code),
    ]);
    return _InventoryData(boq: result[0], inventory: result[1]);
  }

  void _hydrate(_InventoryData data) {
    if (loaded) return;
    loaded = true;
    final existing = <String, Map<String, dynamic>>{};
    for (final raw
        in (data.inventory?['items'] as List? ?? const []).whereType<Map>()) {
      final item = Map<String, dynamic>.from(raw);
      existing[_key(item)] = item;
    }
    rows = (data.boq?['items'] as List? ?? const []).whereType<Map>().map((
      raw,
    ) {
      final boq = Map<String, dynamic>.from(raw);
      final saved = existing[_key(boq)];
      return {
        ...boq,
        'receivedQuantity': saved?['receivedQuantity'] ?? 0,
        'usedQuantity': saved?['usedQuantity'] ?? 0,
        'returnedQuantity': saved?['returnedQuantity'] ?? 0,
        'notes': saved?['notes'] ?? '',
      };
    }).toList();
  }

  String _key(Map<String, dynamic> item) {
    final code = '${item['itemCode'] ?? ''}'.trim().toLowerCase();
    return code.isNotEmpty
        ? code
        : '${item['description'] ?? ''}'.trim().toLowerCase();
  }

  Future<void> _save() async {
    setState(() => busy = true);
    try {
      await widget.state.repository.saveHouseInventory(
        houseCode: widget.house.code,
        parish: widget.house.parish,
        items: rows,
      );
      _snack('House Inventory saved.');
    } catch (_) {
      _snack('House Inventory could not be saved.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.house.code} • House Inventory')),
      body: FutureBuilder<_InventoryData>(
        future: future,
        builder: (context, snap) {
          final data = snap.data ?? const _InventoryData();
          _hydrate(data);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            children: [
              RcPageHeading(
                eyebrow: '${widget.house.parish} • ${widget.house.code}',
                title: 'House Inventory',
                subtitle:
                    'Compare BOQ quantity against material received, used and returned.',
                trailing: canEdit
                    ? FilledButton.icon(
                        onPressed: busy || rows.isEmpty ? null : _save,
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Save'),
                      )
                    : null,
              ),
              const SizedBox(height: 12),
              if (data.boq == null)
                const RcExpressiveSurface(
                  child: Text(
                    'Attach the house BOQ first. Inventory items are generated from the BOQ list.',
                  ),
                ),
              ...rows.asMap().entries.map((entry) {
                final row = entry.value;
                final boq = _double(row['boqQuantity']);
                final received = _double(row['receivedQuantity']);
                final variance = received - boq;
                return Card(
                  child: ListTile(
                    leading: Icon(
                      variance < 0
                          ? Icons.warning_amber_rounded
                          : Icons.check_circle_outline,
                      color: variance < 0 ? RcColors.warning : RcColors.success,
                    ),
                    title: Text('${row['description'] ?? 'Material'}'),
                    subtitle: Text(
                      'BOQ ${_n(boq)} • Received ${_n(received)} • '
                      'Variance ${variance >= 0 ? '+' : ''}${_n(variance)} ${row['unit'] ?? ''}\n'
                      'Used ${_n(_double(row['usedQuantity']))} • '
                      'Returned ${_n(_double(row['returnedQuantity']))}',
                    ),
                    isThreeLine: true,
                    trailing: canEdit
                        ? IconButton(
                            onPressed: () => _edit(entry.key),
                            icon: const Icon(Icons.edit_outlined),
                          )
                        : null,
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Future<void> _edit(int index) async {
    final row = rows[index];
    final received = TextEditingController(
      text: '${row['receivedQuantity'] ?? 0}',
    );
    final used = TextEditingController(text: '${row['usedQuantity'] ?? 0}');
    final returned = TextEditingController(
      text: '${row['returnedQuantity'] ?? 0}',
    );
    final notes = TextEditingController(text: '${row['notes'] ?? ''}');
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${row['description'] ?? 'Inventory Item'}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: received,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Received'),
              ),
              TextField(
                controller: used,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Used'),
              ),
              TextField(
                controller: returned,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Returned'),
              ),
              TextField(
                controller: notes,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Notes'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
    if (saved == true) {
      setState(() {
        row['receivedQuantity'] = double.tryParse(received.text) ?? 0;
        row['usedQuantity'] = double.tryParse(used.text) ?? 0;
        row['returnedQuantity'] = double.tryParse(returned.text) ?? 0;
        row['notes'] = notes.text.trim();
      });
    }
    for (final c in [received, used, returned, notes]) {
      c.dispose();
    }
  }

  double _double(Object? raw) =>
      raw is num ? raw.toDouble() : double.tryParse('$raw') ?? 0;

  String _n(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
}

class HouseMapDirectoryScreen extends StatelessWidget {
  const HouseMapDirectoryScreen({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('House Map & Directions')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: state.repository.houseLocations(state.profile!),
        builder: (context, snap) {
          final rows = snap.data ?? const <Map<String, dynamic>>[];
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
            children: [
              const RcPageHeading(
                eyebrow: 'Field navigation',
                title: 'House Locations',
                subtitle:
                    'Open directions or jump directly from a mapped house to its Control of Works record.',
              ),
              const SizedBox(height: 12),
              ...rows.map((row) {
                final code = '${row['house_code'] ?? ''}';
                final beneficiary = '${row['beneficiary_name'] ?? ''}';
                final rawUrl = '${row['maps_url'] ?? ''}';
                final lat = row['latitude'];
                final lon = row['longitude'];
                final url = lat != null && lon != null
                    ? 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lon'
                    : rawUrl;
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.location_on_outlined),
                    title: Text('$code • $beneficiary'),
                    subtitle: Text(
                      '${row['parish'] ?? ''} • ${row['cluster'] ?? ''}',
                    ),
                    trailing: Wrap(
                      spacing: 2,
                      children: [
                        IconButton(
                          tooltip: 'Directions',
                          onPressed: url.isEmpty
                              ? null
                              : () async {
                                  final uri = Uri.tryParse(url);
                                  if (uri != null) {
                                    await launchUrl(
                                      uri,
                                      mode: LaunchMode.externalApplication,
                                    );
                                  }
                                },
                          icon: const Icon(Icons.directions_outlined),
                        ),
                        IconButton(
                          tooltip: 'Open house',
                          onPressed: code.isEmpty
                              ? null
                              : () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        HouseControlWorkspaceByCodeScreen(
                                          state: state,
                                          houseCode: code,
                                        ),
                                  ),
                                ),
                          icon: const Icon(Icons.home_work_outlined),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              if (rows.isEmpty &&
                  snap.connectionState != ConnectionState.waiting)
                const RcExpressiveSurface(
                  child: Text(
                    'No house locations are available for this account yet.',
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ControlColumnsGrid extends StatelessWidget {
  const _ControlColumnsGrid({required this.columns, required this.children});

  final int columns;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final effective = columns.clamp(1, 3);
        final gap = effective == 3 ? 7.0 : 10.0;
        final tileWidth =
            (constraints.maxWidth - gap * (effective - 1)) / effective;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: children
              .map((child) => SizedBox(width: tileWidth, child: child))
              .toList(),
        );
      },
    );
  }
}

class _ModuleGrid extends StatelessWidget {
  const _ModuleGrid({
    required this.state,
    required this.records,
    required this.columns,
    required this.onOpenBoq,
    required this.onOpenModule,
  });
  final AppState state;
  final List<ProductionRecord> records;
  final int columns;
  final VoidCallback onOpenBoq;
  final ValueChanged<String> onOpenModule;

  @override
  Widget build(BuildContext context) {
    final schemas = RcProductRegistry.visibleSchemas(
      state.profile!,
    ).where((schema) => schema.eventType != 'crewAttendance').toList();
    final configuredOrder = state.controlModuleOrder;
    if (configuredOrder.isNotEmpty) {
      schemas.sort((a, b) {
        final ai = configuredOrder.indexOf(a.eventType);
        final bi = configuredOrder.indexOf(b.eventType);
        final aOrder = ai < 0 ? configuredOrder.length + 1 : ai;
        final bOrder = bi < 0 ? configuredOrder.length + 1 : bi;
        final byOrder = aOrder.compareTo(bOrder);
        return byOrder != 0 ? byOrder : a.title.compareTo(b.title);
      });
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final effective = columns.clamp(1, 3);
        final gap = 10.0;
        final width =
            (constraints.maxWidth - gap * (effective - 1)) / effective;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            SizedBox(
              width: width,
              child: _ActionTile(
                'BOQ',
                Icons.receipt_long_outlined,
                'Per-house bill of quantities',
                onOpenBoq,
              ),
            ),
            ...schemas.map(
              (schema) => SizedBox(
                width: width,
                child: _ActionTile(
                  schema.title,
                  state.uiIcon('module.${schema.eventType}', schema.icon),
                  '${records.where((r) => r.eventType == schema.eventType).length} records • ${schema.phase}',
                  () => onOpenModule(schema.eventType),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HouseTile extends StatelessWidget {
  const _HouseTile({
    required this.house,
    required this.recordCount,
    required this.onTap,
  });
  final HouseRecord house;
  final int recordCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final progress = house.progress.clamp(0, 100);
    return RcExpressiveSurface(
      shape: RcSurfaceShape.offset,
      onTap: onTap,
      semanticLabel: 'Open ${house.code} Control of Works',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(child: Text(house.code)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  rcTitleCase(house.beneficiary),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
          const SizedBox(height: 10),
          Text('${rcTitleCase(house.parish)} • ${rcTitleCase(house.cluster)}'),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: progress / 100),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: Text('${rcTitleCase(house.stage)} • $progress%')),
              Text('$recordCount records'),
            ],
          ),
        ],
      ),
    );
  }
}

class _PulseTile extends StatelessWidget {
  const _PulseTile({
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
    final onColor =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black87;
    return RcExpressiveSurface(
      shape: RcSurfaceShape.offset,
      tone: color,
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: onColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: onColor,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: onColor,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile(this.title, this.icon, this.subtitle, this.onTap);
  final String title;
  final IconData icon;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        RcColors.expressivePalette[
            icon.codePoint % RcColors.expressivePalette.length];
    return RcExpressiveSurface(
      shape: RcSurfaceShape.offset,
      tone: Color.alphaBlend(
        color.withValues(alpha: .15),
        theme.colorScheme.surface,
      ),
      onTap: onTap,
      child: Row(
        children: [
          RcIconWell(
            icon: icon,
            color: color,
            size: 46,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

class _ControlData {
  const _ControlData({this.houses = const [], this.records = const []});
  final List<HouseRecord> houses;
  final List<ProductionRecord> records;
}

class _HouseWorkspaceData {
  const _HouseWorkspaceData({
    this.records = const [],
    this.boq,
    this.inventory,
    this.history = const [],
  });
  final List<ProductionRecord> records;
  final Map<String, dynamic>? boq;
  final Map<String, dynamic>? inventory;
  final List<Map<String, dynamic>> history;
}

class _InventoryData {
  const _InventoryData({this.boq, this.inventory});
  final Map<String, dynamic>? boq;
  final Map<String, dynamic>? inventory;
}
