import 'package:flutter_test/flutter_test.dart';
import 'package:rc_sow_flutter/core/design_tokens.dart';

void main() {
  test('RC SOW brand token remains canonical', () {
    expect(RcColors.brand.toARGB32(), 0xFFC91F2C);
    expect(RcRadius.lg, 24);
    expect(RcIconSize.sm, 18);
    expect(RcLayout.cardPadding, 16);
  });
}
