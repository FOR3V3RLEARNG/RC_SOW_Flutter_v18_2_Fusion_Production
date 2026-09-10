import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_constants.dart';
import '../../core/beneficiary_agreement.dart';
import '../../core/design_tokens.dart';
import '../../core/record_schemas.dart';
import '../../core/ui_studio.dart';
import '../../models/app_models.dart';
import '../community/community_screen.dart';
import '../../core/rc_components.dart';
import '../../services/agreement_import_service.dart';
import '../../services/boq_import_service.dart';
import '../../state/app_state.dart';

class OperationsAdminScreen extends StatefulWidget {
  const OperationsAdminScreen({super.key, required this.state});
  final AppState state;

  @override
  State<OperationsAdminScreen> createState() => _OperationsAdminScreenState();
}

class _OperationsAdminScreenState extends State<OperationsAdminScreen>
    with SingleTickerProviderStateMixin {
  late final TabController tabs;

  @override
  void initState() {
    super.initState();
    tabs = TabController(length: 9, vsync: this);
  }

  @override
  void dispose() {
    tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.state.profile!.canViewAdmin) {
      return const Scaffold(
        body: Center(child: Text('Admin privilege is required.')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Operations Admin'),
        bottom: TabBar(
          controller: tabs,
          isScrollable: true,
          tabs: const [
            Tab(text: 'BOQ', icon: Icon(Icons.receipt_long_outlined)),
            Tab(text: 'Agreement', icon: Icon(Icons.handshake_outlined)),
            Tab(text: 'Authorized', icon: Icon(Icons.mark_email_read_outlined)),
            Tab(
              text: 'Interface',
              icon: Icon(Icons.dashboard_customize_outlined),
            ),
            Tab(text: 'Community', icon: Icon(Icons.live_tv_rounded)),
            Tab(
              text: 'Notify',
              icon: Icon(Icons.notifications_active_outlined),
            ),
            Tab(text: 'Staff', icon: Icon(Icons.badge_outlined)),
            Tab(text: 'Tracker', icon: Icon(Icons.location_searching)),
            Tab(text: 'Map', icon: Icon(Icons.map_outlined)),
          ],
        ),
      ),
      body: TabBarView(
        controller: tabs,
        children: [
          _BoqTemplates(state: widget.state),
          _BeneficiaryAgreementAdmin(state: widget.state),
          _AuthorizedAccounts(state: widget.state),
          _InterfaceConfig(state: widget.state),
          _CommunityStudio(state: widget.state),
          _NotificationCentre(state: widget.state),
          _StaffDirectory(state: widget.state),
          _TrackerConfig(state: widget.state),
          _ParishMapConfig(state: widget.state),
        ],
      ),
    );
  }
}

class _BoqTemplates extends StatefulWidget {
  const _BoqTemplates({required this.state});
  final AppState state;

  @override
  State<_BoqTemplates> createState() => _BoqTemplatesState();
}

class _BoqTemplatesState extends State<_BoqTemplates> {
  late Future<List<Map<String, dynamic>>> future;

  @override
  void initState() {
    super.initState();
    future = widget.state.repository.boqTemplates(widget.state.profile!);
  }

  Future<void> _refresh() async {
    setState(
      () =>
          future = widget.state.repository.boqTemplates(widget.state.profile!),
    );
    await future;
  }

  Future<void> _importExcel() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    if (!mounted) return;

    try {
      final parsed = BoqImportService.parse(bytes);
      String scope = 'All Parishes';
      final chosen = await showDialog<String>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Import BOQ Template'),
            content: DropdownButtonFormField<String>(
              initialValue: scope,
              decoration: const InputDecoration(labelText: 'Template scope'),
              items: [
                'All Parishes',
                ...RcApp.parishes,
              ].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
              onChanged: (v) => setDialogState(() => scope = v!),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, scope),
                child: const Text('Import'),
              ),
            ],
          ),
        ),
      );
      if (chosen == null) return;
      await widget.state.repository.saveBoqTemplate(
        name: file.name.replaceAll(
          RegExp(r'\.xlsx$', caseSensitive: false),
          '',
        ),
        parish: chosen == 'All Parishes' ? null : chosen,
        sourceFileName: file.name,
        items: parsed.items,
      );
      await _refresh();
    } catch (error) {
      _snack('BOQ import failed: $error');
    }
  }

  Future<void> _createBlank() async {
    final name = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create BOQ Template'),
        content: TextField(
          controller: name,
          decoration: const InputDecoration(labelText: 'Template name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (ok == true && name.text.trim().isNotEmpty) {
      await widget.state.repository.saveBoqTemplate(
        name: name.text.trim(),
        items: const [],
      );
      await _refresh();
    }
    name.dispose();
  }

  Future<void> _editTemplate(Map<String, dynamic> template) async {
    final items = (template['items'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    final description = TextEditingController();
    final quantity = TextEditingController();
    final unit = TextEditingController();

    final save = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => FractionallySizedBox(
          heightFactor: .86,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
            child: ListView(
              children: [
                Text(
                  '${template['name'] ?? 'BOQ Template'}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                ...items.asMap().entries.map(
                  (entry) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('${entry.value['description'] ?? ''}'),
                    subtitle: Text(
                      '${entry.value['boqQuantity'] ?? 0} ${entry.value['unit'] ?? ''}',
                    ),
                    trailing: IconButton(
                      onPressed: () =>
                          setSheetState(() => items.removeAt(entry.key)),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ),
                ),
                const Divider(),
                TextField(
                  controller: description,
                  decoration: const InputDecoration(
                    labelText: 'Material description',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: quantity,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Quantity'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: unit,
                  decoration: const InputDecoration(labelText: 'Unit'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    if (description.text.trim().isEmpty) return;
                    setSheetState(() {
                      items.add({
                        'itemCode': '',
                        'description': description.text.trim(),
                        'unit': unit.text.trim(),
                        'size': '',
                        'length': '',
                        'boqQuantity':
                            double.tryParse(quantity.text.trim()) ?? 0,
                      });
                      description.clear();
                      quantity.clear();
                      unit.clear();
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Material'),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => Navigator.pop(context, true),
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save Template'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (save == true) {
      await widget.state.repository.saveBoqTemplate(
        id: '${template['id']}',
        name: '${template['name']}',
        parish: template['parish']?.toString(),
        sourceFileName: template['source_file_name']?.toString(),
        items: items,
      );
      await _refresh();
    }
    description.dispose();
    quantity.dispose();
    unit.dispose();
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snap) {
        final templates = snap.data ?? const <Map<String, dynamic>>[];
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
            children: [
              RcPageHeading(
                eyebrow: 'Bill of Quantities',
                title: 'BOQ Template Studio',
                subtitle:
                    'Import Excel BOQs or create reusable customized material lists.',
                trailing: Wrap(
                  spacing: 4,
                  children: [
                    IconButton.filledTonal(
                      tooltip: 'Blank template',
                      onPressed: _createBlank,
                      icon: const Icon(Icons.add),
                    ),
                    IconButton.filled(
                      tooltip: 'Import XLSX',
                      onPressed: _importExcel,
                      icon: const Icon(Icons.upload_file),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (templates.isEmpty &&
                  snap.connectionState != ConnectionState.waiting)
                const RcExpressiveSurface(
                  child: Text('No BOQ templates have been created yet.'),
                ),
              ...templates.map(
                (template) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.table_view_outlined),
                    title: Text('${template['name'] ?? 'BOQ Template'}'),
                    subtitle: Text(
                      '${template['parish'] ?? 'All Parishes'} • '
                      '${(template['items'] as List? ?? const []).length} items',
                    ),
                    trailing: const Icon(Icons.edit_outlined),
                    onTap: () => _editTemplate(template),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BeneficiaryAgreementAdmin extends StatefulWidget {
  const _BeneficiaryAgreementAdmin({required this.state});

  final AppState state;

  @override
  State<_BeneficiaryAgreementAdmin> createState() =>
      _BeneficiaryAgreementAdminState();
}

class _BeneficiaryAgreementAdminState
    extends State<_BeneficiaryAgreementAdmin> {
  final title = TextEditingController();
  final version = TextEditingController();
  final body = TextEditingController();

  bool loading = true;
  bool saving = false;
  String sourceFileName = 'Built-in default';
  String sourceType = 'Default';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    title.dispose();
    version.dispose();
    body.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    final config = await widget.state.repository.beneficiaryAgreementConfig();
    if (!mounted) return;

    title.text =
        '${config['title'] ?? kDefaultBeneficiaryAgreementTitle}'.trim();
    body.text = '${config['body'] ?? kDefaultBeneficiaryAgreementText}'.trim();
    version.text = '${config['version'] ?? 'Default'}'.trim();
    sourceFileName =
        '${config['sourceFileName'] ?? 'Built-in default'}'.trim();
    sourceType = '${config['sourceType'] ?? 'Default'}'.trim();

    setState(() => loading = false);
  }

  Future<void> _importDocument() async {
    final file = await FilePicker.pickFile(type: FileType.any);
    if (file == null) return;

    try {
      final bytes = await file.readAsBytes();
      final result = AgreementImportService.parse(bytes, file.name);
      if (!mounted) return;

      setState(() {
        sourceFileName = file.name;
        sourceType = result.sourceType;
        if (result.automaticExtraction && result.text.trim().isNotEmpty) {
          body.text = result.text.trim();
        }
        if (version.text.trim().isEmpty || version.text.trim() == 'Default') {
          version.text = '1.0';
        }
      });

      _snack(
        result.automaticExtraction
            ? 'Agreement text imported from ${file.name}. Review it before saving.'
            : '${file.name} selected as the source document. Automatic text extraction is not available for this file type; paste or edit the agreement wording below.',
      );
    } catch (error) {
      _snack('Agreement import failed: $error');
    }
  }

  void _resetDefault() {
    setState(() {
      title.text = kDefaultBeneficiaryAgreementTitle;
      body.text = kDefaultBeneficiaryAgreementText;
      version.text = 'Default';
      sourceFileName = 'Built-in default';
      sourceType = 'Default';
    });
  }

  Future<void> _save() async {
    if (body.text.trim().isEmpty) {
      _snack('Agreement wording cannot be empty.');
      return;
    }

    setState(() => saving = true);
    try {
      await widget.state.repository.saveBeneficiaryAgreementConfig(
        title: title.text.trim().isEmpty
            ? kDefaultBeneficiaryAgreementTitle
            : title.text.trim(),
        body: body.text.trim(),
        version: version.text.trim(),
        sourceFileName: sourceFileName,
        sourceType: sourceType,
      );
      if (!mounted) return;
      _snack('Beneficiary Agreement published for all new printouts.');
    } catch (error) {
      if (!mounted) return;
      _snack('Agreement could not be saved: $error');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
      children: [
        RcPageHeading(
          eyebrow: 'Beneficiary documents',
          title: 'Agreement Template Studio',
          subtitle:
              'Import agreement wording from a document, edit it, version it, and publish one controlled agreement used by the Beneficiary Agreement screen and PDF.',
          trailing: IconButton.filled(
            tooltip: 'Import agreement document',
            onPressed: _importDocument,
            icon: const Icon(Icons.upload_file_rounded),
          ),
        ),
        const SizedBox(height: 14),
        RcExpressiveSurface(
          shape: RcSurfaceShape.hero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  RcStatusPill(
                    label:
                        'VERSION ${version.text.trim().isEmpty ? '1.0' : version.text.trim()}',
                    color: RcColors.blue,
                  ),
                  RcStatusPill(
                    label: sourceType.toUpperCase(),
                    color: RcColors.success,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('Source document', style: theme.textTheme.labelLarge),
              const SizedBox(height: 4),
              SelectableText(
                sourceFileName,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _importDocument,
                icon: const Icon(Icons.file_open_outlined),
                label: const Text('Choose Excel / Word / Document'),
              ),
              const SizedBox(height: 8),
              Text(
                'Automatic extraction: XLSX, DOCX, TXT, CSV, Markdown and RTF. '
                'For PDF or legacy document formats, select the source file then paste/edit the wording in the agreement editor.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        RcExpressiveSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: title,
                decoration: const InputDecoration(labelText: 'Agreement title'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: version,
                decoration: const InputDecoration(
                  labelText: 'Agreement version',
                  hintText: 'e.g. 1.0, Sept 2026, Melissa Roofing v2',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              Text('Available smart fields', style: theme.textTheme.labelLarge),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: kBeneficiaryAgreementPlaceholders
                    .map(
                      (value) => ActionChip(
                        label: Text(value),
                        onPressed: () {
                          final selection = body.selection;
                          final start = selection.isValid
                              ? selection.start
                              : body.text.length;
                          final end = selection.isValid
                              ? selection.end
                              : body.text.length;
                          body.text = body.text.replaceRange(start, end, value);
                          body.selection = TextSelection.collapsed(
                            offset: start + value.length,
                          );
                        },
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: body,
                minLines: 12,
                maxLines: 30,
                decoration: const InputDecoration(
                  labelText: 'Agreement wording',
                  alignLabelWithHint: true,
                  helperText:
                      'This controlled wording is shown to the beneficiary and printed in the PDF.',
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _resetDefault,
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: const Text('Restore Default'),
                  ),
                  FilledButton.icon(
                    onPressed: saving ? null : _save,
                    icon: saving
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.publish_rounded),
                    label: Text(saving ? 'Publishing...' : 'Publish Agreement'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AuthorizedAccounts extends StatefulWidget {
  const _AuthorizedAccounts({required this.state});
  final AppState state;

  @override
  State<_AuthorizedAccounts> createState() => _AuthorizedAccountsState();
}

class _AuthorizedAccountsState extends State<_AuthorizedAccounts> {
  late Future<List<Map<String, dynamic>>> future;

  @override
  void initState() {
    super.initState();
    future = widget.state.repository.authorizedAccounts();
  }

  Future<void> _refresh() async {
    setState(() => future = widget.state.repository.authorizedAccounts());
    await future;
  }

  Future<void> _edit([Map<String, dynamic>? existing]) async {
    final email = TextEditingController(text: '${existing?['email'] ?? ''}');
    final label = TextEditingController(text: '${existing?['label'] ?? ''}');
    String role = RcApp.roles.contains(existing?['role'])
        ? '${existing!['role']}'
        : 'Carpenter';
    String parish = RcApp.parishes.contains(existing?['parish'])
        ? '${existing!['parish']}'
        : 'Hanover';
    bool active = existing?['active'] != false;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            existing == null ? 'Authorize Email' : 'Edit Authorization',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: email,
                  enabled: existing == null,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: label,
                  decoration: const InputDecoration(labelText: 'Name / label'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: role,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: RcApp.roles
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => role = v!),
                ),
                if (!RcApp.managementRoles.contains(role)) ...[
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: parish,
                    decoration: const InputDecoration(labelText: 'Parish'),
                    items: RcApp.parishes
                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged: (v) => setDialogState(() => parish = v!),
                  ),
                ],
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Authorized'),
                  value: active,
                  onChanged: (v) => setDialogState(() => active = v),
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
      ),
    );

    if (ok == true && email.text.contains('@')) {
      await widget.state.repository.manageAuthorizedAccount(
        email: email.text.trim(),
        label: label.text.trim(),
        role: role,
        parish: RcApp.managementRoles.contains(role) ? 'All Parishes' : parish,
        active: active,
      );
      await _refresh();
    }
    email.dispose();
    label.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snap) {
        final rows = snap.data ?? const <Map<String, dynamic>>[];
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
            children: [
              RcPageHeading(
                eyebrow: 'Access governance',
                title: 'Authorized Sign-In Emails',
                subtitle:
                    'Maintain the email allow-list with its default role and parish.',
                trailing: FilledButton.tonalIcon(
                  onPressed: () => _edit(),
                  icon: const Icon(Icons.add),
                  label: const Text('Email'),
                ),
              ),
              const SizedBox(height: 12),
              ...rows.map(
                (row) => Card(
                  child: ListTile(
                    leading: Icon(
                      row['active'] == false
                          ? Icons.block_outlined
                          : Icons.mark_email_read_outlined,
                    ),
                    title: Text('${row['label'] ?? row['email']}'),
                    subtitle: Text(
                      '${row['email']}\n${row['role']} • ${row['parish']}',
                    ),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (action) async {
                        if (action == 'edit') {
                          await _edit(row);
                        } else if (action == 'delete') {
                          await widget.state.repository.deleteAuthorizedAccount(
                            '${row['email']}',
                          );
                          await _refresh();
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InterfaceConfig extends StatefulWidget {
  const _InterfaceConfig({required this.state});
  final AppState state;

  @override
  State<_InterfaceConfig> createState() => _InterfaceConfigState();
}

class _InterfaceConfigState extends State<_InterfaceConfig> {
  late final TextEditingController appTitle;
  late final TextEditingController controlTitle;
  late final TextEditingController controlSubtitle;
  late final TextEditingController completionLabel;
  late final TextEditingController paymentLabel;
  late final TextEditingController needActionLabel;
  late final TextEditingController openLabel;

  int columns = 2;
  String defaultView = 'houses';
  List<String> moduleOrder = const [];
  double expressiveness = 78;
  double depth = 72;
  String surfaceFinish = 'suede';
  String iconPack = 'rounded';
  String iconShape = 'squircle';
  String accentMood = 'red';
  Map<String, String> iconOverrides = {};

  @override
  void initState() {
    super.initState();
    String text(String key, String fallback) {
      final value = '${widget.state.remoteUiConfig[key] ?? ''}'.trim();
      return value.isEmpty ? fallback : value;
    }

    appTitle = TextEditingController(
      text: text('appTitle', 'Red Cross Scope of Work'),
    );
    controlTitle = TextEditingController(
      text: text('controlTitle', 'Control Of Works'),
    );
    controlSubtitle = TextEditingController(
      text: text(
        'controlSubtitle',
        'House-code and production-module views stay synchronized.',
      ),
    );
    completionLabel = TextEditingController(
      text: text('completionLabel', 'Completion'),
    );
    paymentLabel = TextEditingController(text: text('paymentLabel', 'Payment'));
    needActionLabel = TextEditingController(
      text: text('needActionLabel', 'Need Attention'),
    );
    openLabel = TextEditingController(text: text('openLabel', 'Open'));

    columns = widget.state.controlColumns.clamp(1, 3);
    defaultView = widget.state.controlDefaultView;
    final configured = widget.state.controlModuleOrder;
    moduleOrder = configured.isEmpty
        ? RcRecordSchemas.schemas
              .where((schema) => schema.eventType != 'crewAttendance')
              .map((schema) => schema.eventType)
              .toList()
        : List<String>.from(configured);

    expressiveness = widget.state.uiExpressiveness * 100;
    depth = widget.state.uiDepth * 100;
    surfaceFinish = widget.state.uiSurfaceFinish;
    iconPack = widget.state.uiIconPack;
    iconShape = widget.state.uiIconShape;
    accentMood = widget.state.uiAccentMood;
    iconOverrides = Map<String, String>.from(widget.state.uiIconOverrides);
  }

  @override
  void dispose() {
    for (final controller in [
      appTitle,
      controlTitle,
      controlSubtitle,
      completionLabel,
      paymentLabel,
      needActionLabel,
      openLabel,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _editModuleOrder() async {
    final labels = {
      for (final schema in RcRecordSchemas.schemas)
        schema.eventType: schema.title,
    };
    final draft = List<String>.from(moduleOrder);
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => FractionallySizedBox(
          heightFactor: .86,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Arrange Control Of Works Modules',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, draft),
                      child: const Text('Apply'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ReorderableListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                  itemCount: draft.length,
                  onReorderItem: (oldIndex, newIndex) => setSheetState(() {
                    final item = draft.removeAt(oldIndex);
                    draft.insert(newIndex, item);
                  }),
                  itemBuilder: (context, index) {
                    final id = draft[index];
                    return Card(
                      key: ValueKey(id),
                      child: ListTile(
                        leading: const Icon(Icons.drag_handle_rounded),
                        title: Text(labels[id] ?? id),
                        subtitle: Text(id),
                        trailing: Text('${index + 1}'),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (result != null && mounted) setState(() => moduleOrder = result);
  }

  Future<void> _editIcons() async {
    final draft = Map<String, String>.from(iconOverrides);
    final slots = <String, String>{
      ...RcIconCatalog.coreSlots,
      for (final schema in RcRecordSchemas.schemas)
        'module.${schema.eventType}': schema.title,
    };

    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => FractionallySizedBox(
          heightFactor: .92,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Icon Studio',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const Text(
                            'Override navigation, header and Control module icons.',
                          ),
                        ],
                      ),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, draft),
                      child: const Text('Apply'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                  children: slots.entries.map((entry) {
                    final selected = draft[entry.key] ?? '';
                    return Card(
                      child: ListTile(
                        leading: RcIconWell(
                          icon: RcIconCatalog.resolveName(
                            selected.isEmpty ? null : selected,
                            Icons.auto_awesome_rounded,
                          ),
                          size: 46,
                        ),
                        title: Text(entry.value),
                        subtitle: Text(entry.key),
                        trailing: SizedBox(
                          width: 150,
                          child: DropdownButtonFormField<String>(
                            initialValue: selected,
                            isExpanded: true,
                            items: [
                              const DropdownMenuItem(
                                value: '',
                                child: Text('Use pack'),
                              ),
                              ...RcIconCatalog.availableNames.map(
                                (name) => DropdownMenuItem(
                                  value: name,
                                  child: Text(
                                    name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (value) => setSheetState(() {
                              if (value == null || value.isEmpty) {
                                draft.remove(entry.key);
                              } else {
                                draft[entry.key] = value;
                              }
                            }),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (result != null && mounted) setState(() => iconOverrides = result);
  }

  Future<void> _save() async {
    await widget.state.repository.saveUiConfig(
      configKey: 'global',
      config: {
        ...widget.state.remoteUiConfig,
        'appTitle': appTitle.text.trim(),
        'controlTitle': controlTitle.text.trim(),
        'controlSubtitle': controlSubtitle.text.trim(),
        'completionLabel': completionLabel.text.trim(),
        'paymentLabel': paymentLabel.text.trim(),
        'needActionLabel': needActionLabel.text.trim(),
        'openLabel': openLabel.text.trim(),
        'controlColumns': columns,
        'controlDefaultView': defaultView,
        'controlModuleOrder': moduleOrder,
        'uiExpressiveness': expressiveness.round(),
        'uiDepth': depth.round(),
        'uiSurfaceFinish': surfaceFinish,
        'uiIconPack': iconPack,
        'uiIconShape': iconShape,
        'uiAccentMood': accentMood,
        'uiIconOverrides': iconOverrides,
      },
    );
    await widget.state.refreshUiConfig();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Creative interface setup published.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
      children: [
        const RcPageHeading(
          eyebrow: 'Admin UI Studio',
          title: 'Creative Interface Controls',
          subtitle:
              'Control tactile depth, suede finish, icon pack, individual icons, color mood, tile density, text and expressive intensity without rebuilding the app.',
        ),
        const SizedBox(height: 12),
        RcExpressiveSurface(
          shape: RcSurfaceShape.hero,
          tone: theme.colorScheme.primaryContainer.withValues(alpha: .24),
          child: Row(
            children: [
              const RcIconWell(icon: Icons.palette_rounded, size: 58),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live style preview',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${surfaceFinish.toUpperCase()} • '
                      '${expressiveness.round()}% expressive • '
                      '${depth.round()}% depth • $iconPack icons',
                    ),
                  ],
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: _save,
                icon: const Icon(Icons.publish_rounded),
                label: const Text('Publish'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text('Visual expression', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Text('Expressiveness ${expressiveness.round()}%'),
        Slider(
          value: expressiveness,
          min: 25,
          max: 100,
          divisions: 15,
          label: '${expressiveness.round()}%',
          onChanged: (value) => setState(() => expressiveness = value),
        ),
        Text('Depth & press relief ${depth.round()}%'),
        Slider(
          value: depth,
          min: 20,
          max: 100,
          divisions: 16,
          label: '${depth.round()}%',
          onChanged: (value) => setState(() => depth = value),
        ),
        const SizedBox(height: 8),
        RcResponsiveGrid(
          minTileWidth: 230,
          children: [
            DropdownButtonFormField<String>(
              initialValue: surfaceFinish,
              decoration: const InputDecoration(labelText: 'Surface finish'),
              items: const [
                DropdownMenuItem(
                  value: 'suede',
                  child: Text('Soft Suede / Matte'),
                ),
                DropdownMenuItem(value: 'clean', child: Text('Clean Minimal')),
                DropdownMenuItem(value: 'soft', child: Text('Soft Cloud')),
              ],
              onChanged: (value) =>
                  setState(() => surfaceFinish = value ?? 'suede'),
            ),
            DropdownButtonFormField<String>(
              initialValue: accentMood,
              decoration: const InputDecoration(labelText: 'Accent mood'),
              items: const [
                DropdownMenuItem(value: 'red', child: Text('Red Cross')),
                DropdownMenuItem(value: 'ocean', child: Text('Ocean Blue')),
                DropdownMenuItem(value: 'forest', child: Text('Field Green')),
                DropdownMenuItem(value: 'violet', child: Text('Violet')),
                DropdownMenuItem(value: 'gold', child: Text('Warm Gold')),
                DropdownMenuItem(value: 'teal', child: Text('Teal')),
              ],
              onChanged: (value) => setState(() => accentMood = value ?? 'red'),
            ),
            DropdownButtonFormField<String>(
              initialValue: iconPack,
              decoration: const InputDecoration(labelText: 'Icon pack'),
              items: const [
                DropdownMenuItem(
                  value: 'rounded',
                  child: Text('Expressive Rounded'),
                ),
                DropdownMenuItem(
                  value: 'builder',
                  child: Text('Construction / Builder'),
                ),
                DropdownMenuItem(value: 'bold', child: Text('Bold Creative')),
              ],
              onChanged: (value) =>
                  setState(() => iconPack = value ?? 'rounded'),
            ),
            DropdownButtonFormField<String>(
              initialValue: iconShape,
              decoration: const InputDecoration(labelText: 'Icon container'),
              items: const [
                DropdownMenuItem(value: 'squircle', child: Text('Squircle')),
                DropdownMenuItem(value: 'circle', child: Text('Circle')),
                DropdownMenuItem(value: 'pill', child: Text('Pill')),
                DropdownMenuItem(value: 'soft', child: Text('Soft Square')),
              ],
              onChanged: (value) =>
                  setState(() => iconShape = value ?? 'squircle'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _editIcons,
          icon: const Icon(Icons.auto_awesome_rounded),
          label: Text(
            'Customize Icons${iconOverrides.isEmpty ? '' : ' • ${iconOverrides.length} overrides'}',
          ),
        ),
        const SizedBox(height: 20),
        Text('Text & Control layout', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        for (final entry in <(TextEditingController, String)>[
          (appTitle, 'App title'),
          (controlTitle, 'Control heading'),
          (controlSubtitle, 'Control subtitle'),
          (openLabel, 'Open tile label'),
          (needActionLabel, 'Need Attention tile label'),
          (completionLabel, 'Completion tile label'),
          (paymentLabel, 'Payment tile label'),
        ]) ...[
          TextField(
            controller: entry.$1,
            decoration: InputDecoration(labelText: entry.$2),
          ),
          const SizedBox(height: 9),
        ],
        DropdownButtonFormField<int>(
          initialValue: columns,
          decoration: const InputDecoration(labelText: 'Control tile columns'),
          items: const [1, 2, 3]
              .map(
                (value) => DropdownMenuItem(
                  value: value,
                  child: Text('$value columns'),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => columns = value ?? 2),
        ),
        const SizedBox(height: 9),
        DropdownButtonFormField<String>(
          initialValue: defaultView,
          decoration: const InputDecoration(labelText: 'Default Control view'),
          items: const [
            DropdownMenuItem(value: 'houses', child: Text('House Codes')),
            DropdownMenuItem(
              value: 'modules',
              child: Text('Production Modules'),
            ),
          ],
          onChanged: (value) => setState(() => defaultView = value ?? 'houses'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _editModuleOrder,
          icon: const Icon(Icons.reorder_rounded),
          label: const Text('Arrange Production Module Tiles'),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.publish_outlined),
          label: const Text('Publish Creative UI Setup'),
        ),
      ],
    );
  }
}

class _CommunityStudio extends StatefulWidget {
  const _CommunityStudio({required this.state});
  final AppState state;

  @override
  State<_CommunityStudio> createState() => _CommunityStudioState();
}

class _CommunityStudioState extends State<_CommunityStudio> {
  late Future<List<ProductionRecord>> future;

  @override
  void initState() {
    super.initState();
    future = widget.state.repository.communityRecords(
      widget.state.profile!,
      limit: 200,
    );
  }

  Future<void> _refresh() async {
    setState(
      () => future = widget.state.repository.communityRecords(
        widget.state.profile!,
        limit: 200,
      ),
    );
    await future;
  }

  Future<void> _create() async {
    final saved = await showCommunityComposer(
      context,
      widget.state,
      adminMode: true,
    );
    if (saved == true) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<List<ProductionRecord>>(
      future: future,
      builder: (context, snap) {
        final records = (snap.data ?? const <ProductionRecord>[])
            .where((record) => record.eventType == 'communityPost')
            .toList();
        final live = records.where((record) {
          final type = '${record.item['mediaType'] ?? ''}'.toLowerCase();
          return type == 'live stream' ||
              type == 'microsoft teams' ||
              type == 'zoom';
        }).length;
        final upcoming = records.where((record) {
          final start = DateTime.tryParse('${record.item['eventStart'] ?? ''}');
          return start != null && start.isAfter(DateTime.now());
        }).length;

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
            children: [
              RcPageHeading(
                eyebrow: 'Community control',
                title: 'Events, Media & Live Studio',
                subtitle:
                    'Publish meetings, upcoming events, YouTube, Teams, Zoom, livestreams, images, files, links and featured community content.',
                trailing: FilledButton.icon(
                  onPressed: _create,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Create'),
                ),
              ),
              const SizedBox(height: 12),
              RcResponsiveGrid(
                minTileWidth: 160,
                children: [
                  _CommunityAdminMetric(
                    'Published',
                    '${records.length}',
                    Icons.campaign_rounded,
                    theme.colorScheme.primary,
                  ),
                  _CommunityAdminMetric(
                    'Upcoming',
                    '$upcoming',
                    Icons.event_rounded,
                    RcColors.blue,
                  ),
                  _CommunityAdminMetric(
                    'Live / meeting',
                    '$live',
                    Icons.sensors_rounded,
                    RcColors.danger,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (records.isEmpty &&
                  snap.connectionState != ConnectionState.waiting)
                const RcExpressiveSurface(
                  child: Text('No Community items are published yet.'),
                ),
              ...records.map(
                (record) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: RcExpressiveSurface(
                    shape: RcSurfaceShape.offset,
                    child: Row(
                      children: [
                        RcIconWell(
                          icon: record.item['featured'] == true
                              ? Icons.auto_awesome_rounded
                              : Icons.campaign_rounded,
                          color: record.item['featured'] == true
                              ? RcColors.gold
                              : theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                record.title,
                                style: theme.textTheme.titleMedium,
                              ),
                              Text(
                                '${record.item['category'] ?? 'Update'} • '
                                '${record.item['mediaType'] ?? 'No media'} • '
                                '${record.parish.isEmpty ? 'All Parishes' : record.parish}',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (action) async {
                            if (action == 'delete') {
                              await widget.state.repository.deleteCommunityPost(
                                record.id,
                              );
                              await _refresh();
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CommunityAdminMetric extends StatelessWidget {
  const _CommunityAdminMetric(this.label, this.value, this.icon, this.color);
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => RcExpressiveSurface(
    shape: RcSurfaceShape.offset,
    tone: color.withValues(alpha: .07),
    child: Row(
      children: [
        RcIconWell(icon: icon, color: color),
        const SizedBox(width: 10),
        Expanded(child: Text(label)),
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

class _NotificationCentre extends StatefulWidget {
  const _NotificationCentre({required this.state});
  final AppState state;

  @override
  State<_NotificationCentre> createState() => _NotificationCentreState();
}

class _NotificationCentreState extends State<_NotificationCentre> {
  final subject = TextEditingController();
  final body = TextEditingController();
  final emails = TextEditingController();
  final house = TextEditingController();
  final selectedParishes = <String>{};
  String? role;
  String priority = 'Normal';
  String category = 'General';
  bool allUsers = false;
  bool busy = false;

  @override
  void dispose() {
    subject.dispose();
    body.dispose();
    emails.dispose();
    house.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final recipients = <Map<String, dynamic>>[];
    if (allUsers) recipients.add({'type': 'all', 'value': 'all'});
    for (final parish in selectedParishes) {
      recipients.add({'type': 'parish', 'value': parish});
    }
    if (role != null && role!.isNotEmpty) {
      recipients.add({'type': 'role', 'value': role});
    }
    for (final email in emails.text.split(RegExp(r'[\s,;]+'))) {
      if (email.contains('@')) {
        recipients.add({'type': 'email', 'value': email.trim()});
      }
    }

    if (recipients.isEmpty ||
        subject.text.trim().isEmpty ||
        body.text.trim().isEmpty) {
      _snack('Choose at least one target and enter a subject and message.');
      return;
    }

    setState(() => busy = true);
    try {
      await widget.state.repository.sendMessage(
        profile: widget.state.profile!,
        subject: subject.text.trim(),
        body: body.text.trim(),
        recipients: recipients,
        houseCode: house.text.trim().isEmpty
            ? null
            : house.text.trim().toUpperCase(),
        priority: priority,
        category: category,
      );
      _snack('Notification published.');
      subject.clear();
      body.clear();
      emails.clear();
      house.clear();
      setState(() {
        selectedParishes.clear();
        role = null;
        allUsers = false;
      });
    } catch (_) {
      _snack('Notification could not be published.');
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
      children: [
        const RcPageHeading(
          eyebrow: 'Targeted communication',
          title: 'Notification Centre',
          subtitle:
              'Send one operational notice to individuals, roles, multiple parishes or all users in any combination.',
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('All Users'),
          value: allUsers,
          onChanged: (v) => setState(() => allUsers = v),
        ),
        Text('Parishes', style: Theme.of(context).textTheme.titleMedium),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: RcApp.parishes
              .map(
                (p) => FilterChip(
                  label: Text(p),
                  selected: selectedParishes.contains(p),
                  onSelected: (selected) => setState(() {
                    if (selected) {
                      selectedParishes.add(p);
                    } else {
                      selectedParishes.remove(p);
                    }
                  }),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String?>(
          initialValue: role,
          decoration: const InputDecoration(
            labelText: 'Role target (optional)',
          ),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('No Role Target'),
            ),
            ...RcApp.roles.map(
              (r) => DropdownMenuItem<String?>(value: r, child: Text(r)),
            ),
          ],
          onChanged: (v) => setState(() => role = v),
        ),
        const SizedBox(height: 9),
        TextField(
          controller: emails,
          decoration: const InputDecoration(
            labelText: 'Individual emails (comma separated)',
          ),
        ),
        const SizedBox(height: 9),
        TextField(
          controller: house,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Linked house code (optional)',
          ),
        ),
        const SizedBox(height: 9),
        TextField(
          controller: subject,
          decoration: const InputDecoration(labelText: 'Subject'),
        ),
        const SizedBox(height: 9),
        TextField(
          controller: body,
          minLines: 4,
          maxLines: 8,
          decoration: const InputDecoration(labelText: 'Message'),
        ),
        const SizedBox(height: 9),
        DropdownButtonFormField<String>(
          initialValue: category,
          decoration: const InputDecoration(labelText: 'Notification Category'),
          items:
              const [
                    'General',
                    'Push Notice',
                    'Production Alert',
                    'Call To Action',
                    'Signature Required',
                    'House Update',
                    'Safety Alert',
                    'Payment Alert',
                    'Completion Alert',
                    'Meeting',
                    'Event',
                  ]
                  .map(
                    (value) =>
                        DropdownMenuItem(value: value, child: Text(value)),
                  )
                  .toList(),
          onChanged: (value) => setState(() => category = value!),
        ),
        const SizedBox(height: 9),
        DropdownButtonFormField<String>(
          initialValue: priority,
          decoration: const InputDecoration(labelText: 'Priority'),
          items: const [
            'Normal',
            'Action required',
            'Urgent',
          ].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
          onChanged: (v) => setState(() => priority = v!),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: busy ? null : _send,
          icon: const Icon(Icons.notifications_active_outlined),
          label: Text(busy ? 'Publishing…' : 'Publish Notification'),
        ),
        const SizedBox(height: 8),
        const Text(
          'Publishing creates the live RC SOW message event and automatically enters the existing push-dispatch pipeline for registered devices.',
        ),
      ],
    );
  }
}

class _StaffDirectory extends StatelessWidget {
  const _StaffDirectory({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: state.repository.staffDirectory(),
      builder: (context, snap) {
        final staff = snap.data ?? const <Map<String, dynamic>>[];
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
          children: [
            const RcPageHeading(
              eyebrow: 'Workforce database',
              title: 'Staff By Parish & Role',
              subtitle:
                  'Approved staff accounts feed crew assignment and staff-name choices in operational forms.',
            ),
            const SizedBox(height: 12),
            if (staff.isEmpty &&
                snap.connectionState != ConnectionState.waiting)
              const RcExpressiveSurface(
                child: Text('No approved staff are visible in this scope.'),
              ),
            ...staff.map(
              (row) => Card(
                child: ListTile(
                  leading: const Icon(Icons.badge_outlined),
                  title: Text(
                    '${row['full_name'] ?? row['email'] ?? 'Staff Member'}',
                  ),
                  subtitle: Text(
                    '${row['email']}\n${row['role']} • ${row['parish']}',
                  ),
                  isThreeLine: true,
                  trailing: Icon(
                    row['active'] == true
                        ? Icons.check_circle_outline
                        : Icons.pause_circle_outline,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TrackerConfig extends StatefulWidget {
  const _TrackerConfig({required this.state});
  final AppState state;

  @override
  State<_TrackerConfig> createState() => _TrackerConfigState();
}

class _TrackerConfigState extends State<_TrackerConfig> {
  String parish = 'Hanover';
  String provider = 'Google Drive';
  final url = TextEditingController();
  List<Map<String, dynamic>> sources = const [];
  bool loading = true;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    url.dispose();
    super.dispose();
  }

  Map<String, dynamic>? get current {
    for (final row in sources) {
      if ('${row['parish'] ?? ''}' == parish) return row;
    }
    return null;
  }

  Future<void> _refresh() async {
    try {
      final rows = await widget.state.repository.liveTrackers(
        widget.state.profile!,
      );
      if (!mounted) return;
      sources = rows;
      _loadCurrent();
      setState(() => loading = false);
    } catch (error) {
      if (!mounted) return;
      setState(() => loading = false);
      _snack('Tracker configuration could not load: $error');
    }
  }

  void _loadCurrent() {
    final row = current;
    final stored = '${row?['provider'] ?? ''}';
    provider = stored == 'OneDrive' || stored == 'SharePoint'
        ? 'OneDrive'
        : stored == 'Other'
        ? 'Direct URL'
        : 'Google Drive';
    url.text = '${row?['url'] ?? ''}';
  }

  void _selectParish(String value) {
    parish = value;
    _loadCurrent();
    setState(() {});
  }

  bool get _validUrl {
    final uri = Uri.tryParse(url.text.trim());
    return uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.isNotEmpty;
  }

  Future<void> _save() async {
    if (!_validUrl) {
      _snack('Enter a valid workbook URL.');
      return;
    }
    setState(() => busy = true);
    try {
      await widget.state.repository.setParishLiveTrackerSource(
        parish: parish,
        provider: provider,
        url: url.text.trim(),
      );
      await _refresh();
      _snack('$parish Live Tracker source saved.');
    } catch (error) {
      _snack('Tracker source could not be saved: $error');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _sync() async {
    if (!_validUrl) {
      _snack('Save a valid workbook URL before syncing.');
      return;
    }
    setState(() => busy = true);
    try {
      await widget.state.repository.setParishLiveTrackerSource(
        parish: parish,
        provider: provider,
        url: url.text.trim(),
      );
      final result = await widget.state.repository.syncParishLiveTracker(
        parish,
      );
      await _refresh();
      _snack(
        '$parish synced: ${result['houses'] ?? 0} houses, '
        '${(result['clusterSheets'] as List? ?? const []).length} clusters, '
        '${result['inventoryRows'] ?? 0} inventory items.',
      );
    } catch (error) {
      _snack('Live Tracker API sync failed: $error');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _open() async {
    final uri = Uri.tryParse(url.text.trim());
    if (uri == null) return;
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) _snack('The tracker workbook could not be opened.');
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
    final row = current;
    final status = '${row?['last_sync_status'] ?? 'Never synced'}';
    final clusters = (row?['cluster_count'] as num?)?.toInt() ?? 0;
    final inventory = (row?['inventory_count'] as num?)?.toInt() ?? 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
      children: [
        const RcPageHeading(
          eyebrow: 'Dedicated parish source',
          title: 'Live Tracker API',
          subtitle:
              'Configure a separate production/inventory workbook for each parish. This is NOT the Shelter beneficiary file and it does NOT feed the map.',
        ),
        const SizedBox(height: 12),
        RcExpressiveSurface(
          tone: theme.colorScheme.primaryContainer.withValues(alpha: .4),
          child: const Text(
            'Expected workbook: cluster worksheets with House ID, Finished, Started, BOQ, SOW, Contract, verification, rejection, comments and links; plus an optional Storage worksheet with dated IN/OUT stock movements.',
          ),
        ),
        const SizedBox(height: 12),
        Text('Parish', style: theme.textTheme.titleMedium),
        const SizedBox(height: 7),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: RcApp.parishes.map((value) {
            final configured = sources.any(
              (source) =>
                  '${source['parish'] ?? ''}' == value &&
                  '${source['url'] ?? ''}'.trim().isNotEmpty,
            );
            return FilterChip(
              selected: parish == value,
              avatar: Icon(
                configured
                    ? Icons.cloud_done_outlined
                    : Icons.cloud_off_outlined,
                size: 18,
              ),
              label: Text(value),
              onSelected: busy ? null : (_) => _selectParish(value),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          key: ValueKey('$parish-$provider'),
          initialValue: provider,
          decoration: const InputDecoration(labelText: 'API / File Provider'),
          items: const ['Google Drive', 'OneDrive', 'Direct URL']
              .map(
                (value) => DropdownMenuItem(value: value, child: Text(value)),
              )
              .toList(),
          onChanged: busy ? null : (value) => setState(() => provider = value!),
        ),
        const SizedBox(height: 9),
        TextField(
          controller: url,
          enabled: !busy,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            labelText: 'Live Tracker workbook URL',
            hintText: 'Google Drive, OneDrive or direct XLSX link',
            prefixIcon: Icon(Icons.link),
          ),
        ),
        const SizedBox(height: 12),
        RcExpressiveSurface(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$parish API Status',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        RcStatusPill(
                          label: status.toUpperCase(),
                          color: status.toLowerCase() == 'success'
                              ? RcColors.success
                              : status.toLowerCase().contains('fail')
                              ? RcColors.danger
                              : RcColors.warning,
                        ),
                        RcStatusPill(
                          label: '$clusters clusters',
                          color: RcColors.purple,
                        ),
                        RcStatusPill(
                          label: '$inventory inventory items',
                          color: RcColors.success,
                        ),
                      ],
                    ),
                    if ('${row?['last_sync_message'] ?? ''}'
                        .trim()
                        .isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('${row!['last_sync_message']}'),
                    ],
                  ],
                ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: busy ? null : _sync,
              icon: const Icon(Icons.sync_rounded),
              label: Text(busy ? 'Syncing…' : 'Save & Sync API'),
            ),
            FilledButton.tonalIcon(
              onPressed: busy ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save Source'),
            ),
            OutlinedButton.icon(
              onPressed: url.text.trim().isEmpty ? null : _open,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open Workbook'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const RcExpressiveSurface(
          child: Text(
            'Google Drive uses the server-side RC SOW Drive API/service account. OneDrive uses Microsoft Graph when private-file credentials are configured, with share-link download fallback. Live Tracker sync never writes beneficiary GPS or map records.',
          ),
        ),
      ],
    );
  }
}

class _ParishMapConfig extends StatefulWidget {
  const _ParishMapConfig({required this.state});
  final AppState state;

  @override
  State<_ParishMapConfig> createState() => _ParishMapConfigState();
}

class _ParishMapConfigState extends State<_ParishMapConfig> {
  String parish = 'Hanover';
  final url = TextEditingController();
  List<Map<String, dynamic>> sources = const [];
  bool loading = true;
  bool busy = false;

  Map<String, dynamic>? get current {
    for (final row in sources) {
      if ('${row['parish'] ?? ''}' == parish) return row;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    url.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final rows = await widget.state.repository.parishMapSources(
        widget.state.profile!,
        includeDisabled: true,
      );
      if (!mounted) return;
      sources = rows;
      url.text = '${current?['url'] ?? ''}';
      setState(() => loading = false);
    } catch (error) {
      if (!mounted) return;
      setState(() => loading = false);
      _snack('Parish maps could not be loaded: $error');
    }
  }

  void _selectParish(String value) {
    parish = value;
    url.text = '${current?['url'] ?? ''}';
    setState(() {});
  }

  bool get validUrl {
    final uri = Uri.tryParse(url.text.trim());
    return uri != null &&
        uri.scheme == 'https' &&
        uri.host.contains('google.com') &&
        uri.path.contains('/maps/d/');
  }

  Future<void> _save() async {
    if (!validUrl) {
      _snack('Paste the Google My Maps viewer/share URL for $parish.');
      return;
    }
    setState(() => busy = true);
    try {
      await widget.state.repository.setParishMapSource(
        parish: parish,
        url: url.text.trim(),
      );
      await _refresh();
      _snack('$parish map source saved.');
    } catch (error) {
      _snack('Map source could not be saved: $error');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _sync() async {
    if (!validUrl) {
      _snack('Enter a valid Google My Maps URL first.');
      return;
    }
    setState(() => busy = true);
    try {
      await widget.state.repository.setParishMapSource(
        parish: parish,
        url: url.text.trim(),
      );
      final result = await widget.state.repository.syncParishMap(parish);
      await _refresh();
      _snack(
        '$parish map synced: ${result['points'] ?? 0} points, '
        '${result['linkedHouseCodes'] ?? 0} linked house codes.',
      );
    } catch (error) {
      _snack('Google My Maps sync failed: $error');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _open() async {
    final uri = Uri.tryParse(url.text.trim());
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
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
    final source = current;
    final status = '${source?['last_sync_status'] ?? 'Never synced'}';
    final points = (source?['point_count'] as num?)?.toInt() ?? 0;
    final linked = (source?['linked_house_count'] as num?)?.toInt() ?? 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
      children: [
        const RcPageHeading(
          eyebrow: 'Field navigation',
          title: 'Parish Google My Maps',
          subtitle:
              'Every parish has its own independent Google My Maps URL. '
              'Map coordinates come from that parish map and are joined to '
              'Shelter beneficiary information by house code.',
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: RcApp.parishes.map((value) {
            final configured = sources.any(
              (row) =>
                  '${row['parish'] ?? ''}' == value &&
                  '${row['url'] ?? ''}'.trim().isNotEmpty,
            );
            return FilterChip(
              selected: parish == value,
              avatar: Icon(
                configured ? Icons.map_rounded : Icons.map_outlined,
                size: 18,
              ),
              label: Text(value),
              onSelected: busy ? null : (_) => _selectParish(value),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: url,
          enabled: !busy,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(
            labelText: '$parish Google My Maps URL',
            hintText: 'https://www.google.com/maps/d/viewer?mid=...',
            prefixIcon: const Icon(Icons.map_outlined),
          ),
        ),
        const SizedBox(height: 12),
        RcExpressiveSurface(
          tone: theme.colorScheme.surfaceContainerLow,
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$parish Map Status',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        RcStatusPill(
                          label: status.toUpperCase(),
                          color: status.toLowerCase() == 'success'
                              ? RcColors.success
                              : status.toLowerCase().contains('fail')
                              ? RcColors.danger
                              : RcColors.warning,
                        ),
                        RcStatusPill(
                          label: '$points map points',
                          color: RcColors.blue,
                        ),
                        RcStatusPill(
                          label: '$linked linked houses',
                          color: RcColors.success,
                        ),
                      ],
                    ),
                    if ('${source?['last_sync_message'] ?? ''}'
                        .trim()
                        .isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('${source!['last_sync_message']}'),
                    ],
                  ],
                ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: busy ? null : _sync,
              icon: const Icon(Icons.sync_rounded),
              label: Text(busy ? 'Syncing…' : 'Save & Sync Map'),
            ),
            FilledButton.tonalIcon(
              onPressed: busy ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save URL'),
            ),
            OutlinedButton.icon(
              onPressed: url.text.trim().isEmpty ? null : _open,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open My Map'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const RcExpressiveSurface(
          child: Text(
            'Map is separate from Live Tracker. Live Tracker remains '
            'production/inventory. Parish Map remains field navigation.',
          ),
        ),
      ],
    );
  }
}
