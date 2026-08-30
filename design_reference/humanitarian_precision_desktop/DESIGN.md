---
name: Humanitarian Precision Desktop
colors:
  surface: '#f8f9fb'
  surface-dim: '#d8dadc'
  surface-bright: '#f8f9fb'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f2f4f6'
  surface-container: '#eceef0'
  surface-container-high: '#e6e8ea'
  surface-container-highest: '#e0e3e5'
  on-surface: '#191c1e'
  on-surface-variant: '#5b403d'
  inverse-surface: '#2d3133'
  inverse-on-surface: '#eff1f3'
  outline: '#8f6f6c'
  outline-variant: '#e4beba'
  surface-tint: '#ba1a20'
  primary: '#af101a'
  on-primary: '#ffffff'
  primary-container: '#d32f2f'
  on-primary-container: '#fff2f0'
  inverse-primary: '#ffb3ac'
  secondary: '#005faf'
  on-secondary: '#ffffff'
  secondary-container: '#6cabff'
  on-secondary-container: '#003e75'
  tertiary: '#005f7b'
  on-tertiary: '#ffffff'
  tertiary-container: '#2e7895'
  on-tertiary-container: '#eaf7ff'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#ffdad6'
  primary-fixed-dim: '#ffb3ac'
  on-primary-fixed: '#410003'
  on-primary-fixed-variant: '#930010'
  secondary-fixed: '#d4e3ff'
  secondary-fixed-dim: '#a5c8ff'
  on-secondary-fixed: '#001c3a'
  on-secondary-fixed-variant: '#004786'
  tertiary-fixed: '#bee9ff'
  tertiary-fixed-dim: '#8bd0f0'
  on-tertiary-fixed: '#001f2a'
  on-tertiary-fixed-variant: '#004d64'
  background: '#f8f9fb'
  on-background: '#191c1e'
  surface-variant: '#e0e3e5'
  brand-red: '#D32F2F'
  brand-strong: '#B71C1C'
  brand-soft: '#FFEBEE'
  success-green: '#2E7D32'
  attention-amber: '#FFA000'
  info-blue: '#0288D1'
  table-header: '#F0F3F5'
  border-subtle: '#E4BEBA'
  text-on-surface: '#271816'
typography:
  display-lg:
    fontFamily: Hanken Grotesk
    fontSize: 32px
    fontWeight: '900'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Hanken Grotesk
    fontSize: 24px
    fontWeight: '800'
    lineHeight: 32px
  headline-md:
    fontFamily: Hanken Grotesk
    fontSize: 20px
    fontWeight: '750'
    lineHeight: 28px
  section-title:
    fontFamily: Hanken Grotesk
    fontSize: 16px
    fontWeight: '700'
    lineHeight: 24px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: Inter
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 18px
  label-mono:
    fontFamily: JetBrains Mono
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
  metadata:
    fontFamily: Inter
    fontSize: 11px
    fontWeight: '600'
    lineHeight: 14px
    letterSpacing: 0.05em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 4px
  xs: 8px
  sm: 12px
  md: 16px
  lg: 24px
  xl: 32px
  gutter-desktop: 24px
  margin-edge: 32px
---

## Brand & Style

This design system is an institutional command environment tailored for high-density desktop monitoring and reporting. It translates the "Humanitarian Precision" ethos from the field into a **Corporate / Modern** executive dashboard style that prioritizes operational speed, auditability, and institutional trust. 

The aesthetic is built on "Operational Calm," utilizing expansive white surfaces and structured neutral grays to manage dense data without visual fatigue. The brand's signature Red Cross identity is used as a functional "Action Language," reserved for primary triggers and critical status markers. The UI evokes a sense of "Evidence Confidence," where every record's synchronization, approval, and audit state is explicitly visualized to ensure a trustworthy chain of custody from head office to the field.

**Key Design Principles:**
- **Institutional Authority:** Heavy, bold typography and structured grids reflect a reliable, established organization.
- **Dense Clarity:** Information density is maximized through tight vertical rhythms and persistent filtering, ensuring decision-makers can see the "Production Pulse" at a glance.
- **Systematic Reporting:** Use of monospaced accents for technical identifiers to distinguish data-driven evidence from narrative field notes.

## Colors

The palette is functionally segmented to support high-density reporting and clear semantic signaling.

- **Primary (Brand Red):** Used exclusively for high-priority actions, navigation selection, and critical "Attention" markers. It is never used decoratively.
- **Surface Strategy:** 
    - **Canvas (L0):** A soft, low-fatigue light gray (`#F5F7F9`) used for the main application background.
    - **Surface (L1):** Pure white (`#FFFFFF`) for data tables, cards, and primary content modules.
    - **Header/Tint (L2):** Light neutrals (`#F0F3F5`) for table headers and grouping logic.
- **Semantic Indicators:**
    - **Success:** Indicates "Synced," "Approved," or "Complete."
    - **Attention:** Indicates "Pending Review," "Offline Draft," or "Awaiting Evidence."
    - **Info:** Used for logistics, technical measurements, and metadata.
- **Neutral Grays:** A refined range of soft grays is employed to define table structures and borders without adding the visual weight of heavy lines.

## Typography

The typographic system balances institutional authority with high-density legibility.

- **Headlines (Hanken Grotesk):** Utilized for primary page titles and dashboard modules. High weights (800+) provide a sense of stability and institutional "heft."
- **Body (Inter):** The workhorse for all data entry, table content, and narrative reporting. Inter is chosen for its neutral character and exceptional legibility at small sizes.
- **Technical Accents (JetBrains Mono):** Reserved for House Codes, TRN numbers, GPS coordinates, and measurement data. This monospace treatment signals "Technical Truth" and distinguishes identifiers from descriptive text.
- **Operational Eyebrows:** Small-caps or uppercase labels are used as context markers (e.g., `CONTROL / PRODUCTION`) to maintain orientation in deep workflow trees.

## Layout & Spacing

The layout uses a **Fixed Grid** philosophy for Desktop Review Mode to ensure consistent data density and predictable information mapping across large screens.

- **Master/Detail Framework:** The dashboard utilizes a 12-column grid. Complex house records often employ a 4-column master list on the left with an 8-column detail/evidence pane on the right.
- **Production Pulse Layout:** Dashboard modules are grouped into 3 or 4 columns to provide a high-level summary of active phases (Scope, Plan, Delivery, etc.).
- **Spacing Rhythm:** A strict 4px baseline is maintained. In high-density tables, vertical cell padding is reduced to 8px to maximize row visibility, while card-to-card spacing remains at 24px to provide "Operational Calm" and clear grouping.
- **Persistent Shell:** A left-aligned Navigation Rail provides rapid access to primary destinations (Dashboard, Scope, Control) while preserving maximum horizontal space for data tables.

## Elevation & Depth

In the desktop environment, hierarchy is established primarily through **Tonal Layers** and **Low-Contrast Outlines** to minimize visual clutter in dense layouts.

- **Tonal Stacking:** The L0 Canvas background anchors the app. White L1 Surfaces represent actionable cards and modules. L2 Context Tints (using "Brand Soft" or light neutrals) are used inside cards to separate headers or secondary grouping areas.
- **Soft Shadows:** Only used for interactive floating elements like "Command Sheets" or dropdown menus. These shadows are extremely diffused (8px blur, 4% opacity) to avoid looking heavy.
- **Flat Outlines:** For data tables and high-density lists, 1px soft-neutral borders (`#E4BEBA`) are preferred over shadows to define boundaries.
- **Interactive Depth:** On hover, L1 Cards transition from flat to a subtle elevation state to indicate clickability.

## Shapes

The shape language combines modern softness with structured institutional corners. 

- **Data Containers:** Cards and major dashboard modules use a `1.0rem` (16px) radius, providing a distinct container identity that feels professional yet approachable.
- **Input Fields & Buttons:** Standardized at `0.5rem` (8px) for a precise, "tool-like" appearance suitable for high-frequency data entry.
- **Status Indicators:** Use full pill-shaped rounding (`999px`) to immediately distinguish them from interactive buttons or data fields.
- **Subtle Branding:** Asymmetric "roof-profile" cuts may be applied sparingly to the top-right corner of hero summary containers to reinforce the shelter-focused mission.

## Components

- **Review Tables:** High-density structures with fixed headers, zebra-striping using `#F0F3F5`, and monospaced house identifiers. Every row includes a "Sync State" icon (Cloud/Check/Alert).
- **Production Pulse Metrics:** Large numeric tiles featuring Hanken Grotesk 900. Each tile is paired with a semantic progress bar (Success, Attention, or Info).
- **Lifecycle Rail:** A horizontal navigation component for "Control" phases. Active phases use a Brand Red underline and bold text; inactive phases are neutral gray with item counts in parentheses.
- **Smart Next Action Card:** A high-contrast module within the House Command view that uses Brand Soft backgrounds and a primary Brand Red button to drive the workflow forward.
- **Evidence Strip:** A masonry or horizontal grid of thumbnails. Each thumbnail features a metadata overlay showing the "Classification" (e.g., *Before*, *After*, *Defect*) and a verification checkmark.
- **Sync Status Bar:** A persistent, low-profile indicator in the global header. It provides real-time feedback on the "Evidence Chain" readiness (e.g., "14 records queued for sync").
- **Buttons:** Primary desktop buttons are 40px in height (slightly smaller than field mode) with all-caps typography to maintain urgency and institutional authority.