import 'package:flutter_test/flutter_test.dart';
import 'package:rc_sow_flutter/core/beneficiary_agreement.dart';

void main() {
  test('beneficiary agreement template resolves smart fields', () {
    final result = renderBeneficiaryAgreementTemplate(
      'House {{house_code}} for {{beneficiary}} in {{community}}, {{parish}}. '
      'Roof: {{roof_type}}. Repairs: {{repairs}}.',
      houseCode: 'HA18',
      beneficiary: 'Test Beneficiary',
      parish: 'Hanover',
      community: 'Haughton Grove',
      roofType: 'Gable',
      repairs: 'Replace damaged zinc',
    );

    expect(result, contains('HA18'));
    expect(result, contains('Test Beneficiary'));
    expect(result, contains('Haughton Grove'));
    expect(result, contains('Hanover'));
    expect(result, contains('Gable'));
    expect(result, contains('Replace damaged zinc'));
    expect(result, isNot(contains('{{')));
  });
}
