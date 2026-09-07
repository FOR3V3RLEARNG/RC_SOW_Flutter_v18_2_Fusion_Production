import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

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
  late Future<List<Map<String, dynamic>>> future;

  @override
  void initState() {
    super.initState();
    future = widget.state.repository.houseLocations(widget.state.profile!);
  }

  Future<void> _refresh() async {
    setState(
      () => future =
          widget.state.repository.houseLocations(widget.state.profile!),
    );
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('House Map'),
        actions: [
          IconButton(
            tooltip: 'Live Tracker',
            onPressed: () => Navigator.of(context).pop('tracker'),
            icon: const Icon(Icons.location_searching),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: future,
        builder: (context, snap) {
          final allRows = snap.data ?? const <Map<String, dynamic>>[];
          final rows = allRows.where((row) {
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

          if (rows.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: const [
                  RcPageHeading(
                    eyebrow: 'Field Navigation',
                    title: 'House Map',
                    subtitle:
                        'No geocoded house locations are available yet. Add latitude/longitude through beneficiary or house-location data.',
                  ),
                ],
              ),
            );
          }

          final center = _center(rows);
          return Column(
            children: [
              Expanded(
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: rows.length == 1 ? 15 : 10,
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
                        return Marker(
                          point: point,
                          width: 72,
                          height: 72,
                          child: Semantics(
                            button: true,
                            label: 'Open map actions for house $code',
                            child: GestureDetector(
                              onTap: () => _showHouseActions(row),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Material(
                                    elevation: 3,
                                    shape: const CircleBorder(),
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    child: Padding(
                                      padding: const EdgeInsets.all(9),
                                      child: Icon(
                                        Icons.home_work_rounded,
                                        size: 22,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.only(top: 2),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surface
                                          .withValues(alpha: .92),
                                      borderRadius: BorderRadius.circular(7),
                                    ),
                                    child: Text(
                                      code,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w900,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SimpleAttributionWidget(
                      source: Text('OpenStreetMap contributors'),
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
                            '${rows.length} mapped house${rows.length == 1 ? '' : 's'} • tap a house for directions or Control of Works',
                          ),
                        ),
                        IconButton(
                          tooltip: 'Refresh locations',
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

  LatLng _center(List<Map<String, dynamic>> rows) {
    var lat = 0.0;
    var lon = 0.0;
    for (final row in rows) {
      lat += _double(row['latitude'])!;
      lon += _double(row['longitude'])!;
    }
    return LatLng(lat / rows.length, lon / rows.length);
  }

  double? _double(Object? raw) {
    if (raw is num) return raw.toDouble();
    return double.tryParse('${raw ?? ''}');
  }

  Future<void> _showHouseActions(Map<String, dynamic> row) async {
    final code = '${row['house_code'] ?? ''}'.trim().toUpperCase();
    final beneficiary = '${row['beneficiary_name'] ?? ''}'.trim();
    final parish = '${row['parish'] ?? ''}'.trim();
    final cluster = '${row['cluster'] ?? ''}'.trim();
    final lat = _double(row['latitude']);
    final lon = _double(row['longitude']);
    final savedUrl = '${row['maps_url'] ?? ''}'.trim();

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
              '$code • $beneficiary',
              style: Theme.of(sheetContext).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text('$parish${cluster.isEmpty ? '' : ' • $cluster'}'),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: code.isEmpty
                  ? null
                  : () {
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
              label: const Text('Open Control Of Works'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: lat == null && savedUrl.isEmpty
                  ? null
                  : () async {
                      final raw = savedUrl.isNotEmpty
                          ? savedUrl
                          : 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lon';
                      final uri = Uri.tryParse(raw);
                      if (uri == null) return;
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    },
              icon: const Icon(Icons.directions_outlined),
              label: const Text('Directions'),
            ),
          ],
        ),
      ),
    );
  }
}
