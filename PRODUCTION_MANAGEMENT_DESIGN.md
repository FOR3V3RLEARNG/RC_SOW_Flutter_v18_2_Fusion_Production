# RC SOW v18.2 — Expressive Production Management Design

## Product intent
RC SOW is a shelter-production control system, not a generic dashboard. A house is the durable unit of work. Scope, planning, site delivery, quality evidence, completion and payment remain linked to the same house and parish context.

## Material 3 foundation
Material 3 remains the usability contract: labelled destinations, standard back behavior, 48px+ action targets, native text scaling, semantic controls, predictable dialogs/sheets, familiar navigation patterns and platform-appropriate focus behavior.

The RC SOW Design DNA reinterprets that foundation through:
- asymmetric humanitarian/roof-inspired corner families instead of identical rectangles;
- a compact mobile navigation island that still uses Material `NavigationBar` destinations;
- an adaptive wide navigation dock built on `NavigationRail`;
- connected command surfaces for recurring field actions;
- large production headings and semantic status pills;
- CustomPainter progress orbs for completion/readiness signals;
- container transforms implemented as restrained fade/slide transitions;
- phase rails and progress forms that show where the user is and what comes next.

## Production chain
1. **Scope** — house and beneficiary data, roof geometry, printout and files.
2. **Plan** — control record, work plan and document checklist.
3. **Delivery** — site visits, daily log, materials, consumables and inventory.
4. **Quality** — monitoring checklist, corrections and blockers.
5. **Close-out** — Notice of Completion and evidence review.
6. **Finance** — payment submission and final lifecycle status.

## Orientation rules
- Five persistent destinations remain Dashboard, Scope, Control, Houses and More.
- Secondary screens always open on the Navigator stack and retain the standard system/AppBar back action.
- The current Scope form step is visibly represented as House → Roof → Print → Files.
- Production modules expose their phase before their records.
- House Command surfaces show a single left-to-right lifecycle from Scope to Payment.
- Expressive motion must never be required to understand navigation; Reduce Motion removes non-essential transitions.

## Callback contract
The canonical Flutter OAuth callback is declared once in `SupabaseConfig.oauthRedirectUri`:

`org.jamaicaredcross.rcsowflutter://login-callback`

`RcAuthSupport` reads that constant and the Android bootstrap script parses the same source to generate the manifest intent filter. `onAuthStateChange` is the single session-return coordinator. AppState serializes profile synchronization so Google callback, initial session restoration and manual refresh cannot create competing auth/profile update paths.

## Responsive behavior
- **Compact phone**: Material NavigationBar inside a rounded navigation island; overflow header actions collapse into a labelled menu.
- **Large phone/foldable**: same navigation model with room for the Users Online contextual FAB.
- **Tablet/desktop**: adaptive NavigationRail dock plus full header actions; production module grids expand to two or three columns.
- Content uses `LayoutBuilder`, responsive grids and horizontal overflow rails where preserving readable targets is better than shrinking them.

## Accessibility
- Semantic labels are attached to custom tappable surfaces and progress orbs.
- Standard Material controls remain the default for forms, dialogs, tabs, menus and back navigation.
- System text scaling and theme brightness are respected.
- High Contrast, Reduce Motion and Haptics are persisted locally.
- Dark/System/Light appearance modes are supported.
- No credential/token secret is stored in SharedPreferences or exposed through diagnostics.

## Quality gate
Pinned CI toolchain: Flutter 3.44.7 / Dart 3.12.2.

The Green Gate must pass:
1. Android bootstrap and callback patch.
2. `flutter pub get` and dependency graph output.
3. canonical callback manifest verification.
4. `dart format --output=none --set-exit-if-changed .`.
5. `flutter analyze`.
6. `flutter test` including callback contract and production-record lifecycle tests.
7. release APK.
8. release AAB.
9. artifact existence verification and upload.

Physical-device Google OAuth remains a separate end-to-end acceptance gate: Google → Supabase → custom URI → RC SOW valid session.
