# RC SOW v20.4 — Fusion Scalable Production Handoff

Use this project as the scalable production source. Preserve the v18.2 spacious UI language and extend through the registries/configuration points documented in `docs/SCALABLE_ARCHITECTURE.md`. Do not rebuild from scratch and do not change the Android application/package identity.

## Preserve
- Android package/applicationId: `org.jamaicaredcross.rc_sow_flutter`
- Supabase project: `https://gdvhekeupicllxkfctqw.supabase.co`
- Existing RC SOW functionality, role/parish approval rules, Admin-only controls, Scope, Control of Works, Messages, Houses, Live Tracker, Active Users, settings persistence, tests, and Green Gate workflow.

## Current Flutter OAuth callback
Use this valid custom URI callback for Flutter:

`org.jamaicaredcross.rcsowflutter://login-callback`

The Android package stays unchanged; only the deep-link URI scheme omits underscores.

The older React/Expo app can continue using its separate callback:

`rcscopeofworks://auth/callback`

In Supabase Authentication > URL Configuration, these must be separate allowed redirect entries, never combined into one field/string.

Google provider callback remains:

`https://gdvhekeupicllxkfctqw.supabase.co/auth/v1/callback`

## Already applied to this editable package
- Supabase initialization uses `publishableKey`.
- Flutter analyzer brace fixes from the previous Green Gate iteration are applied.
- Android bootstrap script adds `INTERNET` permission idempotently.
- Android bootstrap script adds the valid Flutter OAuth deep-link intent filter idempotently.
- Flutter Google OAuth now requests the valid callback and external-browser launch mode.

## Next Fusion work requested
1. Complete Google OAuth session-return handling using `onAuthStateChange` / current session restoration without duplicate listeners/navigation.
2. Keep React and Flutter callbacks functioning independently.
3. Replace raw auth exception dumps with concise user-facing messages and safe diagnostics.
4. Add a visible Material 3 Settings gear to the authenticated top action area.
5. Expand Settings with Appearance, Accessibility/Motion, Field Drawing, Maps & Location, Connectivity, Account, Security, Diagnostics, and About.
6. Keep SharedPreferences for local settings persistence; never manually persist passwords/tokens/secrets.
7. Visible app name: `RC SOW`.
8. Upgrade branding/logo to a premium humanitarian house-repair identity.
9. Add a short high-quality house/roof repair splash animation; respect Reduce Motion.
10. Preserve compact/expanded responsiveness, semantics, text scaling, light/dark themes, and all operational functionality.

## Quality gate
Run in CI or a Flutter-capable environment:

```bash
dart format --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --release
flutter build appbundle --release
```

Also verify the generated release manifest contains:
- `android.permission.INTERNET`
- scheme `org.jamaicaredcross.rcsowflutter`
- host `login-callback`

Do not claim Google OAuth works end-to-end until a physical-device test completes Google -> Supabase -> RC SOW and the app receives a valid session.
