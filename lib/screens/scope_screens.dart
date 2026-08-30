import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../core/widgets.dart';

class ScopeWorkspace extends StatefulWidget {
  const ScopeWorkspace({
    this.initialStep = 0,
    this.standalone = false,
    super.key,
  });

  final int initialStep;
  final bool standalone;

  @override
  State<ScopeWorkspace> createState() => _ScopeWorkspaceState();
}

class _ScopeWorkspaceState extends State<ScopeWorkspace> {
  late int _step = widget.initialStep;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final body = Column(
      children: <Widget>[
        _ScopeStepper(
          step: _step,
          onStep: (value) => setState(() => _step = value),
        ),
        Expanded(
          child: IndexedStack(
            index: _step,
            children: const <Widget>[
              _HouseScopeStep(),
              _RoofScopeStep(),
              _PrintScopeStep(),
              _FilesScopeStep(),
            ],
          ),
        ),
        _ScopeActionBar(
          step: _step,
          onBack: _step == 0 ? null : () => setState(() => _step -= 1),
          onNext: _step == 3 ? null : () => setState(() => _step += 1),
        ),
      ],
    );
    if (!widget.standalone) return body;
    return Scaffold(
      appBar: AppBar(
        title: Text('${state.selectedHouse.code} • Scope of Work'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Files',
            onPressed: () => setState(() => _step = 3),
            icon: const Icon(Icons.folder_outlined),
          ),
        ],
      ),
      body: body,
    );
  }
}

class _ScopeStepper extends StatelessWidget {
  const _ScopeStepper({required this.step, required this.onStep});

  final int step;
  final ValueChanged<int> onStep;

  static const labels = <String>['House', 'Roof', 'Print', 'Files'];
  static const icons = <IconData>[
    Icons.house_outlined,
    Icons.architecture_outlined,
    Icons.print_outlined,
    Icons.folder_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 13),
          child: Row(
            children: <Widget>[
              for (var index = 0; index < labels.length; index++) ...<Widget>[
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => onStep(index),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: index < step
                                  ? RcColors.success
                                  : index == step
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              index < step ? Icons.check : icons[index],
                              size: 17,
                              color: index <= step
                                  ? Colors.white
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${index + 1}'.padLeft(2, '0') +
                                ' ${labels[index]}',
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: index == step
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                  fontWeight: index == step
                                      ? FontWeight.w900
                                      : FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (index < labels.length - 1)
                  Container(
                    width: 14,
                    height: 2,
                    color: index < step
                        ? RcColors.success
                        : Theme.of(context).colorScheme.outlineVariant,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ScopeActionBar extends StatelessWidget {
  const _ScopeActionBar({
    required this.step,
    required this.onBack,
    required this.onNext,
  });

  final int step;
  final VoidCallback? onBack;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ),
        child: Row(
          children: <Widget>[
            if (onBack != null)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('BACK'),
                ),
              )
            else
              const Spacer(),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: onNext ??
                    () => Navigator.pushNamed(context, RcRoutes.houseCommand),
                icon: Icon(
                  onNext == null ? Icons.task_alt : Icons.arrow_forward,
                ),
                label: Text(onNext == null ? 'OPEN HOUSE COMMAND' : 'CONTINUE'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HouseScopeStep extends StatefulWidget {
  const _HouseScopeStep();

  @override
  State<_HouseScopeStep> createState() => _HouseScopeStepState();
}

class _HouseScopeStepState extends State<_HouseScopeStep> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _beneficiary;
  late final TextEditingController _community;
  late final TextEditingController _phone;
  late final TextEditingController _gps;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final house = AppScope.of(context).selectedHouse;
    _beneficiary = TextEditingController(text: house.beneficiary);
    _community = TextEditingController(text: house.community);
    _phone = TextEditingController(text: house.phone);
    _gps = TextEditingController(text: house.gps);
  }

  @override
  void dispose() {
    _beneficiary.dispose();
    _community.dispose();
    _phone.dispose();
    _gps.dispose();
    super.dispose();
  }

  void _selectHouse(String code) {
    final state = AppScope.of(context)..selectHouse(code);
    final house = state.selectedHouse;
    _beneficiary.text = house.beneficiary;
    _community.text = house.community;
    _phone.text = house.phone;
    _gps.text = house.gps;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final state = AppScope.of(context);
    final house = state.selectedHouse;
    house.beneficiary = _beneficiary.text.trim();
    house.community = _community.text.trim();
    house.phone = _phone.text.trim();
    house.gps = _gps.text.trim();
    state.saveForm(
      type: 'Scope House',
      houseCode: house.code,
      values: <String, String>{
        'beneficiary': house.beneficiary,
        'community': house.community,
        'phone': house.phone,
        'gps': house.gps,
      },
    );
    showSavedMessage(context, submitted: false);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final house = state.selectedHouse;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                RcPageHeading(
                  eyebrow: 'Scope / 01 House',
                  title: 'House information',
                  description:
                      '${house.code} • ${house.parish} • ${house.cluster}',
                  action: const RcStatusChip(
                    label: 'ASSESSMENT FOUND',
                    icon: Icons.verified_outlined,
                    tone: RcStatusTone.success,
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const RcSectionHeader(
                          title: 'IA beneficiary lookup',
                          subtitle:
                              'Select a known source record to auto-fill operational context.',
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          value: house.code,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'House / Beneficiary code',
                            prefixIcon: Icon(Icons.manage_search),
                          ),
                          items: state.houses
                              .map(
                                (item) => DropdownMenuItem<String>(
                                  value: item.code,
                                  child: Text(
                                    '${item.code} — ${item.beneficiary}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) _selectHouse(value);
                          },
                        ),
                        const SizedBox(height: 14),
                        FilledButton.tonalIcon(
                          onPressed: () => Navigator.pushNamed(
                            context,
                            RcRoutes.operationalMap,
                          ),
                          icon: const Icon(Icons.location_on_outlined),
                          label: Text(
                            house.gps.isEmpty
                                ? 'CAPTURE LOCATION'
                                : 'VIEW ${house.gps}',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const RcSectionHeader(title: 'Beneficiary & property'),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _beneficiary,
                          decoration: const InputDecoration(
                            labelText: 'Beneficiary name',
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                                  ? 'Enter the beneficiary name.'
                                  : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _community,
                          decoration: const InputDecoration(
                            labelText: 'Community / Village',
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                                  ? 'Enter the community.'
                                  : null,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: TextFormField(
                                controller: _phone,
                                decoration: const InputDecoration(
                                  labelText: 'Telephone',
                                  prefixIcon: Icon(Icons.phone_outlined),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _gps,
                                decoration: const InputDecoration(
                                  labelText: 'GPS',
                                  prefixIcon: Icon(Icons.gps_fixed),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: <Widget>[
                            RcStatusChip(
                              label: house.roofType,
                              tone: RcStatusTone.info,
                            ),
                            RcStatusChip(
                              label:
                                  '${house.roofArea.toStringAsFixed(0)} sq ft',
                              tone: RcStatusTone.neutral,
                            ),
                            const RcStatusChip(
                              label: 'Wood / Block structure',
                              tone: RcStatusTone.neutral,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('SAVE HOUSE INFORMATION'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoofScopeStep extends StatefulWidget {
  const _RoofScopeStep();

  @override
  State<_RoofScopeStep> createState() => _RoofScopeStepState();
}

class _RoofScopeStepState extends State<_RoofScopeStep> {
  String _tool = 'Select';
  String _roofType = 'Gable';
  double _width = 18;
  double _length = 24.5;
  double _height = 9;
  double _pitch = 6;
  bool _drainEnabled = true;
  bool _snapEnabled = true;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final house = AppScope.of(context).selectedHouse;
    _roofType = house.roofType;
  }

  void _save() {
    final state = AppScope.of(context);
    final house = state.selectedHouse;
    house.roofType = _roofType;
    house.roofArea = _width * _length;
    state.saveForm(
      type: 'Scope Roof',
      houseCode: house.code,
      values: <String, String>{
        'roofType': _roofType,
        'width': _width.toStringAsFixed(1),
        'length': _length.toStringAsFixed(1),
        'wallHeight': _height.toStringAsFixed(1),
        'pitch': '${_pitch.toStringAsFixed(0)}/12',
        'drain': _drainEnabled.toString(),
      },
    );
    showSavedMessage(context, submitted: false);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final house = state.selectedHouse;
    const tools = <String>[
      'Select',
      'Wall',
      'Ridge',
      'Hip',
      'Valley',
      'Measure',
      'Drain',
      'Text',
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              RcPageHeading(
                eyebrow: 'Scope / 02 Roof',
                title: '${house.code} • Roof drawing',
                description:
                    'Build a measurable roof plan with robust field controls and explicit drain direction.',
                action: RcStatusChip(
                  label: _tool.toUpperCase(),
                  icon: Icons.touch_app_outlined,
                  tone: RcStatusTone.brand,
                ),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<String>(
                  segments: tools
                      .map(
                        (tool) => ButtonSegment<String>(
                          value: tool,
                          label: Text(tool),
                        ),
                      )
                      .toList(),
                  selected: <String>{_tool},
                  onSelectionChanged: (selection) =>
                      setState(() => _tool = selection.first),
                  showSelectedIcon: false,
                ),
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 760;
                  final canvas = Card(
                    clipBehavior: Clip.antiAlias,
                    child: SizedBox(
                      height: wide ? 520 : 390,
                      width: double.infinity,
                      child: Stack(
                        children: <Widget>[
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _RoofPlanPainter(
                                roofType: _roofType,
                                width: _width,
                                length: _length,
                                pitch: _pitch,
                                drainEnabled: _drainEnabled,
                                colorScheme: Theme.of(context).colorScheme,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Column(
                              children: <Widget>[
                                IconButton.filledTonal(
                                  onPressed: () => setState(
                                    () => _snapEnabled = !_snapEnabled,
                                  ),
                                  tooltip: _snapEnabled
                                      ? 'Disable snap to grid'
                                      : 'Enable snap to grid',
                                  icon: Icon(
                                    _snapEnabled
                                        ? Icons.grid_on
                                        : Icons.grid_off,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                IconButton.filledTonal(
                                  onPressed: () => setState(() {
                                    _width = 18;
                                    _length = 24.5;
                                    _height = 9;
                                    _pitch = 6;
                                    _roofType = 'Gable';
                                    _drainEnabled = true;
                                  }),
                                  tooltip: 'Reset drawing changes',
                                  icon: const Icon(Icons.undo),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                  final inspector = Card(
                    child: Padding(
                      padding: const EdgeInsets.all(17),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          const RcSectionHeader(
                            title: 'Wall details',
                            subtitle: 'North elevation selected',
                          ),
                          const SizedBox(height: 14),
                          DropdownButtonFormField<String>(
                            value: _roofType,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Roof type',
                            ),
                            items: const <String>[
                              'Gable',
                              'Hip',
                              'Shed / Mono',
                              'Intersecting',
                              'Custom',
                            ]
                                .map(
                                  (value) => DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(
                                      value,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) =>
                                setState(() => _roofType = value ?? _roofType),
                          ),
                          const SizedBox(height: 14),
                          _MeasurementSlider(
                            label: 'Length',
                            value: _length,
                            min: 8,
                            max: 50,
                            suffix: 'ft',
                            onChanged: (value) =>
                                setState(() => _length = value),
                          ),
                          _MeasurementSlider(
                            label: 'Width',
                            value: _width,
                            min: 8,
                            max: 40,
                            suffix: 'ft',
                            onChanged: (value) =>
                                setState(() => _width = value),
                          ),
                          _MeasurementSlider(
                            label: 'Wall height',
                            value: _height,
                            min: 6,
                            max: 16,
                            suffix: 'ft',
                            onChanged: (value) =>
                                setState(() => _height = value),
                          ),
                          _MeasurementSlider(
                            label: 'Pitch',
                            value: _pitch,
                            min: 1,
                            max: 12,
                            suffix: '/12',
                            onChanged: (value) =>
                                setState(() => _pitch = value),
                          ),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            value: _drainEnabled,
                            title: const Text(
                              'Drain system',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: const Text(
                              'Show gutter and flow direction',
                            ),
                            onChanged: (value) =>
                                setState(() => _drainEnabled = value),
                          ),
                          const SizedBox(height: 8),
                          FilledButton.icon(
                            onPressed: _save,
                            icon: const Icon(Icons.save_outlined),
                            label: const Text('SAVE ROOF DRAWING'),
                          ),
                        ],
                      ),
                    ),
                  );
                  if (wide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(flex: 3, child: canvas),
                        const SizedBox(width: 14),
                        SizedBox(width: 330, child: inspector),
                      ],
                    );
                  }
                  return Column(
                    children: <Widget>[
                      canvas,
                      const SizedBox(height: 14),
                      inspector,
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MeasurementSlider extends StatelessWidget {
  const _MeasurementSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.suffix,
    required this.onChanged,
  });
  final String label;
  final double value;
  final double min;
  final double max;
  final String suffix;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(label, style: Theme.of(context).textTheme.labelLarge),
            const Spacer(),
            Text(
              '${value.toStringAsFixed(1)} $suffix',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: Theme.of(context).colorScheme.primary),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: ((max - min) * 2).round(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _RoofPlanPainter extends CustomPainter {
  const _RoofPlanPainter({
    required this.roofType,
    required this.width,
    required this.length,
    required this.pitch,
    required this.drainEnabled,
    required this.colorScheme,
  });
  final String roofType;
  final double width;
  final double length;
  final double pitch;
  final bool drainEnabled;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = colorScheme.outlineVariant.withOpacity(.35)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 24) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += 24) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final planWidth = math.min(size.width * .68, 430.0);
    final planHeight = math.min(
      size.height * .52,
      planWidth * (width / length).clamp(.42, .9).toDouble(),
    );
    final rect = Rect.fromCenter(
      center: Offset(size.width * .47, size.height * .52),
      width: planWidth,
      height: planHeight,
    );
    final fill = Paint()..color = colorScheme.primaryContainer.withOpacity(.45);
    final outline = Paint()
      ..color = colorScheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      outline,
    );
    final ridge = Paint()
      ..color = RcColors.brandStrong
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    if (roofType == 'Hip') {
      final ridgeStart = Offset(rect.left + rect.width * .34, rect.center.dy);
      final ridgeEnd = Offset(rect.right - rect.width * .34, rect.center.dy);
      canvas.drawLine(ridgeStart, ridgeEnd, ridge);
      canvas.drawLine(rect.topLeft, ridgeStart, ridge);
      canvas.drawLine(rect.bottomLeft, ridgeStart, ridge);
      canvas.drawLine(rect.topRight, ridgeEnd, ridge);
      canvas.drawLine(rect.bottomRight, ridgeEnd, ridge);
    } else if (roofType == 'Shed / Mono') {
      canvas.drawLine(
        Offset(rect.left, rect.top + 8),
        Offset(rect.right, rect.top + 8),
        ridge,
      );
    } else {
      canvas.drawLine(
        Offset(rect.left + 10, rect.center.dy),
        Offset(rect.right - 10, rect.center.dy),
        ridge,
      );
    }
    final measure = Paint()
      ..color = colorScheme.onSurface
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawLine(
      Offset(rect.left, rect.bottom + 30),
      Offset(rect.right, rect.bottom + 30),
      measure,
    );
    canvas.drawCircle(
      Offset(rect.left, rect.bottom + 30),
      6,
      Paint()..color = colorScheme.primary,
    );
    canvas.drawCircle(
      Offset(rect.right, rect.bottom + 30),
      6,
      Paint()..color = colorScheme.primary,
    );
    _drawLabel(
      canvas,
      '${length.toStringAsFixed(1)} ft',
      Offset(rect.center.dx, rect.bottom + 45),
      colorScheme.onSurface,
    );
    _drawLabel(
      canvas,
      '$roofType • ${pitch.toStringAsFixed(0)}/12',
      Offset(rect.center.dx, rect.top - 25),
      colorScheme.primary,
    );
    if (drainEnabled) {
      final drain = Paint()
        ..color = RcColors.info
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(rect.right + 16, rect.top),
        Offset(rect.right + 16, rect.bottom),
        drain,
      );
      canvas.drawLine(
        Offset(rect.right + 16, rect.bottom),
        Offset(rect.right + 8, rect.bottom - 12),
        drain,
      );
      canvas.drawLine(
        Offset(rect.right + 16, rect.bottom),
        Offset(rect.right + 24, rect.bottom - 12),
        drain,
      );
    }
  }

  void _drawLabel(Canvas canvas, String text, Offset center, Color color) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _RoofPlanPainter oldDelegate) {
    return oldDelegate.roofType != roofType ||
        oldDelegate.width != width ||
        oldDelegate.length != length ||
        oldDelegate.pitch != pitch ||
        oldDelegate.drainEnabled != drainEnabled ||
        oldDelegate.colorScheme != colorScheme;
  }
}

class _PrintScopeStep extends StatefulWidget {
  const _PrintScopeStep();

  @override
  State<_PrintScopeStep> createState() => _PrintScopeStepState();
}

class _PrintScopeStepState extends State<_PrintScopeStep> {
  bool _beneficiarySigned = true;
  bool _carpenterSigned = true;
  bool _supervisorSigned = false;
  bool _specialistSigned = false;

  @override
  Widget build(BuildContext context) {
    final house = AppScope.of(context).selectedHouse;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              RcPageHeading(
                eyebrow: 'Scope / 03 Print',
                title: 'Beneficiary printout',
                description:
                    'Review the official technical summary and signatures before generating files.',
                action: const RcStatusChip(
                  label: 'PREVIEW',
                  icon: Icons.visibility_outlined,
                  tone: RcStatusTone.info,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: RcColors.outline),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withOpacity(.08),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: DefaultTextStyle.merge(
                  style: const TextStyle(color: RcColors.ink),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 24,
                        runSpacing: 12,
                        children: <Widget>[
                          RcBrand(),
                          Text(
                            'SCOPE OF WORK',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.4,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 34),
                      Text(
                        '${house.code} — ${house.beneficiary}',
                        style: const TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${house.community}, ${house.parish} • ${house.cluster}',
                      ),
                      const SizedBox(height: 22),
                      Wrap(
                        spacing: 28,
                        runSpacing: 12,
                        children: <Widget>[
                          _PrintFact(label: 'Roof type', value: house.roofType),
                          _PrintFact(
                            label: 'Roof area',
                            value: '${house.roofArea.toStringAsFixed(0)} sq ft',
                          ),
                          _PrintFact(
                            label: 'GPS',
                            value: house.gps.isEmpty ? 'Pending' : house.gps,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'TECHNICAL SUMMARY',
                        style: TextStyle(
                          color: RcColors.brandStrong,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Remove and replace damaged roof covering, repair structural timber where required, install hurricane straps, zinc, flashing, fascia and rainwater control according to approved scope.',
                      ),
                      const SizedBox(height: 22),
                      Container(
                        height: 210,
                        decoration: BoxDecoration(
                          color: RcColors.canvas,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: CustomPaint(
                          painter: _RoofPlanPainter(
                            roofType: house.roofType,
                            width: 18,
                            length: 24.5,
                            pitch: 6,
                            drainEnabled: true,
                            colorScheme: const ColorScheme.light(
                              primary: RcColors.brand,
                              onSurface: RcColors.ink,
                              outlineVariant: RcColors.outline,
                              primaryContainer: RcColors.brandSoft,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'AUTHORIZATIONS',
                        style: TextStyle(
                          color: RcColors.brandStrong,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _SignatureCheck(
                        label: 'Beneficiary',
                        value: _beneficiarySigned,
                        onChanged: (value) =>
                            setState(() => _beneficiarySigned = value),
                      ),
                      _SignatureCheck(
                        label: 'Carpenter Lead',
                        value: _carpenterSigned,
                        onChanged: (value) =>
                            setState(() => _carpenterSigned = value),
                      ),
                      _SignatureCheck(
                        label: 'Site Supervisor',
                        value: _supervisorSigned,
                        onChanged: (value) =>
                            setState(() => _supervisorSigned = value),
                      ),
                      _SignatureCheck(
                        label: 'Construction Specialist',
                        value: _specialistSigned,
                        onChanged: (value) =>
                            setState(() => _specialistSigned = value),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _export(context, 'Print'),
                      icon: const Icon(Icons.print_outlined),
                      label: const Text('PRINT'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _export(context, 'PDF'),
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: const Text('GENERATE PDF'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _export(BuildContext context, String type) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$type preview generated and linked to the house files.'),
      ),
    );
  }
}

class _PrintFact extends StatelessWidget {
  const _PrintFact({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            color: Colors.black54,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _SignatureCheck extends StatelessWidget {
  const _SignatureCheck({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: CheckboxListTile(
        value: value,
        onChanged: (next) => onChanged(next ?? false),
        contentPadding: EdgeInsets.zero,
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          value ? 'Digitally acknowledged' : 'Signature required',
        ),
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }
}

class _FilesScopeStep extends StatelessWidget {
  const _FilesScopeStep();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final house = state.selectedHouse;
    final evidence =
        state.evidence.where((item) => item.houseCode == house.code).toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              RcPageHeading(
                eyebrow: 'Scope / 04 Files',
                title: 'Files & evidence',
                description:
                    '${house.code} contains ${evidence.length} captured evidence items and generated operational files.',
                action: FilledButton.icon(
                  onPressed: () => _addEvidence(context),
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: const Text('ADD EVIDENCE'),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      RcSectionHeader(
                        title: 'Evidence readiness',
                        subtitle:
                            '${house.evidenceComplete} of ${house.evidenceRequired} required items complete',
                        trailing: RcStatusChip(
                          label: house.evidenceReady ? 'READY' : 'INCOMPLETE',
                          tone: house.evidenceReady
                              ? RcStatusTone.success
                              : RcStatusTone.warning,
                        ),
                      ),
                      const SizedBox(height: 14),
                      LinearProgressIndicator(
                        value: house.evidenceComplete / house.evidenceRequired,
                        minHeight: 9,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const RcSectionHeader(title: 'Captured evidence'),
              const SizedBox(height: 10),
              if (evidence.isEmpty)
                RcEmptyState(
                  icon: Icons.add_a_photo_outlined,
                  title: 'No evidence captured',
                  message:
                      'Add a classified photo or document. Draft data remains safe.',
                  action: FilledButton(
                    onPressed: () => _addEvidence(context),
                    child: const Text('ADD FIRST EVIDENCE'),
                  ),
                )
              else
                Card(
                  child: Column(
                    children: evidence.map((item) {
                      return ListTile(
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            item.type == 'Document'
                                ? Icons.picture_as_pdf_outlined
                                : Icons.image_outlined,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        title: Text(
                          item.caption,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text('${item.type} • ${item.capturedBy}'),
                        trailing: Icon(
                          item.approved ? Icons.verified : Icons.schedule,
                          color: item.approved
                              ? RcColors.success
                              : RcColors.warning,
                        ),
                        onTap: () =>
                            Navigator.pushNamed(context, RcRoutes.evidence),
                      );
                    }).toList(),
                  ),
                ),
              const SizedBox(height: 18),
              const RcSectionHeader(title: 'Generated files'),
              const SizedBox(height: 10),
              Card(
                child: Column(
                  children: <Widget>[
                    ListTile(
                      leading: const Icon(
                        Icons.picture_as_pdf_outlined,
                        color: RcColors.brand,
                      ),
                      title: Text('${house.code}_Scope_of_Work.pdf'),
                      subtitle: const Text('Generated printout • Synced'),
                      trailing: const Icon(Icons.download_outlined),
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.table_view_outlined,
                        color: RcColors.success,
                      ),
                      title: Text('${house.code}_Control_of_Works.xlsx'),
                      subtitle: const Text('Operational workbook export'),
                      trailing: const Icon(Icons.download_outlined),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addEvidence(BuildContext context) {
    String selectedType = 'During';
    String caption = '';
    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add evidence'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              DropdownButtonFormField<String>(
                value: selectedType,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Evidence type'),
                items: const <String>[
                  'Before',
                  'During',
                  'After',
                  'Delivery',
                  'Defect',
                  'Completion',
                  'Document',
                ]
                    .map(
                      (item) => DropdownMenuItem<String>(
                        value: item,
                        child: Text(
                          item,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (next) => setDialogState(
                  () => selectedType = next ?? selectedType,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                onChanged: (value) => caption = value,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('CANCEL'),
            ),
            FilledButton(
              onPressed: () {
                final description = caption.trim();
                if (description.isEmpty) return;
                AppScope.of(context).addEvidence(
                  type: selectedType,
                  caption: description,
                );
                Navigator.pop(dialogContext);
                showSavedMessage(context, submitted: false);
              },
              child: const Text('SAVE'),
            ),
          ],
        ),
      ),
    );
  }
}
