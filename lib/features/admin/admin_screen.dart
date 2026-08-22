import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/design_tokens.dart';
import '../../core/rc_policy.dart';
import '../../models/app_models.dart';
import '../../services/document_service.dart';
import '../../state/app_state.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key, required this.state});
  final AppState state;

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late final TabController tabs;
  late final RcDocumentService docs;
  late Future<List<Map<String, dynamic>>> requests;
  late Future<List<ManagedUserRecord>> users;

  @override
  void initState() {
    super.initState();
    tabs = TabController(length: 3, vsync: this);
    docs = RcDocumentService(Supabase.instance.client);
    _refresh();
  }

  @override
  void dispose() {
    tabs.dispose();
    super.dispose();
  }

  void _refresh() {
    requests = widget.state.repository.registrationRequests();
    users = widget.state.repository.managedUsers();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (widget.state.profile?.canViewAdmin != true) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin Dashboard')),
        body: const Center(child: Text('Admin access only')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        bottom: TabBar(
          controller: tabs,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Approvals'),
            Tab(text: 'Users & Access'),
            Tab(text: 'Style & Templates'),
          ],
        ),
      ),
      body: TabBarView(
        controller: tabs,
        children: [_approvals(), _users(), _styleTemplates()],
      ),
    );
  }

  Widget _approvals() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: requests,
      builder: (context, snap) {
        final list = snap.data ?? const <Map<String, dynamic>>[];
        return RefreshIndicator(
          onRefresh: () async {
            _refresh();
            await requests;
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '${list.length} registration approvals',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              if (snap.connectionState == ConnectionState.waiting)
                const LinearProgressIndicator(),
              ...list.map(
                (r) => Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person_add_alt_1),
                    ),
                    title: Text(
                      '${r['full_name'] ?? r['email'] ?? 'New user'}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      '${r['requested_role'] ?? 'Role pending'} • '
                      '${r['requested_parish'] ?? 'Parish pending'}',
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (action) => _approval(
                        action,
                        '${r['user_id']}',
                      ),
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'approve',
                          child: Text('Approve'),
                        ),
                        PopupMenuItem(
                          value: 'reject',
                          child: Text('Reject'),
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

  Future<void> _approval(String action, String userId) async {
    if (action == 'approve') {
      await widget.state.repository.approveRegistration(userId);
    } else {
      await widget.state.repository.rejectRegistration(userId);
    }
    _refresh();
  }

  Widget _users() {
    return FutureBuilder<List<ManagedUserRecord>>(
      future: users,
      builder: (context, snap) {
        final list = snap.data ?? const <ManagedUserRecord>[];
        return RefreshIndicator(
          onRefresh: () async {
            _refresh();
            await users;
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'User access management',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              const Text(
                'Block, suspend, restore, promote roles, change parish and '
                'assign management privileges.',
              ),
              const SizedBox(height: 12),
              if (snap.connectionState == ConnectionState.waiting)
                const LinearProgressIndicator(),
              ...list.map(
                (u) => Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          u.active ? RcColors.successSoft : RcColors.dangerSoft,
                      child: Icon(
                        u.active ? Icons.person : Icons.block,
                        color: u.active ? RcColors.success : RcColors.danger,
                      ),
                    ),
                    title: Text(
                      u.displayName,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      '${u.role} • ${u.parish}\n'
                      '${u.active ? 'Active' : 'Suspended'}',
                    ),
                    isThreeLine: true,
                    onTap: () => _editUser(u),
                    trailing: PopupMenuButton<String>(
                      onSelected: (action) => _quickAccess(action, u),
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit privileges'),
                        ),
                        PopupMenuItem(
                          value: u.active ? 'suspend' : 'restore',
                          child: Text(u.active ? 'Suspend' : 'Restore'),
                        ),
                        const PopupMenuItem(
                          value: 'block',
                          child: Text('Block'),
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

  Future<void> _quickAccess(
    String action,
    ManagedUserRecord user,
  ) async {
    if (action == 'edit') {
      await _editUser(user);
      return;
    }
    await widget.state.repository.manageUserAccess(
      userId: user.userId,
      action: action,
    );
    _refresh();
  }

  Future<void> _editUser(ManagedUserRecord user) async {
    var role = RcPolicy.roles.contains(user.role)
        ? user.role
        : RcPolicy.roles.first;
    var parish = RcPolicy.parishes.contains(user.parish)
        ? user.parish
        : RcPolicy.parishes.first;
    final privileges = <String, dynamic>{...user.privileges};
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
            18,
            4,
            18,
            20 + MediaQuery.viewInsetsOf(ctx).bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  user.displayName,
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: role,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: RcPolicy.roles
                      .map(
                        (x) => DropdownMenuItem(value: x, child: Text(x)),
                      )
                      .toList(),
                  onChanged: (v) => setSheet(() => role = v!),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: parish,
                  decoration: const InputDecoration(labelText: 'Primary parish'),
                  items: RcPolicy.parishes
                      .map(
                        (x) => DropdownMenuItem(value: x, child: Text(x)),
                      )
                      .toList(),
                  onChanged: (v) => setSheet(() => parish = v!),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Privileges',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                ...RcPolicy.privilegeLabels.entries.map(
                  (entry) => SwitchListTile(
                    title: Text(entry.value),
                    value: privileges[entry.key] == true,
                    onChanged: (v) => setSheet(
                      () => privileges[entry.key] = v,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: () async {
                    await widget.state.repository.manageUserAccess(
                      userId: user.userId,
                      action: 'update',
                      role: role,
                      parish: parish,
                      privileges: privileges,
                    );
                    if (ctx.mounted) Navigator.pop(ctx, true);
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Save access'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (saved == true) _refresh();
  }

  Widget _styleTemplates() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Display Design DNA',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        const Text(
          'Choose an RC SOW UI template without changing the underlying '
          'production workflow.',
        ),
        const SizedBox(height: 12),
        ...RcDesignStyle.values.map(
          (style) => ListTile(
            leading: Icon(
              widget.state.designStyle == style
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
            ),
            title: Text(style.label),
            onTap: () => widget.state.setSetting('designStyle', style),
          ),
        ),
        const Divider(height: 28),
        const Text(
          'Document templates',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        const Text(
          'Authorized management users can replace active templates without '
          'rebuilding the APK.',
        ),
        const SizedBox(height: 12),
        ...RcTemplates.all.map(
          (template) => Card(
            child: ListTile(
              title: Text(
                template.title,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(template.fileName),
              trailing: PopupMenuButton<String>(
                onSelected: (action) => _templateAction(action, template),
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'save',
                    child: Text('Download template'),
                  ),
                  PopupMenuItem(
                    value: 'share',
                    child: Text('Share / email'),
                  ),
                  PopupMenuItem(
                    value: 'replace',
                    child: Text('Replace template'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _templateAction(
    String action,
    RcTemplateDefinition template,
  ) async {
    try {
      if (action == 'save') await docs.saveTemplate(template);
      if (action == 'share') await docs.shareTemplate(template);
      if (action == 'replace') {
        await docs.replaceTemplate(
          template: template,
          profile: widget.state.profile!,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${template.title}: $action completed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Template action failed: $e')),
        );
      }
    }
  }
}
