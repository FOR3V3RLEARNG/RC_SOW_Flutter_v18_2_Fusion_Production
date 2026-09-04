import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'production_models.dart';

class RoofDrawingController extends ChangeNotifier {
  RoofDrawingController(RoofDrawingDocument document)
      : _document = document.deepCopy();

  RoofDrawingDocument _document;
  final List<RoofDrawingDocument> _undo = <RoofDrawingDocument>[];
  final List<RoofDrawingDocument> _redo = <RoofDrawingDocument>[];

  RoofDrawingDocument get document => _document;
  RoofSection get selectedSection => _document.selectedSection;
  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  void replaceDocument(RoofDrawingDocument document) {
    _checkpoint();
    _document = document.deepCopy();
    _document.updatedAt = DateTime.now();
    notifyListeners();
  }

  void selectSection(String id) {
    if (_document.selectedSectionId == id) return;
    _document.selectedSectionId = id;
    _document.selectedNodeIndex = null;
    notifyListeners();
  }

  void selectNode(String sectionId, int? nodeIndex) {
    _document.selectedSectionId = sectionId;
    _document.selectedNodeIndex = nodeIndex;
    notifyListeners();
  }

  void setSnap(bool value) {
    _document.snapEnabled = value;
    notifyListeners();
  }

  void addSection(String structure) {
    _checkpoint();
    final number = _document.sections.length + 1;
    final id = '${structure.toLowerCase().replaceAll(' ', '-')}-${DateTime.now().microsecondsSinceEpoch}';
    final offset = 42.0 * (_document.sections.length % 4);
    final section = defaultRoofSection(
      id: id,
      name: '$structure roof $number',
      structure: structure,
      left: 240 + offset,
      top: 230 + offset,
      width: structure == 'Verandah' ? 260 : 350,
      height: structure == 'Verandah' ? 120 : 230,
    );
    if (structure == 'Verandah') {
      section.roofType = 'Shed / Mono';
      _rebuildAutomaticLines(section);
    }
    _document.sections.add(section);
    _document.selectedSectionId = section.id;
    _document.selectedNodeIndex = null;
    _touch();
  }

  void duplicateSelected() {
    _checkpoint();
    final source = selectedSection;
    final id = '${source.id}-copy-${DateTime.now().microsecondsSinceEpoch}';
    final copy = source.deepCopy()
      ..name = '${source.name} copy'
      ..nodes = source.nodes
          .map(
            (node) => RoofNode(
              id: '$id-${node.id}',
              x: node.x + 42,
              y: node.y + 42,
            ),
          )
          .toList()
      ..lines = source.lines
          .map(
            (line) => RoofLine(
              id: '$id-${line.id}',
              kind: line.kind,
              start: RoofNode(
                id: '$id-${line.start.id}',
                x: line.start.x + 42,
                y: line.start.y + 42,
              ),
              end: RoofNode(
                id: '$id-${line.end.id}',
                x: line.end.x + 42,
                y: line.end.y + 42,
              ),
              label: line.label,
            ),
          )
          .toList();
    final duplicated = RoofSection.fromMap(<String, dynamic>{
      ...copy.toMap(),
      'id': id,
    });
    _document.sections.add(duplicated);
    _document.selectedSectionId = id;
    _document.selectedNodeIndex = null;
    _touch();
  }

  void deleteSelected() {
    if (_document.sections.length <= 1) return;
    _checkpoint();
    _document.sections.removeWhere(
      (section) => section.id == _document.selectedSectionId,
    );
    _document.selectedSectionId = _document.sections.first.id;
    _document.selectedNodeIndex = null;
    _touch();
  }

  void clearDrawing() {
    _checkpoint();
    final replacement = defaultRoofSection();
    _document.sections = <RoofSection>[replacement];
    _document.selectedSectionId = replacement.id;
    _document.selectedNodeIndex = null;
    _document.source = 'Field drawing';
    _document.sourceFileName = null;
    _document.aiConfidence = null;
    _touch();
  }

  void setLocked(bool value) {
    selectedSection.locked = value;
    notifyListeners();
  }

  void setRoofType(String value) {
    if (selectedSection.roofType == value) return;
    _checkpoint();
    selectedSection.roofType = value;
    _rebuildAutomaticLines(selectedSection);
    _touch();
  }

  void setStructureName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || selectedSection.name == trimmed) return;
    _checkpoint();
    selectedSection.name = trimmed;
    _touch();
  }

  void updateDimensions({
    double? lengthFt,
    double? widthFt,
    double? wallHeightFt,
    double? pitchRisePer12,
    bool recordHistory = true,
  }) {
    final section = selectedSection;
    final nextLength = lengthFt ?? section.lengthFt;
    final nextWidth = widthFt ?? section.widthFt;
    final geometryChanged = nextLength != section.lengthFt ||
        nextWidth != section.widthFt;
    if (!geometryChanged &&
        wallHeightFt == null &&
        pitchRisePer12 == null) {
      return;
    }
    if (recordHistory) _checkpoint();
    if (geometryChanged && section.nodes.isNotEmpty) {
      final center = section.center;
      final scaleX = section.lengthFt == 0 ? 1 : nextLength / section.lengthFt;
      final scaleY = section.widthFt == 0 ? 1 : nextWidth / section.widthFt;
      section.nodes = section.nodes
          .map(
            (node) => node.copyWith(
              x: center.dx + (node.x - center.dx) * scaleX,
              y: center.dy + (node.y - center.dy) * scaleY,
            ),
          )
          .toList();
      section.lines = section.lines
          .map(
            (line) => line.copyWith(
              start: line.start.copyWith(
                x: center.dx + (line.start.x - center.dx) * scaleX,
                y: center.dy + (line.start.y - center.dy) * scaleY,
              ),
              end: line.end.copyWith(
                x: center.dx + (line.end.x - center.dx) * scaleX,
                y: center.dy + (line.end.y - center.dy) * scaleY,
              ),
            ),
          )
          .toList();
    }
    section.lengthFt = nextLength.clamp(4, 120).toDouble();
    section.widthFt = nextWidth.clamp(4, 100).toDouble();
    if (wallHeightFt != null) {
      section.wallHeightFt = wallHeightFt.clamp(5, 30).toDouble();
    }
    if (pitchRisePer12 != null) {
      section.pitchRisePer12 = pitchRisePer12.clamp(0, 18).toDouble();
    }
    _touch();
  }

  void setRotation(double degrees, {bool recordHistory = false}) {
    if (recordHistory) _checkpoint();
    selectedSection.rotationDegrees = _normalizeAngle(degrees);
    _touch();
  }

  void setDrain({
    bool? enabled,
    double? angleDegrees,
    bool recordHistory = true,
  }) {
    if (recordHistory) _checkpoint();
    if (enabled != null) selectedSection.drainEnabled = enabled;
    if (angleDegrees != null) {
      selectedSection.drainAngleDegrees = _normalizeAngle(angleDegrees);
    }
    _touch();
  }

  void beginGestureCheckpoint() {
    _checkpoint();
  }

  void moveNode(String sectionId, int nodeIndex, Offset canvasPoint) {
    final section = _section(sectionId);
    if (section.locked || nodeIndex < 0 || nodeIndex >= section.nodes.length) {
      return;
    }
    final local = inverseTransformPoint(canvasPoint, section);
    final snapped = _snap(local);
    section.nodes[nodeIndex] = section.nodes[nodeIndex].copyWith(
      x: snapped.dx.clamp(12, 1188).toDouble(),
      y: snapped.dy.clamp(12, 888).toDouble(),
    );
    _document.selectedSectionId = sectionId;
    _document.selectedNodeIndex = nodeIndex;
    _touch();
  }

  void moveSelected(Offset delta) {
    final section = selectedSection;
    if (section.locked) return;
    section.nodes = section.nodes
        .map((node) => node.copyWith(x: node.x + delta.dx, y: node.y + delta.dy))
        .toList();
    section.lines = section.lines
        .map(
          (line) => line.copyWith(
            start: line.start.copyWith(
              x: line.start.x + delta.dx,
              y: line.start.y + delta.dy,
            ),
            end: line.end.copyWith(
              x: line.end.x + delta.dx,
              y: line.end.y + delta.dy,
            ),
          ),
        )
        .toList();
    _touch();
  }

  void addWallNode(Offset canvasPoint) {
    final section = selectedSection;
    if (section.locked || section.nodes.length < 2) return;
    _checkpoint();
    final local = _snap(inverseTransformPoint(canvasPoint, section));
    var insertAfter = 0;
    var bestDistance = double.infinity;
    for (var index = 0; index < section.nodes.length; index++) {
      final start = section.nodes[index].offset;
      final end = section.nodes[(index + 1) % section.nodes.length].offset;
      final distance = _distanceToSegment(local, start, end);
      if (distance < bestDistance) {
        bestDistance = distance;
        insertAfter = index;
      }
    }
    section.nodes.insert(
      insertAfter + 1,
      RoofNode(
        id: '${section.id}-n-${DateTime.now().microsecondsSinceEpoch}',
        x: local.dx,
        y: local.dy,
      ),
    );
    _document.selectedNodeIndex = insertAfter + 1;
    _touch();
  }

  void removeSelectedNode() {
    final section = selectedSection;
    final index = _document.selectedNodeIndex;
    if (section.locked || index == null || section.nodes.length <= 3) return;
    _checkpoint();
    section.nodes.removeAt(index);
    _document.selectedNodeIndex = null;
    _touch();
  }

  void addLine(RoofLineKind kind, Offset start, Offset end) {
    final section = selectedSection;
    if (section.locked || (start - end).distance < 8) return;
    _checkpoint();
    final localStart = _snap(inverseTransformPoint(start, section));
    final localEnd = _snap(inverseTransformPoint(end, section));
    final id = '${section.id}-${kind.name}-${DateTime.now().microsecondsSinceEpoch}';
    section.lines.add(
      RoofLine(
        id: id,
        kind: kind,
        start: RoofNode(id: '$id-start', x: localStart.dx, y: localStart.dy),
        end: RoofNode(id: '$id-end', x: localEnd.dx, y: localEnd.dy),
        label: kind == RoofLineKind.measurement
            ? '${_lineLengthFeet(section, localStart, localEnd).toStringAsFixed(1)} ft'
            : kind.label,
      ),
    );
    _touch();
  }

  ({String sectionId, int nodeIndex})? hitTestNode(
    Offset canvasPoint, {
    double radius = 24,
  }) {
    for (final section in _document.sections.reversed) {
      for (var index = 0; index < section.nodes.length; index++) {
        if ((transformPoint(section.nodes[index].offset, section) - canvasPoint)
                .distance <=
            radius) {
          return (sectionId: section.id, nodeIndex: index);
        }
      }
    }
    return null;
  }

  String? hitTestSection(Offset canvasPoint) {
    for (final section in _document.sections.reversed) {
      final point = inverseTransformPoint(canvasPoint, section);
      if (_pointInPolygon(point, section.nodes.map((node) => node.offset).toList())) {
        return section.id;
      }
    }
    return null;
  }

  Offset transformPoint(Offset point, RoofSection section) {
    final radians = section.rotationDegrees * math.pi / 180;
    final center = section.center;
    final translated = point - center;
    return Offset(
          translated.dx * math.cos(radians) -
              translated.dy * math.sin(radians),
          translated.dx * math.sin(radians) +
              translated.dy * math.cos(radians),
        ) +
        center;
  }

  Offset inverseTransformPoint(Offset point, RoofSection section) {
    final radians = -section.rotationDegrees * math.pi / 180;
    final center = section.center;
    final translated = point - center;
    return Offset(
          translated.dx * math.cos(radians) -
              translated.dy * math.sin(radians),
          translated.dx * math.sin(radians) +
              translated.dy * math.cos(radians),
        ) +
        center;
  }

  void undo() {
    if (_undo.isEmpty) return;
    _redo.add(_document.deepCopy());
    _document = _undo.removeLast();
    notifyListeners();
  }

  void redo() {
    if (_redo.isEmpty) return;
    _undo.add(_document.deepCopy());
    _document = _redo.removeLast();
    notifyListeners();
  }

  RoofSection _section(String id) =>
      _document.sections.firstWhere((section) => section.id == id);

  void _checkpoint() {
    _undo.add(_document.deepCopy());
    if (_undo.length > 60) _undo.removeAt(0);
    _redo.clear();
  }

  void _touch() {
    _document.updatedAt = DateTime.now();
    notifyListeners();
  }

  Offset _snap(Offset value) {
    if (!_document.snapEnabled) return value;
    const grid = 20.0;
    return Offset(
      (value.dx / grid).round() * grid,
      (value.dy / grid).round() * grid,
    );
  }

  void _rebuildAutomaticLines(RoofSection section) {
    if (section.nodes.length < 4) return;
    final bounds = _bounds(section.nodes.map((node) => node.offset));
    final id = '${section.id}-auto';
    if (section.roofType == 'Hip') {
      final left = Offset(bounds.left + bounds.width * .32, bounds.center.dy);
      final right = Offset(bounds.right - bounds.width * .32, bounds.center.dy);
      section.lines = <RoofLine>[
        _line(id, RoofLineKind.ridge, left, right, 'Main ridge'),
        _line('$id-1', RoofLineKind.hip, bounds.topLeft, left, 'Hip'),
        _line('$id-2', RoofLineKind.hip, bounds.bottomLeft, left, 'Hip'),
        _line('$id-3', RoofLineKind.hip, bounds.topRight, right, 'Hip'),
        _line('$id-4', RoofLineKind.hip, bounds.bottomRight, right, 'Hip'),
      ];
    } else if (section.roofType == 'Shed / Mono' ||
        section.roofType == 'Flat') {
      section.lines = <RoofLine>[
        _line(
          id,
          RoofLineKind.drain,
          Offset(bounds.left + 20, bounds.center.dy),
          Offset(bounds.right - 20, bounds.center.dy),
          'Fall direction',
        ),
      ];
    } else if (section.roofType == 'Intersecting') {
      section.lines = <RoofLine>[
        _line(
          id,
          RoofLineKind.ridge,
          Offset(bounds.left + 20, bounds.center.dy),
          Offset(bounds.right - 20, bounds.center.dy),
          'Main ridge',
        ),
        _line(
          '$id-valley',
          RoofLineKind.valley,
          bounds.topCenter,
          bounds.center,
          'Valley',
        ),
      ];
    } else {
      section.lines = <RoofLine>[
        _line(
          id,
          RoofLineKind.ridge,
          Offset(bounds.left + 20, bounds.center.dy),
          Offset(bounds.right - 20, bounds.center.dy),
          'Main ridge',
        ),
      ];
    }
  }

  RoofLine _line(
    String id,
    RoofLineKind kind,
    Offset start,
    Offset end,
    String label,
  ) =>
      RoofLine(
        id: id,
        kind: kind,
        start: RoofNode(id: '$id-start', x: start.dx, y: start.dy),
        end: RoofNode(id: '$id-end', x: end.dx, y: end.dy),
        label: label,
      );

  Rect _bounds(Iterable<Offset> points) {
    final values = points.toList();
    var left = values.first.dx;
    var right = values.first.dx;
    var top = values.first.dy;
    var bottom = values.first.dy;
    for (final point in values.skip(1)) {
      left = math.min(left, point.dx);
      right = math.max(right, point.dx);
      top = math.min(top, point.dy);
      bottom = math.max(bottom, point.dy);
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }

  double _distanceToSegment(Offset point, Offset start, Offset end) {
    final lengthSquared = (end - start).distanceSquared;
    if (lengthSquared == 0) return (point - start).distance;
    final t = (((point.dx - start.dx) * (end.dx - start.dx) +
                (point.dy - start.dy) * (end.dy - start.dy)) /
            lengthSquared)
        .clamp(0, 1)
        .toDouble();
    final projection = start + (end - start) * t;
    return (point - projection).distance;
  }

  bool _pointInPolygon(Offset point, List<Offset> polygon) {
    if (polygon.length < 3) return false;
    var inside = false;
    for (var i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      final a = polygon[i];
      final b = polygon[j];
      final intersects = ((a.dy > point.dy) != (b.dy > point.dy)) &&
          (point.dx <
              (b.dx - a.dx) * (point.dy - a.dy) / (b.dy - a.dy) + a.dx);
      if (intersects) inside = !inside;
    }
    return inside;
  }

  double _lineLengthFeet(
    RoofSection section,
    Offset start,
    Offset end,
  ) {
    final bounds = _bounds(section.nodes.map((node) => node.offset));
    final pixelsPerFoot = bounds.width / math.max(section.lengthFt, 1);
    return (start - end).distance / math.max(pixelsPerFoot, .1);
  }

  double _normalizeAngle(double value) {
    final normalized = value % 360;
    return normalized < 0 ? normalized + 360 : normalized;
  }
}
