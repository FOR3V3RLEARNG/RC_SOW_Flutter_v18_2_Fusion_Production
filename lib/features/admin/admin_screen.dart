import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;

import '../../core/app_constants.dart';
import '../../core/design_tokens.dart';
import '../../core/record_schemas.dart';
import '../../core/rc_components.dart';
import '../../models/app_models.dart';
import '../../state/app_state.dart';
import '../../services/shelter_import_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key, required this.state, this.initialTab = 0});
  final AppState state;
  final int initialTab;

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late final TabController tabs;

  @override
  void initState() {
    super.initState();
    tabs = TabController(
      length: 6,
      initialIndex: widget.initialTab.clamp(0, 5).toInt(),
      vsync: this,
    );
  }

  @override
  void dispose() {
    tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.state.profile!;
    if (!profile.canViewAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin')),
        body: const Center(child: Text('Admin privilege is required.')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Control Centre'),
        bottom: TabBar(
          controller: tabs,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Users', icon: Icon(Icons.manage_accounts_outlined)),
            Tab(text: 'Beneficiaries', icon: Icon(Icons.home_work_outlined)),
            Tab(text: 'Templates', icon: Icon(Icons.description_outlined)),
            Tab(text: 'Forms', icon: Icon(Icons.dynamic_form_outlined)),
            Tab(text: 'Parish Maps', icon: Icon(Icons.map_outlined)),
            Tab(text: 'Suggestions', icon: Icon(Icons.lightbulb_outline)),
          ],
        ),
      ),
      body: TabBarView(
        controller: tabs,
        children: [
          _UserAccess(state: widget.state),
          _BeneficiarySourceAdmin(state: widget.state),
          _TemplateAdmin(state: widget.state),
          _FormStudio(state: widget.state),
          _ParishMapAdmin(state: widget.state),
          _SuggestionInbox(state: widget.state),
        ],
      ),
    );
  }
}

class _UserAccess extends StatefulWidget {
  const _UserAccess({required this.state});
  final AppState state;

  @override
  State<_UserAccess> createState() => _UserAccessState();
}

class _UserAccessState extends State<_UserAccess> {
  late Future<List<ManagedUser>> future;
  String search = '';

  @override
  void initState() {
    super.initState();
    future = widget.state.repository.managedUsers();
  }

  Future<void> refresh() async {
    setState(() => future = widget.state.repository.managedUsers());
    await future;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: refresh,
      child: FutureBuilder<List<ManagedUser>>(
        future: future,
        builder: (_, snap) {
          final users = (snap.data ?? const <ManagedUser>[])
              .where(
                (u) =>
                    search.isEmpty ||
                    '${u.fullName} ${u.email} ${u.role} ${u.parish}'
                        .toLowerCase()
                        .contains(search.toLowerCase()),
              )
              .toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
            children: [
              const RcPageHeading(
                eyebrow: 'Governance',
                title: 'User access & privilege levels',
                subtitle:
                    'Approve, block, suspend, restore, promote and tailor operational privileges.',
              ),
              const SizedBox(height: 14),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Search users',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (v) => setState(() => search = v),
              ),
              const SizedBox(height: 14),
              ...users.map(
                (user) => Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: RcExpressiveSurface(
                    shape: RcSurfaceShape.offset,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          child: Text(
                            (user.fullName.isEmpty ? user.email : user.fullName)
                                    .isEmpty
                                ? '?'
                                : (user.fullName.isEmpty
                                          ? user.email
                                          : user.fullName)[0]
                                      .toUpperCase(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.fullName.isEmpty
                                    ? user.email
                                    : user.fullName,
                                style: theme.textTheme.titleMedium,
                              ),
                              Text(
                                '${user.email}\n${user.role} • ${user.parish}',
                                style: theme.textTheme.bodySmall,
                              ),
                              const SizedBox(height: 7),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  RcStatusPill(
                                    label: user.registrationStatus
                                        .toUpperCase(),
                                    color: user.active && user.approved
                                        ? RcColors.success
                                        : RcColors.warning,
                                  ),
                                  if (user.privileges['viewAllParishes'] ==
                                      true)
                                    const RcStatusPill(
                                      label: 'ALL PARISHES',
                                      icon: Icons.public,
                                      color: RcColors.blue,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (action) => _action(user, action),
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Role / parish / privileges'),
                            ),
                            if (user.registrationStatus == 'suspended' ||
                                user.registrationStatus == 'blocked' ||
                                !user.active)
                              const PopupMenuItem(
                                value: 'restore',
                                child: Text('Restore access'),
                              )
                            else ...[
                              const PopupMenuItem(
                                value: 'suspend',
                                child: Text('Suspend account'),
                              ),
                              const PopupMenuItem(
                                value: 'block',
                                child: Text('Block account'),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (snap.hasError)
                RcExpressiveSurface(
                  tone: theme.colorScheme.errorContainer,
                  child: const Text(
                    'User management could not be loaded. Confirm the v20.3 Supabase migration is applied.',
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _action(ManagedUser user, String action) async {
    if (action == 'edit') {
      await _editUser(user);
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          '${action[0].toUpperCase()}${action.substring(1)} ${user.fullName.isEmpty ? user.email : user.fullName}?',
        ),
        content: Text(
          action == 'restore'
              ? 'This restores approved access.'
              : 'This immediately restricts access to RC SOW until an Admin restores the account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await widget.state.repository.manageUser(
      userId: user.userId,
      action: action,
    );
    await refresh();
  }

  Future<void> _editUser(ManagedUser user) async {
    String role = RcApp.roles.contains(user.role)
        ? user.role
        : 'Site Supervisor';
    String parish = RcApp.parishes.contains(user.parish)
        ? user.parish
        : 'Hanover';
    final privileges = <String, dynamic>{...user.privileges};
    const privilegeKeys = [
      'viewAllParishes',
      'editControl',
      'submitScope',
      'approveScope',
      'exportData',
      'raiseIssues',
      'reviewControl',
      'reviewPayments',
      'approvePayments',
      'approveNotice',
      'messageAllUsers',
      'viewAuditLog',
      'manageFolders',
      'manageCommunity',
      'manageCrew',
      'verifyAttendance',
      'manageForms',
      'manageBeneficiarySources',
      'viewAssignedHouses',
      'editOwnAttendance',
      'submitFieldRequests',
      'uploadEvidence',
    ];
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (_, setSheetState) => FractionallySizedBox(
          heightFactor: .9,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: ListView(
              children: [
                Text(
                  'Role & privileges',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: role,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: RcApp.roles
                      .map((x) => DropdownMenuItem(value: x, child: Text(x)))
                      .toList(),
                  onChanged: (v) => setSheetState(() => role = v!),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: RcApp.managementRoles.contains(role)
                      ? 'All Parishes'
                      : parish,
                  decoration: const InputDecoration(labelText: 'Parish'),
                  items:
                      (RcApp.managementRoles.contains(role)
                              ? const ['All Parishes']
                              : RcApp.parishes)
                          .map(
                            (x) => DropdownMenuItem(value: x, child: Text(x)),
                          )
                          .toList(),
                  onChanged: RcApp.managementRoles.contains(role)
                      ? null
                      : (v) => setSheetState(() => parish = v!),
                ),
                const SizedBox(height: 14),
                Text(
                  'Privilege overrides',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                ...privilegeKeys.map(
                  (key) => SwitchListTile.adaptive(
                    title: Text(_pretty(key)),
                    value: privileges[key] == true,
                    onChanged: (v) => setSheetState(() => privileges[key] = v),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => Navigator.pop(context, true),
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Apply access policy'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (saved != true) return;
    await widget.state.repository.manageUser(
      userId: user.userId,
      action: 'promote',
      role: role,
      parish: parish,
    );
    await widget.state.repository.manageUser(
      userId: user.userId,
      action: 'set_privileges',
      privileges: privileges,
    );
    await refresh();
  }

  String _pretty(String value) => value
      .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(1)}')
      .trim();
}

class _BeneficiarySourceAdmin extends StatefulWidget {
  const _BeneficiarySourceAdmin({required this.state});
  final AppState state;

  @override
  State<_BeneficiarySourceAdmin> createState() =>
      _BeneficiarySourceAdminState();
}

class _BeneficiarySourceAdminState extends State<_BeneficiarySourceAdmin> {
  late Future<List<Map<String, dynamic>>> future;

  @override
  void initState() {
    super.initState();
    future = widget.state.repository.beneficiarySources();
  }

  Future<void> refresh() async {
    setState(() => future = widget.state.repository.beneficiarySources());
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (_, snap) {
        final sources = snap.data ?? const <Map<String, dynamic>>[];
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
          children: [
            RcPageHeading(
              eyebrow: 'Protected source data',
              title: 'Beneficiary data by parish',
              subtitle:
                  'Each parish can have a separate Shelter assessment workbook. The raw file and full row payload stay in protected Supabase storage; operational screens autofill safe house data and remain editable.',
              trailing: FilledButton.tonalIcon(
                onPressed: _import,
                icon: const Icon(Icons.upload_file),
                label: const Text('Import XLSX'),
              ),
            ),
            const SizedBox(height: 14),
            if (sources.isEmpty)
              const RcExpressiveSurface(
                child: Text(
                  'No parish source workbook is registered in this environment yet.',
                ),
              ),
            ...sources.map(
              (source) => Card(
                child: ListTile(
                  leading: const Icon(Icons.table_view_outlined),
                  title: Text('${source['parish'] ?? ''}'),
                  subtitle: Text(
                    '${source['file_name'] ?? ''}\n${source['row_count'] ?? 0} imported beneficiary rows',
                  ),
                  isThreeLine: true,
                  trailing: RcStatusPill(
                    label: source['active'] == false ? 'INACTIVE' : 'ACTIVE',
                    color: source['active'] == false
                        ? RcColors.warning
                        : RcColors.success,
                  ),
                ),
              ),
            ),
            if (snap.hasError)
              const RcExpressiveSurface(
                child: Text(
                  'Beneficiary source registry requires the included v20.3 Supabase migration.',
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _import() async {
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: true,
      allowMultiple: false,
    );
    if (picked.isEmpty) return;
    final file = picked.single;
    final bytes = file.bytes;
    if (bytes == null) return;
    if (!mounted) return;
    String parish = 'Hanover';
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          title: const Text('Assign beneficiary workbook'),
          content: DropdownButtonFormField<String>(
            initialValue: parish,
            decoration: const InputDecoration(labelText: 'Parish'),
            items: RcApp.parishes
                .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                .toList(),
            onChanged: (v) => setDialogState(() => parish = v!),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, parish),
              child: const Text('Import'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || selected == null) return;
    try {
      final parsed = ShelterImportService.parse(
        bytes: bytes,
        sourceName: file.name,
        fallbackParish: selected,
      );
      final client = widget.state.repository.client;
      final path =
          '$selected/${DateTime.now().millisecondsSinceEpoch}-${file.name.replaceAll(' ', '_')}';
      await client.storage
          .from('beneficiary-sources')
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );
      final count = await widget.state.repository.importBeneficiaryRows(
        parsed.rows,
      );
      await client.from('beneficiary_sources').upsert({
        'parish': selected,
        'file_name': file.name,
        'storage_path': path,
        'sheet_name': parsed.sheetName,
        'header_row': parsed.headerRow,
        'source_column_count': parsed.sourceColumnCount,
        'row_count': count,
        'active': true,
        'updated_by': client.auth.currentUser?.id,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'parish');
      if (mounted)
        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(
            content: Text('$count beneficiary rows imported for $selected.'),
          ),
        );
      await refresh();
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(this.context).showSnackBar(
          const SnackBar(
            content: Text(
              'Beneficiary workbook could not be imported. Confirm the Shelter workbook format and backend migration.',
            ),
          ),
        );
    }
  }
}

class _TemplateAdmin extends StatefulWidget {
  const _TemplateAdmin({required this.state});
  final AppState state;

  @override
  State<_TemplateAdmin> createState() => _TemplateAdminState();
}

class _TemplateAdminState extends State<_TemplateAdmin> {
  late Future<List<Map<String, dynamic>>> future;

  @override
  void initState() {
    super.initState();
    future = widget.state.repository.documentTemplates();
  }

  Future<void> refresh() async {
    setState(() => future = widget.state.repository.documentTemplates());
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (_, snap) {
        final templates = snap.data ?? const <Map<String, dynamic>>[];
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
          children: [
            RcPageHeading(
              eyebrow: 'Documents',
              title: 'Editable production templates',
              subtitle:
                  'Authorized Admin can replace the active Work Plan, SOW, Control, Monitoring, Completion and Payment source files without rebuilding the app.',
              trailing: FilledButton.tonalIcon(
                onPressed: _upload,
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload'),
              ),
            ),
            const SizedBox(height: 14),
            if (templates.isEmpty)
              const RcExpressiveSurface(
                child: Text(
                  'No server template overrides are registered. The packaged original templates remain the baseline.',
                ),
              ),
            ...templates.map(
              (t) => Card(
                child: ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: Text('${t['display_name'] ?? t['template_key']}'),
                  subtitle: Text(
                    '${t['file_name'] ?? ''}\nUpdated ${t['updated_at'] ?? ''}',
                  ),
                  trailing: RcStatusPill(
                    label: t['active'] == false ? 'INACTIVE' : 'ACTIVE',
                    color: t['active'] == false
                        ? RcColors.warning
                        : RcColors.success,
                  ),
                ),
              ),
            ),
            if (snap.hasError)
              const RcExpressiveSurface(
                child: Text(
                  'Server template registry is not available yet. Apply the included Supabase migration.',
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _upload() async {
    final result = await FilePicker.pickFiles(
      withData: true,
      allowedExtensions: ['xlsx', 'docx', 'pdf'],
      type: FileType.custom,
      allowMultiple: false,
    );
    if (result.isEmpty) return;
    final file = result.single;
    final bytes = file.bytes;
    if (bytes == null) return;
    const schemaNames = <String, String>{
      'work-plan': 'Work Plan',
      'scope': 'Scope of Work',
      'control-of-works': 'Control of Works',
      'monitoring': 'Monitoring Checklist',
      'notice-completion': 'Notice of Completion',
      'payment-request': 'Payment Request',
    };
    String key = schemaNames.keys.first;
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (_, setStateDialog) => AlertDialog(
          title: const Text('Assign template'),
          content: DropdownButtonFormField<String>(
            initialValue: key,
            decoration: const InputDecoration(labelText: 'Record type'),
            items: schemaNames.entries
                .map(
                  (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                )
                .toList(),
            onChanged: (v) => setStateDialog(() => key = v!),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Upload'),
            ),
          ],
        ),
      ),
    );
    if (saved != true) return;
    final path =
        '$key/${DateTime.now().millisecondsSinceEpoch}-${file.name.replaceAll(' ', '_')}';
    final client = widget.state.repository.client;
    await client.storage
        .from('document-templates')
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
    await client.from('document_templates').upsert({
      'template_key': key,
      'display_name': schemaNames[key],
      'file_name': file.name,
      'mime_type': _mime(file.extension ?? ''),
      'storage_path': path,
      'active': true,
      'updated_by': client.auth.currentUser?.id,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
    await refresh();
  }

  String _mime(String extension) => switch (extension.toLowerCase()) {
    'xlsx' =>
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'docx' =>
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    _ => 'application/pdf',
  };
}

class _FormStudio extends StatefulWidget {
  const _FormStudio({required this.state});
  final AppState state;

  @override
  State<_FormStudio> createState() => _FormStudioState();
}

class _FormStudioState extends State<_FormStudio> {
  late Future<List<Map<String, dynamic>>> future;
  @override
  void initState() {
    super.initState();
    future = widget.state.repository.customFormTemplates();
  }

  Future<void> refresh() async {
    setState(() => future = widget.state.repository.customFormTemplates());
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (_, snap) {
        final forms = snap.data ?? const <Map<String, dynamic>>[];
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
          children: [
            RcPageHeading(
              eyebrow: 'No-code records',
              title: 'Form Studio',
              subtitle:
                  'Create adjustable Add Record forms while keeping the built-in Red Cross source forms protected.',
              trailing: FilledButton.tonalIcon(
                onPressed: () => _edit(),
                icon: const Icon(Icons.add_rounded),
                label: const Text('New form'),
              ),
            ),
            const SizedBox(height: 14),
            ...RcRecordSchemas.schemas.map(
              (s) => Card(
                child: ListTile(
                  leading: Icon(s.icon),
                  title: Text(s.title),
                  subtitle: Text(
                    'Built-in • ${s.fields.length} fields • ${s.phase}',
                  ),
                  trailing: const Icon(Icons.lock_outline),
                ),
              ),
            ),
            ...forms.map(
              (form) => Card(
                child: ListTile(
                  leading: const Icon(Icons.dynamic_form_outlined),
                  title: Text('${form['title'] ?? ''}'),
                  subtitle: Text(
                    '${form['phase'] ?? ''} • ${form['event_type'] ?? ''}',
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (action) {
                      if (action == 'edit') _edit(existing: form);
                      if (action == 'delete') _delete('${form['id']}');
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ),
              ),
            ),
            if (snap.hasError)
              const RcExpressiveSurface(
                child: Text(
                  'Custom Form Studio requires the included v20.3 Supabase migration.',
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _edit({Map<String, dynamic>? existing}) async {
    final title = TextEditingController(text: '${existing?['title'] ?? ''}');
    final event = TextEditingController(
      text: '${existing?['event_type'] ?? 'custom:record'}',
    );
    String phase = '${existing?['phase'] ?? 'Plan'}';
    final fields = TextEditingController(
      text: _fieldsText(existing?['fields']),
    );
    final save = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          0,
          18,
          18 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                existing == null ? 'Create form' : 'Edit form',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: title,
                decoration: const InputDecoration(labelText: 'Form title'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: event,
                enabled: existing == null,
                decoration: const InputDecoration(labelText: 'Event key'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: phase,
                decoration: const InputDecoration(
                  labelText: 'Production phase',
                ),
                items:
                    const [
                          'Plan',
                          'Delivery',
                          'Quality',
                          'Close-out',
                          'Finance',
                        ]
                        .map((x) => DropdownMenuItem(value: x, child: Text(x)))
                        .toList(),
                onChanged: (v) => phase = v!,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: fields,
                minLines: 6,
                maxLines: 12,
                decoration: const InputDecoration(
                  labelText: 'Fields — one per line',
                  helperText:
                      'Format: key | Label | text/number/date/dropdown/checkbox/multiline/signature | required(optional)',
                ),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Save form'),
              ),
            ],
          ),
        ),
      ),
    );
    if (save == true && title.text.trim().isNotEmpty) {
      final rawEvent = event.text.trim();
      final normalizedEvent = rawEvent.startsWith('custom:')
          ? rawEvent
          : 'custom:${_slug(rawEvent)}';
      if (normalizedEvent == 'custom:' || _parseFields(fields.text).isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(this.context).showSnackBar(
            const SnackBar(
              content: Text(
                'A form needs a valid event key and at least one field.',
              ),
            ),
          );
        }
      } else {
        await widget.state.repository.saveCustomFormTemplate(
          templateId: existing?['id']?.toString(),
          title: title.text.trim(),
          eventType: normalizedEvent,
          phase: phase,
          fields: _parseFields(fields.text),
        );
        await refresh();
      }
    }
    title.dispose();
    event.dispose();
    fields.dispose();
  }

  String _fieldsText(Object? raw) {
    if (raw is! List)
      return 'houseCode | House number | text | required\nparish | Parish | dropdown | required';
    return raw
        .whereType<Map>()
        .map(
          (m) =>
              '${m['key']} | ${m['label']} | ${m['kind'] ?? 'text'} | ${m['required'] == true ? 'required' : ''}',
        )
        .join('\n');
  }

  List<Map<String, dynamic>> _parseFields(String value) => value
      .split('\n')
      .map((line) {
        final parts = line.split('|').map((x) => x.trim()).toList();
        if (parts.length < 2) return <String, dynamic>{};
        return {
          'key': parts[0],
          'label': parts[1],
          'kind': parts.length > 2 ? parts[2] : 'text',
          'required':
              parts.length > 3 && parts[3].toLowerCase().contains('required'),
          'options': parts.length > 4
              ? parts[4].split(',').map((x) => x.trim()).toList()
              : <String>[],
        };
      })
      .where((m) => m.isNotEmpty)
      .toList();

  String _slug(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');

  Future<void> _delete(String id) async {
    await widget.state.repository.deleteCustomFormTemplate(id);
    await refresh();
  }
}

class _ParishMapAdmin extends StatefulWidget {
  const _ParishMapAdmin({required this.state});
  final AppState state;
  @override
  State<_ParishMapAdmin> createState() => _ParishMapAdminState();
}

class _ParishMapAdminState extends State<_ParishMapAdmin> {
  final controllers = <String, TextEditingController>{};
  @override
  void dispose() {
    for (final c in controllers.values) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
      children: [
        const RcPageHeading(
          eyebrow: 'Maps',
          title: 'Parish map resources',
          subtitle:
              'Admin can manually set a live map/tracker URL per parish. Parish users see only their map; management can switch across all parishes.',
        ),
        const SizedBox(height: 14),
        ...RcApp.parishes.map((parish) {
          final controller = controllers.putIfAbsent(
            parish,
            TextEditingController.new,
          );
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: '$parish map URL',
                      prefixIcon: const Icon(Icons.link),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: () async {
                    final url = controller.text.trim();
                    if (url.isEmpty) return;
                    await widget.state.repository.setParishMapUrl(
                      parish: parish,
                      url: url,
                    );
                    if (mounted)
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(content: Text('$parish map saved.')),
                      );
                  },
                  icon: const Icon(Icons.save_outlined),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _SuggestionInbox extends StatelessWidget {
  const _SuggestionInbox({required this.state});
  final AppState state;
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ProductionRecord>>(
      future: state.repository.communityRecords(state.profile!, limit: 200),
      builder: (_, snap) {
        final suggestions = (snap.data ?? const <ProductionRecord>[])
            .where((r) => r.eventType == 'communitySuggestion')
            .toList();
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
          children: [
            const RcPageHeading(
              eyebrow: 'Community feedback',
              title: 'Suggestion inbox',
              subtitle:
                  'Read-only Community Board users send suggestions and event requests here for Admin review.',
            ),
            const SizedBox(height: 14),
            if (snap.connectionState == ConnectionState.waiting)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
            if (snap.hasError)
              RcExpressiveSurface(
                tone: Theme.of(context).colorScheme.errorContainer,
                child: const Text(
                  'Community suggestions could not be loaded. Check the connection and production migration, then retry.',
                ),
              ),
            if (!snap.hasError &&
                snap.connectionState != ConnectionState.waiting &&
                suggestions.isEmpty)
              const RcExpressiveSurface(
                child: Text('No community suggestions are waiting.'),
              ),
            if (!snap.hasError)
              ...suggestions.map(
                (r) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.lightbulb_outline),
                    title: Text(r.parish),
                    subtitle: Text('${r.item['body'] ?? r.summary}'),
                    trailing: RcStatusPill(
                      label: r.status.toUpperCase(),
                      color: RcColors.blue,
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
