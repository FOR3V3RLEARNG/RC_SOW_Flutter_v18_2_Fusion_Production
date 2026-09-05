import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../core/weekly_projection.dart';
import '../core/widgets.dart';
import '../services/production_backend.dart';
import '../services/weekly_projection_repository.dart';

class WeeklyWorkProjectionScreen extends StatefulWidget {
  const WeeklyWorkProjectionScreen({super.key});

  @override
  State<WeeklyWorkProjectionScreen> createState() =>
      _WeeklyWorkProjectionScreenState();
}

class _WeeklyWorkProjectionScreenState
    extends State<WeeklyWorkProjectionScreen> {
  final _name = TextEditingController();
  final _position = TextEditingController();
  final _cluster = TextEditingController();

  DateTime _weekStarting = rcWeekStarting(DateTime.now());
  BackendProfile? _profile;
  WeeklyAdminProjectionFile? _mine;
  List<WeeklyAdminProjectionFile> _visible = <WeeklyAdminProjectionFile>[];
  List<DailyAdminWorkPlan> _days =
      defaultAdminWorkWeek(rcWeekStarting(DateTime.now()));
  List<List<SignaturePointData>> _signature =
      <List<SignaturePointData>>[];

  String _parish = 'Hanover';
  String _parishFilter = 'All';
  bool _started = false;
  bool _loading = true;
  bool _saving = false;
  String? _warning;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _loadWeek();
  }

  @override
  void dispose() {
    _name.dispose();
    _position.dispose();
    _cluster.dispose();
    super.dispose();
  }

  Future<void> _loadWeek() async {
    final state = AppScope.of(context);
    final repository = WeeklyProjectionRepository(state);

    if (mounted) {
      setState(() {
        _loading = true;
        _warning = null;
      });
    }

    final profile = await repository.profile();
    final viewerId = profile?.userId ?? 'local-${_roleKey(state.role)}';
    final viewerName = profile != null && profile.fullName.trim().isNotEmpty
        ? profile.fullName.trim()
        : '${state.role} User';
    final viewerParishes =
        profile != null && profile.assignedParishes.isNotEmpty
            ? profile.assignedParishes
            : <String>[state.selectedParish];

    List<WeeklyAdminProjectionFile> files;
    try {
      files = await repository.fetchWeek(_weekStarting);
    } on Object {
      files = <WeeklyAdminProjectionFile>[];
      _warning =
          'Connected weekly files could not be refreshed. Your local copy is still available.';
    }

    files = files
        .where(
          (file) => WeeklyProjectionAccess.canView(
            viewerRole: state.role,
            viewerId: viewerId,
            viewerParishes: viewerParishes,
            file: file,
          ),
        )
        .toList();

    WeeklyAdminProjectionFile? mine;
    for (final file in files) {
      if (file.ownerId == viewerId) {
        mine = file;
        break;
      }
    }

    if (mine == null) {
      final local = state.formDrafts[
          weeklyProjectionCacheKey(viewerId, _weekStarting)];
      final json = local?['json'];
      if (json != null && json.isNotEmpty) {
        try {
          mine = WeeklyAdminProjectionFile.fromJson(json);
        } on FormatException {
          mine = null;
        }
      }
    }

    mine ??= WeeklyAdminProjectionFile(
      id: 'LOCAL-${rcWeekKey(_weekStarting)}-${_roleKey(viewerId)}',
      weekStarting: _weekStarting,
      ownerId: viewerId,
      ownerName: viewerName,
      position: state.role,
      parish: viewerParishes.first,
      cluster: _defaultCluster(state, viewerParishes.first),
      days: defaultAdminWorkWeek(_weekStarting),
      signatureStrokes: <List<SignaturePointData>>[],
      status: WeeklyProjectionStatus.draft,
      updatedAt: DateTime.now(),
    );

    if (!files.any((file) => file.ownerId == mine!.ownerId)) {
      files.insert(0, mine);
    }

    files.sort((a, b) {
      final parishCompare = a.parish.compareTo(b.parish);
      return parishCompare != 0
          ? parishCompare
          : a.ownerName.compareTo(b.ownerName);
    });

    if (!mounted) return;
    setState(() {
      _profile = profile;
      _visible = files;
      _mine = mine;
      _name.text = mine!.ownerName;
      _position.text = mine.position;
      _parish = mine.parish;
      _cluster.text = mine.cluster;
      _days = mine.days
          .map((day) => DailyAdminWorkPlan.fromMap(day.toMap()))
          .toList();
      _signature = _copySignature(mine.signatureStrokes);
      _parishFilter = 'All';
      _loading = false;
    });
  }

  Future<void> _pickWeek() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _weekStarting,
      firstDate: DateTime(2025),
      lastDate: DateTime(2035),
      helpText: 'SELECT WORK PROJECTION WEEK',
    );
    if (selected == null || !mounted) return;
    _weekStarting = rcWeekStarting(selected);
    await _loadWeek();
  }

  Future<void> _pickTime(int index, {required bool start}) async {
    final day = _days[index];
    final minutes = start ? day.startMinutes : day.endMinutes;
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: minutes ~/ 60,
        minute: minutes % 60,
      ),
      initialEntryMode: TimePickerEntryMode.input,
      helpText: start ? 'START TIME' : 'END TIME',
    );
    if (selected == null || !mounted) return;

    final next = selected.hour * 60 + selected.minute;
    setState(() {
      if (start) {
        day.startMinutes = next;
      } else {
        day.endMinutes = next;
      }
    });
  }

  String? _validate() {
    if (_name.text.trim().isEmpty) return 'Enter your name.';
    if (_position.text.trim().isEmpty) return 'Enter your position.';
    if (_parish.trim().isEmpty) return 'Select a parish.';
    if (_cluster.text.trim().isEmpty) return 'Enter a cluster.';
    if (!_signature.any((stroke) => stroke.length >= 2)) {
      return 'Add your signature before saving the weekly file.';
    }

    final active = _days.where((day) => day.enabled).toList();
    if (active.isEmpty) return 'Select at least one working day.';

    for (final day in active) {
      if (day.endMinutes <= day.startMinutes) {
        return '${_weekday(day.date)} has an invalid time range.';
      }
      if (day.detail.trim().isEmpty) {
        return 'Add planned work for ${_weekday(day.date)}.';
      }
    }
    return null;
  }

  Future<void> _save({required bool submit}) async {
    final state = AppScope.of(context);
    final current = _mine!;
    if (current.status == WeeklyProjectionStatus.submitted) return;

    final error = _validate();
    if (error != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    if (submit) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.verified_user_outlined),
          title: const Text('Submit weekly work projection?'),
          content: const Text(
            'Submitting locks this signed weekly file for audit and supervisory review.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('KEEP EDITING'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.send_outlined),
              label: const Text('SUBMIT WEEK'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    final file = WeeklyAdminProjectionFile(
      id: current.id,
      weekStarting: _weekStarting,
      ownerId: current.ownerId,
      ownerName: _name.text.trim(),
      position: _position.text.trim(),
      parish: _parish,
      cluster: _cluster.text.trim(),
      days: _days
          .map((day) => DailyAdminWorkPlan.fromMap(day.toMap()))
          .toList(),
      signatureStrokes: _copySignature(_signature),
      status: submit
          ? WeeklyProjectionStatus.submitted
          : WeeklyProjectionStatus.draft,
      updatedAt: DateTime.now(),
      submittedAt: submit ? DateTime.now() : null,
    );

    setState(() => _saving = true);
    try {
      await WeeklyProjectionRepository(state).save(file);
      if (!mounted) return;
      setState(() {
        _mine = file;
        final index =
            _visible.indexWhere((item) => item.ownerId == file.ownerId);
        if (index >= 0) {
          _visible[index] = file;
        } else {
          _visible.insert(0, file);
        }
      });
      showSavedMessage(context, submitted: submit);
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Weekly projection could not be saved: $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    if (_loading || _mine == null) {
      return Scaffold(
        appBar: RcAppBar(title: const Text('Work Projection Log')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final mine = _mine!;
    final locked = mine.status == WeeklyProjectionStatus.submitted;
    final viewerId = _profile?.userId ?? 'local-${_roleKey(state.role)}';
    final viewerParishes =
        _profile != null && _profile!.assignedParishes.isNotEmpty
            ? _profile!.assignedParishes
            : <String>[state.selectedParish];

    final availableParishes = _visible.map((file) => file.parish).toSet().toList()
      ..sort();

    final shownFiles = _visible.where((file) {
      if (_parishFilter != 'All' && file.parish != _parishFilter) {
        return false;
      }
      return WeeklyProjectionAccess.canView(
        viewerRole: state.role,
        viewerId: viewerId,
        viewerParishes: viewerParishes,
        file: file,
      );
    }).toList();

    final reviewer = WeeklyProjectionAccess.isGlobalReviewer(state.role) ||
        WeeklyProjectionAccess.isParishSupervisor(state.role);

    return Scaffold(
      appBar: RcAppBar(
        title: const Text('Work Projection Log'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Refresh weekly files',
            onPressed: _saving ? null : _loadWeek,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          const RcSyncBanner(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
              children: <Widget>[
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        RcPageHeading(
                          eyebrow: 'Control of Works / Weekly Administration',
                          title: 'One signed weekly file per person',
                          description:
                              'Name, week, position, parish, cluster, signature and a daily work plan are kept together. Monday–Friday defaults to 09:00–17:00, and every day supports custom hours.',
                          action: RcStatusChip(
                            label: mine.status.label.toUpperCase(),
                            icon: locked
                                ? Icons.lock_outline
                                : Icons.edit_calendar_outlined,
                            tone: locked
                                ? RcStatusTone.success
                                : RcStatusTone.info,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _AccessBanner(
                          role: state.role,
                          scope: WeeklyProjectionAccess.scopeLabel(state.role),
                        ),
                        if (_warning != null) ...<Widget>[
                          const SizedBox(height: 10),
                          _WarningBanner(message: _warning!),
                        ],
                        const SizedBox(height: 16),
                        _WeekHero(
                          weekStarting: _weekStarting,
                          myHours: mine.plannedHours,
                          visibleCount: shownFiles.length,
                          onPickWeek: _pickWeek,
                        ),
                        const SizedBox(height: 22),
                        RcSectionHeader(
                          title: locked ? 'My submitted file' : 'My weekly file',
                          subtitle: locked
                              ? 'This signed week is read-only.'
                              : 'Only you can edit your file. Supervisory roles can review files within their access scope.',
                        ),
                        const SizedBox(height: 10),
                        if (locked)
                          _ReadOnlyOwnFile(file: mine)
                        else
                          _Editor(
                            name: _name,
                            position: _position,
                            cluster: _cluster,
                            parish: _parish,
                            days: _days,
                            signature: _signature,
                            saving: _saving,
                            onParishChanged: (value) =>
                                setState(() => _parish = value),
                            onDayEnabled: (index, value) =>
                                setState(() => _days[index].enabled = value),
                            onStart: (index) => _pickTime(index, start: true),
                            onEnd: (index) => _pickTime(index, start: false),
                            onDetail: (index, value) =>
                                _days[index].detail = value,
                            onSignatureChanged: (value) =>
                                setState(() => _signature = value),
                            onSave: () => _save(submit: false),
                            onSubmit: () => _save(submit: true),
                          ),
                        if (reviewer) ...<Widget>[
                          const SizedBox(height: 26),
                          RcSectionHeader(
                            title: 'Weekly staff directory',
                            subtitle:
                                '${WeeklyProjectionAccess.scopeLabel(state.role)} • ${shownFiles.length} visible file(s)',
                            trailing: availableParishes.length > 1
                                ? SizedBox(
                                    width: 210,
                                    child: DropdownButtonFormField<String>(
                                      value: _parishFilter,
                                      isExpanded: true,
                                      decoration: const InputDecoration(
                                        labelText: 'Parish filter',
                                        isDense: true,
                                      ),
                                      items: <String>[
                                        'All',
                                        ...availableParishes,
                                      ]
                                          .map(
                                            (value) =>
                                                DropdownMenuItem<String>(
                                              value: value,
                                              child: Text(value),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (value) => setState(
                                        () => _parishFilter = value ?? 'All',
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 10),
                          if (shownFiles.isEmpty)
                            const RcEmptyState(
                              icon: Icons.folder_shared_outlined,
                              title: 'No visible weekly files',
                              message:
                                  'Authorized staff files will appear here after they save their week.',
                            )
                          else
                            for (final file in shownFiles) ...<Widget>[
                              _WeeklyFileCard(
                                file: file,
                                mine: file.ownerId == viewerId,
                              ),
                              const SizedBox(height: 10),
                            ],
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _defaultCluster(AppState state, String parish) {
    for (final house in state.houses) {
      if (house.parish == parish && house.cluster.trim().isNotEmpty) {
        return house.cluster;
      }
    }
    return 'Unassigned';
  }
}

class _Editor extends StatelessWidget {
  const _Editor({
    required this.name,
    required this.position,
    required this.cluster,
    required this.parish,
    required this.days,
    required this.signature,
    required this.saving,
    required this.onParishChanged,
    required this.onDayEnabled,
    required this.onStart,
    required this.onEnd,
    required this.onDetail,
    required this.onSignatureChanged,
    required this.onSave,
    required this.onSubmit,
  });

  final TextEditingController name;
  final TextEditingController position;
  final TextEditingController cluster;
  final String parish;
  final List<DailyAdminWorkPlan> days;
  final List<List<SignaturePointData>> signature;
  final bool saving;
  final ValueChanged<String> onParishChanged;
  final void Function(int index, bool value) onDayEnabled;
  final ValueChanged<int> onStart;
  final ValueChanged<int> onEnd;
  final void Function(int index, String value) onDetail;
  final ValueChanged<List<List<SignaturePointData>>> onSignatureChanged;
  final VoidCallback onSave;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _TwoColumn(
              first: TextField(
                controller: name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              second: TextField(
                controller: position,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Position',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _TwoColumn(
              first: DropdownButtonFormField<String>(
                value: parish,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Parish',
                  prefixIcon: Icon(Icons.map_outlined),
                ),
                items: jamaicaParishes
                    .map(
                      (value) => DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) onParishChanged(value);
                },
              ),
              second: TextField(
                controller: cluster,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Cluster',
                  prefixIcon: Icon(Icons.location_city_outlined),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const RcSectionHeader(
              title: 'Daily work projection',
              subtitle:
                  'Monday–Friday defaults to 09:00–17:00. Turn days off or customize each time range.',
            ),
            const SizedBox(height: 10),
            for (var index = 0; index < days.length; index++) ...<Widget>[
              _DailyPlanCard(
                day: days[index],
                onEnabled: (value) => onDayEnabled(index, value),
                onStart: () => onStart(index),
                onEnd: () => onEnd(index),
                onDetail: (value) => onDetail(index, value),
              ),
              if (index < days.length - 1) const SizedBox(height: 10),
            ],
            const SizedBox(height: 20),
            const RcSectionHeader(
              title: 'Signature',
              subtitle:
                  'Sign inside the box. The signature is stored with this person’s weekly file.',
            ),
            const SizedBox(height: 10),
            _SignaturePad(
              strokes: signature,
              onChanged: onSignatureChanged,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.end,
              children: <Widget>[
                OutlinedButton.icon(
                  onPressed: saving ? null : onSave,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('SAVE WEEKLY DRAFT'),
                ),
                FilledButton.icon(
                  onPressed: saving ? null : onSubmit,
                  icon: const Icon(Icons.send_outlined),
                  label: const Text('SUBMIT WEEKLY FILE'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TwoColumn extends StatelessWidget {
  const _TwoColumn({required this.first, required this.second});

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 720) {
          return Column(
            children: <Widget>[
              first,
              const SizedBox(height: 12),
              second,
            ],
          );
        }
        return Row(
          children: <Widget>[
            Expanded(child: first),
            const SizedBox(width: 12),
            Expanded(child: second),
          ],
        );
      },
    );
  }
}

class _DailyPlanCard extends StatelessWidget {
  const _DailyPlanCard({
    required this.day,
    required this.onEnabled,
    required this.onStart,
    required this.onEnd,
    required this.onDetail,
  });

  final DailyAdminWorkPlan day;
  final ValueChanged<bool> onEnabled;
  final VoidCallback onStart;
  final VoidCallback onEnd;
  final ValueChanged<String> onDetail;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final localizations = MaterialLocalizations.of(context);
    final start = TimeOfDay(
      hour: day.startMinutes ~/ 60,
      minute: day.startMinutes % 60,
    );
    final end = TimeOfDay(
      hour: day.endMinutes ~/ 60,
      minute: day.endMinutes % 60,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: day.enabled
            ? scheme.secondaryContainer.withOpacity(.5)
            : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '${_weekday(day.date)} • ${_dateLabel(day.date)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      day.enabled
                          ? '${day.plannedHours.toStringAsFixed(1)} planned hours'
                          : 'Not scheduled',
                    ),
                  ],
                ),
              ),
              Switch(value: day.enabled, onChanged: onEnabled),
            ],
          ),
          if (day.enabled) ...<Widget>[
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                OutlinedButton.icon(
                  onPressed: onStart,
                  icon: const Icon(Icons.login_outlined),
                  label: Text(
                    'START ${localizations.formatTimeOfDay(start)}',
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: onEnd,
                  icon: const Icon(Icons.logout_outlined),
                  label: Text(
                    'END ${localizations.formatTimeOfDay(end)}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              key: ValueKey(
                '${day.date.toIso8601String()}-${day.detail.hashCode}',
              ),
              initialValue: day.detail,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              onChanged: onDetail,
              decoration: InputDecoration(
                labelText: 'Work planned for ${_weekday(day.date)}',
                hintText:
                    'Technical visits, SOW/BOQ, tracker updates, meetings, logistics, documents, calls or other planned work.',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SignaturePad extends StatefulWidget {
  const _SignaturePad({
    required this.strokes,
    required this.onChanged,
  });

  final List<List<SignaturePointData>> strokes;
  final ValueChanged<List<List<SignaturePointData>>> onChanged;

  @override
  State<_SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<_SignaturePad> {
  late List<List<SignaturePointData>> _strokes;

  @override
  void initState() {
    super.initState();
    _strokes = _copySignature(widget.strokes);
  }

  @override
  void didUpdateWidget(covariant _SignaturePad oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.strokes, widget.strokes)) {
      _strokes = _copySignature(widget.strokes);
    }
  }

  void _start(DragStartDetails details, Size size) {
    setState(() {
      _strokes.add(<SignaturePointData>[
        _normalize(details.localPosition, size),
      ]);
    });
    widget.onChanged(_copySignature(_strokes));
  }

  void _update(DragUpdateDetails details, Size size) {
    if (_strokes.isEmpty) return;
    setState(() {
      _strokes.last.add(_normalize(details.localPosition, size));
    });
    widget.onChanged(_copySignature(_strokes));
  }

  SignaturePointData _normalize(Offset point, Size size) => SignaturePointData(
        x: (point.dx / size.width).clamp(0, 1).toDouble(),
        y: (point.dy / size.height).clamp(0, 1).toDouble(),
      );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, 180);
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: (details) => _start(details, size),
              onPanUpdate: (details) => _update(details, size),
              child: CustomPaint(
                painter: _SignaturePainter(
                  strokes: _strokes,
                  color: scheme.onSurface,
                ),
                child: const SizedBox(height: 180),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _strokes.isEmpty
                ? null
                : () {
                    setState(() => _strokes.clear());
                    widget.onChanged(<List<SignaturePointData>>[]);
                  },
            icon: const Icon(Icons.backspace_outlined),
            label: const Text('CLEAR SIGNATURE'),
          ),
        ),
      ],
    );
  }
}

class _SignaturePainter extends CustomPainter {
  const _SignaturePainter({required this.strokes, required this.color});

  final List<List<SignaturePointData>> strokes;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(18),
    );

    canvas.drawRRect(rect, Paint()..color = Colors.white);
    canvas.drawRRect(
      rect,
      Paint()
        ..color = const Color(0xFFD7D0CC)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    final ink = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      final path = Path()
        ..moveTo(
          stroke.first.x * size.width,
          stroke.first.y * size.height,
        );
      for (final point in stroke.skip(1)) {
        path.lineTo(point.x * size.width, point.y * size.height);
      }
      canvas.drawPath(path, ink);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}

class _WeeklyFileCard extends StatelessWidget {
  const _WeeklyFileCard({required this.file, required this.mine});

  final WeeklyAdminProjectionFile file;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: mine
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.tertiaryContainer,
          child: Icon(mine ? Icons.person_outline : Icons.badge_outlined),
        ),
        title: Text('${file.ownerName}${mine ? ' • You' : ''}'),
        subtitle: Text(
          '${file.position} • ${file.parish} • ${file.cluster}\n'
          '${file.plannedDays} days • ${file.plannedHours.toStringAsFixed(1)} hours',
        ),
        trailing: RcStatusChip(
          label: file.status.label.toUpperCase(),
          tone: file.status == WeeklyProjectionStatus.submitted
              ? RcStatusTone.success
              : RcStatusTone.info,
          compact: true,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: <Widget>[
          const Divider(),
          for (final day in file.days.where((item) => item.enabled))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(
                    width: 84,
                    child: Text(
                      _weekday(day.date),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${_timeText(day.startMinutes)}–'
                      '${_timeText(day.endMinutes)} • ${day.detail}',
                    ),
                  ),
                ],
              ),
            ),
          if (file.hasSignature) ...<Widget>[
            const SizedBox(height: 12),
            SizedBox(
              height: 90,
              width: double.infinity,
              child: CustomPaint(
                painter: _SignaturePainter(
                  strokes: file.signatureStrokes,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReadOnlyOwnFile extends StatelessWidget {
  const _ReadOnlyOwnFile({required this.file});

  final WeeklyAdminProjectionFile file;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: RcColors.successSoft,
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Row(
            children: <Widget>[
              Icon(Icons.verified_user_outlined, color: RcColors.success),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'This weekly projection is signed and submitted. '
                  'It is locked to preserve the audit trail.',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _WeeklyFileCard(file: file, mine: true),
      ],
    );
  }
}

class _WeekHero extends StatelessWidget {
  const _WeekHero({
    required this.weekStarting,
    required this.myHours,
    required this.visibleCount,
    required this.onPickWeek,
  });

  final DateTime weekStarting;
  final double myHours;
  final int visibleCount;
  final VoidCallback onPickWeek;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'WEEK OF',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: scheme.onPrimaryContainer,
                letterSpacing: 1.1,
              ),
        ),
        const SizedBox(height: 5),
        Text(
          '${_dateLabel(weekStarting)} – '
          '${_dateLabel(weekStarting.add(const Duration(days: 6)))}',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: scheme.onPrimaryContainer,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            _SummaryPill(
              icon: Icons.schedule_outlined,
              label: '${myHours.toStringAsFixed(1)} my hours',
            ),
            _SummaryPill(
              icon: Icons.folder_shared_outlined,
              label: '$visibleCount visible files',
            ),
          ],
        ),
      ],
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(34),
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(34),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final button = OutlinedButton.icon(
            onPressed: onPickWeek,
            icon: const Icon(Icons.date_range_outlined),
            label: const Text('CHANGE WEEK'),
          );

          if (constraints.maxWidth < 720) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                details,
                const SizedBox(height: 14),
                button,
              ],
            );
          }

          return Row(
            children: <Widget>[
              Expanded(child: details),
              const SizedBox(width: 14),
              button,
            ],
          );
        },
      ),
    );
  }
}

class _AccessBanner extends StatelessWidget {
  const _AccessBanner({required this.role, required this.scope});

  final String role;
  final String scope;

  @override
  Widget build(BuildContext context) {
    final message = WeeklyProjectionAccess.isGlobalReviewer(role)
        ? 'You can review every person’s weekly file across every parish.'
        : WeeklyProjectionAccess.isParishSupervisor(role)
            ? 'You can review every weekly file in your assigned parish.'
            : 'You can view and edit only your own weekly file.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RcColors.infoSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.admin_panel_settings_outlined, color: RcColors.info),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '$role • $scope',
                  style: const TextStyle(
                    color: RcColors.info,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(message),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WarningBanner extends StatelessWidget {
  const _WarningBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: RcColors.warningSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.cloud_off_outlined, color: RcColors.warning),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: scheme.surface.withOpacity(.78),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 18, color: scheme.primary),
          const SizedBox(width: 7),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

List<List<SignaturePointData>> _copySignature(
  List<List<SignaturePointData>> source,
) =>
    source
        .map(
          (stroke) => stroke
              .map(
                (point) => SignaturePointData(x: point.x, y: point.y),
              )
              .toList(),
        )
        .toList();

String _weekday(DateTime date) => const <String>[
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ][date.weekday - 1];

String _dateLabel(DateTime date) {
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

String _timeText(int total) =>
    '${(total ~/ 60).toString().padLeft(2, '0')}:'
    '${(total % 60).toString().padLeft(2, '0')}';

String _roleKey(String value) =>
    value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
