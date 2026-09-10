const String kDefaultBeneficiaryAgreementTitle = 'BENEFICIARY REPAIR AGREEMENT';

const String kDefaultBeneficiaryAgreementText =
    'I acknowledge the repair work described in this agreement and permit '
    'the Jamaica Red Cross and its authorized construction team to carry '
    'out the stated roof repairs. I understand that the roof illustration '
    'is a representative Red Cross construction concept for the selected '
    'roof style. It is not the editable field Scope drawing, a measurement '
    'record, or a substitute for final site decisions made by the '
    'authorized technical team.';

const List<String> kBeneficiaryAgreementPlaceholders = [
  '{{house_code}}',
  '{{beneficiary}}',
  '{{parish}}',
  '{{community}}',
  '{{roof_type}}',
  '{{repairs}}',
];

String renderBeneficiaryAgreementTemplate(
  String template, {
  required String houseCode,
  required String beneficiary,
  required String parish,
  required String community,
  required String roofType,
  required String repairs,
}) {
  final values = <String, String>{
    '{{house_code}}': houseCode,
    '{{beneficiary}}': beneficiary,
    '{{parish}}': parish,
    '{{community}}': community,
    '{{roof_type}}': roofType,
    '{{repairs}}': repairs,
  };

  var result = template.trim();
  for (final entry in values.entries) {
    result = result.replaceAll(entry.key, entry.value);
  }
  return result;
}
