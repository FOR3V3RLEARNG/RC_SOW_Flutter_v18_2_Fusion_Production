import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/design_tokens.dart';
import '../../core/rc_components.dart';
import '../../state/app_state.dart';
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
  late Future<List<Map<String, dynamic>>> future;

  @override
  void initState() {
    super.initState();
    future = widget.state.repository.liveTrackers(widget.state.profile!);
  }

  Future<void> _refresh() async {
    setState(() {
      future = widget.state.repository.liveTrackers(widget.state.profile!);
    });
    await future;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Parish Live Tracker')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: future,
        builder: (context, snap) {
          final trackers = snap.data ?? const <Map<String, dynamic>>[];
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
              children: [
                const RcPageHeading(
                  eyebrow: 'Production + inventory',
                  title: 'Live Tracker Workbooks',
                  subtitle:
                      'Separate from the Shelter beneficiary source. Cluster worksheets track production and Storage tracks parish inventory. Beneficiary GPS and Field Map continue to use Shelter data only.',
                ),
                const SizedBox(height: 12),
                RcExpressiveSurface(
                  tone: theme.colorScheme.primaryContainer.withValues(alpha: .42),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.account_tree_outlined),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Live Tracker ≠ Beneficiary Map. Tracker sync never writes beneficiary_directory or house_locations.',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (snap.hasError)
                  RcExpressiveSurface(
                    tone: theme.colorScheme.errorContainer,
                    child: Text('Tracker configuration could not load: ${snap.error}'),
                  ),
                if (snap.connectionState == ConnectionState.waiting)
                  const Padding(
                    padding: EdgeInsets.all(30),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                if (trackers.isEmpty && snap.connectionState != ConnectionState.waiting)
                  const RcExpressiveSurface(
                    child: Text('No parish Live Tracker workbook is configured yet.'),
                  ),
                ...trackers.map(_trackerCard),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _trackerCard(Map<String, dynamic> tracker) {
    final theme = Theme.of(context);
    final parish = '${tracker['parish'] ?? ''}'.trim();
    final provider = '${tracker['provider'] ?? 'Workbook'}'.trim();
    final status = '${tracker['last_sync_status'] ?? 'Never synced'}'.trim();
    final message = '${tracker['last_sync_message'] ?? ''}'.trim();
    final clusters = (tracker['cluster_count'] as num?)?.toInt() ?? 0;
    final inventory = (tracker['inventory_count'] as num?)?.toInt() ?? 0;
    final syncedAt = DateTime.tryParse('${tracker['last_synced_at'] ?? ''}');
    final statusColor = status.toLowerCase() == 'success'
        ? RcColors.success
        : status.toLowerCase().contains('fail')
            ? RcColors.danger
            : RcColors.warning;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: RcExpressiveSurface(
        shape: RcSurfaceShape.offset,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    provider.toLowerCase().contains('one')
                        ? Icons.cloud_outlined
                        : Icons.table_view_rounded,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$parish Live Tracker', style: theme.textTheme.titleLarge),
                      Text('$provider • external XLSX workbook'),
                    ],
                  ),
                ),
                RcStatusPill(label: status.toUpperCase(), color: statusColor),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                RcStatusPill(label: '$clusters clusters', icon: Icons.hub_outlined, color: RcColors.purple),
                RcStatusPill(label: '$inventory inventory items', icon: Icons.inventory_2_outlined, color: RcColors.success),
              ],
            ),
            if (message.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(message),
            ],
            if (syncedAt != null) ...[
              const SizedBox(height: 5),
              Text(
                'Last API sync: ${syncedAt.toLocal()}',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: parish.isEmpty ? null : () => _showProduction(parish),
                  icon: const Icon(Icons.fact_check_outlined),
                  label: const Text('Cluster Production'),
                ),
                FilledButton.tonalIcon(
                  onPressed: parish.isEmpty ? null : () => _showInventory(parish),
                  icon: const Icon(Icons.inventory_2_outlined),
                  label: const Text('Parish Inventory'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _openUrl('${tracker['url'] ?? ''}'),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open Workbook'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showProduction(String parish) async {
    final snapshot = await widget.state.repository.liveTrackerSnapshot(
      widget.state.profile!,
      parish: parish,
    );
    if (!mounted) return;
    if (snapshot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$parish has no synced tracker snapshot yet.')),
      );
      return;
    }
    final item = Map<String, dynamic>.from(snapshot['item'] as Map? ?? const {});
    final clusters = (item['clusters'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: .92,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 10, 8),
              child: Row(
                children: [
                  Expanded(child: Text('$parish Cluster Production', style: Theme.of(sheetContext).textTheme.titleLarge)),
                  IconButton(onPressed: () => Navigator.pop(sheetContext), icon: const Icon(Icons.close)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 30),
                children: clusters.map((cluster) {
                  final name = '${cluster['name'] ?? 'Cluster'}';
                  final houses = (cluster['houses'] as List? ?? const [])
                      .whereType<Map>()
                      .map((e) => Map<String, dynamic>.from(e))
                      .toList();
                  return Card(
                    child: ExpansionTile(
                      leading: const Icon(Icons.hub_outlined),
                      title: Text(name),
                      subtitle: Text('${houses.length} houses'),
                      children: houses.map(_houseTile).toList(),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _houseTile(Map<String, dynamic> row) {
    final code = '${row['houseId'] ?? ''}'.trim().toUpperCase();
    final rejected = row['rejected'] == true;
    final statuses = <String>[
      if (row['finished'] == true) 'Finished',
      if (row['started'] == true) 'Started',
      if (row['boqSent'] == true) 'BOQ Sent',
      if (row['boqDone'] == true) 'BOQ Done',
      if (row['sowDone'] == true) 'SOW Done',
      if (row['contractSigned'] == true) 'Contract Signed',
      if (row['houseVisitedVerified'] == true) 'Verified',
      if (row['materialsOnSiteNotStarted'] == true) 'Materials On Site',
      if (rejected) 'Rejected',
    ];
    return ListTile(
      title: Text(code.isEmpty ? 'House' : code),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (statuses.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Wrap(
                spacing: 5,
                runSpacing: 5,
                children: statuses
                    .map((s) => RcStatusPill(
                          label: s.toUpperCase(),
                          color: s == 'Rejected'
                              ? RcColors.danger
                              : s == 'Finished'
                                  ? RcColors.success
                                  : RcColors.blue,
                        ))
                    .toList(),
              ),
            ),
          if ('${row['comments'] ?? ''}'.trim().isNotEmpty) ...[
            const SizedBox(height: 5),
            Text('${row['comments']}'),
          ],
        ],
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'control' && code.isNotEmpty) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => HouseControlWorkspaceByCodeScreen(
                  state: widget.state,
                  houseCode: code,
                ),
              ),
            );
          } else if (value == 'link') {
            _openUrl('${row['link'] ?? ''}');
          }
        },
        itemBuilder: (_) => [
          if (code.isNotEmpty)
            const PopupMenuItem(value: 'control', child: Text('Open Control Of Works')),
          if ('${row['link'] ?? ''}'.trim().isNotEmpty)
            const PopupMenuItem(value: 'link', child: Text('Open Tracker Link')),
        ],
      ),
    );
  }

  Future<void> _showInventory(String parish) async {
    final rows = await widget.state.repository.liveTrackerParishInventory(
      widget.state.profile!,
      parish: parish,
    );
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: .9,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 10, 8),
              child: Row(
                children: [
                  Expanded(child: Text('$parish Parish Inventory', style: Theme.of(sheetContext).textTheme.titleLarge)),
                  IconButton(onPressed: () => Navigator.pop(sheetContext), icon: const Icon(Icons.close)),
                ],
              ),
            ),
            Expanded(
              child: rows.isEmpty
                  ? const Center(child: Text('No Storage worksheet has been synced yet.'))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 30),
                      itemCount: rows.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 6),
                      itemBuilder: (_, index) {
                        final row = rows[index];
                        final payload = Map<String, dynamic>.from(row['source_payload'] as Map? ?? const {});
                        final unit = '${row['unit'] ?? ''}'.trim();
                        final size = '${payload['size'] ?? ''}'.trim();
                        final length = '${payload['length'] ?? ''}'.trim();
                        final movements = (payload['transactions'] as List? ?? const []).length;
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.inventory_2_outlined),
                            title: Text('${row['description'] ?? 'Material'}'),
                            subtitle: Text([
                              if (size.isNotEmpty) size,
                              if (length.isNotEmpty) length,
                              'IN ${_qty(row['received'])}',
                              'OUT ${_qty(row['issued'])}',
                              '$movements movements',
                            ].join(' • ')),
                            trailing: Text(
                              '${_qty(row['balance'])}${unit.isEmpty ? '' : ' $unit'}',
                              style: Theme.of(sheetContext).textTheme.titleMedium,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openUrl(String raw) async {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null || !uri.hasScheme) return;
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The external link could not be opened.')),
      );
    }
  }

  String _qty(Object? raw) {
    final value = raw is num ? raw.toDouble() : double.tryParse('${raw ?? ''}') ?? 0;
    return value == value.roundToDouble() ? '${value.toInt()}' : value.toStringAsFixed(2);
  }
}
