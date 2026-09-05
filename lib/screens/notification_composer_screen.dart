import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/models.dart';
import '../core/routes.dart';
import '../core/widgets.dart';

class NotificationComposerScreen extends StatefulWidget {
  const NotificationComposerScreen({super.key});

  @override
  State<NotificationComposerScreen> createState() => _NotificationComposerScreenState();
}

class _NotificationComposerScreenState extends State<NotificationComposerScreen> {
  final _title = TextEditingController();
  final _message = TextEditingController();
  final Set<String> _audiences = <String>{};
  String _kind = 'Meeting';
  String _priority = 'Action';
  String _houseCode = '';
  DateTime? _scheduledFor;

  @override
  void dispose() {
    _title.dispose();
    _message.dispose();
    super.dispose();
  }

  bool _canBroadcast(String role) {
    final normalized = role.toLowerCase();
    return normalized.contains('admin') ||
        normalized.contains('regional') ||
        normalized.contains('construction') ||
        normalized.contains('account');
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 730)),
      initialDate: _scheduledFor ?? now,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledFor ?? now),
    );
    if (time == null) return;
    setState(() {
      _scheduledFor = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  void _send() {
    final state = AppScope.of(context);
    if (!_canBroadcast(state.role)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your role does not have broadcast permission.')),
      );
      return;
    }
    if (_title.text.trim().isEmpty || _message.text.trim().isEmpty || _audiences.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a title, message and at least one audience.')),
      );
      return;
    }
    state.createOperationalNotification(
      title: _title.text.trim(),
      detail: _message.text.trim(),
      priority: _priority,
      kind: _kind,
      audiences: _audiences.toList(growable: false),
      houseCode: _houseCode.isEmpty ? null : _houseCode,
      scheduledFor: _scheduledFor,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final audienceOptions = <String>[
      'Individual',
      'Crew',
      'Parish',
      'Regional Supervisors',
      'Construction Specialists',
      'Accounts',
      'All operational users',
    ];
    return Scaffold(
      appBar: RcAppBar(title: const Text('Send notification')),
      body: Form(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    RcPageHeading(
                      eyebrow: 'Targeted communication',
                      title: 'Meeting & production alert',
                      description:
                          'Send one notification to any combination of individuals, crews, parishes or management groups.',
                      action: RcStatusChip(label: state.role.toUpperCase()),
                    ),
                    const SizedBox(height: 18),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: <Widget>[
                            TextField(
                              controller: _title,
                              decoration: const InputDecoration(
                                labelText: 'Notification title',
                                prefixIcon: Icon(Icons.title),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _message,
                              minLines: 4,
                              maxLines: 7,
                              decoration: const InputDecoration(
                                labelText: 'Message / meeting details',
                                alignLabelWithHint: true,
                                prefixIcon: Icon(Icons.notes_outlined),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _kind,
                                    decoration: const InputDecoration(labelText: 'Type'),
                                    items: const <String>[
                                      'Meeting',
                                      'Site visit',
                                      'Material alert',
                                      'Approval',
                                      'Deadline',
                                      'Operational',
                                    ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                                    onChanged: (v) => setState(() => _kind = v ?? _kind),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _priority,
                                    decoration: const InputDecoration(labelText: 'Priority'),
                                    items: const <String>['Info', 'Action', 'High']
                                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                                        .toList(),
                                    onChanged: (v) => setState(() => _priority = v ?? _priority),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: _houseCode,
                              decoration: const InputDecoration(
                                labelText: 'House context (optional)',
                                prefixIcon: Icon(Icons.house_outlined),
                              ),
                              items: <DropdownMenuItem<String>>[
                                const DropdownMenuItem<String>(value: '', child: Text('No single house')),
                                ...state.houses.map(
                                  (house) => DropdownMenuItem<String>(
                                    value: house.code,
                                    child: Text('${house.code} • ${house.beneficiary}'),
                                  ),
                                ),
                              ],
                              onChanged: (value) => setState(() => _houseCode = value),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const RcSectionHeader(
                      title: 'Audience',
                      subtitle: 'Choose one or multiple targets.',
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: audienceOptions.map((audience) {
                        return FilterChip(
                          avatar: Icon(
                            audience.startsWith('Parish')
                                ? Icons.location_on_outlined
                                : audience == 'Crew'
                                    ? Icons.groups_2_outlined
                                    : audience == 'Individual'
                                        ? Icons.person_outline
                                        : Icons.campaign_outlined,
                            size: 18,
                          ),
                          label: Text(audience),
                          selected: _audiences.contains(audience),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _audiences.add(audience);
                              } else {
                                _audiences.remove(audience);
                                if (audience == 'Individual') {
                                  _audiences.removeWhere(
                                    (value) => value.startsWith('Individual • '),
                                  );
                                } else if (audience == 'Crew') {
                                  _audiences.removeWhere(
                                    (value) => value.startsWith('Crew • '),
                                  );
                                } else if (audience == 'Parish') {
                                  _audiences.removeWhere(
                                    (value) => value.startsWith('Parish • '),
                                  );
                                }
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    if (_audiences.contains('Individual')) ...<Widget>[
                      const SizedBox(height: 14),
                      const Text(
                        'Individuals',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 7),
                      Wrap(
                        spacing: 7,
                        runSpacing: 7,
                        children: state.team.map((person) {
                          final target = 'Individual • ${person.name}';
                          return FilterChip(
                            avatar: const Icon(Icons.person_outline, size: 16),
                            label: Text('${person.name} • ${person.role}'),
                            selected: _audiences.contains(target),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _audiences.add(target);
                                } else {
                                  _audiences.remove(target);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                    if (_audiences.contains('Crew')) ...<Widget>[
                      const SizedBox(height: 14),
                      const Text(
                        'Crews / house teams',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 7),
                      Wrap(
                        spacing: 7,
                        runSpacing: 7,
                        children: state.houses.map((house) {
                          final target = 'Crew • ${house.code}';
                          return FilterChip(
                            avatar: const Icon(Icons.groups_2_outlined, size: 16),
                            label: Text('${house.code} • ${house.team.length} crew'),
                            selected: _audiences.contains(target),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _audiences.add(target);
                                } else {
                                  _audiences.remove(target);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                    if (_audiences.contains('Parish')) ...<Widget>[
                      const SizedBox(height: 14),
                      const Text(
                        'Parishes',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 7),
                      Wrap(
                        spacing: 7,
                        runSpacing: 7,
                        children: jamaicaParishes.map((parish) {
                          final target = 'Parish • $parish';
                          return FilterChip(
                            avatar: const Icon(Icons.location_on_outlined, size: 16),
                            label: Text(parish),
                            selected: _audiences.contains(target),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _audiences.add(target);
                                } else {
                                  _audiences.remove(target);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.schedule_outlined),
                        title: Text(
                          _scheduledFor == null
                              ? 'Send immediately'
                              : 'Scheduled ${_scheduledFor!.toLocal()}',
                        ),
                        subtitle: const Text('Set a future meeting or reminder time if needed.'),
                        trailing: TextButton(
                          onPressed: _pickDateTime,
                          child: Text(_scheduledFor == null ? 'SCHEDULE' : 'CHANGE'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _send,
                      icon: const Icon(Icons.send_outlined),
                      label: const Text('SEND NOTIFICATION'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
