import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/design_tokens.dart';
import '../../core/rc_policy.dart';
import '../../models/app_models.dart';
import '../../services/document_service.dart';
import '../../state/app_state.dart';

class ControlScreen extends StatefulWidget {
  const ControlScreen({super.key, required this.state});

  final AppState state;

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  late Future<List<ProductionRecord>> future;
  late final RcDocumentService documents;
  String phase = 'All';

  static const modules = <_ControlModule>[
    _ControlModule(
      'Work Plan',
      'workPlan',
      'Plan',
      Icons.calendar_view_week_outlined,
    ),
    _ControlModule(
      'Document Checklist',
      'documentChecklist',
      'Plan',
      Icons.task_alt_outlined,
    ),
    _ControlModule(
      'Monitoring Checklist',
      'monitoring',
      'Quality',
      Icons.fact_check_outlined,
    ),
    _ControlModule(
      'Site Visits',
      'siteVisit',
      'Delivery',
      Icons.location_on_outlined,
    ),
    _ControlModule(
      'Daily Site Log',
      'dailyLog',
      'Delivery',
      Icons.menu_book_outlined,
    ),
    _ControlModule(
      'Material Request',
      'materialRequest',
      'Delivery',
      Icons.inventory_2_outlined,
    ),
    _ControlModule(
      'Consumables Form',
      'consumables',
      'Delivery',
      Icons.handyman_outlined,
    ),
    _ControlModule(
      'Inventory Tracker',
      'inventory',
      'Delivery',
      Icons.warehouse_outlined,
    ),
    _ControlModule(
      'Notice of Completion',
      'notice',
      'Close-out',
      Icons.verified_outlined,
    ),
    _ControlModule(
      'Payment Submission',
      'payment',
      'Finance',
      Icons.payments_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    documents = RcDocumentService(Supabase.instance.client);
    future = _load();
  }

  Future<List<ProductionRecord>> _load() =>
      widget.state.repository.productionRecords(widget.state.profile!);

  Future<void> _refresh() async {
    final next = _load();
    setState(() => future = next);
    await next;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<List<ProductionRecord>>(
        future: future,
        builder: (context, snapshot) {
          final records = snapshot.data ?? const <ProductionRecord>[];
          final visibleModules = phase == 'All'
              ? modules
              : modules.where((module) => module.phase == phase).toList();
          final attention = records
              .where((record) => record.needsAttention)
              .length;
          final open = records.where((record) => !record.isClosed).length;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 118),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Control of Works',
                          style: theme.textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'House-linked production records across planning, delivery, quality, completion and payment.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Export production data',
                    enabled: widget.state.profile!.canExportData,
                    icon: const Icon(Icons.ios_share_outlined),
                    onSelected: (action) => _export(action, records),
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'xlsx-share',
                        child: Text('Share Excel'),
                      ),
                      PopupMenuItem(
                        value: 'xlsx-save',
                        child: Text('Save Excel'),
                      ),
                      PopupMenuItem(
                        value: 'pdf-share',
                        child: Text('Share PDF'),
                      ),
                      PopupMenuItem(value: 'pdf-save', child: Text('Save PDF')),
                    ],
                  ),
                  const SizedBox(width: 6),
                  FilledButton.tonalIcon(
                    onPressed: () => _createRecord(
                      const _ControlModule(
                        'Control of Work',
                        'controlData',
                        'Delivery',
                        Icons.add_task_outlined,
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('New'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: .34,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _MetricChip(
                        label: '$open open',
                        icon: Icons.play_arrow_rounded,
                      ),
                      _MetricChip(
                        label: '$attention attention',
                        icon: Icons.priority_high_rounded,
                        color: attention > 0
                            ? RcColors.warning
                            : RcColors.success,
                      ),
                      _MetricChip(
                        label: '${records.length} total',
                        icon: Icons.inventory_2_outlined,
                        color: RcColors.blue,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<String>(
                  segments:
                      const [
                            'All',
                            'Plan',
                            'Delivery',
                            'Quality',
                            'Close-out',
                            'Finance',
                          ]
                          .map(
                            (value) =>
                                ButtonSegment(value: value, label: Text(value)),
                          )
                          .toList(),
                  selected: {phase},
                  showSelectedIcon: false,
                  onSelectionChanged: (selection) {
                    setState(() => phase = selection.first);
                  },
                ),
              ),
              const SizedBox(height: 16),
              if (snapshot.connectionState == ConnectionState.waiting)
                const LinearProgressIndicator(),
              if (snapshot.hasError)
                Card(
                  color: theme.colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      'Could not load production records. Pull to refresh.\n${snapshot.error}',
                    ),
                  ),
                ),
              ...visibleModules.map(
                (module) => Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Card(
                    child: ListTile(
                      leading: CircleAvatar(child: Icon(module.icon)),
                      title: Text(
                        module.title,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      subtitle: Text(
                        '${records.where((record) => record.eventType == module.eventType).length} records • ${module.phase}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _openModule(module),
                    ),
                  ),
                ),
              ),
              if (records.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Recent activity', style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                ...records
                    .take(8)
                    .map(
                      (record) => ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                        ),
                        leading: const Icon(Icons.history),
                        title: Text('${record.houseCode} • ${record.title}'),
                        subtitle: Text('${record.parish} • ${record.status}'),
                        trailing: Text(
                          _shortDate(record.updatedAt),
                          style: theme.textTheme.bodySmall,
                        ),
                        onTap: () {
                          final matching = modules.where(
                            (module) => module.eventType == record.eventType,
                          );
                          if (matching.isNotEmpty) {
                            _openModule(matching.first);
                          }
                        },
                      ),
                    ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _openModule(_ControlModule module) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            _ProductionModuleScreen(state: widget.state, module: module),
      ),
    );
    if (mounted) {
      await _refresh();
    }
  }

  Future<void> _createRecord(_ControlModule module) async {
    final created = await _showProductionRecordDialog(
      context,
      state: widget.state,
      module: module,
    );
    if (created && mounted) {
      await _refresh();
    }
  }

  Future<void> _export(String action, List<ProductionRecord> records) async {
    if (records.isEmpty) {
      _toast('There are no production records to export.');
      return;
    }
    try {
      if (action.startsWith('xlsx')) {
        final bytes = await documents.productionXlsx(records);
        if (action.endsWith('share')) {
          await documents.shareBytes(
            bytes: bytes,
            fileName: 'RC_SOW_Production_Export.xlsx',
            mimeType:
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            subject: 'RC SOW production export',
          );
        } else {
          await documents.saveBytes(
            bytes: bytes,
            fileName: 'RC_SOW_Production_Export.xlsx',
            mimeType:
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          );
        }
      } else {
        final bytes = await documents.productionPdf(records);
        if (action.endsWith('share')) {
          await documents.shareBytes(
            bytes: bytes,
            fileName: 'RC_SOW_Production_Export.pdf',
            mimeType: 'application/pdf',
            subject: 'RC SOW production export',
          );
        } else {
          await documents.saveBytes(
            bytes: bytes,
            fileName: 'RC_SOW_Production_Export.pdf',
            mimeType: 'application/pdf',
          );
        }
      }
      _toast('Export prepared successfully.');
    } catch (e) {
      _toast('Export failed: $e');
    }
  }

  void _toast(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _shortDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
}

class _ProductionModuleScreen extends StatefulWidget {
  const _ProductionModuleScreen({required this.state, required this.module});

  final AppState state;
  final _ControlModule module;

  @override
  State<_ProductionModuleScreen> createState() =>
      _ProductionModuleScreenState();
}

class _ProductionModuleScreenState extends State<_ProductionModuleScreen> {
  late Future<List<ProductionRecord>> future;
  late final RcDocumentService documents;

  @override
  void initState() {
    super.initState();
    documents = RcDocumentService(Supabase.instance.client);
    future = _load();
  }

  Future<List<ProductionRecord>> _load() async {
    final all = await widget.state.repository.productionRecords(
      widget.state.profile!,
    );
    return all
        .where((record) => record.eventType == widget.module.eventType)
        .toList();
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() => future = next);
    await next;
  }

  @override
  Widget build(BuildContext context) {
    final template = RcTemplates.forEventType(widget.module.eventType);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.module.title),
        actions: [
          if (template != null)
            PopupMenuButton<String>(
              tooltip: 'Template',
              icon: const Icon(Icons.description_outlined),
              onSelected: (action) => _templateAction(action, template),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'save', child: Text('Download template')),
                PopupMenuItem(
                  value: 'share',
                  child: Text('Share / email template'),
                ),
              ],
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add),
        label: const Text('Add record'),
      ),
      body: FutureBuilder<List<ProductionRecord>>(
        future: future,
        builder: (context, snapshot) {
          final records = snapshot.data ?? const <ProductionRecord>[];
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.module.title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Create, review and retain ${widget.module.title.toLowerCase()} records by house and parish.',
                        ),
                        if (template != null) ...[
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () => _templateAction('save', template),
                            icon: const Icon(Icons.download_outlined),
                            label: const Text('Use approved template'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const LinearProgressIndicator(),
                if (snapshot.hasError)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text('Could not load records: ${snapshot.error}'),
                    ),
                  ),
                if (snapshot.connectionState != ConnectionState.waiting &&
                    records.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(28),
                    child: Center(
                      child: Text('No records yet. Tap Add record.'),
                    ),
                  ),
                ...records.map(
                  (record) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.assignment_outlined),
                      title: Text(
                        record.houseCode,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      subtitle: Text(
                        '${record.parish} • ${record.status}\n${record.summary.isEmpty ? record.title : record.summary}',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      isThreeLine: true,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _create() async {
    final created = await _showProductionRecordDialog(
      context,
      state: widget.state,
      module: widget.module,
    );
    if (created && mounted) {
      await _refresh();
    }
  }

  Future<void> _templateAction(
    String action,
    RcTemplateDefinition template,
  ) async {
    try {
      if (action == 'save') {
        await documents.saveTemplate(template);
      } else {
        await documents.shareTemplate(template);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${template.title} template ready.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Template action failed: $e')));
      }
    }
  }
}

Future<bool> _showProductionRecordDialog(
  BuildContext context, {
  required AppState state,
  required _ControlModule module,
}) async {
  final house = TextEditingController();
  final note = TextEditingController();
  final profile = state.profile!;
  final allowedParishes = profile.canViewAllParishes
      ? RcPolicy.parishes
      : <String>[profile.parish];
  var parish = allowedParishes.contains(profile.parish)
      ? profile.parish
      : allowedParishes.first;
  var status = module.eventType == 'notice' || module.eventType == 'payment'
      ? 'Submitted'
      : 'Draft';
  var busy = false;
  String? error;

  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text('Add ${module.title}'),
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
                DropdownButtonFormField<String>(
                  initialValue: parish,
                  decoration: const InputDecoration(labelText: 'Parish'),
                  items: allowedParishes
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                  onChanged: busy ? null : (value) => parish = value!,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items:
                      const [
                            'Draft',
                            'Open',
                            'Submitted',
                            'In Review',
                            'Approved',
                            'Completed',
                            'Blocked',
                            'Paid',
                          ]
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(),
                  onChanged: busy ? null : (value) => status = value!,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: note,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Work details / notes',
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: busy ? null : () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: busy
                ? null
                : () async {
                    if (house.text.trim().isEmpty) {
                      setDialogState(() => error = 'House Code is required.');
                      return;
                    }
                    setDialogState(() {
                      busy = true;
                      error = null;
                    });
                    try {
                      await state.repository.submitControlEvent(
                        profile: profile,
                        eventType: module.eventType,
                        houseCode: house.text.trim(),
                        parish: parish,
                        item: {
                          'status': status,
                          'summary': note.text.trim(),
                          'title': module.title,
                          'createdFrom': 'RC SOW v18.3.1 Fusion',
                        },
                      );
                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext, true);
                      }
                    } catch (e) {
                      setDialogState(() {
                        busy = false;
                        error = 'Could not save record: $e';
                      });
                    }
                  },
            child: Text(busy ? 'Saving…' : 'Save'),
          ),
        ],
      ),
    ),
  );

  house.dispose();
  note.dispose();
  return result == true;
}

class _ControlModule {
  const _ControlModule(this.title, this.eventType, this.phase, this.icon);

  final String title;
  final String eventType;
  final String phase;
  final IconData icon;
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.icon,
    this.color = RcColors.brand,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18, color: color),
      label: Text(label.toUpperCase()),
    );
  }
}
