import 'package:flutter_test/flutter_test.dart';
import 'package:rc_sow_flutter/core/auth_support.dart';
import 'package:rc_sow_flutter/core/supabase_config.dart';

void main() {
  test('OAuth callback has one canonical mobile contract', () {
    expect(RcAuthSupport.oauthRedirectUri, SupabaseConfig.oauthRedirectUri);
    expect(
      SupabaseConfig.oauthRedirectUri,
      'org.jamaicaredcross.rcsowflutter://login-callback',
    );
    final uri = Uri.parse(SupabaseConfig.oauthRedirectUri);
    expect(uri.scheme, 'org.jamaicaredcross.rcsowflutter');
    expect(uri.host, 'login-callback');
  });
}
