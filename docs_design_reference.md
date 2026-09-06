# RC SOW — Premium Design System

> Extracted from **RedCross ScopeWorks v16.0.1 BugChecked**. This document captures the actual visual language, UI primitives, motion system, graphics approach, navigation model, and implementation rules used by the app so the same design DNA can be reused consistently.

## 1. Design DNA

RC SOW is a premium humanitarian field-operations product. The interface should feel:

- **Professional and institutional** — appropriate for Red Cross / shelter-project field work.
- **Fast and calm** — no decorative motion that slows field use.
- **Highly legible** — optimized for outdoor/mobile operation and dense operational data.
- **Actionable** — cards, metrics, alerts and requests should always lead somewhere useful.
- **Evidence-focused** — roof drawings, beneficiary data, approvals, signatures, tasks and live tracking are first-class UI elements.
- **Premium without being flashy** — soft gradients, glass surfaces, restrained shadows, responsive haptics, Skia accents and purposeful Rive/Reanimated motion.

The dominant visual language is **clean white surfaces + soft neutral canvas + Jamaica Red Cross red accents + operational status colors**.

---

## 2. Core Technology Stack

The premium UI layer is built on:

- React Native 0.81.5
- Expo SDK 54
- React Native Reanimated 4.1
- React Native Gesture Handler 2.28
- React Native Skia 2.2
- Rive React Native 0.4.19
- Lottie React Native 7.3
- Expo Blur
- Expo Linear Gradient
- Expo Image
- Expo Haptics
- React Native SVG

### Runtime rule

Rive is an enhancement, not a hard dependency for basic UI rendering. Expo Go falls back to Reanimated/native UI. Full Rive experiences belong in development/EAS builds.

---

## 3. Color System

### Brand

| Token | Hex | Use |
|---|---:|---|
| `brand` | `#C91F2C` | Primary Red Cross accent, active states, metrics, logo |
| `brandDeep` | `#971621` | Deep red emphasis |
| `brandSoft` | `#FFF1F2` | Soft red containers / secondary red actions |

### Neutral

| Token | Hex | Use |
|---|---:|---|
| `ink` | `#101828` | Primary headings and strongest text |
| `text` | `#344054` | Standard body / labels |
| `muted` | `#667085` | Secondary text, metadata, helper copy |
| `bg` | `#F4F7FB` | App canvas |
| `surface` | `#FFFFFF` | Primary cards and surfaces |
| `surface2` | `#F8FAFC` | Inputs, soft cards, metrics |
| `line` | `#E4E7EC` | Standard dividers / borders |
| `lineStrong` | `#D0D5DD` | Inputs / stronger borders |
| `white` | `#FFFFFF` | White foreground/content |

### Status

| Token | Hex | Soft background | Purpose |
|---|---:|---:|---|
| `success` | `#12805C` | `#ECFDF3` | Completed / valid / healthy |
| `warning` | `#B54708` | `#FFFAEB` | Urgent / caution |
| `blue` | `#175CD3` | `#EFF8FF` | Informational / normal workflow |
| `purple` | `#6941C6` | `#F4F3FF` | Alternate categorization |
| `danger` | `#B42318` | `#FEF3F2` | Critical / destructive / failed |

### Priority mapping

- None → muted
- Normal → blue
- Urgent → warning
- Critical → danger

---

## 4. Radius, Spacing and Elevation

### Radius

| Token | Value |
|---|---:|
| `R.sm` | 12 |
| `R.md` | 18 |
| `R.lg` | 24 |
| `R.xl` | 30 |

Use 12px for controls, 16–24px for premium cards and 999px for pills/badges.

### Spacing

| Token | Value |
|---|---:|
| `S.xs` | 4 |
| `S.sm` | 8 |
| `S.md` | 12 |
| `S.lg` | 16 |
| `S.xl` | 24 |
| `S.xxl` | 32 |

### Shadow

Standard elevated card shadow:

```js
{
  shadowColor: '#101828',
  shadowOpacity: 0.08,
  shadowRadius: 16,
  shadowOffset: { width: 0, height: 7 },
  elevation: 3,
}
```

Use elevation sparingly. Operational surfaces should feel layered, not floating excessively.

---

## 5. Typography

The current implementation uses the system font with weight hierarchy rather than requiring a custom font.

### Hierarchy

- App / hero title: **25–27px, 900 weight**
- Card title: **19px, 900 weight**, slight negative tracking (`-0.3`)
- Section / key label: **14–15px, 800–900 weight**
- Body: **13–14px, 600–700 weight** where needed
- Field labels: **12px, 800 weight**
- Metadata: **9–10px**
- Eyebrow / uppercase kicker: **8–10px, 900 weight**, increased letter spacing

Use `ink` for titles, `text` for normal content and `muted` for metadata.

---

## 6. App Shell

### Header

The main authenticated shell uses a premium glass header:

- `BlurView` with intensity around 72
- light tint
- translucent white → pale red gradient
- thin neutral bottom border
- 48×48 rounded red brand mark containing a white cross
- user metadata shown below app subtitle
- message notification button with red unread badge
- soft-red Logout action

Header identity:

- **RC SOW**
- **Premium Field Operations**

### Primary navigation

Only five persistent primary destinations:

1. **My Dashboard**
2. **Scope of Work Data**
3. **CONTROL OF WORKS**
4. **Active Houses**
5. **More**

Secondary screens are opened from dashboard shortcuts or More. Avoid overcrowding the main tab row.

### Layout

- Global background: `#F4F7FB`
- horizontal primary navigation under the header
- page content padding: ~13px
- bottom content breathing room: ~44px

---

## 7. Core UI Components

### Card

Use for every coherent operational group.

Visual rules:

- white surface
- 24px radius
- 1px neutral border
- 16px padding
- subtle shadow
- optional `surface2` soft tone
- clear title and optional subtitle

Do not nest many cards deeply.

### Field

- minimum height: 48px
- `surface2` background
- 1px `lineStrong` border
- 12px radius
- 12px horizontal padding
- 14px text
- multiline minimum height: 120px

Readonly fields may reduce opacity but should remain readable.

### Primary Button

Active buttons use a red gradient:

```text
#D92D3A → #B71C27
```

Interaction:

- spring press scale to ~0.965
- return to 1.0 with Reanimated spring
- selection haptic on press
- minimum height ~46px
- strong 900-weight label

### Secondary Button

- soft neutral surface
- neutral border
- dark text

### Danger Button

- pale red background
- light danger border
- danger text

### Badge

Rounded pill with semantic background + text color.

Supported tones:

- blue
- red
- amber
- green
- purple
- gray

### Select / MultiSelect

- input-like trigger
- modal selection sheet
- dark translucent backdrop
- selected row gets `brandSoft`
- selected text becomes brand red and heavier
- MultiSelect uses a Done action rather than closing after each selection

### Toggle

Custom 46×26 pill toggle:

- inactive: neutral gray
- active: brand red
- white knob

---

## 8. Motion & Haptics

Motion must support comprehension and tactile quality.

### Reanimated rules

Use Reanimated for:

- press-scale feedback
- splash sequencing
- progress reveals
- state transitions where they clarify change
- future dashboard micro-interactions

Recommended press spring:

```js
withSpring(0.965, { damping: 18, stiffness: 340 })
```

Then return to `1` with the same spring family.

### Haptics

Use `expo-haptics` for:

- button selections
- important state confirmations
- successful approvals / received confirmations
- errors or critical state changes when appropriate

Do not vibrate for passive scrolling or every render.

---

## 9. Splash Screen

The splash visually communicates the app’s roofing purpose instead of using a static logo only.

### Composition

- white → pale red → light gray vertical background gradient
- 190×190 premium icon container
- rounded 44px corners
- large soft shadow
- central app icon via Expo Image
- animated timber/roof-frame overlay
- app title **RC SOW**
- tagline **BUILDING BACK SAFER**
- slim red progress line

### Roof-frame animation sequence

The roof is visually repaired/constructed quickly:

1. Wall plate
2. Left rafter
3. Right rafter
4. Ridge
5. Additional left rafter
6. Additional right rafter

Beams animate from almost zero scale to full width using cubic-out easing.

Approximate staging:

- 150 ms plate
- 320 ms first left rafter
- 480 ms first right rafter
- 650 ms ridge
- 780 ms second left rafter
- 900 ms second right rafter
- splash completion around 1750 ms

### Rive layer

When a native/EAS build has `EXPO_PUBLIC_RIVE_SPLASH_URL`, Rive may render as an overlay. The Reanimated roof sequence remains the guaranteed fallback.

---

## 10. Dashboard Design

Dashboard is action-oriented, not a passive analytics page.

### Premium operations visual

Skia paints a compact 76px branded banner:

- soft red → soft blue → neutral gradient
- subtle circular light fields
- uppercase kicker: **FIELD OPERATIONS**
- main line: **One controlled record. Live actions.**
- supporting line: **Scope • Control • Houses • Approvals • Tracking**

### Metrics

Metrics are tappable cards, not decorative counters.

Examples:

- Unread Messages
- Open Tasks
- House Alerts
- Active Houses

Metric rules:

- surface2 background
- 16px radius
- neutral border
- prominent brand-red number (~27px, 900)
- small centered label
- red `OPEN ›` cue
- each card navigates directly to the matching screen

### Active Houses preview

Show a compact set of active houses on My Dashboard:

- house code + beneficiary
- parish • cluster • stage
- progress badge
- row tap selects the house and opens Active Houses

---

## 11. Login & Account UX

The login screen shares the same premium visual identity.

### Login brand block

- 70×70 red rounded-square logo
- white cross
- strong red product title
- dark supporting subtitle

### Secure backend state

Use green success surfaces for production-auth messaging:

- soft green background
- green border
- dark green heading + helper text

### Registration information

Use blue informational surfaces for approval explanations.

### Google sign-in

Google authentication must include:

- requested role
- requested parish when applicable
- visible explanation that server-approved users retain their role
- pending/new users submit the selected role for Admin approval

---

## 12. Operational Status UI

Use color as a secondary signal, not the only signal.

### Suggested mappings

- Approved / Received / Complete → green
- Pending / Informational → blue
- Urgent → amber
- Returned / Rejected / Critical → red
- Administrative category → purple where useful

Always show text such as `Approved`, `Urgent`, `Critical`, etc. with the color.

---

## 13. Roof Drawing UX

The drawing system is a technical tool and must prioritize accuracy over decoration.

### Supported roof logic

- Gable
- Hip
- Shed / mono-pitch
- Intersecting
- multiple roof sections in one plan

### Premium interaction expectations

- Gesture Handler for tap/pan input
- pan mode for canvas movement
- wall creation
- dotted construction/reference lines
- roof section selection
- ridge tool
- drain/slope-direction tool
- undo and redo
- scale / translation handling
- snap logical geometry where appropriate

### Hip roof visual logic

Hip roofs show:

- explicit central ridge
- framing lines from ridge ends toward corners
- adjustable `ridgeOffset`
- moveable drain/slope center
- four logical drain arrows

### Multi-roof rule

Multiple roofs should share a consistent visual coordinate system so combinations such as **Gable + Shed** can be displayed in the same logical direction.

---

## 14. Graphics Strategy

Use the graphics stack purposefully:

### Skia

Best for:

- lightweight dashboard/metric art
- procedural visual accents
- advanced gauges/charts
- scalable custom visuals

### SVG

Best for:

- roof plans
- dimensions
- arrows
- technical diagrams
- printable geometry

### Rive

Best for:

- flagship splash/brand animation
- interactive stateful mascot or workflow illustration
- high-value onboarding or success moments

Do not require Rive for essential field operation.

### Lottie

Use for lightweight non-interactive completion/loading illustrations when Rive would be excessive.

### Expo Image

Use for optimized app graphics/photos and stable content fitting.

---

## 15. Performance Rules

This app is intended for field use, so premium visuals must remain fast.

- Do not mount heavy WebViews/screens until opened.
- Keep animations short and GPU-friendly.
- Prefer transform/opacity animation over layout-heavy animation.
- Keep dashboard illustrations compact.
- Use Skia/SVG rather than large raster backgrounds when procedural graphics are suitable.
- Keep the five-tab primary shell lightweight.
- Secondary tools belong under More and should mount on demand.
- Never block a core workflow because an animation asset fails.
- Rive must have a native fallback.

---

## 16. Accessibility Rules

- Buttons use `accessibilityRole="button"`.
- Every actionable icon-only control must receive an accessibility label.
- Touch targets should be at least ~44–48px where practical.
- Do not use color alone to communicate status.
- Maintain high text/background contrast.
- Keep field labels visible; do not rely on placeholders as labels.
- Preserve logical reading order in modals and forms.
- Support readable metadata without excessive tiny text on critical screens.

---

## 17. Screen Organization

### Primary

1. My Dashboard
2. Scope of Work Data
3. CONTROL OF WORKS
4. Active Houses
5. More

### Secondary / More

Typical secondary destinations include:

- Messages
- Beneficiary Print Out
- Calculations
- Google Map
- Live Tracker
- Extract
- Notice of Completion
- Payment Submission
- Active Users
- Admin Dashboard
- dynamic admin-defined forms

### Admin design principle

Admin functionality should be grouped into internal dashboard subsections rather than becoming independent top-level navigation items.

---

## 18. Reusable Premium Patterns

### Pattern A — Action card

```text
[Card title]
[Short operational subtitle]
[Fields / status]
[Primary action] [Secondary action]
```

### Pattern B — Metric shortcut

```text
[large count]
[label]
OPEN ›
```

Tap navigates to the exact source data.

### Pattern C — Status row

```text
[primary identity / house code]
[metadata]
[status badge]
```

### Pattern D — Approval flow

```text
Draft → Submitted → Approved/Returned → Received
```

Use badges and clearly separated action buttons for each state.

### Pattern E — Human-readable operational empty state

Avoid blank surfaces. Use a short direct message such as:

> No open task requests.

or

> No active houses visible for this account.

---

## 19. UI Do / Don’t

### Do

- Use generous radius and compact shadows.
- Keep card titles strong and readable.
- Keep forms vertically clear.
- Make dashboard metrics actionable.
- Pair status colors with text labels.
- Use haptics on deliberate actions.
- Keep animations under ~2 seconds unless they are interactive.
- Preserve field usability before decorative effects.
- Use the Red Cross red strategically, not as the entire background.

### Don’t

- Do not create a dark gaming-style interface for this app.
- Do not flood every surface with red.
- Do not add heavy animations to technical forms.
- Do not mount all secondary screens at startup.
- Do not hide labels inside placeholders.
- Do not use tiny touch controls for drawing actions.
- Do not make Rive mandatory for login, scope entry or field work.
- Do not add extra primary tabs when an item belongs under More.

---

## 20. Canonical Design Tokens

```js
export const C = {
  brand: '#C91F2C',
  brandDeep: '#971621',
  brandSoft: '#FFF1F2',
  ink: '#101828',
  text: '#344054',
  muted: '#667085',
  bg: '#F4F7FB',
  surface: '#FFFFFF',
  surface2: '#F8FAFC',
  line: '#E4E7EC',
  lineStrong: '#D0D5DD',
  success: '#12805C',
  successSoft: '#ECFDF3',
  warning: '#B54708',
  warningSoft: '#FFFAEB',
  blue: '#175CD3',
  blueSoft: '#EFF8FF',
  purple: '#6941C6',
  purpleSoft: '#F4F3FF',
  danger: '#B42318',
  dangerSoft: '#FEF3F2',
  white: '#FFFFFF',
};

export const R = {
  sm: 12,
  md: 18,
  lg: 24,
  xl: 30,
};

export const S = {
  xs: 4,
  sm: 8,
  md: 12,
  lg: 16,
  xl: 24,
  xxl: 32,
};
```

---

## 21. Standard for Future RC SOW Screens

Any new screen should pass this visual checklist:

- uses `C`, `R`, `S` tokens rather than arbitrary values where practical
- uses the shared `Card`, `Field`, `Btn`, `Badge`, `Select` or `MultiSelect` primitives
- has one clear primary action per major section
- respects the five-primary-tab navigation model
- has direct task/message/status navigation where applicable
- uses Reanimated for purposeful micro-interaction only
- uses haptics for deliberate interaction feedback
- uses semantic status colors
- avoids unnecessary native-module dependencies
- mounts expensive content only when visible
- works without Rive assets
- remains readable in bright outdoor conditions

---

## 22. Source Files Defining the Design

Primary implementation references in v16.0.1:

- `src/theme/premium.js`
- `src/components/UI.js`
- `src/components/PremiumVisuals.js`
- `src/screens/AppShell.js`
- `src/screens/PremiumSplashScreen.js`
- `src/screens/DashboardScreen.js`
- `src/screens/LoginScreen.js`
- `src/drawing/RoofCanvas.js`

These files are the canonical implementation source if this document and the app ever diverge.

---

**Design identity:** Premium humanitarian field operations — precise, fast, calm, tactile, evidence-driven, and unmistakably RC SOW.
