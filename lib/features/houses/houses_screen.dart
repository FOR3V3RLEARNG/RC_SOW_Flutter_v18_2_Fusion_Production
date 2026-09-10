import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/design_tokens.dart';
import '../../core/record_schemas.dart';
import '../../core/rc_components.dart';
import '../../models/app_models.dart';
import '../../state/app_state.dart';
import '../control/control_screen.dart';
import '../control/record_form_screen.dart';
import '../workforce/crew_attendance_screen.dart';
import '../workforce/crew_assignment_panel.dart';

class HousesScreen extends StatefulWidget {
  const HousesScreen({super.key, required this.state});
  final AppState state;

  @override
  State<HousesScreen> createState() => _HousesScreenState();
}

class _HousesScreenState extends State<HousesScreen> {
  String query = '';
  late Future<List<HouseRecord>> future;

  @override
  void initState() {
    super.initState();
    future = widget.state.repository.houses(widget.state.profile!);
  }

  Future<void> _refresh() async {
    setState(
      () => future = widget.state.repository.houses(widget.state.profile!),
    );
    await future;
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.state.profile!;
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<List<HouseRecord>>(
        future: future,
        builder: (context, snap) {
          final all = snap.data ?? const <HouseRecord>[];
          final filtered = all
              .where(
                (h) => '${h.code} ${h.beneficiary} ${h.parish} ${h.cluster}'
                    .toLowerCase()
                    .contains(query.toLowerCase()),
              )
              .toList();
          final grouped = <String, List<HouseRecord>>{};
          for (final house in filtered) {
            grouped.putIfAbsent(house.parish, () => []).add(house);
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 124),
            children: [
              RcPageHeading(
                eyebrow: 'Portfolio',
                title: 'Active Houses',
                subtitle:
                    'Each house is a production container for scope, control records, evidence, close-out and payment.',
                trailing: profile.canViewAllParishes
                    ? const RcStatusPill(
                        label: 'ALL PARISHES',
                        icon: Icons.public_outlined,
                        color: RcColors.blue,
                      )
                    : null,
              ),
              const SizedBox(height: 16),
              SearchBar(
                hintText: 'Search house, beneficiary, parish…',
                leading: const Icon(Icons.search),
                onChanged: (v) => setState(() => query = v),
              ),
              const SizedBox(height: 16),
              if (snap.connectionState == ConnectionState.waiting)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(30),
                    child: CircularProgressIndicator(),
                  ),
                ),
              if (snap.hasError)
                RcExpressiveSurface(
                  tone: theme.colorScheme.errorContainer,
                  child: const Text(
                    'Could not load houses. Check connectivity and pull to refresh.',
                  ),
                ),
              if (snap.connectionState != ConnectionState.waiting &&
                  filtered.isEmpty)
                const RcExpressiveSurface(
                  child: Text('No active houses are visible for this account.'),
                ),
              for (final parish in grouped.keys.toList()..sort()) ...[
                if (profile.canViewAllParishes)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
                    child: Text(parish, style: theme.textTheme.titleMedium),
                  ),
                ...grouped[parish]!.map(
                  (h) => Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: RcExpressiveSurface(
                      shape: RcSurfaceShape.offset,
                      onTap: () => _openHouse(context, h),
                      semanticLabel: 'Open ${h.code} ${h.beneficiary}',
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          _HouseCoverPhoto(
                            state: widget.state,
                            path: h.displayPhotoPath,
                            size: 52,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${h.code} • ${h.beneficiary}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${h.cluster}${h.cluster.isEmpty ? '' : ' • '}${h.stage}',
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
                          RcProgressOrb(
                            value: h.progress / 100,
                            label: 'done',
                            size: 62,
                            color: h.progress >= 80
                                ? RcColors.success
                                : theme.colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _openHouse(BuildContext context, HouseRecord house) async {
    final deleted = await Navigator.of(context).push<bool>(
      PageRouteBuilder<bool>(
        settings: RouteSettings(name: '/houses/${house.code}'),
        transitionDuration: widget.state.reduceMotion
            ? Duration.zero
            : RcMotion.medium,
        pageBuilder: (_, _, _) =>
            HouseCommandScreen(state: widget.state, house: house),
        transitionsBuilder: (_, animation, _, child) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(.02, .01),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
      ),
    );

    if (deleted == true && mounted) {
      await _refresh();
    }
  }
}

class _HouseCoverPhoto extends StatefulWidget {
  const _HouseCoverPhoto({
    required this.state,
    required this.path,
    required this.size,
  });

  final AppState state;
  final String? path;
  final double size;

  @override
  State<_HouseCoverPhoto> createState() => _HouseCoverPhotoState();
}

class _HouseCoverPhotoState extends State<_HouseCoverPhoto> {
  late Future<String?> future;

  @override
  void initState() {
    super.initState();
    future = _load();
  }

  @override
  void didUpdateWidget(covariant _HouseCoverPhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) future = _load();
  }

  Future<String?> _load() async {
    final path = widget.path?.trim() ?? '';
    if (path.isEmpty) return null;
    try {
      return await widget.state.repository.evidenceSignedUrl(path);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget fallback() => Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(19),
          topRight: Radius.circular(11),
          bottomLeft: Radius.circular(11),
          bottomRight: Radius.circular(19),
        ),
      ),
      child: Icon(
        Icons.home_work_outlined,
        color: theme.colorScheme.onPrimaryContainer,
      ),
    );

    if (widget.path?.trim().isEmpty ?? true) return fallback();

    return FutureBuilder<String?>(
      future: future,
      builder: (context, snapshot) {
        final url = snapshot.data;
        if (url == null || url.isEmpty) return fallback();
        return ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(19),
            topRight: Radius.circular(11),
            bottomLeft: Radius.circular(11),
            bottomRight: Radius.circular(19),
          ),
          child: Image.network(
            url,
            width: widget.size,
            height: widget.size,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => fallback(),
          ),
        );
      },
    );
  }
}

class HouseCommandScreen extends StatelessWidget {
  const HouseCommandScreen({
    super.key,
    required this.state,
    required this.house,
  });
  final AppState state;
  final HouseRecord house;

  Future<_HouseCommandData> _load() async {
    final results = await Future.wait([
      state.repository.productionRecords(state.profile!, houseCode: house.code),
      state.repository.crewAttendance(
        profile: state.profile!,
        houseCode: house.code,
      ),
      state.repository.searchBeneficiaries(
        state.profile!,
        query: house.code,
        limit: 50,
      ),
    ]);

    final beneficiaries = results[2] as List<BeneficiaryRecord>;
    BeneficiaryRecord? beneficiaryLocation;
    for (final candidate in beneficiaries) {
      if (candidate.houseCode.trim().toUpperCase() ==
          house.code.trim().toUpperCase()) {
        beneficiaryLocation = candidate;
        break;
      }
    }

    return _HouseCommandData(
      records: results[0] as List<ProductionRecord>,
      attendance: results[1] as List<Map<String, dynamic>>,
      beneficiary: beneficiaryLocation,
    );
  }

  Future<void> _confirmDeleteHouse(BuildContext context) async {
    if (!state.profile!.isAdmin) return;

    final typedController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded),
        title: Text('Delete ${house.code} from Active Houses?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This removes the activation/start record so the house no longer appears in Active Houses.',
            ),
            const SizedBox(height: 10),
            const Text(
              'Shelter beneficiary data, Scope, Control of Work, photos and other production history are preserved.',
            ),
            const SizedBox(height: 14),
            Text(
              'Type ${house.code} to confirm:',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 7),
            TextField(
              controller: typedController,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'House code',
                hintText: house.code,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () {
              final typed = typedController.text.trim().toUpperCase();
              if (typed != house.code.trim().toUpperCase()) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('House code does not match.')),
                );
                return;
              }
              Navigator.pop(dialogContext, true);
            },
            icon: const Icon(Icons.delete_forever_outlined),
            label: const Text('Delete Active House'),
          ),
        ],
      ),
    );
    typedController.dispose();

    if (confirmed != true || !context.mounted) return;

    try {
      await state.repository.deleteHouseStartRecord(
        profile: state.profile!,
        houseCode: house.code,
      );
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${house.code} removed from Active Houses. Project records were preserved.',
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('House could not be deleted: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(house.code),
        actions: [
          if (state.profile!.isAdmin)
            PopupMenuButton<String>(
              tooltip: 'House administration',
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (action) async {
                if (action == 'delete-house') {
                  await _confirmDeleteHouse(context);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem<String>(
                  value: 'delete-house',
                  child: Row(
                    children: [
                      Icon(Icons.delete_forever_outlined),
                      SizedBox(width: 10),
                      Text('Delete from Active Houses'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: FutureBuilder<_HouseCommandData>(
        future: _load(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
              children: [
                RcExpressiveSurface(
                  tone: Theme.of(context).colorScheme.errorContainer,
                  child: const Text(
                    'This house workspace could not be loaded. Your data was not changed. Check the connection and retry.',
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          HouseCommandScreen(state: state, house: house),
                    ),
                  ),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            );
          }
          final records = snap.data?.records ?? const <ProductionRecord>[];
          final attendance =
              snap.data?.attendance ?? const <Map<String, dynamic>>[];
          final beneficiaryLocation = snap.data?.beneficiary;
          final open = records.where((r) => !r.isClosed).length;
          final attention = records.where((r) => r.needsAttention).length;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
            children: [
              _HouseLocationHero(
                house: house,
                beneficiary: beneficiaryLocation,
                openRecords: open,
                attentionRecords: attention,
              ),
              const SizedBox(height: 18),
              Text('Production chain', style: theme.textTheme.titleLarge),
              const SizedBox(height: 9),
              _HousePipeline(
                records: records,
                onOpen: (type) {
                  if (type == 'crewAttendance') {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CrewAttendanceScreen(
                          state: state,
                          initialHouseCode: house.code,
                        ),
                      ),
                    );
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ProductionModuleScreen(
                          state: state,
                          schema: RcRecordSchemas.byEventType(type),
                        ),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 18),
              _AttendanceSummary(
                rows: attendance,
                onOpen: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CrewAttendanceScreen(
                      state: state,
                      initialHouseCode: house.code,
                    ),
                  ),
                ),
              ),
              if (state.profile!.hasPrivilege('manageCrew')) ...[
                const SizedBox(height: 18),
                CrewAssignmentPanel(
                  state: state,
                  initialHouseCode: house.code,
                  compact: true,
                ),
              ],
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Evidence & activity',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  Text(
                    '${records.length} records',
                    style: theme.textTheme.labelMedium,
                  ),
                ],
              ),
              const SizedBox(height: 9),
              if (snap.connectionState == ConnectionState.waiting)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (records.isEmpty)
                const RcExpressiveSurface(
                  child: Text(
                    'No production records are linked to this house yet.',
                  ),
                )
              else
                ...records.map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: RcExpressiveSurface(
                      shape: RcSurfaceShape.offset,
                      onTap: () {
                        if (r.eventType == 'crewAttendance') {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CrewAttendanceScreen(
                                state: state,
                                initialHouseCode: house.code,
                              ),
                            ),
                          );
                        } else {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => RecordFormScreen(
                                state: state,
                                schema: RcRecordSchemas.byEventType(
                                  r.eventType,
                                ),
                                record: r,
                              ),
                            ),
                          );
                        }
                      },
                      child: Row(
                        children: [
                          Icon(
                            r.needsAttention
                                ? Icons.warning_amber_rounded
                                : Icons.description_outlined,
                            color: r.needsAttention
                                ? RcColors.warning
                                : theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r.title,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  r.summary.isEmpty ? r.eventType : r.summary,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          RcStatusPill(
                            label: r.status.toUpperCase(),
                            color: r.needsAttention
                                ? RcColors.warning
                                : r.isClosed
                                ? RcColors.success
                                : theme.colorScheme.secondary,
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
}

class _HouseLocationHero extends StatelessWidget {
  const _HouseLocationHero({
    required this.house,
    required this.beneficiary,
    required this.openRecords,
    required this.attentionRecords,
  });

  final HouseRecord house;
  final BeneficiaryRecord? beneficiary;
  final int openRecords;
  final int attentionRecords;

  Future<void> _openLocation() async {
    final item = beneficiary;
    if (item == null || !item.hasCoordinates) return;

    final uri = Uri.parse(
      item.mapsUrl ??
          'https://www.google.com/maps/search/?api=1&query=${item.latitude},${item.longitude}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = beneficiary;
    final hasLocation = item?.hasCoordinates == true;
    final point = hasLocation ? LatLng(item!.latitude!, item.longitude!) : null;

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${house.code} • ${house.beneficiary}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${house.parish}${house.cluster.isEmpty ? '' : ' • ${house.cluster}'}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            RcProgressOrb(
              value: house.progress / 100,
              label: 'house',
              size: 82,
              color: house.progress >= 80
                  ? RcColors.success
                  : theme.colorScheme.primary,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            RcStatusPill(
              label: house.stage.toUpperCase(),
              icon: Icons.flag_outlined,
            ),
            RcStatusPill(label: '$openRecords OPEN', color: RcColors.blue),
            RcStatusPill(
              label: '$attentionRecords ATTENTION',
              color: attentionRecords > 0 ? RcColors.warning : RcColors.success,
            ),
            RcStatusPill(
              label: hasLocation ? 'GPS CONNECTED' : 'NO GPS',
              icon: hasLocation
                  ? Icons.location_on_outlined
                  : Icons.location_off_outlined,
              color: hasLocation ? RcColors.success : RcColors.warning,
            ),
          ],
        ),
        if (hasLocation) ...[
          const SizedBox(height: 10),
          FilledButton.tonalIcon(
            onPressed: _openLocation,
            icon: const Icon(Icons.near_me_outlined),
            label: const Text('Open beneficiary location'),
          ),
        ],
      ],
    );

    return Semantics(
      label: hasLocation
          ? 'Active house ${house.code} with beneficiary map location'
          : 'Active house ${house.code}; beneficiary GPS unavailable',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Container(
          constraints: const BoxConstraints(minHeight: 270),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: hasLocation
                    ? FlutterMap(
                        options: MapOptions(
                          initialCenter: point!,
                          initialZoom: 17.0,
                          interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.none,
                          ),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'rc_sow_flutter',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: point,
                                width: 74,
                                height: 74,
                                alignment: Alignment.center,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: theme.colorScheme.primary,
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: theme.colorScheme.shadow
                                            .withValues(alpha: .18),
                                        blurRadius: 14,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.home_work_rounded,
                                    color: theme.colorScheme.primary,
                                    size: 32,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          RichAttributionWidget(
                            attributions: [
                              TextSourceAttribution(
                                'OpenStreetMap contributors',
                                onTap: () => launchUrl(
                                  Uri.parse(
                                    'https://www.openstreetmap.org/copyright',
                                  ),
                                  mode: LaunchMode.externalApplication,
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    : Container(
                        color: theme.colorScheme.primaryContainer.withValues(
                          alpha: .48,
                        ),
                        alignment: Alignment.topRight,
                        padding: const EdgeInsets.all(22),
                        child: Icon(
                          Icons.map_outlined,
                          size: 76,
                          color: theme.colorScheme.primary.withValues(
                            alpha: .18,
                          ),
                        ),
                      ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomLeft,
                        end: Alignment.topRight,
                        colors: [
                          theme.colorScheme.surface.withValues(alpha: .97),
                          theme.colorScheme.surface.withValues(alpha: .82),
                          theme.colorScheme.surface.withValues(alpha: .30),
                        ],
                        stops: const [0.0, .55, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(padding: const EdgeInsets.all(18), child: info),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttendanceSummary extends StatelessWidget {
  const _AttendanceSummary({required this.rows, required this.onOpen});
  final List<Map<String, dynamic>> rows;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final verified = rows.where((row) => row['verified'] == true).length;
    return RcExpressiveSurface(
      shape: RcSurfaceShape.offset,
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.how_to_reg_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Who worked on this house',
                  style: theme.textTheme.titleLarge,
                ),
              ),
              RcStatusPill(
                label: '${rows.length} DAYS',
                color: rows.isEmpty ? theme.colorScheme.outline : RcColors.blue,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$verified verified attendance entries • tap to review or verify',
          ),
          const SizedBox(height: 8),
          if (rows.isEmpty)
            const Text(
              'No daily attendance has been recorded for this house yet.',
            )
          else
            ...rows
                .take(8)
                .map(
                  (row) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: Icon(
                      row['verified'] == true
                          ? Icons.verified_outlined
                          : Icons.schedule_outlined,
                    ),
                    title: Text(
                      '${row['member_name'] ?? row['member_email'] ?? 'Crew member'}',
                    ),
                    subtitle: Text(
                      '${row['work_date'] ?? ''} • ${row['member_role'] ?? ''} • ${row['status'] ?? ''}',
                    ),
                    trailing: RcStatusPill(
                      label: row['verified'] == true ? 'VERIFIED' : 'PENDING',
                      color: row['verified'] == true
                          ? RcColors.success
                          : RcColors.warning,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _HouseCommandData {
  const _HouseCommandData({
    this.records = const [],
    this.attendance = const [],
    this.beneficiary,
  });

  final List<ProductionRecord> records;
  final List<Map<String, dynamic>> attendance;
  final BeneficiaryRecord? beneficiary;
}

class _HousePipeline extends StatelessWidget {
  const _HousePipeline({required this.records, required this.onOpen});
  final List<ProductionRecord> records;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    bool hasAny(Set<String> types) =>
        records.any((r) => types.contains(r.eventType));
    final steps = [
      ('Scope', 'scope', hasAny({'scope'})),
      (
        'Plan',
        'workPlan',
        hasAny({'controlData', 'workPlan', 'documentChecklist'}),
      ),
      (
        'Delivery',
        'dailyLog',
        hasAny({
          'siteVisit',
          'dailyLog',
          'crewAttendance',
          'materialRequest',
          'consumables',
          'inventory',
        }),
      ),
      ('Quality', 'monitoring', hasAny({'monitoring'})),
      ('Complete', 'notice', hasAny({'notice'})),
      ('Payment', 'payment', hasAny({'payment'})),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            InkWell(
              borderRadius: BorderRadius.circular(15),
              onTap: () => onOpen(steps[i].$2),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: steps[i].$3
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    Icon(
                      steps[i].$3
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      size: 17,
                      color: steps[i].$3
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      steps[i].$1,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ),
            if (i != steps.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: theme.colorScheme.outline,
                ),
              ),
          ],
        ],
      ),
    );
  }
}
