import 'dart:math' as math;
import 'dart:ui';

enum InventoryTier {
  parish('Parish depot'),
  cluster('Cluster store'),
  house('House allocation');

  const InventoryTier(this.label);
  final String label;
}

enum InventoryHealth {
  healthy('In stock'),
  low('Low stock'),
  critical('Critical'),
  outOfStock('Out of stock');

  const InventoryHealth(this.label);
  final String label;
}

class StockLedgerItem {
  StockLedgerItem({
    required this.id,
    required this.materialCode,
    required this.name,
    required this.unit,
    required this.tier,
    required this.parish,
    required this.location,
    required this.opening,
    required this.received,
    required this.issued,
    required this.adjustments,
    required this.minimumStock,
    required this.unitCostJmd,
    required this.updatedAt,
    this.cluster,
    this.houseCode,
    this.zone = '',
    this.liveSynced = true,
  });

  final String id;
  final String materialCode;
  final String name;
  final String unit;
  final InventoryTier tier;
  final String parish;
  final String? cluster;
  final String? houseCode;
  String location;
  String zone;
  double opening;
  double received;
  double issued;
  double adjustments;
  double minimumStock;
  double unitCostJmd;
  DateTime updatedAt;
  bool liveSynced;

  double get onHand =>
      math.max(0, opening + received - issued + adjustments).toDouble();

  double get stockValueJmd => onHand * unitCostJmd;

  InventoryHealth get health {
    if (onHand <= 0) return InventoryHealth.outOfStock;
    if (onHand <= minimumStock * .5) return InventoryHealth.critical;
    if (onHand <= minimumStock) return InventoryHealth.low;
    return InventoryHealth.healthy;
  }

  String get scopeLabel => switch (tier) {
        InventoryTier.parish => parish,
        InventoryTier.cluster => cluster ?? parish,
        InventoryTier.house => houseCode ?? cluster ?? parish,
      };
}

enum ProjectionStatus {
  draft('Draft'),
  submitted('Submitted'),
  approved('Approved'),
  atRisk('At risk'),
  complete('Complete');

  const ProjectionStatus(this.label);
  final String label;
}

class WorkProjection {
  WorkProjection({
    required this.id,
    required this.weekStarting,
    required this.parish,
    required this.cluster,
    required this.houseCode,
    required this.milestone,
    required this.estimatedHours,
    required this.actualHours,
    required this.crewNeeded,
    required this.materialNeeds,
    required this.risks,
    required this.status,
  });

  final String id;
  DateTime weekStarting;
  String parish;
  String cluster;
  String houseCode;
  String milestone;
  double estimatedHours;
  double actualHours;
  int crewNeeded;
  String materialNeeds;
  String risks;
  ProjectionStatus status;

  double get varianceHours => actualHours - estimatedHours;
  double get completionRatio => estimatedHours <= 0
      ? 0
      : (actualHours / estimatedHours).clamp(0, 2).toDouble();
}

enum ProductionIssueSeverity {
  information('Information'),
  warning('Warning'),
  critical('Critical');

  const ProductionIssueSeverity(this.label);
  final String label;
}

class ProductionIssue {
  ProductionIssue({
    required this.id,
    required this.houseCode,
    required this.title,
    required this.owner,
    required this.dueAt,
    required this.severity,
    this.resolved = false,
  });

  final String id;
  final String houseCode;
  final String title;
  String owner;
  DateTime dueAt;
  ProductionIssueSeverity severity;
  bool resolved;
}

class ImportFieldMapping {
  ImportFieldMapping({
    required this.systemField,
    required this.sourceColumn,
    required this.sampleValue,
    required this.confidence,
    this.required = false,
  });

  final String systemField;
  String sourceColumn;
  final String sampleValue;
  double confidence;
  final bool required;
}

enum LegacyImportStatus {
  selected('Selected'),
  mapping('Mapping review'),
  ready('Ready to import'),
  queued('Queued for sync'),
  imported('Imported');

  const LegacyImportStatus(this.label);
  final String label;
}

class LegacyImportBatch {
  LegacyImportBatch({
    required this.id,
    required this.fileName,
    required this.rowCount,
    required this.mappings,
    required this.warnings,
    required this.createdAt,
    required this.status,
  });

  final String id;
  final String fileName;
  final int rowCount;
  final List<ImportFieldMapping> mappings;
  final List<String> warnings;
  final DateTime createdAt;
  LegacyImportStatus status;

  int get mappedFields =>
      mappings.where((mapping) => mapping.sourceColumn.isNotEmpty).length;

  bool get canImport => mappings
      .where((mapping) => mapping.required)
      .every((mapping) => mapping.sourceColumn.isNotEmpty);
}

enum RoofTool {
  select('Select'),
  pan('Pan / zoom'),
  wall('Wall'),
  ridge('Ridge'),
  hip('Hip'),
  valley('Valley'),
  measure('Measure'),
  drain('Drain'),
  text('Text');

  const RoofTool(this.label);
  final String label;
}

enum RoofLineKind {
  ridge('Ridge'),
  hip('Hip'),
  valley('Valley'),
  measurement('Measurement'),
  drain('Drain'),
  note('Note');

  const RoofLineKind(this.label);
  final String label;
}

class RoofNode {
  const RoofNode({required this.id, required this.x, required this.y});

  final String id;
  final double x;
  final double y;

  Offset get offset => Offset(x, y);

  RoofNode copyWith({double? x, double? y}) => RoofNode(
        id: id,
        x: x ?? this.x,
        y: y ?? this.y,
      );

  Map<String, Object> toMap() => <String, Object>{'id': id, 'x': x, 'y': y};

  factory RoofNode.fromMap(Map<String, dynamic> map) => RoofNode(
        id: '${map['id'] ?? ''}',
        x: (map['x'] as num?)?.toDouble() ?? 0,
        y: (map['y'] as num?)?.toDouble() ?? 0,
      );
}

class RoofLine {
  const RoofLine({
    required this.id,
    required this.kind,
    required this.start,
    required this.end,
    this.label = '',
  });

  final String id;
  final RoofLineKind kind;
  final RoofNode start;
  final RoofNode end;
  final String label;

  RoofLine copyWith({RoofNode? start, RoofNode? end, String? label}) => RoofLine(
        id: id,
        kind: kind,
        start: start ?? this.start,
        end: end ?? this.end,
        label: label ?? this.label,
      );

  Map<String, Object> toMap() => <String, Object>{
        'id': id,
        'kind': kind.name,
        'start': start.toMap(),
        'end': end.toMap(),
        'label': label,
      };

  factory RoofLine.fromMap(Map<String, dynamic> map) => RoofLine(
        id: '${map['id'] ?? ''}',
        kind: RoofLineKind.values.firstWhere(
          (kind) => kind.name == map['kind'],
          orElse: () => RoofLineKind.measurement,
        ),
        start: RoofNode.fromMap(
          Map<String, dynamic>.from(map['start'] as Map? ?? const {}),
        ),
        end: RoofNode.fromMap(
          Map<String, dynamic>.from(map['end'] as Map? ?? const {}),
        ),
        label: '${map['label'] ?? ''}',
      );
}

class RoofSection {
  RoofSection({
    required this.id,
    required this.name,
    required this.structure,
    required this.roofType,
    required this.nodes,
    required this.lines,
    required this.lengthFt,
    required this.widthFt,
    required this.wallHeightFt,
    required this.pitchRisePer12,
    this.rotationDegrees = 0,
    this.drainAngleDegrees = 180,
    this.drainEnabled = true,
    this.locked = false,
  });

  final String id;
  String name;
  String structure;
  String roofType;
  List<RoofNode> nodes;
  List<RoofLine> lines;
  double lengthFt;
  double widthFt;
  double wallHeightFt;
  double pitchRisePer12;
  double rotationDegrees;
  double drainAngleDegrees;
  bool drainEnabled;
  bool locked;

  double get planAreaSqFt => lengthFt * widthFt;
  double get ridgeRiseFt => widthFt / 2 * pitchRisePer12 / 12;
  double get rafterLengthFt => math.sqrt(
        math.pow(widthFt / 2, 2) + math.pow(ridgeRiseFt, 2),
      );

  Offset get center {
    if (nodes.isEmpty) return Offset.zero;
    final x = nodes.fold<double>(0, (sum, node) => sum + node.x) / nodes.length;
    final y = nodes.fold<double>(0, (sum, node) => sum + node.y) / nodes.length;
    return Offset(x, y);
  }

  RoofSection deepCopy() => RoofSection.fromMap(toMap());

  Map<String, Object> toMap() => <String, Object>{
        'id': id,
        'name': name,
        'structure': structure,
        'roofType': roofType,
        'nodes': nodes.map((node) => node.toMap()).toList(),
        'lines': lines.map((line) => line.toMap()).toList(),
        'lengthFt': lengthFt,
        'widthFt': widthFt,
        'wallHeightFt': wallHeightFt,
        'pitchRisePer12': pitchRisePer12,
        'rotationDegrees': rotationDegrees,
        'drainAngleDegrees': drainAngleDegrees,
        'drainEnabled': drainEnabled,
        'locked': locked,
      };

  factory RoofSection.fromMap(Map<String, dynamic> map) => RoofSection(
        id: '${map['id'] ?? ''}',
        name: '${map['name'] ?? 'Roof section'}',
        structure: '${map['structure'] ?? 'Main house'}',
        roofType: '${map['roofType'] ?? 'Gable'}',
        nodes: (map['nodes'] as List? ?? const <Object>[])
            .map(
              (node) => RoofNode.fromMap(
                Map<String, dynamic>.from(node as Map),
              ),
            )
            .toList(),
        lines: (map['lines'] as List? ?? const <Object>[])
            .map(
              (line) => RoofLine.fromMap(
                Map<String, dynamic>.from(line as Map),
              ),
            )
            .toList(),
        lengthFt: (map['lengthFt'] as num?)?.toDouble() ?? 24.5,
        widthFt: (map['widthFt'] as num?)?.toDouble() ?? 18,
        wallHeightFt: (map['wallHeightFt'] as num?)?.toDouble() ?? 9,
        pitchRisePer12: (map['pitchRisePer12'] as num?)?.toDouble() ?? 6,
        rotationDegrees: (map['rotationDegrees'] as num?)?.toDouble() ?? 0,
        drainAngleDegrees:
            (map['drainAngleDegrees'] as num?)?.toDouble() ?? 180,
        drainEnabled: map['drainEnabled'] != false,
        locked: map['locked'] == true,
      );
}

class RoofDrawingDocument {
  RoofDrawingDocument({
    required this.houseCode,
    required this.sections,
    required this.selectedSectionId,
    this.selectedNodeIndex,
    this.snapEnabled = true,
    this.source = 'Field drawing',
    this.sourceFileName,
    this.aiConfidence,
    this.updatedAt,
  });

  final String houseCode;
  List<RoofSection> sections;
  String selectedSectionId;
  int? selectedNodeIndex;
  bool snapEnabled;
  String source;
  String? sourceFileName;
  double? aiConfidence;
  DateTime? updatedAt;

  RoofSection get selectedSection => sections.firstWhere(
        (section) => section.id == selectedSectionId,
        orElse: () => sections.first,
      );

  double get totalPlanAreaSqFt => sections.fold<double>(
        0,
        (sum, section) => sum + section.planAreaSqFt,
      );

  RoofDrawingDocument deepCopy() => RoofDrawingDocument.fromMap(toMap());

  Map<String, Object?> toMap() => <String, Object?>{
        'houseCode': houseCode,
        'sections': sections.map((section) => section.toMap()).toList(),
        'selectedSectionId': selectedSectionId,
        'selectedNodeIndex': selectedNodeIndex,
        'snapEnabled': snapEnabled,
        'source': source,
        'sourceFileName': sourceFileName,
        'aiConfidence': aiConfidence,
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory RoofDrawingDocument.fromMap(Map<String, dynamic> map) {
    final sections = (map['sections'] as List? ?? const <Object>[])
        .map(
          (section) => RoofSection.fromMap(
            Map<String, dynamic>.from(section as Map),
          ),
        )
        .toList();
    if (sections.isEmpty) {
      sections.add(defaultRoofSection());
    }
    return RoofDrawingDocument(
      houseCode: '${map['houseCode'] ?? 'H12'}',
      sections: sections,
      selectedSectionId:
          '${map['selectedSectionId'] ?? sections.first.id}',
      selectedNodeIndex: (map['selectedNodeIndex'] as num?)?.toInt(),
      snapEnabled: map['snapEnabled'] != false,
      source: '${map['source'] ?? 'Field drawing'}',
      sourceFileName: map['sourceFileName'] as String?,
      aiConfidence: (map['aiConfidence'] as num?)?.toDouble(),
      updatedAt: DateTime.tryParse('${map['updatedAt'] ?? ''}'),
    );
  }
}

RoofSection defaultRoofSection({
  String id = 'main-house',
  String name = 'Main roof',
  String structure = 'Main house',
  double left = 190,
  double top = 190,
  double width = 420,
  double height = 280,
}) {
  final nodes = <RoofNode>[
    RoofNode(id: '$id-n1', x: left, y: top),
    RoofNode(id: '$id-n2', x: left + width, y: top),
    RoofNode(id: '$id-n3', x: left + width, y: top + height),
    RoofNode(id: '$id-n4', x: left, y: top + height),
  ];
  return RoofSection(
    id: id,
    name: name,
    structure: structure,
    roofType: 'Gable',
    nodes: nodes,
    lines: <RoofLine>[
      RoofLine(
        id: '$id-ridge',
        kind: RoofLineKind.ridge,
        start: RoofNode(
          id: '$id-rs',
          x: left + 30,
          y: top + height / 2,
        ),
        end: RoofNode(
          id: '$id-re',
          x: left + width - 30,
          y: top + height / 2,
        ),
        label: 'Main ridge',
      ),
    ],
    lengthFt: 24.5,
    widthFt: 18,
    wallHeightFt: 9,
    pitchRisePer12: 6,
  );
}

class AiMeasurementSuggestion {
  const AiMeasurementSuggestion({
    required this.label,
    required this.value,
    required this.unit,
    required this.confidence,
  });

  final String label;
  final double value;
  final String unit;
  final double confidence;
}

class AiRoofSuggestion {
  const AiRoofSuggestion({
    required this.fileName,
    required this.document,
    required this.measurements,
    required this.overallConfidence,
    required this.engineLabel,
  });

  final String fileName;
  final RoofDrawingDocument document;
  final List<AiMeasurementSuggestion> measurements;
  final double overallConfidence;
  final String engineLabel;
}
