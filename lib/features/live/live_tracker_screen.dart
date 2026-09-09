import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/design_tokens.dart';
import '../../core/rc_components.dart';
import '../../core/product_registry.dart';
import '../../models/app_models.dart';
import '../../state/app_state.dart';
import '../control/control_screen.dart';
import '../control/house_operations_control_screen.dart';

class LiveTrackerScreen extends StatefulWidget {
  const LiveTrackerScreen({
    super.key,
    required this.state,
    this.showMapFirst = false,
  });

  final AppState state;
  final bool showMapFirst;

  @override
  State<LiveTrackerScreen> createState() => _LiveTrackerScreenState();
}

class _LiveTrackerScreenState extends State<LiveTrackerScreen> {
  Future<_TrackerData>? future;
  String? parish;
  String query = '';
  String statusFilter = 'All';
  String clusterFilter = 'All';
  int section = 0;

  UserProfile get profile => widget.state.profile!;

  @override
  void initState() {
    super.initState();
    future = _load();
  }

  Future<_TrackerData> _load() async {
    final trackers = await widget.state.repository.liveTrackers(profile);

    String selected = parish ?? '';
    if (!profile.canViewAllParishes && profile.parish.isNotEmpty) {
      selected = profile.parish;
    } else if (selected.isEmpty && trackers.isNotEmpty) {
      selected = '${trackers.first['parish'] ?? ''}'.trim();
    }
    parish = selected.isEmpty ? null : selected;

    if (selected.isEmpty) {
      return _TrackerData(trackers: trackers);
    }

    final result = await Future.wait([
      widget.state.repository.liveTrackerSnapshot(profile, parish: selected),
      widget.state.repository.liveTrackerParishInventory(
        profile,
        parish: selected,
      ),
      widget.state.repository.liveTrackerHouseStatuses(
        profile,
        parish: selected,
      ),
      widget.state.repository.houses(profile),
    ]);

    final snapshot = result[0] as Map<String, dynamic>?;
    final inventory = result[1] as List<Map<String, dynamic>>;
    final statusRows = result[2] as List<Map<String, dynamic>>;
    final houses = result[3] as List<HouseRecord>;

    final item = Map<String, dynamic>.from(
      snapshot?['item'] as Map? ?? const {},
    );

    final rawClusters = (item['clusters'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    final statusByTracker = <String, Map<String, dynamic>>{};
    for (final row in statusRows) {
      final code = '${row['tracker_house_code'] ?? ''}'.trim().toUpperCase();
      if (code.isNotEmpty) statusByTracker[code] = row;
    }

    final houseByCode = <String, HouseRecord>{
      for (final house in houses) house.code.trim().toUpperCase(): house,
    };
    final accessibleCodes = houseByCode.keys.toSet();

    final clusters = <_TrackerCluster>[];
    for (final cluster in rawClusters) {
      final name = '${cluster['name'] ?? 'Cluster'}'.trim();
      final rawHouses = (cluster['houses'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      final rows = <Map<String, dynamic>>[];
      for (final raw in rawHouses) {
        final row = Map<String, dynamic>.from(raw);
        final trackerCode = '${row['houseId'] ?? ''}'.trim().toUpperCase();
        final statusRow = statusByTracker[trackerCode];

        final resolved = _resolveHouseCode(
          trackerCode,
          statusRow,
          accessibleCodes,
        );

        final rejected =
            row['rejected'] == true || statusRow?['rejected'] == true;
        final redFlag = statusRow?['red_house_code'] == true;

        if (profile.isCrew && resolved.isEmpty) continue;

        final appHouse = resolved.isEmpty ? null : houseByCode[resolved];
        rows.add({
          ...row,
          'clusterName': name,
          'trackerHouseCode': trackerCode,
          'resolvedHouseCode': resolved,
          'appHouseStage': appHouse?.stage ?? '',
          'appHouseProgress': appHouse?.progress ?? 0,
          'rejected': rejected,
          'redHouseCode': redFlag,
          'mapExcluded':
              statusRow?['excluded_from_map'] == true || rejected || redFlag,
          'statusComments': statusRow?['comments'] ?? row['comments'] ?? '',
        });
      }

      clusters.add(_TrackerCluster(name: name, houses: rows));
    }

    Map<String, dynamic>? source;
    for (final tracker in trackers) {
      if ('${tracker['parish'] ?? ''}'.trim() == selected) {
        source = tracker;
        break;
      }
    }

    return _TrackerData(
      trackers: trackers,
      parish: selected,
      source: source,
      clusters: clusters,
      inventory: inventory,
    );
  }

  String _resolveHouseCode(
    String trackerCode,
    Map<String, dynamic>? statusRow,
    Set<String> accessibleCodes,
  ) {
    final backend = '${statusRow?['resolved_house_code'] ?? ''}'
        .trim()
        .toUpperCase();
    if (backend.isNotEmpty && accessibleCodes.contains(backend)) {
      return backend;
    }

    if (accessibleCodes.contains(trackerCode)) return trackerCode;

    final digits = RegExp(r'\d+').firstMatch(trackerCode)?.group(0);
    if (digits == null) return backend;

    final target = int.tryParse(digits);
    if (target == null) return backend;

    final matches = accessibleCodes.where((candidate) {
      final part = RegExp(r'\d+').firstMatch(candidate)?.group(0);
      return part != null && int.tryParse(part) == target;
    }).toList();

    if (matches.length == 1) return matches.first;
    return '';
  }

  Future<void> _refresh() async {
    setState(() => future = _load());
    await future;
  }

  void _selectParish(String value) {
    setState(() {
      parish = value;
      query = '';
      clusterFilter = 'All';
      statusFilter = 'All';
      future = _load();
    });
  }

  Future<void> _openHouseModules(String houseCode) async {
    final houses = await widget.state.repository.houses(profile);
    final house = houses
        .where(
          (candidate) =>
              candidate.code.trim().toUpperCase() ==
              houseCode.trim().toUpperCase(),
        )
        .firstOrNull;

    if (!mounted) return;
    if (house == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This tracker row is not linked to an accessible house record.',
          ),
        ),
      );
      return;
    }

    final schemas = RcProductRegistry.visibleSchemas(
      profile,
    ).where((schema) => schema.eventType != 'crewAttendance').toList();

    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: .82,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
          children: [
            RcPageHeading(
              eyebrow: '${house.parish} • ${house.cluster}',
              title: '${house.code} Quick Modules',
              subtitle:
                  'Open the selected house directly in a Control of Works module.',
            ),
            const SizedBox(height: 10),
            RcResponsiveGrid(
              minTileWidth: 165,
              childAspectRatio: 1.48,
              children: schemas.map((schema) {
                final color =
                    RcColors.expressivePalette[schema.icon.codePoint %
                        RcColors.expressivePalette.length];
                return RcExpressiveSurface(
                  shape: RcSurfaceShape.offset,
                  tone: Color.alphaBlend(
                    color.withValues(alpha: .16),
                    Theme.of(sheetContext).colorScheme.surface,
                  ),
                  onTap: () => Navigator.pop(sheetContext, schema.eventType),
                  child: Row(
                    children: [
                      RcIconWell(
                        icon: widget.state.uiIcon(
                          'module.${schema.eventType}',
                          schema.icon,
                        ),
                        color: color,
                        size: 44,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          schema.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(sheetContext).textTheme.titleMedium,
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );

    if (!mounted || selected == null) return;
    final schema = RcProductRegistry.resolveSchema(selected);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductionModuleScreen(
          state: widget.state,
          schema: schema,
          initialHouse: house,
        ),
      ),
    );
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Tracker'),
        actions: [
          IconButton(
            tooltip: 'Refresh synced tracker data',
            onPressed: _refresh,
            icon: const Icon(Icons.sync_rounded),
          ),
        ],
      ),
      body: FutureBuilder<_TrackerData>(
        future: future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting &&
              snap.data == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.hasError) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                children: [
                  RcExpressiveSurface(
                    tone: theme.colorScheme.errorContainer,
                    child: const Text(
                      'Live Tracker data could not be loaded. '
                      'The workbook source was not changed. Pull to retry.',
                    ),
                  ),
                ],
              ),
            );
          }

          final data = snap.data ?? const _TrackerData();

          if (data.trackers.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                children: const [
                  RcPageHeading(
                    eyebrow: 'Excel → RC SOW',
                    title: 'No Live Tracker source configured',
                    subtitle:
                        'An Admin must configure and sync the parish Live Tracker workbook in Operations Admin → Tracker.',
                  ),
                ],
              ),
            );
          }

          final allRows = data.clusters.expand((c) => c.houses).toList();
          final finished = allRows
              .where((row) => row['finished'] == true)
              .length;
          final started = allRows.where((row) => row['started'] == true).length;
          final rejected = allRows
              .where((row) => row['rejected'] == true)
              .length;
          final verified = allRows
              .where((row) => row['houseVisitedVerified'] == true)
              .length;
          final boqDone = allRows.where((row) => row['boqDone'] == true).length;
          final sowDone = allRows.where((row) => row['sowDone'] == true).length;

          final sourceStatus =
              '${data.source?['last_sync_status'] ?? 'Never synced'}';
          final lastSync = DateTime.tryParse(
            '${data.source?['last_synced_at'] ?? ''}',
          );

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
              children: [
                RcPageHeading(
                  eyebrow: 'Excel data rendered in RC SOW',
                  title: '${data.parish ?? 'Parish'} Live Tracker',
                  subtitle:
                      'Production sheets and Storage are shown natively in the app. '
                      'Workbook configuration remains in Admin.',
                ),
                if (profile.canViewAllParishes) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: data.parish,
                    decoration: const InputDecoration(
                      labelText: 'Parish tracker',
                      prefixIcon: Icon(Icons.account_tree_outlined),
                    ),
                    items: data.trackers
                        .map(
                          (tracker) => DropdownMenuItem(
                            value: '${tracker['parish'] ?? ''}',
                            child: Text('${tracker['parish'] ?? ''}'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null && value.isNotEmpty) {
                        _selectParish(value);
                      }
                    },
                  ),
                ],
                const SizedBox(height: 12),
                RcExpressiveSurface(
                  shape: RcSurfaceShape.offset,
                  tone: theme.colorScheme.surfaceContainerLow,
                  child: Row(
                    children: [
                      Icon(
                        sourceStatus.toLowerCase() == 'success'
                            ? Icons.cloud_done_outlined
                            : Icons.sync_problem_outlined,
                        color: sourceStatus.toLowerCase() == 'success'
                            ? RcColors.success
                            : RcColors.warning,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Synced Live Tracker Data',
                              style: theme.textTheme.titleMedium,
                            ),
                            Text(
                              lastSync == null
                                  ? sourceStatus
                                  : '$sourceStatus • ${lastSync.toLocal()}',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      RcStatusPill(
                        label: sourceStatus.toUpperCase(),
                        color: sourceStatus.toLowerCase() == 'success'
                            ? RcColors.success
                            : RcColors.warning,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(
                      value: 0,
                      icon: Icon(Icons.dashboard_outlined),
                      label: Text('Overview'),
                    ),
                    ButtonSegment(
                      value: 1,
                      icon: Icon(Icons.home_work_outlined),
                      label: Text('Houses'),
                    ),
                    ButtonSegment(
                      value: 2,
                      icon: Icon(Icons.inventory_2_outlined),
                      label: Text('Storage'),
                    ),
                  ],
                  selected: {section},
                  showSelectedIcon: false,
                  onSelectionChanged: (values) =>
                      setState(() => section = values.first),
                ),
                const SizedBox(height: 14),
                if (section == 0)
                  _overview(
                    data,
                    total: allRows.length,
                    finished: finished,
                    started: started,
                    rejected: rejected,
                    verified: verified,
                    boqDone: boqDone,
                    sowDone: sowDone,
                  )
                else if (section == 1)
                  _houses(data)
                else
                  _storage(data),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openOverviewFilter(String filter) {
    setState(() {
      query = '';
      clusterFilter = 'All';
      statusFilter = filter;
      section = 1;
    });
  }

  Widget _overview(
    _TrackerData data, {
    required int total,
    required int finished,
    required int started,
    required int rejected,
    required int verified,
    required int boqDone,
    required int sowDone,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RcResponsiveGrid(
          minTileWidth: 145,
          childAspectRatio: 1.7,
          children: [
            _Metric(
              'Houses',
              '$total',
              Icons.home_work_outlined,
              theme.colorScheme.primary,
              onTap: () => _openOverviewFilter('All'),
            ),
            _Metric(
              'Started',
              '$started',
              Icons.construction_outlined,
              RcColors.blue,
              onTap: () => _openOverviewFilter('Started'),
            ),
            _Metric(
              'Finished',
              '$finished',
              Icons.verified_outlined,
              RcColors.success,
              onTap: () => _openOverviewFilter('Finished'),
            ),
            _Metric(
              'Verified',
              '$verified',
              Icons.fact_check_outlined,
              RcColors.purple,
              onTap: () => _openOverviewFilter('Verified'),
            ),
            _Metric(
              'BOQ Done',
              '$boqDone',
              Icons.receipt_long_outlined,
              RcColors.blue,
              onTap: () => _openOverviewFilter('BOQ Done'),
            ),
            _Metric(
              'SOW Done',
              '$sowDone',
              Icons.description_outlined,
              RcColors.success,
              onTap: () => _openOverviewFilter('SOW Done'),
            ),
            _Metric(
              'Rejected',
              '$rejected',
              Icons.block_outlined,
              RcColors.danger,
              onTap: () => _openOverviewFilter('Rejected'),
            ),
            _Metric(
              'Storage',
              '${data.inventory.length}',
              Icons.inventory_2_outlined,
              RcColors.warning,
              onTap: () => setState(() => section = 2),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text('Clusters', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        ...data.clusters.map((cluster) {
          final rows = cluster.houses;
          final done = rows.where((row) => row['finished'] == true).length;
          final rejected = rows.where((row) => row['rejected'] == true).length;
          final ready = rows.where(_isReady).length;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: RcExpressiveSurface(
              shape: RcSurfaceShape.offset,
              onTap: () {
                setState(() {
                  clusterFilter = cluster.name;
                  statusFilter = 'All';
                  section = 1;
                });
              },
              child: Row(
                children: [
                  CircleAvatar(child: Text('${rows.length}')),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cluster.name, style: theme.textTheme.titleMedium),
                        const SizedBox(height: 5),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            RcStatusPill(
                              label: '$done FINISHED',
                              color: RcColors.success,
                            ),
                            RcStatusPill(
                              label: '$ready READY',
                              color: RcColors.blue,
                            ),
                            if (rejected > 0)
                              RcStatusPill(
                                label: '$rejected REJECTED',
                                color: RcColors.danger,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        RcExpressiveSurface(
          tone: theme.colorScheme.surfaceContainerLow,
          child: const Text(
            'Live Tracker is a synchronized operational view. '
            'Excel source URL, provider and sync controls remain in Operations Admin → Tracker.',
          ),
        ),
      ],
    );
  }

  Widget _houses(_TrackerData data) {
    final theme = Theme.of(context);
    final allRows = data.clusters.expand((c) => c.houses).toList();
    final clusterNames = data.clusters.map((c) => c.name).toList();

    final filtered = allRows.where((row) {
      final code = '${row['trackerHouseCode'] ?? row['houseId'] ?? ''}'
          .toLowerCase();
      final resolved = '${row['resolvedHouseCode'] ?? ''}'.toLowerCase();
      final comments = '${row['statusComments'] ?? row['comments'] ?? ''}'
          .toLowerCase();
      final q = query.trim().toLowerCase();
      final queryOk =
          q.isEmpty ||
          code.contains(q) ||
          resolved.contains(q) ||
          comments.contains(q);

      final clusterOk =
          clusterFilter == 'All' ||
          '${row['clusterName'] ?? ''}' == clusterFilter;

      final statusOk = switch (statusFilter) {
        'Finished' => row['finished'] == true,
        'Started' =>
          row['started'] == true && row['appHouseStage'] != 'Revoked',
        'Ready' => _isReady(row),
        'Verified' => row['houseVisitedVerified'] == true,
        'BOQ Done' => row['boqDone'] == true,
        'SOW Done' => row['sowDone'] == true,
        'Revoked' => row['appHouseStage'] == 'Revoked',
        'Rejected' => row['rejected'] == true,
        'Attention' =>
          row['rejected'] != true &&
              (row['sowDone'] != true ||
                  row['boqDone'] != true ||
                  row['houseVisitedVerified'] != true),
        _ => true,
      };

      return queryOk && clusterOk && statusOk;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          decoration: const InputDecoration(
            labelText: 'Search house or comment',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) => setState(() => query = value),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children:
                [
                  'All',
                  'Started',
                  'Ready',
                  'Finished',
                  'Verified',
                  'BOQ Done',
                  'SOW Done',
                  'Revoked',
                  'Rejected',
                  'Attention',
                ]
                    .map(
                      (value) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          selected: statusFilter == value,
                          label: Text(value),
                          onSelected: (_) =>
                              setState(() => statusFilter = value),
                        ),
                      ),
                    )
                    .toList(),
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['All', ...clusterNames]
                .map(
                  (value) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      selected: clusterFilter == value,
                      label: Text(value),
                      onSelected: (_) => setState(() => clusterFilter = value),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                '${filtered.length} tracker houses',
                style: theme.textTheme.titleMedium,
              ),
            ),
            if (clusterFilter != 'All')
              Text(clusterFilter, style: theme.textTheme.labelLarge),
          ],
        ),
        const SizedBox(height: 8),
        if (filtered.isEmpty)
          const RcExpressiveSurface(
            child: Text('No houses match the current filters.'),
          ),
        ...filtered.map(_houseCard),
      ],
    );
  }

  bool get _canStartHouse =>
      profile.isAdmin || profile.isSiteSupervisor || profile.canEditProduction;

  Future<void> _startHouse(Map<String, dynamic> row) async {
    if (!_canStartHouse) return;
    final trackerCode =
        '${row['trackerHouseCode'] ?? row['houseId'] ?? ''}'
            .trim()
            .toUpperCase();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Start $trackerCode in RC SOW?'),
        content: const Text(
          'This creates the RC SOW house workspace from Tracker/Shelter data. '
          'It does not edit the source Excel workbook.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Start House'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final code = await widget.state.repository.startHouseFromTracker(
        profile: profile,
        trackerHouseCode: trackerCode,
        parish: parish ?? profile.parish,
        cluster: '${row['clusterName'] ?? ''}',
      );
      await _refresh();
      if (mounted) await _openHouse(code);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('House could not be started: $error')),
      );
    }
  }

  Future<void> _adminHouseAction(
    Map<String, dynamic> row,
    String action,
  ) async {
    if (!profile.isAdmin) return;
    final code = '${row['resolvedHouseCode'] ?? ''}'.trim().toUpperCase();
    if (code.isEmpty) return;

    try {
      if (action == 'delete') {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text('Delete $code start record?'),
            content: const Text(
              'This removes only the RC SOW house activation/start record. '
              'Existing SOW, BOQ, photos and Control records are preserved.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Delete Start Record'),
              ),
            ],
          ),
        );
        if (confirmed != true || !mounted) return;
        await widget.state.repository.deleteHouseStartRecord(
          profile: profile,
          houseCode: code,
        );
      } else {
        await widget.state.repository.setHouseLifecycle(
          profile: profile,
          houseCode: code,
          action: action,
        );
      }
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('House lifecycle action failed: $error')),
      );
    }
  }

  Widget _houseCard(Map<String, dynamic> row) {
    final theme = Theme.of(context);
    final trackerCode = '${row['trackerHouseCode'] ?? row['houseId'] ?? ''}'
        .trim()
        .toUpperCase();
    final resolved = '${row['resolvedHouseCode'] ?? ''}'.trim().toUpperCase();
    final rejected = row['rejected'] == true;
    final redFlag = row['redHouseCode'] == true;
    final revoked = row['appHouseStage'] == 'Revoked';
    final state = _houseState(row);
    final stateColor = switch (state) {
      'Rejected' => RcColors.danger,
      'Revoked' => RcColors.danger,
      'Finished' => RcColors.success,
      'In Progress' => RcColors.blue,
      'Ready' => RcColors.purple,
      _ => RcColors.warning,
    };

    final date = '${row['projectEstimatedStartDate'] ?? ''}'.trim();
    final comments = '${row['statusComments'] ?? row['comments'] ?? ''}'.trim();
    final link = '${row['link'] ?? ''}'.trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: RcExpressiveSurface(
        shape: RcSurfaceShape.offset,
        tone: rejected || redFlag
            ? theme.colorScheme.errorContainer.withValues(alpha: .34)
            : null,
        onTap: resolved.isEmpty || (revoked && !profile.isAdmin)
            ? null
            : () => _openHouse(resolved),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: stateColor.withValues(alpha: .14),
                  child: Icon(Icons.home_work_rounded, color: stateColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resolved.isNotEmpty && resolved != trackerCode
                            ? '$trackerCode → $resolved'
                            : trackerCode,
                        style: theme.textTheme.titleLarge,
                      ),
                      Text(
                        '${row['clusterName'] ?? ''}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                RcStatusPill(label: state.toUpperCase(), color: stateColor),
                if (profile.isAdmin && resolved.isNotEmpty)
                  PopupMenuButton<String>(
                    tooltip: 'Admin house lifecycle',
                    onSelected: (action) => _adminHouseAction(row, action),
                    itemBuilder: (_) => [
                      if (revoked)
                        const PopupMenuItem(
                          value: 'resume',
                          child: Text('Resume house'),
                        )
                      else
                        const PopupMenuItem(
                          value: 'revoke',
                          child: Text('Revoke house start'),
                        ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete start record'),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 9),
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children: [
                if (row['finished'] == true)
                  const RcStatusPill(
                    label: 'FINISHED',
                    color: RcColors.success,
                  ),
                if (row['started'] == true)
                  const RcStatusPill(label: 'STARTED', color: RcColors.blue),
                if (row['materialsOnSiteNotStarted'] == true)
                  const RcStatusPill(
                    label: 'MATERIALS ON SITE',
                    color: RcColors.warning,
                  ),
                if (row['boqSent'] == true)
                  const RcStatusPill(label: 'BOQ SENT', color: RcColors.blue),
                if (row['boqDone'] == true)
                  const RcStatusPill(
                    label: 'BOQ DONE',
                    color: RcColors.success,
                  ),
                if (row['sowDone'] == true)
                  const RcStatusPill(
                    label: 'SOW DONE',
                    color: RcColors.success,
                  ),
                if (row['contractSigned'] == true)
                  const RcStatusPill(
                    label: 'CONTRACT SIGNED',
                    color: RcColors.purple,
                  ),
                if (row['houseVisitedVerified'] == true)
                  const RcStatusPill(
                    label: 'SITE VERIFIED',
                    color: RcColors.success,
                  ),
                if (rejected)
                  const RcStatusPill(label: 'REJECTED', color: RcColors.danger),
                if (redFlag)
                  const RcStatusPill(label: 'RED FLAG', color: RcColors.danger),
              ],
            ),
            if (date.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.event_outlined, size: 18),
                  const SizedBox(width: 6),
                  Expanded(child: Text('Estimated start: $date')),
                ],
              ),
            ],
            if (comments.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                comments,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: rejected || redFlag
                      ? FontWeight.w700
                      : FontWeight.normal,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: resolved.isEmpty
                        ? ((rejected || redFlag || !_canStartHouse)
                              ? null
                              : () => _startHouse(row))
                        : ((revoked && !profile.isAdmin)
                              ? null
                              : () => _openHouse(resolved)),
                    icon: Icon(
                      resolved.isEmpty
                          ? Icons.play_arrow_rounded
                          : Icons.home_repair_service_outlined,
                    ),
                    label: Text(
                      resolved.isEmpty
                          ? (rejected || redFlag ? 'Rejected' : 'Start House')
                          : (revoked ? 'View Revoked' : 'House'),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: resolved.isEmpty || revoked
                        ? null
                        : () => _openHouseModules(resolved),
                    icon: const Icon(Icons.dashboard_customize_outlined),
                    label: const Text('Modules'),
                  ),
                ),
                if (link.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: 'Open linked tracker folder/document',
                    onPressed: () => _openUrl(link),
                    icon: const Icon(Icons.link_outlined),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _storage(_TrackerData data) {
    final theme = Theme.of(context);

    if (data.inventory.isEmpty) {
      return const RcExpressiveSurface(
        child: Text(
          'No Storage worksheet data has been synchronized for this parish yet.',
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Parish Storage', style: theme.textTheme.titleLarge),
            ),
            Text(
              '${data.inventory.length} material lines',
              style: theme.textTheme.labelLarge,
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          'IN, OUT and balance are rendered from the workbook Storage sheet.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 10),
        ...data.inventory.map((row) {
          final payload = Map<String, dynamic>.from(
            row['source_payload'] as Map? ?? const {},
          );
          final size = '${payload['size'] ?? ''}'.trim();
          final length = '${payload['length'] ?? ''}'.trim();
          final unit = '${row['unit'] ?? ''}'.trim();
          final transactions = (payload['transactions'] as List? ?? const [])
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: RcExpressiveSurface(
              shape: RcSurfaceShape.offset,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        child: Icon(Icons.inventory_2_outlined),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${row['description'] ?? 'Material'}',
                              style: theme.textTheme.titleMedium,
                            ),
                            Text(
                              [
                                if (size.isNotEmpty) size,
                                if (length.isNotEmpty) length,
                                if (unit.isNotEmpty) unit,
                              ].join(' • '),
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${_qty(row['balance'])}${unit.isEmpty ? '' : ' $unit'}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      RcStatusPill(
                        label: 'IN ${_qty(row['received'])}',
                        color: RcColors.success,
                      ),
                      RcStatusPill(
                        label: 'OUT ${_qty(row['issued'])}',
                        color: RcColors.warning,
                      ),
                      RcStatusPill(
                        label: '${transactions.length} MOVEMENTS',
                        color: RcColors.blue,
                      ),
                    ],
                  ),
                  if (transactions.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: EdgeInsets.zero,
                      title: const Text('Movement history'),
                      children: transactions.map((tx) {
                        final direction = '${tx['direction'] ?? ''}'.trim();
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            direction.toUpperCase() == 'IN'
                                ? Icons.south_west_rounded
                                : Icons.north_east_rounded,
                          ),
                          title: Text('$direction ${_qty(tx['quantity'])}'),
                          subtitle: Text(
                            [
                              if ('${tx['date'] ?? ''}'.trim().isNotEmpty)
                                '${tx['date']}',
                              if ('${tx['fromTo'] ?? ''}'.trim().isNotEmpty)
                                '${tx['fromTo']}',
                            ].join(' • '),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  bool _isReady(Map<String, dynamic> row) =>
      row['rejected'] != true &&
      row['houseVisitedVerified'] == true &&
      row['sowDone'] == true &&
      row['boqDone'] == true;

  String _houseState(Map<String, dynamic> row) {
    if (row['rejected'] == true) return 'Rejected';
    if (row['appHouseStage'] == 'Revoked') return 'Revoked';
    if (row['finished'] == true) return 'Finished';
    if (row['started'] == true) return 'In Progress';
    if (_isReady(row)) return 'Ready';
    return 'Pending';
  }

  Future<void> _openHouse(String code) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HouseControlWorkspaceByCodeScreen(
          state: widget.state,
          houseCode: code,
        ),
      ),
    );
    await _refresh();
  }

  Future<void> _openUrl(String raw) async {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null || !uri.hasScheme) return;
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The linked document could not be opened.'),
        ),
      );
    }
  }

  String _qty(Object? raw) {
    final value = raw is num
        ? raw.toDouble()
        : double.tryParse('${raw ?? ''}') ?? 0;
    return value == value.roundToDouble()
        ? '${value.toInt()}'
        : value.toStringAsFixed(2);
  }
}

class _Metric extends StatelessWidget {
  const _Metric(
    this.label,
    this.value,
    this.icon,
    this.color, {
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return RcExpressiveSurface(
      shape: RcSurfaceShape.offset,
      tone: color.withValues(alpha: .12),
      onTap: onTap,
      semanticLabel: '$label: $value. Open matching houses.',
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 9),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackerCluster {
  const _TrackerCluster({required this.name, this.houses = const []});

  final String name;
  final List<Map<String, dynamic>> houses;
}

class _TrackerData {
  const _TrackerData({
    this.trackers = const [],
    this.parish,
    this.source,
    this.clusters = const [],
    this.inventory = const [],
  });

  final List<Map<String, dynamic>> trackers;
  final String? parish;
  final Map<String, dynamic>? source;
  final List<_TrackerCluster> clusters;
  final List<Map<String, dynamic>> inventory;
}
