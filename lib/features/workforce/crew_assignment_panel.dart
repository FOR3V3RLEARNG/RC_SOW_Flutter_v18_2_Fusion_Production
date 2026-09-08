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
    final houses = await widget.state.repository.houses(profile);

    if ((selectedHouse == null ||
            !houses.any((house) => house.code == selectedHouse)) &&
        houses.isNotEmpty) {
      final preferred = widget.initialHouseCode?.trim().toUpperCase();
      selectedHouse =
          preferred != null && houses.any((house) => house.code == preferred)
          ? preferred
          : houses.first.code;
    }

    final selected = houses
        .where((house) => house.code == selectedHouse)
        .firstOrNull;

    final results = await Future.wait([
      widget.state.repository.crewDirectory(parish: selected?.parish),
      widget.state.repository.crewAssignments(houseCode: selectedHouse),
    ]);

    return _CrewAssignmentData(
      houses: houses,
      users: results[0] as List<Map<String, dynamic>>,
      assignments: results[1] as List<Map<String, dynamic>>,
    );
  }

  Future<void> _refresh() async {
    setState(() => future = _load());
    await future;
  }

  Future<void> _assign(_CrewAssignmentData data) async {
    final houseCode = selectedHouse;
    final email = selectedEmail;
    if (houseCode == null ||
        email == null ||
        houseCode.isEmpty ||
        email.isEmpty) {
      _snack('Select a house and crew member first.');
      return;
    }

    final house = data.houses.where((h) => h.code == houseCode).firstOrNull;
    final member = data.users
        .where(
          (u) => '${u['email'] ?? ''}'.toLowerCase() == email.toLowerCase(),
        )
        .firstOrNull;

    if (house == null || member == null) {
      _snack('Crew member or house is no longer available. Refresh and retry.');
      return;
    }

    final role = '${member['role'] ?? ''}';
    if (!RcApp.crewRoles.contains(role)) {
      _snack('Only Carpenter, Worker or Apprentice can be assigned as crew.');
      return;
    }

    setState(() => saving = true);
    try {
      await widget.state.repository.assignCrew(
        houseCode: house.code,
        parish: house.parish,
        userId: member['user_id']?.toString(),
        email: '${member['email'] ?? ''}',
        memberName: '${member['full_name'] ?? member['email'] ?? ''}',
        role: role,
      );

      _snack(
        '${member['full_name'] ?? member['email']} assigned to ${house.code}.',
      );
      selectedEmail = null;
      await _refresh();
    } catch (error) {
      _snack('Crew assignment could not be saved: $error');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _createAndAssign(_CrewAssignmentData data) async {
    if (!profile.canManageUsers) {
      _snack('Admin user-management privilege is required to create crew.');
      return;
    }

    final house = data.houses
        .where((candidate) => candidate.code == selectedHouse)
        .firstOrNull;
    if (house == null) {
      _snack('Choose a house first.');
      return;
    }

    final name = TextEditingController();
    final email = TextEditingController();
    var role = 'Carpenter';

    final create = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text('Add crew • ${house.code}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${house.parish} • Crew will be authorized by email and assigned immediately.',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Crew member name',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.alternate_email),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: role,
                  decoration: const InputDecoration(
                    labelText: 'Crew role',
                    prefixIcon: Icon(Icons.engineering_outlined),
                  ),
                  items: RcApp.crewRoles
                      .map(
                        (crewRole) => DropdownMenuItem(
                          value: crewRole,
                          child: Text(crewRole),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => role = value);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () {
                if (name.text.trim().isEmpty ||
                    !email.text.trim().contains('@')) {
                  return;
                }
                Navigator.pop(dialogContext, true);
              },
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: const Text('Create & assign'),
            ),
          ],
        ),
      ),
    );

    if (create != true) {
      name.dispose();
      email.dispose();
      return;
    }

    final memberName = name.text.trim();
    final memberEmail = email.text.trim().toLowerCase();

    setState(() => saving = true);
    try {
      await widget.state.repository.manageAuthorizedAccount(
        email: memberEmail,
        label: memberName,
        role: role,
        parish: house.parish,
        active: true,
      );

      await widget.state.repository.assignCrew(
        houseCode: house.code,
        parish: house.parish,
        userId: null,
        email: memberEmail,
        memberName: memberName,
        role: role,
      );

      _snack('$memberName created and assigned to ${house.code}.');
      await _refresh();
    } catch (error) {
      _snack('Crew member could not be created/assigned: $error');
    } finally {
      name.dispose();
      email.dispose();
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _remove(Map<String, dynamic> assignment) async {
    setState(() => saving = true);
    try {
      await widget.state.repository.assignCrew(
        houseCode: '${assignment['house_code'] ?? ''}',
        parish: '${assignment['parish'] ?? ''}',
        userId: assignment['user_id']?.toString(),
        email: '${assignment['email'] ?? ''}',
        memberName: '${assignment['member_name'] ?? ''}',
        role: '${assignment['role'] ?? ''}',
        active: false,
      );
      _snack('${assignment['member_name'] ?? assignment['email']} removed.');
      await _refresh();
    } catch (error) {
      _snack('Crew assignment could not be removed: $error');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _initial(String value) =>
      value.trim().isEmpty ? '?' : value.trim()[0].toUpperCase();

  @override
  Widget build(BuildContext context) {
    if (!profile.canManageCrew) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return FutureBuilder<_CrewAssignmentData>(
      future: future,
      builder: (context, snap) {
        final data = snap.data ?? const _CrewAssignmentData();
        final houses = data.houses;

        final selectedHouseRecord = houses
            .where((h) => h.code == selectedHouse)
            .firstOrNull;

        final crew = data.users.where((u) {
          final role = '${u['role'] ?? ''}';
          if (!RcApp.crewRoles.contains(role)) return false;
          if (selectedHouseRecord == null || profile.canViewAllParishes) {
            return true;
          }
          return '${u['parish'] ?? ''}' == selectedHouseRecord.parish;
        }).toList();

        final assignments = data.assignments
            .where((a) => a['active'] != false)
            .toList();

        return RcExpressiveSurface(
          shape: RcSurfaceShape.offset,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.groups_2_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'House Crew',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Authorize and assign the Carpenter / Worker / Apprentice team to this house.',
                        ),
                      ],
                    ),
                  ),
                  if (profile.canManageUsers)
                    IconButton.filledTonal(
                      tooltip: 'Create crew member',
                      onPressed:
                          saving || selectedHouseRecord == null
                          ? null
                          : () => _createAndAssign(data),
                      icon: const Icon(Icons.person_add_alt_1_outlined),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              if (snap.connectionState == ConnectionState.waiting)
                const LinearProgressIndicator()
              else if (snap.hasError)
                RcExpressiveSurface(
                  tone: theme.colorScheme.errorContainer,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Crew data could not be loaded.',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text('${snap.error}'),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _refresh,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              else if (houses.isEmpty)
                const Text(
                  'No active houses are available in your access scope.',
                )
              else ...[
                DropdownButtonFormField<String>(
                  key: ValueKey('crew-house-${selectedHouse ?? ''}'),
                  initialValue: selectedHouse,
                  decoration: const InputDecoration(
                    labelText: 'House',
                    prefixIcon: Icon(Icons.home_work_outlined),
                  ),
                  items: houses
                      .map(
                        (h) => DropdownMenuItem(
                          value: h.code,
                          child: Text('${h.code} • ${h.parish}'),
                        ),
                      )
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

                if (crew.isEmpty)
                  RcExpressiveSurface(
                    tone: theme.colorScheme.surfaceContainerLow,
                    child: Row(
                      children: [
                        const Icon(Icons.person_search_outlined),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            profile.canManageUsers
                                ? 'No authorized Carpenter, Worker or Apprentice is available for ${selectedHouseRecord?.parish ?? 'this parish'}. Tap + to create one.'
                                : 'No authorized crew is available for ${selectedHouseRecord?.parish ?? 'this parish'}. Ask an Admin to authorize the crew email first.',
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  DropdownButtonFormField<String>(
                    key: ValueKey(
                      'crew-member-${selectedHouse ?? ''}-${selectedEmail ?? ''}',
                    ),
                    initialValue:
                        crew.any(
                          (u) =>
                              '${u['email'] ?? ''}'.toLowerCase() ==
                              selectedEmail?.toLowerCase(),
                        )
                        ? selectedEmail
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'Crew member',
                      prefixIcon: Icon(Icons.engineering_outlined),
                    ),
                    items: crew.map((u) {
                      final accountStatus =
                          '${u['account_status'] ?? ''}'.trim();
                      return DropdownMenuItem(
                        value: '${u['email'] ?? ''}',
                        child: Text(
                          '${u['full_name'] ?? u['email']} • '
                          '${u['role'] ?? ''}'
                          '${accountStatus.isEmpty ? '' : ' • $accountStatus'}',
                        ),
                      );
                    }).toList(),
                    onChanged: saving
                        ? null
                        : (value) => setState(() => selectedEmail = value),
                  ),

                const SizedBox(height: 10),
                Row(
                  children: [
                    if (profile.canManageUsers)
                      OutlinedButton.icon(
                        onPressed:
                            saving || selectedHouseRecord == null
                            ? null
                            : () => _createAndAssign(data),
                        icon: const Icon(Icons.person_add_alt_1_outlined),
                        label: const Text('Add crew'),
                      ),
                    const Spacer(),
                    FilledButton.tonalIcon(
                      onPressed:
                          saving || selectedEmail == null
                          ? null
                          : () => _assign(data),
                      icon: const Icon(Icons.link_outlined),
                      label: Text(saving ? 'Saving…' : 'Assign to house'),
                    ),
                  ],
                ),
              ],

              if (assignments.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  'Current team',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                ...assignments.map(
                  (a) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: widget.compact,
                    leading: CircleAvatar(
                      child: Text(_initial('${a['role'] ?? '?'}')),
                    ),
                    title: Text(
                      '${a['member_name'] ?? a['email'] ?? 'Crew member'}',
                    ),
                    subtitle: Text(
                      '${a['role'] ?? ''} • ${a['house_code'] ?? ''}'
                      '${a['user_id'] == null ? ' • Awaiting first sign-in' : ''}',
                    ),
                    trailing: IconButton(
                      tooltip: 'Remove assignment',
                      onPressed: saving ? null : () => _remove(a),
                      icon: const Icon(Icons.person_remove_outlined),
                    ),
                  ),
                ),
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
