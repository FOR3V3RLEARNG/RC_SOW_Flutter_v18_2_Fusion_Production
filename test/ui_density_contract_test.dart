import 'package:flutter_test/flutter_test.dart';
import 'package:rc_sow_flutter/core/design_tokens.dart';

void main() {
  test('v18.2 spacious layout and restrained icon contract remains stable', () {
    expect(RcLayout.pageHorizontal, 16);
    expect(RcLayout.sectionGap, 20);
    expect(RcLayout.cardPadding, 16);
    expect(RcLayout.cardGap, 12);
    expect(RcIconSize.sm, 18);
    expect(RcIconSize.md, 20);
    expect(RcIconSize.lg, lessThanOrEqualTo(22));
  });
}
