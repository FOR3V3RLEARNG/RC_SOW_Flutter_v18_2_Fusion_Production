abstract final class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://gdvhekeupicllxkfctqw.supabase.co',
  );

  // Supabase publishable keys are intended for public clients. Authorization
  // remains enforced by RLS; never place a secret/service-role key here.
  static const String publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_OgOVkNQsV1iysQN9N6FJeA_Q4ibnnZM',
  );

  static const String oauthRedirectUri =
      'org.jamaicaredcross.rcsowflutter://login-callback';

  static const String aiRoofFunction = String.fromEnvironment(
    'RC_SOW_AI_ROOF_FUNCTION',
    defaultValue: 'rc-sow-roof-extract',
  );

  static const String legacyImportFunction = String.fromEnvironment(
    'RC_SOW_LEGACY_IMPORT_FUNCTION',
    defaultValue: 'rc-sow-legacy-import-preview',
  );

  static bool get isConfigured =>
      url.startsWith('https://') && publishableKey.startsWith('sb_publishable_');
}
