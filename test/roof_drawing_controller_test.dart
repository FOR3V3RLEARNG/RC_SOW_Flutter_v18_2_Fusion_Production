import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rc_sow_connected/core/production_models.dart';
import 'package:rc_sow_connected/core/roof_drawing_controller.dart';

void main() {
  group('touch roof drawing controller', () {
    late RoofDrawingController controller;

    setUp(() {
      final section = defaultRoofSection();
      controller = RoofDrawingController(
        RoofDrawingDocument(
          houseCode: 'H12',
          sections: <RoofSection>[section],
          selectedSectionId: section.id,
        ),
      );
    });

    tearDown(() => controller.dispose());

    test('node movement snaps and can be undone', () {
      final before = controller.selectedSection.nodes.first.offset;
      controller.beginGestureCheckpoint();
      controller.moveNode('main-house', 0, const Offset(233, 247));

      expect(
        controller.selectedSection.nodes.first.offset,
        const Offset(240, 240),
      );
      controller.undo();
      expect(controller.selectedSection.nodes.first.offset, before);
    });

    test('multi-structure drawing supports roof geometry variants', () {
      controller.addSection('Verandah');
      expect(controller.document.sections, hasLength(2));
      expect(controller.selectedSection.roofType, 'Shed / Mono');

      controller.setRoofType('Hip');
      expect(
        controller.selectedSection.lines
            .where((line) => line.kind == RoofLineKind.hip),
        hasLength(4),
      );
    });

    test('draws annotations and calculates combined plan area', () {
      final initialArea = controller.document.totalPlanAreaSqFt;
      controller.addLine(
        RoofLineKind.measurement,
        const Offset(210, 210),
        const Offset(410, 210),
      );
      expect(
        controller.selectedSection.lines
            .any((line) => line.kind == RoofLineKind.measurement),
        isTrue,
      );

      controller.duplicateSelected();
      expect(controller.document.totalPlanAreaSqFt, initialArea * 2);
      controller.deleteSelected();
      expect(controller.document.sections, hasLength(1));
    });
  });
}
