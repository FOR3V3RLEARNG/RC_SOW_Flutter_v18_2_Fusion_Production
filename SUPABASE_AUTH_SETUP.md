# Supabase Authentication Setup — RC SOW v18.2

Use these values for the current Flutter production source.

## Supabase Authentication → URL Configuration

- **Site URL:** `org.jamaicaredcross.rcsowflutter://login-callback`
- **Redirect URL:** `org.jamaicaredcross.rcsowflutter://login-callback`

## Google OAuth provider callback

Use the Supabase provider callback in Google Cloud:

`https://gdvhekeupicllxkfctqw.supabase.co/auth/v1/callback`

## Android identity

- Application/package ID: `org.jamaicaredcross.rc_sow_flutter`
- Mobile OAuth callback scheme: `org.jamaicaredcross.rcsowflutter`
- Mobile OAuth callback host: `login-callback`

The callback URI is centralized in `lib/core/supabase_config.dart`. `scripts/patch_android.sh` derives the Android manifest deep-link from that value during the GitHub build.
