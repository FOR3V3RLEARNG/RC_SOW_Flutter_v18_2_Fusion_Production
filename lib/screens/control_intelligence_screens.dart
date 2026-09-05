import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/construction_schedule_intelligence.dart';
import '../core/models.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../core/widgets.dart';

class ProximityConstructionScheduleScreen extends StatefulWidget {
  const ProximityConstructionScheduleScreen({super.key});

  @override
  State<ProximityConstructionScheduleScreen> createState() =>
      _ProximityConstructionScheduleScreenState();
}

class _ProximityConstructionScheduleScreenState
    extends State<ProximityConstructionScheduleScreen> {
  bool _initialized = false;
  String _parish = '';
  String _cluster = 'All clusters';
  String? _startCode;
  List<String> _orderedCodes = <String>[];
  String _orderingMethod = 'Custom manual order';
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final state = AppScope.of(context);
    _parish = state.selectedParish;
    _seedOrder(state);
  }

  bool _isGlobalRole(String role) {
    final normalized =
        role.trim().toLowerCase().replaceAll('_', ' ').replaceAll('-', ' ');
    return normalized == 'admin' ||
        normalized == 'administrator' ||
        normalized == 'regional supervisor' ||
        normalized == 'regional site supervisor' ||
        normalized == 'construction specialist';
  }

  List<String> _availableParishes(AppState state) {
    if (!_isGlobalRole(state.role)) return <String>[state.selectedParish];
    final result = state.houses.map((house) => house.parish).toSet().toList()
      ..sort();
    return result.isEmpty ? <String>[state.selectedParish] : result;
  }

  List<String> _availableClusters(AppState state) {
    final result = state.houses
        .where((house) => house.parish == _parish)
        .map((house) => house.cluster)
        .where((cluster) => cluster.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return <String>['All clusters', ...result];
  }

  List<HouseRecord> _scopeHouses(AppState state) {
    return state.houses.where((house) {
      if (house.parish != _parish) return false;
      if (_cluster != 'All clusters' && house.cluster != _cluster) {
        return false;
      }
      return house.status != RecordStatus.paid;
    }).toList();
  }

  void _seedOrder(AppState state) {
    final houses = _scopeHouses(state);
    houses.sort((a, b) {
      final aSaved = int.tryParse(
            state.formDrafts['${a.code}:Construction Schedule']?['sequence'] ??
                '',
          ) ??
          999999;
      final bSaved = int.tryParse(
            state.formDrafts['${b.code}:Construction Schedule']?['sequence'] ??
                '',
          ) ??
          999999;
      if (aSaved != bSaved) return aSaved.compareTo(bSaved);
      final clusterCompare = a.cluster.compareTo(b.cluster);
      if (clusterCompare != 0) return clusterCompare;
      return a.code.compareTo(b.code);
    });

    _orderedCodes = houses.map((house) => house.code).toList();
    final validStart = _orderedCodes.where((code) {
      final house = state.houseByCode(code);
      return parseBeneficiaryGps(house.gps) != null;
    }).toList();
    _startCode = validStart.isEmpty ? null : validStart.first;
    _orderingMethod = 'Custom manual order';
  }

  void _changeScope(
    AppState state, {
    String? parish,
    String? cluster,
  }) {
    setState(() {
      if (parish != null) {
        _parish = parish;
        _cluster = 'All clusters';
      }
      if (cluster != null) _cluster = cluster;
      _seedOrder(state);
    });
  }

  void _suggest(AppState state) {
    final houses = _scopeHouses(state);
    final suggested = suggestProximityOrder(
      houses
          .map((house) => ScheduleLocation(code: house.code, gps: house.gps))
          .toList(),
      startCode: _startCode,
    );
    setState(() {
      _orderedCodes = suggested;
      _orderingMethod = 'AI-assisted GPS proximity';
    });
  }

  void _move(int index, int delta) {
    final target = index + delta;
    if (target < 0 || target >= _orderedCodes.length) return;
    setState(() {
      final item = _orderedCodes.removeAt(index);
      _orderedCodes.insert(target, item);
      _orderingMethod = 'Custom manual order';
    });
  }

  HouseRecord? _houseForCode(AppState state, String code) {
    for (final house in state.houses) {
      if (house.code == code) return house;
    }
    return null;
  }

  double? _legDistance(int index, List<HouseRecord> ordered) {
    if (index <= 0 || index >= ordered.length) return null;
    return distanceBetweenGps(ordered[index - 1].gps, ordered[index].gps);
  }

  Future<void> _saveOrder(AppState state) async {
    final ordered = _orderedCodes
        .map((code) => _houseForCode(state, code))
        .whereType<HouseRecord>()
        .toList();

    if (ordered.isEmpty) return;

    setState(() => _saving = true);
    var changed = 0;

    for (var index = 0; index < ordered.length; index++) {
      final house = ordered[index];
      final distance = _legDistance(index, ordered);
      final nextValues = <String, String>{
        'parish': house.parish,
        'cluster': house.cluster,
        'sequence': '${index + 1}',
        'orderingMethod': _orderingMethod,
        'previousHouse': index == 0 ? '' : ordered[index - 1].code,
        'distanceFromPreviousKm':
            distance == null ? '' : distance.toStringAsFixed(2),
        'beneficiaryGps': house.gps,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      final current = state.formDrafts['${house.code}:Construction Schedule'];
      final same = current != null &&
          current['sequence'] == nextValues['sequence'] &&
          current['orderingMethod'] == nextValues['orderingMethod'] &&
          current['previousHouse'] == nextValues['previousHouse'];

      if (same) continue;

      changed += 1;
      state.recordOperationalUpdate(
        recordType: 'Construction Schedule',
        houseCode: house.code,
        status: 'scheduled',
        values: nextValues,
        activityTitle: 'Construction schedule updated',
        activityDetail:
            'Build position ${index + 1}/${ordered.length} • $_orderingMethod'
            '${distance == null ? '' : ' • ${distance.toStringAsFixed(2)} km from previous house'}.',
        icon: Icons.route_outlined,
      );
    }

    if (!mounted) return;
    setState(() => _saving = false);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            changed == 0
                ? 'No construction schedule changes to save.'
                : '$changed house schedule update(s) saved and added to the activity/notification trail.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final parishOptions = _availableParishes(state);
    if (!parishOptions.contains(_parish)) _parish = parishOptions.first;

    final clusterOptions = _availableClusters(state);
    if (!clusterOptions.contains(_cluster)) _cluster = 'All clusters';

    final housesByCode = <String, HouseRecord>{
      for (final house in _scopeHouses(state)) house.code: house,
    };
    final ordered = <HouseRecord>[];
    for (final code in _orderedCodes) {
      final house = housesByCode.remove(code);
      if (house != null) ordered.add(house);
    }
    ordered.addAll(housesByCode.values);

    final gpsReady =
        ordered.where((house) => parseBeneficiaryGps(house.gps) != null).length;
    final routeKm = _totalRouteKm(ordered);
    final validStartCodes = ordered
        .where((house) => parseBeneficiaryGps(house.gps) != null)
        .map((house) => house.code)
        .toSet();
    if (_startCode != null && !validStartCodes.contains(_startCode)) {
      _startCode = validStartCodes.isEmpty ? null : validStartCodes.first;
    }

    return Scaffold(
      appBar: RcAppBar(
        title: const Text('Construction Schedule'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Live team briefing',
            onPressed: () =>
                Navigator.pushNamed(context, RcRoutes.liveBriefing),
            icon: const Icon(Icons.video_camera_front_outlined),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          const RcSyncBanner(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
              children: <Widget>[
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        RcPageHeading(
                          eyebrow: 'Control of Works / Route intelligence',
                          title: 'Build houses in a practical proximity order',
                          description:
                              'Sequence houses by parish and cluster. AI-assisted GPS proximity can suggest a route from beneficiary coordinates, while supervisors can always override the order manually.',
                          action: RcStatusChip(
                            label: _orderingMethod == 'AI-assisted GPS proximity'
                                ? 'AI SUGGESTED'
                                : 'CUSTOM ORDER',
                            icon: _orderingMethod == 'AI-assisted GPS proximity'
                                ? Icons.auto_awesome_outlined
                                : Icons.tune_outlined,
                            tone: RcStatusTone.info,
                          ),
                        ),
                        const SizedBox(height: 18),
                        RcResponsiveGrid(
                          minItemWidth: 190,
                          childAspectRatio: 1.35,
                          children: <Widget>[
                            RcMetricTile(
                              label: 'Scheduled houses',
                              value: '${ordered.length}',
                              icon: Icons.home_work_outlined,
                              color: RcColors.brand,
                            ),
                            RcMetricTile(
                              label: 'GPS ready',
                              value: '$gpsReady/${ordered.length}',
                              icon: Icons.location_on_outlined,
                              color: gpsReady == ordered.length
                                  ? RcColors.success
                                  : RcColors.warning,
                            ),
                            RcMetricTile(
                              label: 'Route distance',
                              value: routeKm == null
                                  ? 'Needs GPS'
                                  : '${routeKm.toStringAsFixed(1)} km',
                              icon: Icons.route_outlined,
                              color: RcColors.info,
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Schedule scope & AI suggestion',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 14),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final wide = constraints.maxWidth >= 720;
                                    final parish =
                                        DropdownButtonFormField<String>(
                                      value: _parish,
                                      isExpanded: true,
                                      decoration: const InputDecoration(
                                        labelText: 'Parish',
                                      ),
                                      items: parishOptions
                                          .map(
                                            (value) =>
                                                DropdownMenuItem<String>(
                                              value: value,
                                              child: Text(value),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (value) {
                                        if (value != null) {
                                          _changeScope(state, parish: value);
                                        }
                                      },
                                    );
                                    final cluster =
                                        DropdownButtonFormField<String>(
                                      value: _cluster,
                                      isExpanded: true,
                                      decoration: const InputDecoration(
                                        labelText: 'Cluster',
                                      ),
                                      items: clusterOptions
                                          .map(
                                            (value) =>
                                                DropdownMenuItem<String>(
                                              value: value,
                                              child: Text(value),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (value) {
                                        if (value != null) {
                                          _changeScope(state, cluster: value);
                                        }
                                      },
                                    );
                                    final start =
                                        DropdownButtonFormField<String>(
                                      value: _startCode,
                                      isExpanded: true,
                                      decoration: const InputDecoration(
                                        labelText: 'AI route starting house',
                                        helperText:
                                            'Only houses with valid GPS are shown.',
                                      ),
                                      items: ordered
                                          .where(
                                            (house) =>
                                                parseBeneficiaryGps(house.gps) !=
                                                null,
                                          )
                                          .map(
                                            (house) =>
                                                DropdownMenuItem<String>(
                                              value: house.code,
                                              child: Text(
                                                '${house.code} • ${house.community}',
                                              ),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (value) =>
                                          setState(() => _startCode = value),
                                    );

                                    if (!wide) {
                                      return Column(
                                        children: <Widget>[
                                          parish,
                                          const SizedBox(height: 12),
                                          cluster,
                                          const SizedBox(height: 12),
                                          start,
                                        ],
                                      );
                                    }

                                    return Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Expanded(child: parish),
                                        const SizedBox(width: 12),
                                        Expanded(child: cluster),
                                        const SizedBox(width: 12),
                                        Expanded(child: start),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 14),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: <Widget>[
                                    FilledButton.icon(
                                      onPressed: gpsReady >= 2
                                          ? () => _suggest(state)
                                          : null,
                                      icon: const Icon(
                                        Icons.auto_awesome_outlined,
                                      ),
                                      label: const Text(
                                        'AI SUGGEST PROXIMITY',
                                      ),
                                    ),
                                    OutlinedButton.icon(
                                      onPressed: () =>
                                          setState(() => _seedOrder(state)),
                                      icon:
                                          const Icon(Icons.restore_outlined),
                                      label:
                                          const Text('RESTORE SAVED ORDER'),
                                    ),
                                    FilledButton.tonalIcon(
                                      onPressed: _saving
                                          ? null
                                          : () => _saveOrder(state),
                                      icon: _saving
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Icon(Icons.save_outlined),
                                      label:
                                          const Text('SAVE BUILD ORDER'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'AI suggestion uses beneficiary GPS to minimize successive travel distance. It is a planning recommendation, not a road-routing guarantee; field staff can move any house up or down before saving.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        RcSectionHeader(
                          title:
                              '${ordered.length} house${ordered.length == 1 ? '' : 's'} in build order',
                          subtitle:
                              'Use the arrows for custom priority, logistics, beneficiary readiness or crew constraints.',
                        ),
                        const SizedBox(height: 10),
                        if (ordered.isEmpty)
                          const RcEmptyState(
                            icon: Icons.event_busy_outlined,
                            title: 'No houses in this schedule scope',
                            message:
                                'Choose another parish or cluster to create a build sequence.',
                          )
                        else
                          for (var index = 0;
                              index < ordered.length;
                              index++) ...<Widget>[
                            _BuildOrderCard(
                              index: index,
                              total: ordered.length,
                              house: ordered[index],
                              distanceKm: _legDistance(index, ordered),
                              onMoveUp:
                                  index == 0 ? null : () => _move(index, -1),
                              onMoveDown: index == ordered.length - 1
                                  ? null
                                  : () => _move(index, 1),
                              onOpen: () {
                                state.selectHouse(ordered[index].code);
                                Navigator.pushNamed(
                                  context,
                                  RcRoutes.houseCommand,
                                );
                              },
                            ),
                            const SizedBox(height: 10),
                          ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double? _totalRouteKm(List<HouseRecord> ordered) {
    if (ordered.length < 2) return 0;
    var total = 0.0;
    var measuredLegs = 0;

    for (var index = 1; index < ordered.length; index++) {
      final distance =
          distanceBetweenGps(ordered[index - 1].gps, ordered[index].gps);
      if (distance != null) {
        total += distance;
        measuredLegs += 1;
      }
    }

    return measuredLegs == 0 ? null : total;
  }
}

class _BuildOrderCard extends StatelessWidget {
  const _BuildOrderCard({
    required this.index,
    required this.total,
    required this.house,
    required this.distanceKm,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onOpen,
  });

  final int index;
  final int total;
  final HouseRecord house;
  final double? distanceKm;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final gpsReady = parseBeneficiaryGps(house.gps) != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${index + 1}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      Text(
                        '${house.code} — ${house.beneficiary}',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                      RcStatusChip(
                        label: house.phase.label.toUpperCase(),
                        compact: true,
                        tone: house.needsAttention
                            ? RcStatusTone.warning
                            : RcStatusTone.info,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('${house.cluster} • ${house.community}'),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: <Widget>[
                      _Meta(
                        icon: gpsReady
                            ? Icons.gps_fixed_outlined
                            : Icons.gps_off_outlined,
                        label: gpsReady
                            ? house.gps
                            : 'GPS missing — manual order available',
                      ),
                      if (index > 0)
                        _Meta(
                          icon: Icons.route_outlined,
                          label: distanceKm == null
                              ? 'Distance unavailable'
                              : '${distanceKm!.toStringAsFixed(2)} km from previous',
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: onOpen,
                    icon: const Icon(Icons.open_in_new_outlined),
                    label: const Text('OPEN HOUSE'),
                  ),
                ],
              ),
            ),
            Column(
              children: <Widget>[
                IconButton(
                  tooltip: 'Move earlier',
                  onPressed: onMoveUp,
                  icon: const Icon(Icons.keyboard_arrow_up),
                ),
                Text(
                  '${index + 1}/$total',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                IconButton(
                  tooltip: 'Move later',
                  onPressed: onMoveDown,
                  icon: const Icon(Icons.keyboard_arrow_down),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AllHouseCompletionDocumentsScreen extends StatefulWidget {
  const AllHouseCompletionDocumentsScreen({super.key});

  @override
  State<AllHouseCompletionDocumentsScreen> createState() =>
      _AllHouseCompletionDocumentsScreenState();
}

class _AllHouseCompletionDocumentsScreenState
    extends State<AllHouseCompletionDocumentsScreen> {
  static const documents = <String>[
    'BOQ',
    'Scope',
    'Workplan',
    'Time Extension',
    'Notice of Completion',
    'Monitoring Checklist',
    'KOBO',
  ];

  String _parish = 'All';
  String _cluster = 'All';
  bool _onlyIncomplete = false;

  bool _isGlobalRole(String role) {
    final normalized =
        role.trim().toLowerCase().replaceAll('_', ' ').replaceAll('-', ' ');
    return normalized == 'admin' ||
        normalized == 'administrator' ||
        normalized == 'regional supervisor' ||
        normalized == 'regional site supervisor' ||
        normalized == 'construction specialist';
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final global = _isGlobalRole(state.role);
    final allowed = state.houses.where((house) {
      if (global) return true;
      return house.parish == state.selectedParish;
    }).toList();

    final parishes = allowed.map((house) => house.parish).toSet().toList()
      ..sort();
    final parishOptions = global
        ? <String>['All', ...parishes]
        : (parishes.isEmpty ? <String>[state.selectedParish] : parishes);

    if (!parishOptions.contains(_parish)) {
      _parish = global ? 'All' : parishOptions.first;
    }

    final clusterSource = allowed.where(
      (house) => _parish == 'All' || house.parish == _parish,
    );
    final clusters = clusterSource
        .map((house) => house.cluster)
        .where((cluster) => cluster.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final clusterOptions = <String>['All', ...clusters];
    if (!clusterOptions.contains(_cluster)) _cluster = 'All';

    final visible = allowed.where((house) {
      if (_parish != 'All' && house.parish != _parish) return false;
      if (_cluster != 'All' && house.cluster != _cluster) return false;
      if (_onlyIncomplete) {
        final count = state.completedDocuments[house.code]?.length ?? 0;
        if (count >= documents.length) return false;
      }
      return true;
    }).toList()
      ..sort((a, b) {
        final parishCompare = a.parish.compareTo(b.parish);
        if (parishCompare != 0) return parishCompare;
        final clusterCompare = a.cluster.compareTo(b.cluster);
        if (clusterCompare != 0) return clusterCompare;
        return a.code.compareTo(b.code);
      });

    final fullyComplete = visible.where((house) {
      return (state.completedDocuments[house.code]?.length ?? 0) >=
          documents.length;
    }).length;

    final missingDocs = visible.fold<int>(
      0,
      (sum, house) =>
          sum +
          (documents.length -
                  (state.completedDocuments[house.code]?.length ?? 0))
              .clamp(0, documents.length)
              .toInt(),
    );

    final visibleCodes = visible.map((house) => house.code).toSet();
    final recentChanges = state.activities
        .where((entry) => visibleCodes.contains(entry.houseCode))
        .take(8)
        .toList();

    return Scaffold(
      appBar: RcAppBar(
        title: const Text('All House Completion Documents'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Notifications',
            onPressed: () =>
                Navigator.pushNamed(context, RcRoutes.notifications),
            icon: Badge(
              isLabelVisible: state.unreadNotifications > 0,
              label: Text('${state.unreadNotifications}'),
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          const RcSyncBanner(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
              children: <Widget>[
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1150),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        RcPageHeading(
                          eyebrow: 'Control of Works / Close-out command',
                          title: 'Every house document and every change',
                          description: global
                              ? 'Your role can review completion-document status across all parishes. Document changes create a production notification and an audit activity against the affected house.'
                              : 'Your completion-document command is scoped to ${state.selectedParish}. Every change is recorded against the affected house.',
                          action: RcStatusChip(
                            label: global
                                ? 'ALL PARISHES'
                                : state.selectedParish.toUpperCase(),
                            icon: global
                                ? Icons.public_outlined
                                : Icons.location_on_outlined,
                            tone: RcStatusTone.info,
                          ),
                        ),
                        const SizedBox(height: 18),
                        RcResponsiveGrid(
                          minItemWidth: 190,
                          childAspectRatio: 1.35,
                          children: <Widget>[
                            RcMetricTile(
                              label: 'Visible houses',
                              value: '${visible.length}',
                              icon: Icons.home_work_outlined,
                              color: RcColors.brand,
                            ),
                            RcMetricTile(
                              label: 'Document-complete',
                              value: '$fullyComplete',
                              icon: Icons.task_alt_outlined,
                              color: RcColors.success,
                            ),
                            RcMetricTile(
                              label: 'Missing documents',
                              value: '$missingDocs',
                              icon: Icons.description_outlined,
                              color: missingDocs == 0
                                  ? RcColors.success
                                  : RcColors.warning,
                            ),
                            RcMetricTile(
                              label: 'Unread updates',
                              value: '${state.unreadNotifications}',
                              icon: Icons.notifications_active_outlined,
                              color: RcColors.info,
                              onTap: () => Navigator.pushNamed(
                                context,
                                RcRoutes.notifications,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final wide = constraints.maxWidth >= 760;

                                final parish =
                                    DropdownButtonFormField<String>(
                                  value: _parish,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Parish',
                                  ),
                                  items: parishOptions
                                      .map(
                                        (value) => DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(value),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: global
                                      ? (value) => setState(() {
                                            _parish = value ?? 'All';
                                            _cluster = 'All';
                                          })
                                      : null,
                                );

                                final cluster =
                                    DropdownButtonFormField<String>(
                                  value: _cluster,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Cluster',
                                  ),
                                  items: clusterOptions
                                      .map(
                                        (value) => DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(value),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) => setState(
                                    () => _cluster = value ?? 'All',
                                  ),
                                );

                                final incomplete = SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('Show incomplete only'),
                                  subtitle: const Text(
                                    'Focus on houses still missing close-out documents.',
                                  ),
                                  value: _onlyIncomplete,
                                  onChanged: (value) =>
                                      setState(() => _onlyIncomplete = value),
                                );

                                if (!wide) {
                                  return Column(
                                    children: <Widget>[
                                      parish,
                                      const SizedBox(height: 12),
                                      cluster,
                                      incomplete,
                                    ],
                                  );
                                }

                                return Row(
                                  children: <Widget>[
                                    Expanded(child: parish),
                                    const SizedBox(width: 12),
                                    Expanded(child: cluster),
                                    const SizedBox(width: 18),
                                    Expanded(child: incomplete),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        RcSectionHeader(
                          title: 'House completion files',
                          subtitle:
                              '${visible.length} house file(s) • checklist, connected records, notifications and activity trail',
                        ),
                        const SizedBox(height: 10),
                        if (visible.isEmpty)
                          const RcEmptyState(
                            icon: Icons.folder_off_outlined,
                            title: 'No matching house files',
                            message:
                                'Adjust the parish, cluster or incomplete filter.',
                          )
                        else
                          for (final house in visible) ...<Widget>[
                            _CompletionHouseCard(
                              house: house,
                              requiredDocuments: documents,
                              canEdit: global ||
                                  house.parish == state.selectedParish,
                            ),
                            const SizedBox(height: 10),
                          ],
                        const SizedBox(height: 22),
                        RcSectionHeader(
                          title: 'Recent document & production changes',
                          subtitle: global
                              ? 'Cross-parish activity visible to management review roles.'
                              : '${state.selectedParish} activity trail.',
                          trailing: TextButton.icon(
                            onPressed: () => Navigator.pushNamed(
                              context,
                              RcRoutes.activity,
                            ),
                            icon: const Icon(Icons.history_outlined),
                            label: const Text('ACTIVITY LOG'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Card(
                          child: recentChanges.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.all(18),
                                  child:
                                      Text('No recent changes in this scope.'),
                                )
                              : Column(
                                  children: recentChanges.map((entry) {
                                    return ListTile(
                                      leading: Icon(entry.icon),
                                      title: Text(
                                        '${entry.houseCode} • ${entry.title}',
                                      ),
                                      subtitle: Text(
                                        '${entry.detail}\n${entry.actor}',
                                      ),
                                      isThreeLine: true,
                                      onTap: () {
                                        state.selectHouse(entry.houseCode);
                                        Navigator.pushNamed(
                                          context,
                                          RcRoutes.activity,
                                        );
                                      },
                                    );
                                  }).toList(),
                                ),
                        ),
                      ],
                    ),
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

class _CompletionHouseCard extends StatelessWidget {
  const _CompletionHouseCard({
    required this.house,
    required this.requiredDocuments,
    required this.canEdit,
  });

  final HouseRecord house;
  final List<String> requiredDocuments;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final complete = state.completedDocuments[house.code] ?? <String>{};
    final percent = requiredDocuments.isEmpty
        ? 0.0
        : complete.length / requiredDocuments.length;
    final connectedRecords = _connectedRecordTypes(state, house.code);
    final latestActivity = _latestActivity(state, house.code);
    final latestNotification = _latestNotification(state, house.code);

    return Card(
      child: ExpansionTile(
        leading: CircleAvatar(
          child: Text(
            house.code,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        title: Text(
          '${house.code} — ${house.beneficiary}',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          '${house.parish} • ${house.cluster}\n'
          '${complete.length}/${requiredDocuments.length} documents • '
          '${house.evidenceComplete}/${house.evidenceRequired} evidence',
        ),
        trailing: SizedBox(
          width: 64,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                '${(percent * 100).round()}%',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: percent.clamp(0.0, 1.0).toDouble(),
                minHeight: 5,
              ),
            ],
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
        children: <Widget>[
          const Divider(),
          for (final document in requiredDocuments)
            CheckboxListTile(
              value: complete.contains(document),
              onChanged: canEdit
                  ? (_) => state.toggleDocument(house.code, document)
                  : null,
              title: Text(document),
              subtitle: Text(
                complete.contains(document)
                    ? 'Verified and linked'
                    : 'Required / outstanding',
              ),
              secondary: Icon(
                complete.contains(document)
                    ? Icons.verified_outlined
                    : Icons.description_outlined,
                color: complete.contains(document)
                    ? RcColors.success
                    : RcColors.warning,
              ),
            ),
          if (connectedRecords.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Connected records',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: connectedRecords
                    .map(
                      (record) => Chip(
                        avatar: const Icon(
                          Icons.link_outlined,
                          size: 16,
                        ),
                        label: Text(record),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
          if (latestActivity != null || latestNotification != null) ...<Widget>[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (latestActivity != null)
                    Text(
                      'Latest activity: ${latestActivity.title} — ${latestActivity.detail}',
                    ),
                  if (latestActivity != null && latestNotification != null)
                    const SizedBox(height: 6),
                  if (latestNotification != null)
                    Text(
                      'Latest notification: ${latestNotification.title}',
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: () {
                  state.selectHouse(house.code);
                  Navigator.pushNamed(context, RcRoutes.houseCommand);
                },
                icon: const Icon(Icons.home_work_outlined),
                label: const Text('OPEN HOUSE'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  state.selectHouse(house.code);
                  Navigator.pushNamed(
                    context,
                    RcRoutes.documentChecklist,
                  );
                },
                icon: const Icon(Icons.fact_check_outlined),
                label: const Text('DOCUMENT CHECKLIST'),
              ),
              FilledButton.tonalIcon(
                onPressed: () {
                  state.selectHouse(house.code);
                  Navigator.pushNamed(context, RcRoutes.completion);
                },
                icon: const Icon(Icons.task_alt_outlined),
                label: const Text('COMPLETION'),
              ),
              TextButton.icon(
                onPressed: () {
                  state.selectHouse(house.code);
                  Navigator.pushNamed(context, RcRoutes.activity);
                },
                icon: const Icon(Icons.history_outlined),
                label: const Text('ACTIVITY'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<String> _connectedRecordTypes(AppState state, String houseCode) {
    final prefix = '$houseCode:';
    final result = state.formDrafts.keys
        .where((key) => key.startsWith(prefix))
        .map((key) => key.substring(prefix.length))
        .where((type) => type.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return result;
  }

  ActivityEntry? _latestActivity(AppState state, String houseCode) {
    for (final entry in state.activities) {
      if (entry.houseCode == houseCode) return entry;
    }
    return null;
  }

  AppNotification? _latestNotification(AppState state, String houseCode) {
    for (final notification in state.notifications) {
      if (notification.houseCode == houseCode) return notification;
    }
    return null;
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
