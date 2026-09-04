import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../core/widgets.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final Map<String, bool> _active = <String, bool>{
    'Maria Green': true,
    'Andre Brown': true,
    'Kim Ross': true,
    'David Clarke': true,
  };
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final people = state.team
        .where(
          (person) =>
              person.name.toLowerCase().contains(_query.toLowerCase()) ||
              person.role.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();
    return Scaffold(
      appBar: RcAppBar(
        title: const Text('Access Management'),
        actions: <Widget>[
          FilledButton.tonalIcon(
            onPressed: () => _showInvite(context),
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('INVITE'),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const RcPageHeading(
                    eyebrow: 'Admin / Security',
                    title: 'User access & privileges',
                    description:
                        'Role, parish scope and account state are explicit and auditable.',
                  ),
                  const SizedBox(height: 18),
                  RcResponsiveGrid(
                    minItemWidth: 190,
                    childAspectRatio: 1.25,
                    children: <Widget>[
                      RcMetricTile(
                        label: 'Total users',
                        value: '${state.team.length}',
                        icon: Icons.groups_outlined,
                        color: RcColors.brand,
                      ),
                      RcMetricTile(
                        label: 'Active accounts',
                        value:
                            '${_active.values.where((value) => value).length}',
                        icon: Icons.verified_user_outlined,
                        color: RcColors.success,
                      ),
                      RcMetricTile(
                        label: 'Admin roles',
                        value: '2',
                        icon: Icons.admin_panel_settings_outlined,
                        color: RcColors.info,
                      ),
                      RcMetricTile(
                        label: 'Pending review',
                        value: '1',
                        icon: Icons.pending_actions_outlined,
                        color: RcColors.warning,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    onChanged: (value) => setState(() => _query = value),
                    decoration: const InputDecoration(
                      labelText: 'Search user or role',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: 14),
                  for (final person in people) ...<Widget>[
                    Card(
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          child: Text(
                            person.name
                                .split(' ')
                                .map((part) => part[0])
                                .take(2)
                                .join(),
                          ),
                        ),
                        title: Text(
                          person.name,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text('${person.role} • ${person.parish}'),
                        trailing: RcStatusChip(
                          label: (_active[person.name] ?? true)
                              ? 'ACTIVE'
                              : 'SUSPENDED',
                          compact: true,
                          tone: (_active[person.name] ?? true)
                              ? RcStatusTone.success
                              : RcStatusTone.error,
                        ),
                        childrenPadding: const EdgeInsets.fromLTRB(
                          18,
                          0,
                          18,
                          18,
                        ),
                        children: <Widget>[
                          DropdownButtonFormField<String>(
                            value: person.role,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Role',
                            ),
                            items: const <String>[
                              'Site Supervisor',
                              'Regional Site Supervisor',
                              'Construction Specialist',
                              'Technical Admin',
                              'Community Admin',
                              'Admin',
                              'Carpenter Lead',
                            ]
                                .map(
                                  (role) => DropdownMenuItem<String>(
                                    value: role,
                                    child: Text(
                                      role,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              state.updateTeamAccess(
                                name: person.name,
                                newRole: value,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Role updated and added to the audit trail.',
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: person.parish,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Parish scope',
                            ),
                            items: const <String>[
                              'Hanover',
                              'St. Elizabeth',
                              'Westmoreland',
                              'St. James',
                              'All Parishes',
                            ]
                                .map(
                                  (parish) => DropdownMenuItem<String>(
                                    value: parish,
                                    child: Text(
                                      parish,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              state.updateTeamAccess(
                                name: person.name,
                                newParish: value,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Parish scope updated and added to the audit trail.',
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: const <Widget>[
                              FilterChip(
                                label: Text('Scope'),
                                selected: true,
                                onSelected: null,
                              ),
                              FilterChip(
                                label: Text('Control'),
                                selected: true,
                                onSelected: null,
                              ),
                              FilterChip(
                                label: Text('Evidence'),
                                selected: true,
                                onSelected: null,
                              ),
                              FilterChip(
                                label: Text('Payments'),
                                selected: false,
                                onSelected: null,
                              ),
                              FilterChip(
                                label: Text('Admin'),
                                selected: false,
                                onSelected: null,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Audit history opened.',
                                      ),
                                    ),
                                  ),
                                  icon: const Icon(Icons.history),
                                  label: const Text('AUDIT'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: FilledButton.tonalIcon(
                                  onPressed: () => setState(
                                    () => _active[person.name] =
                                        !(_active[person.name] ?? true),
                                  ),
                                  icon: Icon(
                                    (_active[person.name] ?? true)
                                        ? Icons.block
                                        : Icons.check_circle_outline,
                                  ),
                                  label: Text(
                                    (_active[person.name] ?? true)
                                        ? 'SUSPEND'
                                        : 'RESTORE',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showInvite(BuildContext context) {
    String email = '';
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Invite operational user'),
        content: TextField(
          onChanged: (value) => email = value,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Work email'),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () {
              final address = email.trim();
              if (address.isEmpty) return;
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Invitation prepared for $address.',
                  ),
                ),
              );
            },
            child: const Text('SEND INVITE'),
          ),
        ],
      ),
    );
  }
}

class AdminTemplatesScreen extends StatelessWidget {
  const AdminTemplatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const templates = <_TemplateRecord>[
      _TemplateRecord(
        'Beneficiary Scope Printout',
        'v4.2',
        'Published',
        '28 Aug 2026',
      ),
      _TemplateRecord(
        'Notice of Completion',
        'v3.1',
        'Published',
        '26 Aug 2026',
      ),
      _TemplateRecord('Payment Submission', 'v2.8', 'Draft', '25 Aug 2026'),
      _TemplateRecord(
        'Monitoring Checklist',
        'v5.0',
        'Published',
        '24 Aug 2026',
      ),
      _TemplateRecord(
        'Control Workbook Export',
        'v6.3',
        'Published',
        '21 Aug 2026',
      ),
    ];
    return Scaffold(
      appBar: RcAppBar(
        title: const Text('Template Management'),
        actions: <Widget>[
          FilledButton.tonalIcon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('New template draft created.')),
            ),
            icon: const Icon(Icons.add),
            label: const Text('NEW TEMPLATE'),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 950),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const RcPageHeading(
                    eyebrow: 'Admin / Documents',
                    title: 'Templates & versioning',
                    description:
                        'Published operational documents retain version history, preview and rollback controls.',
                  ),
                  const SizedBox(height: 18),
                  Card(
                    child: Column(
                      children: templates.map((template) {
                        return ListTile(
                          minVerticalPadding: 13,
                          leading: Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: RcColors.brandSoft,
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: const Icon(
                              Icons.description_outlined,
                              color: RcColors.brand,
                            ),
                          ),
                          title: Text(
                            template.name,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(
                            '${template.version} • Updated ${template.updated}',
                          ),
                          trailing: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            children: <Widget>[
                              RcStatusChip(
                                label: template.status.toUpperCase(),
                                compact: true,
                                tone: template.status == 'Published'
                                    ? RcStatusTone.success
                                    : RcStatusTone.warning,
                              ),
                              PopupMenuButton<String>(
                                onSelected: (value) =>
                                    ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '$value: ${template.name}',
                                    ),
                                  ),
                                ),
                                itemBuilder: (_) =>
                                    const <PopupMenuEntry<String>>[
                                  PopupMenuItem<String>(
                                    value: 'Preview',
                                    child: Text('Preview'),
                                  ),
                                  PopupMenuItem<String>(
                                    value: 'Duplicate',
                                    child: Text('Duplicate'),
                                  ),
                                  PopupMenuItem<String>(
                                    value: 'Version history',
                                    child: Text('Version history'),
                                  ),
                                  PopupMenuItem<String>(
                                    value: 'Publish',
                                    child: Text('Publish'),
                                  ),
                                ],
                              ),
                            ],
                          ),
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
    );
  }
}

class _TemplateRecord {
  const _TemplateRecord(this.name, this.version, this.status, this.updated);
  final String name;
  final String version;
  final String status;
  final String updated;
}

class GmailScreen extends StatefulWidget {
  const GmailScreen({super.key});

  @override
  State<GmailScreen> createState() => _GmailScreenState();
}

class _GmailScreenState extends State<GmailScreen> {
  bool _compose = false;
  final _to = TextEditingController(text: 'regional.supervisor@redcross.org');
  final _subject = TextEditingController();
  final _body = TextEditingController();

  @override
  void dispose() {
    _to.dispose();
    _subject.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final house = AppScope.of(context).selectedHouse;
    if (_subject.text.isEmpty)
      _subject.text = '${house.code} — Operational update';
    return Scaffold(
      appBar: RcAppBar(
        title: Text(
          _compose ? 'Compose institutional email' : 'Institutional Gmail',
        ),
      ),
      floatingActionButton: _compose
          ? null
          : FloatingActionButton.extended(
              onPressed: () => setState(() => _compose = true),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('COMPOSE'),
            ),
      body:
          _compose ? _buildCompose(context, house.code) : _buildInbox(context),
    );
  }

  Widget _buildInbox(BuildContext context) {
    const messages = <(String, String, String)>[
      (
        'Maria Green',
        'H12 material transfer approval',
        'Please attach the latest request and inventory gap.',
      ),
      (
        'Finance Operations',
        'H2 payment package returned',
        'Beneficiary signature needs a clearer scan.',
      ),
      (
        'Technical Team',
        'Hanover weekly production review',
        'Meeting notes and action list attached.',
      ),
      (
        'Logistics',
        'Central depot stock synchronization',
        'Inventory synchronization completed successfully.',
      ),
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 850),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const RcPageHeading(
                  eyebrow: 'Institutional Communication',
                  title: 'Inbox',
                  description:
                      'Email remains linked to operational houses and records where appropriate.',
                ),
                const SizedBox(height: 18),
                Card(
                  child: Column(
                    children: messages.map((message) {
                      return ListTile(
                        leading: CircleAvatar(child: Text(message.$1[0])),
                        title: Text(
                          message.$1,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text('${message.$2}\n${message.$3}'),
                        isThreeLine: true,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Opened: ${message.$2}')),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompose(BuildContext context, String houseCode) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                RcPageHeading(
                  eyebrow: 'Linked to $houseCode',
                  title: 'Compose message',
                  description:
                      'Institutional email with explicit house context and attachments.',
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _to,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'To'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _subject,
                  decoration: const InputDecoration(labelText: 'Subject'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _body,
                  minLines: 10,
                  maxLines: 16,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, RcRoutes.evidence),
                  icon: const Icon(Icons.attach_file),
                  label: const Text('ATTACH HOUSE FILE'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _compose = false),
                        child: const Text('SAVE DRAFT'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          if (_to.text.trim().isEmpty ||
                              _subject.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Recipient and subject are required.',
                                ),
                              ),
                            );
                            return;
                          }
                          setState(() => _compose = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Institutional email queued for delivery.',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.send_outlined),
                        label: const Text('SEND'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
