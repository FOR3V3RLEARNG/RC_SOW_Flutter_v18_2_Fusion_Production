import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_constants.dart';
import '../../core/design_tokens.dart';
import '../../core/rc_components.dart';
import '../../state/app_state.dart';
import '../control/house_operations_control_screen.dart';

class InteractiveHouseMapScreen extends StatefulWidget {
  const InteractiveHouseMapScreen({super.key, required this.state});
  final AppState state;

  @override
  State<InteractiveHouseMapScreen> createState() =>
      _InteractiveHouseMapScreenState();
}

class _InteractiveHouseMapScreenState extends State<InteractiveHouseMapScreen> {
  String? parish;
  Future<_ParishMapData>? future;

  @override
  void initState() {
    super.initState();
    final profile = widget.state.profile!;
    parish = profile.canViewAllParishes ? null : profile.parish;
    if (parish != null && parish!.trim().isNotEmpty) {
      future = _load(parish!);
    }
  }

  Future<_ParishMapData> _load(String selectedParish) async {
    final result = await Future.wait([
      widget.state.repository.parishMapSource(
        widget.state.profile!,
        parish: selectedParish,
      ),
      widget.state.repository.parishMapPoints(
        widget.state.profile!,
        parish: selectedParish,
      ),
    ]);
    return _ParishMapData(
      source: result[0] as Map<String, dynamic>?,
      points: result[1] as List<Map<String, dynamic>>,
    );
  }

  void _selectParish(String value) {
    setState(() {
      parish = value;
      future = _load(value);
    });
  }

  Future<void> _refresh() async {
    final current = parish;
    if (current == null) return;
    setState(() => future = _load(current));
    await future;
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.state.profile!;

    if (profile.canViewAllParishes && parish == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Parish House Map')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 80),
          children: [
            const RcPageHeading(
              eyebrow: 'Google My Maps',
              title: 'Choose A Parish Map',
              subtitle:
                  'Maps are isolated by parish. Select one parish at a time.',
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: RcApp.parishes
                  .map(
                    (value) => FilledButton.tonalIcon(
                      onPressed: () => _selectParish(value),
                      icon: const Icon(Icons.map_outlined),
                      label: Text(value),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      );
    }

    final selectedParish = parish ?? profile.parish;

    return Scaffold(
      appBar: AppBar(
        title: Text('$selectedParish House Map'),
        actions: [
          if (profile.canViewAllParishes)
            IconButton(
              tooltip: 'Change parish',
              onPressed: () => setState(() {
                parish = null;
                future = null;
              }),
              icon: const Icon(Icons.swap_horiz_rounded),
            ),
        ],
      ),
      body: FutureBuilder<_ParishMapData>(
        future: future ?? _load(selectedParish),
        builder: (context, snap) {
          final data = snap.data ?? const _ParishMapData();
          final rows = data.points.where((row) {
            final lat = _double(row['latitude']);
            final lon = _double(row['longitude']);
            return lat != null &&
                lon != null &&
                lat >= -90 &&
                lat <= 90 &&
                lon >= -180 &&
                lon <= 180;
          }).toList();

          if (snap.connectionState == ConnectionState.waiting && rows.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.hasError) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                RcExpressiveSurface(
                  tone: Theme.of(context).colorScheme.errorContainer,
                  child: Text('Parish map could not be loaded: ${snap.error}'),
                ),
              ],
            );
          }

          if (data.source == null) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                RcPageHeading(
                  eyebrow: selectedParish,
                  title: 'No parish map configured',
                  subtitle:
                      'Admin must add a separate Google My Maps URL for $selectedParish in Operations Admin → Map.',
                ),
              ],
            );
          }

          if (rows.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  RcPageHeading(
                    eyebrow: selectedParish,
                    title: 'Map source configured',
                    subtitle:
                        'No synced Google My Maps points are available yet.',
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    onPressed: () => _openOriginal(data.source!),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Open Original Google My Map'),
                  ),
                ],
              ),
            );
          }

          final center = _center(rows);
          final linked = rows
              .where((row) => '${row['house_code'] ?? ''}'.trim().isNotEmpty)
              .length;
          final unlinked = rows.length - linked;

          return Column(
            children: [
              Material(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: Row(
                    children: [
                      const Icon(Icons.map_outlined),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Coordinates: $selectedParish Google My Maps • '
                          '$linked linked houses'
                          '${unlinked == 0 ? '' : ' • $unlinked other points'}',
                        ),
                      ),
                      IconButton(
                        tooltip: 'Open original Google My Map',
                        onPressed: () => _openOriginal(data.source!),
                        icon: const Icon(Icons.open_in_new),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: rows.length == 1 ? 15 : 11,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName:
                          'org.jamaicaredcross.rc_sow_flutter',
                    ),
                    MarkerLayer(
                      markers: rows.map((row) {
                        final point = LatLng(
                          _double(row['latitude'])!,
                          _double(row['longitude'])!,
                        );
                        final code = '${row['house_code'] ?? ''}'.trim();
                        final marker = '${row['marker_name'] ?? ''}'.trim();
                        final linkedHouse = code.isNotEmpty;
                        final label = linkedHouse ? code : marker;
                        final color = linkedHouse
                            ? Theme.of(context).colorScheme.primary
                            : RcColors.warning;

                        return Marker(
                          point: point,
                          width: 88,
                          height: 78,
                          child: GestureDetector(
                            onTap: () =>
                                _showPointActions(row, data.source!),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Material(
                                  elevation: 4,
                                  shape: const CircleBorder(),
                                  color: color,
                                  child: Padding(
                                    padding: const EdgeInsets.all(9),
                                    child: Icon(
                                      linkedHouse
                                          ? Icons.home_work_rounded
                                          : Icons.place_rounded,
                                      size: 22,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surface
                                        .withValues(alpha: .96),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                          fontWeight: FontWeight.w900,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SimpleAttributionWidget(
                      source: Text(
                        'OpenStreetMap contributors • point data: Google My Maps',
                      ),
                    ),
                  ],
                ),
              ),
              Material(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                    child: Row(
                      children: [
                        const Icon(Icons.touch_app_outlined),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '$linked house markers linked by RC SOW house code',
                          ),
                        ),
                        IconButton(
                          tooltip: 'Refresh map',
                          onPressed: _refresh,
                          icon: const Icon(Icons.refresh),
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
    );
  }

  Future<void> _openOriginal(Map<String, dynamic> source) async {
    final uri = Uri.tryParse('${source['url'] ?? ''}'.trim());
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  LatLng _center(List<Map<String, dynamic>> rows) {
    var lat = 0.0;
    var lon = 0.0;
    for (final row in rows) {
      lat += _double(row['latitude'])!;
      lon += _double(row['longitude'])!;
    }
    return LatLng(lat / rows.length, lon / rows.length);
  }

  double? _double(Object? raw) =>
      raw is num ? raw.toDouble() : double.tryParse('${raw ?? ''}');

  Future<void> _showPointActions(
    Map<String, dynamic> row,
    Map<String, dynamic> source,
  ) async {
    final code = '${row['house_code'] ?? ''}'.trim().toUpperCase();
    final marker = '${row['marker_name'] ?? ''}'.trim();
    final beneficiary = '${row['beneficiary_name'] ?? ''}'.trim();
    final cluster = '${row['cluster'] ?? ''}'.trim();
    final lat = _double(row['latitude']);
    final lon = _double(row['longitude']);

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              code.isNotEmpty ? code : marker,
              style: Theme.of(sheetContext).textTheme.titleLarge,
            ),
            if (beneficiary.isNotEmpty) Text(beneficiary),
            if (cluster.isNotEmpty) Text(cluster),
            const SizedBox(height: 6),
            Text(
              'Google My Maps: ${lat?.toStringAsFixed(7)}, '
              '${lon?.toStringAsFixed(7)}',
            ),
            const SizedBox(height: 14),
            if (code.isNotEmpty)
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => HouseControlWorkspaceByCodeScreen(
                        state: widget.state,
                        houseCode: code,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.home_work_outlined),
                label: Text('Open $code Control Of Works'),
              ),
            if (code.isNotEmpty) const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: lat == null || lon == null
                  ? null
                  : () async {
                      final uri = Uri.parse(
                        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lon',
                      );
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    },
              icon: const Icon(Icons.directions_outlined),
              label: const Text('Directions'),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _openOriginal(source),
              icon: const Icon(Icons.map_outlined),
              label: const Text('Open Original Google My Map'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParishMapData {
  const _ParishMapData({
    this.source,
    this.points = const [],
  });

  final Map<String, dynamic>? source;
  final List<Map<String, dynamic>> points;
}
