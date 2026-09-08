import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

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
  String? selectedCrewEmail;
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

    if ((selectedHouse == null ||
            !houses.any((house) => house.code == selectedHouse)) &&
        houses.isNotEmpty) {
      final preferred = widget.initialHouseCode?.trim().toUpperCase();
      selectedHouse =
          preferred != null && houses.any((house) => house.code == preferred)
          ? preferred
          : houses.first.code;
    }

    final rows = await widget.state.repository.crewAttendance(
      profile: profile,
      houseCode: selectedHouse,
    );

    var assignments = <Map<String, dynamic>>[];
    if (!profile.isCrew &&
        profile.canVerifyAttendance &&
        selectedHouse != null) {
      assignments = await widget.state.repository.crewAssignments(
        houseCode: selectedHouse,
      );
    }

    return _AttendanceData(
      houses: houses,
      rows: rows,
      assignments: assignments,
    );
  }

  Future<void> _refresh() async {
    setState(() => future = _load());
    await future;
  }

  Future<void> _submitSelf(String action) async {
    final house = selectedHouse;
    if (house == null || house.isEmpty) {
      _snack('Choose an assigned house first.');
      return;
    }

    setState(() => busy = true);
    try {
      final location = await _captureLocation();

      await widget.state.repository.submitOwnAttendance(
        profile: profile,
        houseCode: house,
        workDate: workDate,
        status: status,
        clockAction: action,
        note: note.text.trim().isEmpty ? null : note.text.trim(),
        latitude: location.$1,
        longitude: location.$2,
        accuracyM: location.$3,
        locationStatus: location.$4,
      );

      await widget.state.feedback(strong: true);
      _snack(
        action == 'sign_out'
            ? 'Signed out. Attendance saved.'
            : 'Signed in. Attendance saved.',
      );
      await _refresh();
    } catch (error) {
      _snack('Attendance could not be saved: $error');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _recordSupervisor(
    _AttendanceData data,
    String clockAction,
  ) async {
    final house = selectedHouse;
    final email = selectedCrewEmail;

    if (house == null || house.isEmpty) {
      _snack('Choose a house first.');
      return;
    }
    if (email == null || email.isEmpty) {
      _snack('Choose an assigned crew member first.');
      return;
    }

    final assignment = data.assignments
        .where(
          (row) =>
              row['active'] != false &&
              '${row['email'] ?? ''}'.toLowerCase() == email.toLowerCase(),
        )
        .firstOrNull;

    if (assignment == null) {
      _snack('That crew assignment is no longer active.');
      return;
    }

    setState(() => busy = true);
    try {
      await widget.state.repository.recordCrewAttendance(
        profile: profile,
        houseCode: house,
        memberEmail: email,
        workDate: workDate,
        status: status,
        clockAction: clockAction,
        note: note.text.trim().isEmpty ? null : note.text.trim(),
      );

      await widget.state.feedback(strong: true);

      final actionLabel = switch (clockAction) {
        'sign_in' => 'Clock-in recorded and verified.',
        'sign_out' => 'Clock-out recorded and verified.',
        _ => 'Attendance recorded and verified.',
      };
      _snack(actionLabel);
      await _refresh();
    } catch (error) {
      _snack('Attendance register could not be saved: $error');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<(double?, double?, double?, String)> _captureLocation() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return (null, null, null, 'service_disabled');

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        return (null, null, null, 'permission_denied');
      }
      if (permission == LocationPermission.deniedForever) {
        return (null, null, null, 'permission_denied_forever');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );

      return (
        position.latitude,
        position.longitude,
        position.accuracy,
        'captured',
      );
    } catch (_) {
      return (null, null, null, 'unavailable');
    }
  }

  Future<void> _verify(Map<String, dynamic> row, bool value) async {
    try {
      await widget.state.repository.verifyAttendance(
        attendanceId: '${row['id']}',
        verified: value,
      );
      await _refresh();
    } catch (error) {
      _snack('Attendance verification failed: $error');
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2025),
      lastDate: DateTime.now().add(const Duration(days: 7)),
      initialDate: workDate,
    );
    if (!mounted || picked == null) return;
    setState(() => workDate = picked);
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
            final canVerify = profile.canVerifyAttendance;
            final activeAssignments = data.assignments
                .where((row) => row['active'] != false)
                .toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
              children: [
                RcPageHeading(
                  eyebrow: profile.isCrew
                      ? 'Daily crew register'
                      : 'Workforce control',
                  title: profile.isCrew
                      ? 'Sign attendance for assigned work'
                      : 'House Attendance Register',
                  subtitle: profile.isCrew
                      ? 'Sign in and out against an assigned house. GPS is captured when available and remains auditable.'
                      : 'Select a house and assigned crew member. Supervisors and management can record and verify attendance even before the crew member creates an app account.',
                ),
                const SizedBox(height: 14),

                if (profile.isCrew)
                  _selfRegister(
                    context,
                    theme,
                    data,
                    houseCodes,
                  )
                else if (canVerify)
                  _supervisorRegister(
                    context,
                    theme,
                    data,
                    activeAssignments,
                  )
                else
                  const RcExpressiveSurface(
                    child: Text(
                      'This account can view attendance but cannot record or verify the workforce register.',
                    ),
                  ),

                const SizedBox(height: 18),
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
                      'No attendance entries are visible for this house yet.',
                    ),
                  ),

                ...data.rows.map(
                  (row) => _attendanceRow(
                    context,
                    theme,
                    row,
                    canVerify,
                  ),
                ),

                if (snap.hasError) ...[
                  const SizedBox(height: 12),
                  RcExpressiveSurface(
                    tone: theme.colorScheme.errorContainer,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Attendance data could not be loaded.',
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
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _selfRegister(
    BuildContext context,
    ThemeData theme,
    _AttendanceData data,
    List<String> houseCodes,
  ) {
    return RcExpressiveSurface(
      shape: RcSurfaceShape.hero,
      tone: theme.colorScheme.primaryContainer.withValues(alpha: .32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            key: ValueKey('attendance-house-${selectedHouse ?? ''}'),
            initialValue: houseCodes.contains(selectedHouse)
                ? selectedHouse
                : null,
            decoration: const InputDecoration(
              labelText: 'Assigned house',
              prefixIcon: Icon(Icons.home_work_outlined),
            ),
            items: data.houses
                .map(
                  (house) => DropdownMenuItem(
                    value: house.code,
                    child: Text('${house.code} • ${house.beneficiary}'),
                  ),
                )
                .toList(),
            onChanged: busy
                ? null
                : (value) {
                    setState(() {
                      selectedHouse = value;
                      future = _load();
                    });
                  },
          ),
          const SizedBox(height: 10),
          _dateTile(),
          const SizedBox(height: 8),
          _statusPicker(),
          const SizedBox(height: 10),
          _noteField(),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: busy || data.houses.isEmpty
                      ? null
                      : () => _submitSelf('sign_in'),
                  icon: const Icon(Icons.login_rounded),
                  label: const Text('Sign in'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: busy || data.houses.isEmpty
                      ? null
                      : () => _submitSelf('sign_out'),
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
    );
  }

  Widget _supervisorRegister(
    BuildContext context,
    ThemeData theme,
    _AttendanceData data,
    List<Map<String, dynamic>> assignments,
  ) {
    final crewEmailExists = assignments.any(
      (row) =>
          '${row['email'] ?? ''}'.toLowerCase() ==
          selectedCrewEmail?.toLowerCase(),
    );

    return RcExpressiveSurface(
      shape: RcSurfaceShape.hero,
      tone: theme.colorScheme.primaryContainer.withValues(alpha: .22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Supervisor register',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Rows recorded here are supervisor-verified and remain linked by crew email until a user account exists.',
          ),
          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            key: ValueKey('attendance-manager-house-${selectedHouse ?? ''}'),
            initialValue: data.houses.any((h) => h.code == selectedHouse)
                ? selectedHouse
                : null,
            decoration: const InputDecoration(
              labelText: 'House',
              prefixIcon: Icon(Icons.home_work_outlined),
            ),
            items: data.houses
                .map(
                  (house) => DropdownMenuItem(
                    value: house.code,
                    child: Text('${house.code} • ${house.beneficiary}'),
                  ),
                )
                .toList(),
            onChanged: busy
                ? null
                : (value) {
                    setState(() {
                      selectedHouse = value;
                      selectedCrewEmail = null;
                      future = _load();
                    });
                  },
          ),
          const SizedBox(height: 10),

          if (assignments.isEmpty)
            const RcExpressiveSurface(
              child: Text(
                'No active crew is assigned to this house. Add the Carpenter / Worker / Apprentice in House Crew first.',
              ),
            )
          else
            DropdownButtonFormField<String>(
              key: ValueKey(
                'attendance-crew-${selectedHouse ?? ''}-${selectedCrewEmail ?? ''}',
              ),
              initialValue: crewEmailExists ? selectedCrewEmail : null,
              decoration: const InputDecoration(
                labelText: 'Assigned crew member',
                prefixIcon: Icon(Icons.engineering_outlined),
              ),
              items: assignments
                  .map(
                    (row) => DropdownMenuItem(
                      value: '${row['email'] ?? ''}',
                      child: Text(
                        '${row['member_name'] ?? row['email']} • ${row['role'] ?? ''}',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: busy
                  ? null
                  : (value) => setState(() => selectedCrewEmail = value),
            ),

          const SizedBox(height: 10),
          _dateTile(),
          const SizedBox(height: 8),
          _statusPicker(),
          const SizedBox(height: 10),
          _noteField(),
          const SizedBox(height: 14),

          FilledButton.icon(
            onPressed:
                busy || assignments.isEmpty || selectedCrewEmail == null
                ? null
                : () => _recordSupervisor(data, 'status_only'),
            icon: const Icon(Icons.fact_check_outlined),
            label: const Text('Record & verify attendance'),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      busy ||
                          assignments.isEmpty ||
                          selectedCrewEmail == null ||
                          status == 'Absent' ||
                          status == 'Excused'
                      ? null
                      : () => _recordSupervisor(data, 'sign_in'),
                  icon: const Icon(Icons.login_rounded),
                  label: const Text('Clock in'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      busy ||
                          assignments.isEmpty ||
                          selectedCrewEmail == null ||
                          status == 'Absent' ||
                          status == 'Excused'
                      ? null
                      : () => _recordSupervisor(data, 'sign_out'),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Clock out'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dateTile() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Work date'),
      subtitle: Text(workDate.toIso8601String().split('T').first),
      trailing: const Icon(Icons.calendar_today_outlined),
      onTap: busy ? null : _pickDate,
    );
  }

  Widget _statusPicker() {
    return DropdownButtonFormField<String>(
      initialValue: status,
      decoration: const InputDecoration(
        labelText: 'Attendance status',
        prefixIcon: Icon(Icons.how_to_reg_outlined),
      ),
      items: const ['Present', 'Half day', 'Absent', 'Excused']
          .map(
            (value) => DropdownMenuItem(
              value: value,
              child: Text(value),
            ),
          )
          .toList(),
      onChanged: busy
          ? null
          : (value) {
              if (value != null) setState(() => status = value);
            },
    );
  }

  Widget _noteField() {
    return TextField(
      controller: note,
      minLines: 2,
      maxLines: 4,
      decoration: const InputDecoration(
        labelText: 'Work / attendance note',
        prefixIcon: Icon(Icons.notes_outlined),
      ),
    );
  }

  Widget _attendanceRow(
    BuildContext context,
    ThemeData theme,
    Map<String, dynamic> row,
    bool canVerify,
  ) {
    final verified = row['verified'] == true;
    final statusText = '${row['status'] ?? ''}';
    final name =
        '${row['member_name'] ?? row['member_email'] ?? 'Crew member'}';
    final role = '${row['member_role'] ?? ''}';
    final date = '${row['work_date'] ?? ''}';
    final recordingMode = '${row['recording_mode'] ?? ''}'.trim();
    final recordedBy = '${row['recorded_by_email'] ?? ''}'.trim();

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
                color: verified ? RcColors.success : RcColors.warning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 3),
                  Text('${row['house_code'] ?? ''} • $role • $date'),
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
                  if ('${row['note'] ?? ''}'.trim().isNotEmpty) ...[
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
                  if (recordingMode.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      recordingMode == 'self_gps'
                          ? 'Recorded by crew self check-in'
                          : 'Recorded by supervisor${recordedBy.isEmpty ? '' : ' • $recordedBy'}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                  if ('${row['location_status'] ?? ''}'
                      .trim()
                      .isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'GPS audit: ${row['location_status']}'
                      '${row['location_accuracy_m'] == null ? '' : ' • ±${row['location_accuracy_m']} m'}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            if (canVerify)
              Switch.adaptive(
                value: verified,
                onChanged: busy ? null : (value) => _verify(row, value),
              ),
          ],
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
  const _AttendanceData({
    this.houses = const [],
    this.rows = const [],
    this.assignments = const [],
  });

  final List<HouseRecord> houses;
  final List<Map<String, dynamic>> rows;
  final List<Map<String, dynamic>> assignments;
}

extension _AttendanceFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
