import 'package:flutter/material.dart';

import '../../core/app_constants.dart';
import '../../core/design_tokens.dart';
import '../../core/rc_components.dart';
import '../../models/app_models.dart';
import '../../state/app_state.dart';

class CrewAssignmentPanel extends StatefulWidget {
  const CrewAssignmentPanel({
    super.key,
    required this.state,
    this.initialHouseCode,
    this.compact = false,
  });

  final AppState state;
  final String? initialHouseCode;
  final bool compact;

  @override
  State<CrewAssignmentPanel> createState() => _CrewAssignmentPanelState();
}

class _CrewAssignmentPanelState extends State<CrewAssignmentPanel> {
  late Future<_CrewAssignmentData> future;
  String? selectedHouse;
  String? selectedEmail;
  bool saving = false;

  UserProfile get profile => widget.state.profile!;

  @override
  void initState() {
    super.initState();
    selectedHouse = widget.initialHouseCode?.trim().toUpperCase();
    future = _load();
  }

  Future<_CrewAssignmentData> _load() async {
    final results = await Future.wait([
      widget.state.repository.houses(profile),
      widget.state.repository.activeUsers(),
      widget.state.repository.crewAssignments(houseCode: selectedHouse),
    ]);
    return _CrewAssignmentData(
      houses: results[0] as List<HouseRecord>,
      users: results[1] as List<Map<String, dynamic>>,
      assignments: results[2] as List<Map<String, dynamic>>,
    );
  }

  Future<void> _refresh() async {
    setState(() => future = _load());
    await future;
  }

  Future<void> _assign(_CrewAssignmentData data) async {
    final houseCode = selectedHouse;
    final email = selectedEmail;
    if (houseCode == null || email == null || houseCode.isEmpty || email.isEmpty) return;
    final house = data.houses.where((h) => h.code == houseCode).firstOrNull;
    final member = data.users.where((u) => '${u['email'] ?? ''}'.toLowerCase() == email.toLowerCase()).firstOrNull;
    if (house == null || member == null) return;
    final role = '${member['role'] ?? ''}';
    if (!RcApp.crewRoles.contains(role)) return;
    setState(() => saving = true);
    try {
      await widget.state.repository.assignCrew(
        houseCode: house.code,
        parish: house.parish,
        userId: '${member['user_id'] ?? ''}',
        email: '${member['email'] ?? ''}',
        memberName: '${member['full_name'] ?? member['email'] ?? ''}',
        role: role,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${member['full_name'] ?? member['email']} assigned to ${house.code}.')),
        );
      }
      await _refresh();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Crew assignment could not be saved. Check permissions and retry.')),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _remove(Map<String, dynamic> assignment) async {
    setState(() => saving = true);
    try {
      await widget.state.repository.assignCrew(
        houseCode: '${assignment['house_code'] ?? ''}',
        parish: '${assignment['parish'] ?? ''}',
        userId: '${assignment['user_id'] ?? ''}',
        email: '${assignment['email'] ?? ''}',
        memberName: '${assignment['member_name'] ?? ''}',
        role: '${assignment['role'] ?? ''}',
        active: false,
      );
      await _refresh();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Crew assignment could not be removed.')),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  String _initial(String value) => value.trim().isEmpty ? '?' : value.trim()[0].toUpperCase();

  @override
  Widget build(BuildContext context) {
    if (!profile.hasPrivilege('manageCrew')) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return FutureBuilder<_CrewAssignmentData>(
      future: future,
      builder: (context, snap) {
        final data = snap.data ?? const _CrewAssignmentData();
        final houses = data.houses;
        if ((selectedHouse == null || !houses.any((h) => h.code == selectedHouse)) && houses.isNotEmpty) {
          selectedHouse = widget.initialHouseCode != null && houses.any((h) => h.code == widget.initialHouseCode)
              ? widget.initialHouseCode
              : houses.first.code;
        }
        final selectedHouseRecord = houses.where((h) => h.code == selectedHouse).firstOrNull;
        final crew = data.users.where((u) {
          final role = '${u['role'] ?? ''}';
          if (!RcApp.crewRoles.contains(role)) return false;
          if (selectedHouseRecord == null || profile.canViewAllParishes) return true;
          return '${u['parish'] ?? ''}' == selectedHouseRecord.parish;
        }).toList();
        final assignments = data.assignments.where((a) => a['active'] != false).toList();

        return RcExpressiveSurface(
          shape: RcSurfaceShape.offset,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.groups_2_outlined, color: theme.colorScheme.primary),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('House crew assignment', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 2),
                        const Text('Connect the construction schedule to the actual Carpenter / Worker / Apprentice team.'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (snap.connectionState == ConnectionState.waiting)
                const LinearProgressIndicator()
              else if (houses.isEmpty)
                const Text('No active houses are available in your access scope.')
              else ...[
                DropdownButtonFormField<String>(
                  key: ValueKey('crew-house-${selectedHouse ?? ''}'),
                  initialValue: selectedHouse,
                  decoration: const InputDecoration(labelText: 'House'),
                  items: houses
                      .map((h) => DropdownMenuItem(value: h.code, child: Text('${h.code} • ${h.parish}')))
                      .toList(),
                  onChanged: saving
                      ? null
                      : (value) {
                          setState(() {
                            selectedHouse = value;
                            selectedEmail = null;
                            future = _load();
                          });
                        },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  key: ValueKey('crew-member-${selectedHouse ?? ''}-${selectedEmail ?? ''}'),
                  initialValue: crew.any((u) => '${u['email'] ?? ''}' == selectedEmail) ? selectedEmail : null,
                  decoration: const InputDecoration(labelText: 'Crew member'),
                  items: crew
                      .map(
                        (u) => DropdownMenuItem(
                          value: '${u['email'] ?? ''}',
                          child: Text('${u['full_name'] ?? u['email']} • ${u['role'] ?? ''}'),
                        ),
                      )
                      .toList(),
                  onChanged: saving ? null : (value) => setState(() => selectedEmail = value),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.tonalIcon(
                    onPressed: saving || selectedEmail == null ? null : () => _assign(data),
                    icon: const Icon(Icons.person_add_alt_1_outlined),
                    label: Text(saving ? 'Saving…' : 'Assign to house'),
                  ),
                ),
              ],
              if (assignments.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text('Current team', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                ...assignments.map(
                  (a) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: widget.compact,
                    leading: CircleAvatar(child: Text(_initial('${a['role'] ?? '?'}'))),
                    title: Text('${a['member_name'] ?? a['email'] ?? 'Crew member'}'),
                    subtitle: Text('${a['role'] ?? ''} • ${a['house_code'] ?? ''}'),
                    trailing: IconButton(
                      tooltip: 'Remove assignment',
                      onPressed: saving ? null : () => _remove(a),
                      icon: const Icon(Icons.person_remove_outlined),
                    ),
                  ),
                ),
              ],
              if (snap.hasError) ...[
                const SizedBox(height: 8),
                const Text('Crew assignments require the v20.3 workforce backend.', style: TextStyle(color: RcColors.warning)),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _CrewAssignmentData {
  const _CrewAssignmentData({
    this.houses = const [],
    this.users = const [],
    this.assignments = const [],
  });

  final List<HouseRecord> houses;
  final List<Map<String, dynamic>> users;
  final List<Map<String, dynamic>> assignments;
}

extension _CrewFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
