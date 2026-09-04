import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/production_models.dart';
import '../core/roof_drawing_controller.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../core/widgets.dart';

class RoofDrawingStudio extends StatefulWidget {
  const RoofDrawingStudio({super.key});

  @override
  State<RoofDrawingStudio> createState() => _RoofDrawingStudioState();
}

class _RoofDrawingStudioState extends State<RoofDrawingStudio> {
  RoofDrawingController? _controller;
  final TransformationController _viewport = TransformationController();
  RoofTool _tool = RoofTool.select;
  ({String sectionId, int nodeIndex})? _draggedNode;
  bool _draggingSection = false;
  Offset? _lineStart;
  Offset? _lineEnd;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final state = AppScope.of(context);
    _controller = RoofDrawingController(
      state.roofDrawingFor(state.selectedHouseCode),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _viewport.dispose();
    super.dispose();
  }

  Future<void> _openImport() async {
    final controller = _controller!;
    final result = await Navigator.pushNamed(
      context,
      RcRoutes.scopeImport,
      arguments: controller.document.deepCopy(),
    );
    if (!mounted || result is! AiRoofSuggestion) return;
    controller.replaceDocument(result.document);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Image proposal added at ${(result.overallConfidence * 100).round()}% confidence. Review every node before submission.',
        ),
      ),
    );
  }

  void _save({bool submit = false}) {
    final state = AppScope.of(context);
    state.saveRoofDrawing(_controller!.document, submit: submit);
    showSavedMessage(context, submitted: submit);
  }

  void _zoom(double factor) {
    final current = _viewport.value.getMaxScaleOnAxis();
    final next = (current * factor).clamp(.35, 4).toDouble();
    _viewport.value = Matrix4.diagonal3Values(next, next, 1);
  }

  void _resetView() => _viewport.value = Matrix4.identity();

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final document = controller.document;
        final selected = controller.selectedSection;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1240),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  RcPageHeading(
                    eyebrow: 'Scope / 02 Roof / Drawing Studio',
                    title: '${document.houseCode} • Roof drawing studio',
                    description:
                        'Draw, resize, rotate and combine roof structures. Every image-assisted result remains a proposal until you verify and accept it.',
                    action: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.end,
                      children: <Widget>[
                        OutlinedButton.icon(
                          onPressed: _openImport,
                          icon: const Icon(Icons.auto_awesome_outlined),
                          label: const Text('IMAGE / LEGACY IMPORT'),
                        ),
                        PopupMenuButton<String>(
                          tooltip: 'Add roof structure',
                          onSelected: controller.addSection,
                          itemBuilder: (context) => const <PopupMenuEntry<String>>[
                            PopupMenuItem<String>(
                              value: 'Main house',
                              child: Text('Add main structure'),
                            ),
                            PopupMenuItem<String>(
                              value: 'Verandah',
                              child: Text('Add verandah'),
                            ),
                            PopupMenuItem<String>(
                              value: 'Secondary structure',
                              child: Text('Add secondary structure'),
                            ),
                          ],
                          child: const Chip(
                            avatar: Icon(Icons.add_home_work_outlined),
                            label: Text('ADD STRUCTURE'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _DrawingProvenance(document: document),
                  const SizedBox(height: 12),
                  _ToolRail(
                    selected: _tool,
                    snapEnabled: document.snapEnabled,
                    canUndo: controller.canUndo,
                    canRedo: controller.canRedo,
                    onTool: (tool) => setState(() => _tool = tool),
                    onUndo: controller.undo,
                    onRedo: controller.redo,
                    onSnap: () => controller.setSnap(!document.snapEnabled),
                    onClear: _confirmClear,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: document.sections.map((section) {
                      final active = section.id == document.selectedSectionId;
                      return ChoiceChip(
                        selected: active,
                        avatar: Icon(
                          section.locked
                              ? Icons.lock_outline
                              : Icons.roofing_outlined,
                          size: 18,
                        ),
                        label: Text(section.name),
                        onSelected: (_) => controller.selectSection(section.id),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 860;
                      final canvas = _DrawingCanvas(
                        controller: controller,
                        viewport: _viewport,
                        tool: _tool,
                        lineStart: _lineStart,
                        lineEnd: _lineEnd,
                        onTapDown: _handleTap,
                        onPanStart: _handlePanStart,
                        onPanUpdate: _handlePanUpdate,
                        onPanEnd: _handlePanEnd,
                        onZoomIn: () => _zoom(1.25),
                        onZoomOut: () => _zoom(.8),
                        onResetView: _resetView,
                      );
                      final inspector = _RoofInspector(
                        controller: controller,
                        section: selected,
                        onSave: () => _save(),
                        onSubmit: () => _save(submit: true),
                      );
                      if (wide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Expanded(child: canvas),
                            const SizedBox(width: 14),
                            SizedBox(width: 350, child: inspector),
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
      },
    );
  }

  Future<void> _confirmClear() async {
    final clear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear drawing?'),
        content: const Text(
          'This resets the canvas to one main roof. You can undo the change afterwards.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('CLEAR'),
          ),
        ],
      ),
    );
    if (clear == true) _controller!.clearDrawing();
  }

  void _handleTap(TapDownDetails details) {
    final controller = _controller!;
    final point = details.localPosition;
    if (_tool == RoofTool.wall) {
      controller.addWallNode(point);
      return;
    }
    if (_tool != RoofTool.select) return;
    final node = controller.hitTestNode(point);
    if (node != null) {
      controller.selectNode(node.sectionId, node.nodeIndex);
      return;
    }
    final section = controller.hitTestSection(point);
    if (section != null) controller.selectSection(section);
  }

  void _handlePanStart(DragStartDetails details) {
    final controller = _controller!;
    if (_tool == RoofTool.pan) return;
    if (_lineKindFor(_tool) != null) {
      setState(() {
        _lineStart = details.localPosition;
        _lineEnd = details.localPosition;
      });
      return;
    }
    if (_tool != RoofTool.select) return;
    final node = controller.hitTestNode(details.localPosition);
    if (node != null) {
      controller.beginGestureCheckpoint();
      controller.selectNode(node.sectionId, node.nodeIndex);
      _draggedNode = node;
      return;
    }
    final section = controller.hitTestSection(details.localPosition);
    if (section != null) {
      controller.selectSection(section);
      controller.beginGestureCheckpoint();
      _draggingSection = true;
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    final controller = _controller!;
    if (_lineStart != null) {
      setState(() => _lineEnd = details.localPosition);
      return;
    }
    final node = _draggedNode;
    if (node != null) {
      controller.moveNode(node.sectionId, node.nodeIndex, details.localPosition);
    } else if (_draggingSection) {
      controller.moveSelected(details.delta);
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    final start = _lineStart;
    final end = _lineEnd;
    final kind = _lineKindFor(_tool);
    if (start != null && end != null && kind != null) {
      _controller!.addLine(kind, start, end);
    }
    setState(() {
      _draggedNode = null;
      _draggingSection = false;
      _lineStart = null;
      _lineEnd = null;
    });
  }

  RoofLineKind? _lineKindFor(RoofTool tool) => switch (tool) {
        RoofTool.ridge => RoofLineKind.ridge,
        RoofTool.hip => RoofLineKind.hip,
        RoofTool.valley => RoofLineKind.valley,
        RoofTool.measure => RoofLineKind.measurement,
        RoofTool.drain => RoofLineKind.drain,
        RoofTool.text => RoofLineKind.note,
        _ => null,
      };
}

class _DrawingProvenance extends StatelessWidget {
  const _DrawingProvenance({required this.document});

  final RoofDrawingDocument document;

  @override
  Widget build(BuildContext context) {
    final imported = document.sourceFileName != null;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        RcStatusChip(
          label: document.source.toUpperCase(),
          icon: imported ? Icons.auto_awesome : Icons.touch_app_outlined,
          tone: imported ? RcStatusTone.info : RcStatusTone.brand,
        ),
        RcStatusChip(
          label: '${document.sections.length} STRUCTURE${document.sections.length == 1 ? '' : 'S'}',
          icon: Icons.layers_outlined,
          tone: RcStatusTone.neutral,
        ),
        RcStatusChip(
          label: '${document.totalPlanAreaSqFt.toStringAsFixed(0)} SQ FT',
          icon: Icons.square_foot,
          tone: RcStatusTone.success,
        ),
        if (document.aiConfidence case final confidence?)
          RcStatusChip(
            label: 'AI ${(confidence * 100).round()}% • REVIEW REQUIRED',
            icon: Icons.fact_check_outlined,
            tone: confidence < .7
                ? RcStatusTone.warning
                : RcStatusTone.info,
          ),
      ],
    );
  }
}

class _ToolRail extends StatelessWidget {
  const _ToolRail({
    required this.selected,
    required this.snapEnabled,
    required this.canUndo,
    required this.canRedo,
    required this.onTool,
    required this.onUndo,
    required this.onRedo,
    required this.onSnap,
    required this.onClear,
  });

  final RoofTool selected;
  final bool snapEnabled;
  final bool canUndo;
  final bool canRedo;
  final ValueChanged<RoofTool> onTool;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onSnap;
  final VoidCallback onClear;

  IconData _icon(RoofTool tool) => switch (tool) {
        RoofTool.select => Icons.touch_app_outlined,
        RoofTool.pan => Icons.pan_tool_alt_outlined,
        RoofTool.wall => Icons.polyline_outlined,
        RoofTool.ridge => Icons.horizontal_rule,
        RoofTool.hip => Icons.call_made,
        RoofTool.valley => Icons.call_received,
        RoofTool.measure => Icons.straighten,
        RoofTool.drain => Icons.south,
        RoofTool.text => Icons.title,
      };

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: RoofTool.values.map((tool) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        selected: selected == tool,
                        avatar: Icon(_icon(tool), size: 18),
                        label: Text(tool.label),
                        onSelected: (_) => onTool(tool),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const VerticalDivider(width: 18),
            IconButton(
              tooltip: 'Undo drawing change',
              onPressed: canUndo ? onUndo : null,
              icon: const Icon(Icons.undo),
            ),
            IconButton(
              tooltip: 'Redo drawing change',
              onPressed: canRedo ? onRedo : null,
              icon: const Icon(Icons.redo),
            ),
            IconButton(
              tooltip: snapEnabled ? 'Disable snap' : 'Enable snap',
              onPressed: onSnap,
              icon: Icon(snapEnabled ? Icons.grid_on : Icons.grid_off),
            ),
            IconButton(
              tooltip: 'Clear drawing',
              onPressed: onClear,
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawingCanvas extends StatelessWidget {
  const _DrawingCanvas({
    required this.controller,
    required this.viewport,
    required this.tool,
    required this.lineStart,
    required this.lineEnd,
    required this.onTapDown,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onResetView,
  });

  final RoofDrawingController controller;
  final TransformationController viewport;
  final RoofTool tool;
  final Offset? lineStart;
  final Offset? lineEnd;
  final GestureTapDownCallback onTapDown;
  final GestureDragStartCallback onPanStart;
  final GestureDragUpdateCallback onPanUpdate;
  final GestureDragEndCallback onPanEnd;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onResetView;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 610,
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: InteractiveViewer(
                transformationController: viewport,
                constrained: false,
                minScale: .35,
                maxScale: 4,
                boundaryMargin: const EdgeInsets.all(180),
                panEnabled: tool == RoofTool.pan,
                scaleEnabled: tool == RoofTool.pan,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: tool == RoofTool.pan ? null : onTapDown,
                  onPanStart: tool == RoofTool.pan ? null : onPanStart,
                  onPanUpdate: tool == RoofTool.pan ? null : onPanUpdate,
                  onPanEnd: tool == RoofTool.pan ? null : onPanEnd,
                  child: CustomPaint(
                    size: const Size(1200, 900),
                    painter: _EditableRoofPainter(
                      controller: controller,
                      colorScheme: Theme.of(context).colorScheme,
                      previewStart: lineStart,
                      previewEnd: lineEnd,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12,
              top: 12,
              child: Card(
                color: Theme.of(context).colorScheme.surface.withOpacity(.94),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        tool == RoofTool.pan
                            ? Icons.pinch_outlined
                            : Icons.touch_app_outlined,
                        size: 18,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        _instruction(tool),
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: 12,
              top: 12,
              child: Column(
                children: <Widget>[
                  IconButton.filledTonal(
                    tooltip: 'Zoom in',
                    onPressed: onZoomIn,
                    icon: const Icon(Icons.add),
                  ),
                  const SizedBox(height: 6),
                  IconButton.filledTonal(
                    tooltip: 'Zoom out',
                    onPressed: onZoomOut,
                    icon: const Icon(Icons.remove),
                  ),
                  const SizedBox(height: 6),
                  IconButton.filledTonal(
                    tooltip: 'Fit drawing',
                    onPressed: onResetView,
                    icon: const Icon(Icons.center_focus_strong),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _instruction(RoofTool tool) => switch (tool) {
        RoofTool.select => 'Drag a blue node or move the selected roof',
        RoofTool.pan => 'Pinch to zoom • drag to pan',
        RoofTool.wall => 'Tap an edge to add a wall node',
        RoofTool.text => 'Drag to place a note leader',
        _ => 'Drag from start to end to add ${tool.label.toLowerCase()}',
      };
}

class _RoofInspector extends StatelessWidget {
  const _RoofInspector({
    required this.controller,
    required this.section,
    required this.onSave,
    required this.onSubmit,
  });

  final RoofDrawingController controller;
  final RoofSection section;
  final VoidCallback onSave;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                        section.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '${section.structure} • ${section.nodes.length} wall nodes',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: section.locked ? 'Unlock section' : 'Lock section',
                  onPressed: () => controller.setLocked(!section.locked),
                  icon: Icon(section.locked ? Icons.lock : Icons.lock_open),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: section.roofType,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Roof type'),
              items: const <String>[
                'Gable',
                'Hip',
                'Shed / Mono',
                'Flat',
                'Intersecting',
                'Custom',
              ]
                  .map(
                    (value) => DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    ),
                  )
                  .toList(),
              onChanged: section.locked
                  ? null
                  : (value) {
                      if (value != null) controller.setRoofType(value);
                    },
            ),
            const SizedBox(height: 12),
            _MeasurementControl(
              label: 'Length',
              value: section.lengthFt,
              min: 4,
              max: 80,
              suffix: 'ft',
              enabled: !section.locked,
              onStart: controller.beginGestureCheckpoint,
              onChanged: (value) => controller.updateDimensions(
                lengthFt: value,
                recordHistory: false,
              ),
            ),
            _MeasurementControl(
              label: 'Width',
              value: section.widthFt,
              min: 4,
              max: 60,
              suffix: 'ft',
              enabled: !section.locked,
              onStart: controller.beginGestureCheckpoint,
              onChanged: (value) => controller.updateDimensions(
                widthFt: value,
                recordHistory: false,
              ),
            ),
            _MeasurementControl(
              label: 'Wall height',
              value: section.wallHeightFt,
              min: 5,
              max: 20,
              suffix: 'ft',
              enabled: !section.locked,
              onStart: controller.beginGestureCheckpoint,
              onChanged: (value) => controller.updateDimensions(
                wallHeightFt: value,
                recordHistory: false,
              ),
            ),
            _MeasurementControl(
              label: 'Pitch',
              value: section.pitchRisePer12,
              min: 0,
              max: 14,
              suffix: '/12',
              enabled: !section.locked,
              onStart: controller.beginGestureCheckpoint,
              onChanged: (value) => controller.updateDimensions(
                pitchRisePer12: value,
                recordHistory: false,
              ),
            ),
            _MeasurementControl(
              label: 'Rotation',
              value: section.rotationDegrees,
              min: 0,
              max: 360,
              suffix: '°',
              enabled: !section.locked,
              onStart: controller.beginGestureCheckpoint,
              onChanged: (value) =>
                  controller.setRotation(value, recordHistory: false),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: section.drainEnabled,
              title: const Text(
                'Drain / fall arrow',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text('${section.drainAngleDegrees.round()}° direction'),
              onChanged: section.locked
                  ? null
                  : (value) => controller.setDrain(enabled: value),
            ),
            if (section.drainEnabled)
              _MeasurementControl(
                label: 'Fall direction',
                value: section.drainAngleDegrees,
                min: 0,
                max: 360,
                suffix: '°',
                enabled: !section.locked,
                onStart: controller.beginGestureCheckpoint,
                onChanged: (value) => controller.setDrain(
                  angleDegrees: value,
                  recordHistory: false,
                ),
              ),
            const Divider(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                RcStatusChip(
                  label: '${section.planAreaSqFt.toStringAsFixed(0)} SQ FT',
                  icon: Icons.square_foot,
                  tone: RcStatusTone.info,
                ),
                RcStatusChip(
                  label: 'RAFTER ${section.rafterLengthFt.toStringAsFixed(1)} FT',
                  icon: Icons.architecture_outlined,
                  tone: RcStatusTone.neutral,
                ),
                RcStatusChip(
                  label: 'RISE ${section.ridgeRiseFt.toStringAsFixed(1)} FT',
                  icon: Icons.height,
                  tone: RcStatusTone.neutral,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: controller.duplicateSelected,
                    icon: const Icon(Icons.copy_outlined),
                    label: const Text('DUPLICATE'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.outlined(
                  tooltip: 'Delete selected node',
                  onPressed: controller.document.selectedNodeIndex == null
                      ? null
                      : controller.removeSelectedNode,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                const SizedBox(width: 8),
                IconButton.outlined(
                  tooltip: 'Delete selected structure',
                  onPressed: controller.document.sections.length <= 1
                      ? null
                      : controller.deleteSelected,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onSave,
              icon: const Icon(Icons.save_outlined),
              label: const Text('SAVE DRAFT ON DEVICE'),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: onSubmit,
              icon: const Icon(Icons.send_outlined),
              label: const Text('SUBMIT VERIFIED DRAWING'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MeasurementControl extends StatelessWidget {
  const _MeasurementControl({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.suffix,
    required this.enabled,
    required this.onStart,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final String suffix;
  final bool enabled;
  final VoidCallback onStart;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: Text(label)),
            TextButton.icon(
              onPressed: enabled ? () => _editValue(context) : null,
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: Text('${value.toStringAsFixed(1)} $suffix'),
            ),
          ],
        ),
        Slider(
          value: value.clamp(min, max).toDouble(),
          min: min,
          max: max,
          divisions: ((max - min) * 2).round(),
          onChangeStart: enabled ? (_) => onStart() : null,
          onChanged: enabled ? onChanged : null,
        ),
      ],
    );
  }

  Future<void> _editValue(BuildContext context) async {
    final field = TextEditingController(text: value.toStringAsFixed(1));
    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enter $label'),
        content: TextField(
          controller: field,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(suffixText: suffix),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              double.tryParse(field.text)?.clamp(min, max).toDouble(),
            ),
            child: const Text('APPLY'),
          ),
        ],
      ),
    );
    field.dispose();
    if (result != null) {
      onStart();
      onChanged(result);
    }
  }
}

class _EditableRoofPainter extends CustomPainter {
  const _EditableRoofPainter({
    required this.controller,
    required this.colorScheme,
    required this.previewStart,
    required this.previewEnd,
  });

  final RoofDrawingController controller;
  final ColorScheme colorScheme;
  final Offset? previewStart;
  final Offset? previewEnd;

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas, size);
    for (final section in controller.document.sections) {
      _drawSection(canvas, section);
    }
    final start = previewStart;
    final end = previewEnd;
    if (start != null && end != null) {
      canvas.drawLine(
        start,
        end,
        Paint()
          ..color = colorScheme.primary
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final minor = Paint()
      ..color = colorScheme.outlineVariant.withOpacity(.22)
      ..strokeWidth = 1;
    final major = Paint()
      ..color = colorScheme.outlineVariant.withOpacity(.42)
      ..strokeWidth = 1.4;
    for (double x = 0; x <= size.width; x += 20) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        x % 100 == 0 ? major : minor,
      );
    }
    for (double y = 0; y <= size.height; y += 20) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        y % 100 == 0 ? major : minor,
      );
    }
  }

  void _drawSection(Canvas canvas, RoofSection section) {
    if (section.nodes.length < 3) return;
    final active = section.id == controller.document.selectedSectionId;
    final transformed = section.nodes
        .map((node) => controller.transformPoint(node.offset, section))
        .toList();
    final path = Path()..moveTo(transformed.first.dx, transformed.first.dy);
    for (final point in transformed.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..color = active
            ? colorScheme.primaryContainer.withOpacity(.38)
            : colorScheme.surface.withOpacity(.88),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = active ? colorScheme.primary : colorScheme.outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = active ? 4 : 2
        ..strokeJoin = StrokeJoin.round,
    );
    for (final line in section.lines) {
      final start = controller.transformPoint(line.start.offset, section);
      final end = controller.transformPoint(line.end.offset, section);
      final paint = Paint()
        ..color = _lineColor(line.kind)
        ..strokeWidth = line.kind == RoofLineKind.ridge ? 4 : 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      if (line.kind == RoofLineKind.valley ||
          line.kind == RoofLineKind.measurement) {
        _drawDashedLine(canvas, start, end, paint);
      } else {
        canvas.drawLine(start, end, paint);
      }
      if (line.kind == RoofLineKind.drain) _arrowHead(canvas, start, end, paint);
      if (line.label.isNotEmpty) {
        _label(canvas, line.label, Offset.lerp(start, end, .5)!, paint.color);
      }
    }
    if (section.drainEnabled) {
      final radians = section.drainAngleDegrees * math.pi / 180;
      final start = section.center;
      final end = start + Offset(math.cos(radians), math.sin(radians)) * 76;
      final drain = Paint()
        ..color = RcColors.info
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(start, end, drain);
      _arrowHead(canvas, start, end, drain);
    }
    for (var index = 0; index < transformed.length; index++) {
      final point = transformed[index];
      final selected = active && controller.document.selectedNodeIndex == index;
      canvas.drawCircle(
        point,
        selected ? 15 : 12,
        Paint()..color = colorScheme.surface,
      );
      canvas.drawCircle(
        point,
        selected ? 11 : 8,
        Paint()..color = selected ? colorScheme.primary : RcColors.info,
      );
    }
    final top = transformed.reduce((a, b) => a.dy < b.dy ? a : b);
    _label(
      canvas,
      '${section.name} • ${section.lengthFt.toStringAsFixed(1)} × ${section.widthFt.toStringAsFixed(1)} ft',
      top - const Offset(0, 28),
      active ? colorScheme.primary : colorScheme.onSurface,
    );
  }

  Color _lineColor(RoofLineKind kind) => switch (kind) {
        RoofLineKind.ridge => RcColors.brandStrong,
        RoofLineKind.hip => RcColors.brand,
        RoofLineKind.valley => RcColors.warning,
        RoofLineKind.measurement => colorScheme.onSurfaceVariant,
        RoofLineKind.drain => RcColors.info,
        RoofLineKind.note => RcColors.success,
      };

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    final distance = (end - start).distance;
    if (distance == 0) return;
    final direction = (end - start) / distance;
    for (double position = 0; position < distance; position += 14) {
      canvas.drawLine(
        start + direction * position,
        start + direction * math.min(position + 8, distance),
        paint,
      );
    }
  }

  void _arrowHead(Canvas canvas, Offset start, Offset end, Paint paint) {
    final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
    const spread = .62;
    const length = 13.0;
    canvas.drawLine(
      end,
      end - Offset(math.cos(angle - spread), math.sin(angle - spread)) * length,
      paint,
    );
    canvas.drawLine(
      end,
      end - Offset(math.cos(angle + spread), math.sin(angle + spread)) * length,
      paint,
    );
  }

  void _label(Canvas canvas, String text, Offset center, Color color) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w800,
          backgroundColor: colorScheme.surface.withOpacity(.78),
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: 320);
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _EditableRoofPainter oldDelegate) => true;
}
