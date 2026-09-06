import 'package:flutter/material.dart';

import '../../core/design_tokens.dart';
import '../../core/rc_components.dart';
import '../../models/app_models.dart';
import '../../state/app_state.dart';

class CrewAttendanceScreen extends StatefulWidget {
  const CrewAttendanceScreen({
    super.key,
    required this.state,
    this.initialHouseCode,
  });

  final AppState state;
  final String? initialHouseCode;

  @override
  State<CrewAttendanceScreen> createState() => _CrewAttendanceScreenState();
}

class _CrewAttendanceScreenState extends State<CrewAttendanceScreen> {
  late Future<_AttendanceData> future;
  String? selectedHouse;
  String status = 'Present';
  DateTime workDate = DateTime.now();
  final note = TextEditingController();
  bool busy = false;

  UserProfile get profile => widget.state.profile!;

  @override
  void initState() {
    super.initState();
    selectedHouse = widget.initialHouseCode?.trim().toUpperCase();
    future = _load();
  }

  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  Future<_AttendanceData> _load() async {
    final houses = await widget.state.repository.houses(profile);
    if (selectedHouse == null && houses.isNotEmpty)
      selectedHouse = houses.first.code;
    final rows = await widget.state.repository.crewAttendance(
      profile: profile,
      houseCode: selectedHouse,
    );
    return _AttendanceData(houses: houses, rows: rows);
  }

  Future<void> _refresh() async {
    setState(() => future = _load());
    await future;
  }

  Future<void> _submit(String action) async {
    final house = selectedHouse;
    if (house == null || house.isEmpty) {
      _snack('Choose an assigned house first.');
      return;
    }
    setState(() => busy = true);
    try {
      await widget.state.repository.submitOwnAttendance(
        profile: profile,
        houseCode: house,
        workDate: workDate,
        status: status,
        clockAction: action,
        note: note.text.trim().isEmpty ? null : note.text.trim(),
      );
      await widget.state.feedback(strong: true);
      _snack(
        action == 'sign_out'
            ? 'Signed out. Attendance is awaiting verification.'
            : 'Signed in. Attendance is awaiting verification.',
      );
      await _refresh();
    } catch (_) {
      _snack(
        'Attendance could not be saved. Confirm this house is assigned to your crew and retry.',
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _verify(Map<String, dynamic> row, bool value) async {
    try {
      await widget.state.repository.verifyAttendance(
        attendanceId: '${row['id']}',
        verified: value,
      );
      await _refresh();
    } catch (_) {
      _snack('Attendance verification failed.');
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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Crew Daily Attendance')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<_AttendanceData>(
          future: future,
          builder: (context, snap) {
            final data = snap.data ?? const _AttendanceData();
            final houseCodes = data.houses.map((h) => h.code).toList();
            final canVerify = profile.hasPrivilege('verifyAttendance');
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
              children: [
                RcPageHeading(
                  eyebrow: profile.isCrew
                      ? 'Daily crew register'
                      : 'Workforce control',
                  title: profile.isCrew
                      ? 'Sign attendance for assigned work'
                      : 'Verify house attendance',
                  subtitle: profile.isCrew
                      ? 'Attendance is tied to a specific house and becomes payable only after supervisor verification.'
                      : 'Review who worked, attendance status, clock times and verification before payment processing.',
                ),
                const SizedBox(height: 14),
                if (profile.isCrew)
                  RcExpressiveSurface(
                    shape: RcSurfaceShape.hero,
                    tone: theme.colorScheme.primaryContainer.withValues(
                      alpha: .32,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DropdownButtonFormField<String>(
                          key: ValueKey(
                            'attendance-house-${selectedHouse ?? ''}',
                          ),
                          initialValue: houseCodes.contains(selectedHouse)
                              ? selectedHouse
                              : null,
                          decoration: const InputDecoration(
                            labelText: 'Assigned house',
                          ),
                          items: data.houses
                              .map(
                                (house) => DropdownMenuItem(
                                  value: house.code,
                                  child: Text(
                                    '${house.code} • ${house.beneficiary}',
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) async {
                            setState(() {
                              selectedHouse = value;
                              future = _load();
                            });
                          },
                        ),
                        const SizedBox(height: 10),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Work date'),
                          subtitle: Text(
                            workDate.toIso8601String().split('T').first,
                          ),
                          trailing: const Icon(Icons.calendar_today_outlined),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              firstDate: DateTime(2025),
                              lastDate: DateTime.now().add(
                                const Duration(days: 7),
                              ),
                              initialDate: workDate,
                            );
                            if (!mounted) return;
                            if (picked != null)
                              setState(() => workDate = picked);
                          },
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: status,
                          decoration: const InputDecoration(
                            labelText: 'Attendance status',
                          ),
                          items:
                              const ['Present', 'Half day', 'Absent', 'Excused']
                                  .map(
                                    (value) => DropdownMenuItem(
                                      value: value,
                                      child: Text(value),
                                    ),
                                  )
                                  .toList(),
                          onChanged: busy
                              ? null
                              : (value) => setState(() => status = value!),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: note,
                          minLines: 2,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Work / attendance note',
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: busy || data.houses.isEmpty
                                    ? null
                                    : () => _submit('sign_in'),
                                icon: const Icon(Icons.login_rounded),
                                label: const Text('Sign in'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton.tonalIcon(
                                onPressed: busy || data.houses.isEmpty
                                    ? null
                                    : () => _submit('sign_out'),
                                icon: const Icon(Icons.logout_rounded),
                                label: const Text('Sign out'),
                              ),
                            ),
                          ],
                        ),
                        if (data.houses.isEmpty) ...[
                          const SizedBox(height: 12),
                          const Text(
                            'No active house is assigned to this crew account. Ask the Site Supervisor or management team to assign a house.',
                          ),
                        ],
                      ],
                    ),
                  ),
                if (profile.isCrew) const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Attendance ledger',
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    if (snap.connectionState == ConnectionState.waiting)
                      const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 9),
                if (data.rows.isEmpty &&
                    snap.connectionState != ConnectionState.waiting)
                  const RcExpressiveSurface(
                    child: Text(
                      'No attendance entries are visible for this selection.',
                    ),
                  ),
                ...data.rows.map((row) {
                  final verified = row['verified'] == true;
                  final statusText = '${row['status'] ?? ''}';
                  final name =
                      '${row['member_name'] ?? row['member_email'] ?? 'Crew member'}';
                  final role = '${row['member_role'] ?? ''}';
                  final date = '${row['work_date'] ?? ''}';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: RcExpressiveSurface(
                      shape: RcSurfaceShape.offset,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundColor: verified
                                ? RcColors.success.withValues(alpha: .12)
                                : RcColors.warning.withValues(alpha: .12),
                            child: Icon(
                              verified
                                  ? Icons.verified_outlined
                                  : Icons.schedule_outlined,
                              color: verified
                                  ? RcColors.success
                                  : RcColors.warning,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: theme.textTheme.titleMedium),
                                const SizedBox(height: 3),
                                Text(
                                  '${row['house_code'] ?? ''} • $role • $date',
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    RcStatusPill(
                                      label: statusText.toUpperCase(),
                                      color: statusText == 'Absent'
                                          ? RcColors.warning
                                          : theme.colorScheme.primary,
                                    ),
                                    RcStatusPill(
                                      label: verified ? 'VERIFIED' : 'PENDING',
                                      color: verified
                                          ? RcColors.success
                                          : RcColors.warning,
                                    ),
                                  ],
                                ),
                                if ('${row['note'] ?? ''}'
                                    .trim()
                                    .isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text('${row['note']}'),
                                ],
                                if (row['clock_in'] != null ||
                                    row['clock_out'] != null) ...[
                                  const SizedBox(height: 5),
                                  Text(
                                    'In ${_time(row['clock_in'])} • Out ${_time(row['clock_out'])}',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (canVerify)
                            Switch.adaptive(
                              value: verified,
                              onChanged: (value) => _verify(row, value),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
                if (snap.hasError) ...[
                  const SizedBox(height: 12),
                  RcExpressiveSurface(
                    tone: theme.colorScheme.errorContainer,
                    child: const Text(
                      'Attendance could not be loaded. Apply the v20.3 workforce migration and retry.',
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  String _time(Object? raw) {
    final parsed = DateTime.tryParse('${raw ?? ''}')?.toLocal();
    if (parsed == null) return '—';
    final hour = parsed.hour % 12 == 0 ? 12 : parsed.hour % 12;
    final minute = parsed.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${parsed.hour >= 12 ? 'PM' : 'AM'}';
  }
}

class _AttendanceData {
  const _AttendanceData({this.houses = const [], this.rows = const []});
  final List<HouseRecord> houses;
  final List<Map<String, dynamic>> rows;
}
