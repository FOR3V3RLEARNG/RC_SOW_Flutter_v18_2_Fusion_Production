import 'package:flutter_test/flutter_test.dart';
import 'package:rc_sow_flutter/models/app_models.dart';

void main() {
  test('ridge rise is measured from wall plate to ridge beam', () {
    const m = RoofMeasurements(widthFt: 24, lengthFt: 30, wallHeightFt: 9, pitchRisePer12: 4);
    expect(m.ridgeRiseFt, closeTo(4, 0.0001));
    expect(m.ridgeHeightFt, closeTo(13, 0.0001));
    expect(m.wallHeightFt, closeTo(9, 0.0001));
  });
}
