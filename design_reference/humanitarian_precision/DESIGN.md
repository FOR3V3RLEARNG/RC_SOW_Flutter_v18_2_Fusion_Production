---
name: Humanitarian Precision
colors:
  surface: '#fff8f7'
  surface-dim: '#f1d3d0'
  surface-bright: '#fff8f7'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#fff0ef'
  surface-container: '#ffe9e7'
  surface-container-high: '#ffe2de'
  surface-container-highest: '#f9dcd9'
  on-surface: '#271816'
  on-surface-variant: '#5b403d'
  inverse-surface: '#3e2c2a'
  inverse-on-surface: '#ffedeb'
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
  secondary-container: '#54a0fe'
  on-secondary-container: '#003567'
  tertiary: '#005f7b'
  on-tertiary: '#ffffff'
  tertiary-container: '#00799c'
  on-tertiary-container: '#e9f7ff'
  error: '#C62828'
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
  tertiary-fixed-dim: '#7bd1f8'
  on-tertiary-fixed: '#001f2a'
  on-tertiary-fixed-variant: '#004d65'
  background: '#fff8f7'
  on-background: '#271816'
  surface-variant: '#f9dcd9'
  brand-red: '#D32F2F'
  brand-strong: '#B71C1C'
  brand-soft: '#FFEBEE'
  canvas-l0: '#F5F7F9'
  surface-l1: '#FFFFFF'
  surface-l2: '#F0F3F5'
  success: '#2E7D32'
  warning: '#FFA000'
  info: '#0288D1'
typography:
  hero-title:
    fontFamily: Hanken Grotesk
    fontSize: 32px
    fontWeight: '900'
    lineHeight: 36px
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
    fontSize: 18px
    fontWeight: '700'
    lineHeight: 24px
  body-lg:
    fontFamily: Inter
    fontSize: 17px
    fontWeight: '400'
    lineHeight: 26px
  body-md:
    fontFamily: Inter
    fontSize: 15px
    fontWeight: '400'
    lineHeight: 22px
  label-md:
    fontFamily: JetBrains Mono
    fontSize: 13px
    fontWeight: '500'
    lineHeight: 16px
  metadata:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
  hero-title-mobile:
    fontFamily: Hanken Grotesk
    fontSize: 28px
    fontWeight: '900'
    lineHeight: 32px
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
  gutter-phone: 16px
  gutter-tablet: 24px
  target-min: 48px
---

## Brand & Style

The design system is a humanitarian field-operations command system that balances institutional trust with operational speed. The visual narrative is built around "Humanitarian Precision"—an aesthetic that is professional, dependable, and deeply humane. It is designed to function as a trustworthy evidence chain, ensuring every action from assessment to payment is verifiable and visible.

### Design Style: Corporate / Modern (Humanitarian Variant)
We utilize a refined Material 3 foundation, customized with a distinctive "House-centric" identity. The UI is characterized by:
- **Operational Calm:** High-density information is only presented where it improves decisions, using a clean, light-neutral canvas to reduce visual fatigue.
- **Evidence Confidence:** Explicit states for saving, syncing, and completion to reassure field workers.
- **Field Resilience:** High-contrast elements and large touch targets (minimum 48dp) for reliable use in outdoor, high-glare environments.
- **Institutional Trust:** Restrained motion and clear historical audit trails.
- **Geometric Nuance:** Subtle roof-profile/asymmetric cuts are used sparingly in hero sections to reinforce the shelter-focused mission without becoming decorative.

## Colors

The color palette is functionally driven, prioritizing legibility and semantic clarity over decoration.

- **Brand Red:** Reserved for primary actions, selected navigation states, and key brand moments. It is the "Action Color."
- **Semantic Hierarchy:** 
    - **Success (Green):** Completed, approved, or synced.
    - **Attention (Amber):** Pending, incomplete, or queued offline.
    - **Info (Blue):** Logistics, maps, and technical details.
    - **Error (Red):** Critical failures. Distinguished from Brand Red through iconography and high-contrast surfaces.
- **Surface Levels:**
    - **L0 Canvas:** A soft neutral background to anchor the experience.
    - **L1 Standard Surface:** Pure white containers for records and primary forms.
    - **L2 Context Surface:** Subtly tinted panels for house summaries and phase-specific context.

## Typography

Typography focuses on high-impact hierarchy and outdoor legibility. 

- **Headlines:** Use Hanken Grotesk with extreme weights (800-900) for a confident, institutional presence. Titles are compact and authoritative.
- **Body:** Inter provides a neutral, highly readable platform for dense field data and long-form assessment text.
- **Labels:** JetBrains Mono is utilized for house codes, TRN numbers, and technical measurements to provide a "technical/data" feel that distinguishes identifiers from narrative text.
- **Operational Eyebrows:** Small, uppercase section titles are used to maintain context in deep workflows (e.g., "CONTROL / PRODUCTION").

## Layout & Spacing

The layout utilizes a flexible grid system that adapts between two primary density modes:

- **Field Mode (Mobile):** A single-column fluid layout with 16px gutters. It prioritizes one dominant action per screen and large, one-handed touch targets (48px minimum).
- **Review Mode (Tablet/Desktop):** A multi-column fixed grid (12 columns) that allows for master/detail views and side-by-side record comparison.

The spacing rhythm follows a 4px baseline. Vertical spacing is generous between cards to emphasize the "House" as a distinct operational unit, while internal card spacing is tighter to maintain information density.

## Elevation & Depth

Hierarchy is established through **Tonal Layering** and **Soft Shadows** rather than aggressive elevation.

- **L0 (Canvas):** The base layer. No shadows.
- **L1 (Surfaces):** Cards and records use a very subtle, diffused shadow (4px blur, 5% opacity) to lift slightly from the canvas.
- **L2 (Context):** These surfaces do not use shadows; depth is achieved via tonal shifts (Brand Soft or Surface Secondary tints) to indicate active phases or specific "readiness" states.
- **L3 (Command):** Sheets and dialogs use standard Material 3 elevation (Level 3) to focus attention.
- **Flat Outlines:** In high-density Review Mode, cards may swap shadows for 1px neutral-200 outlines to maintain clarity without visual noise.

## Shapes

The shape language reflects an institutional yet approachable character. Roundedness increases with the scale of the container to create a nested visual logic.

- **Controls & Inputs:** 12px–16px radius for a tactile, modern feel.
- **Records & Cards:** 18px–24px radius, providing a clear container identity.
- **Operational Summaries:** 24px–32px radius for large hero-style containers and dashboard pulses.
- **Status Pills:** Full radius (999px) for immediate identification as a tag or state indicator.
- **Signatures:** Digital signature pads utilize a 12px radius to match input controls.

## Components

- **Buttons:** High-contrast Brand Red for primary actions. 48dp minimum height. Text is all-caps or medium-weight sans-serif for urgency.
- **Phase Chips:** Used in the "Lifecycle Rail." They utilize tonal backgrounds (L2) when inactive and Brand Red when active.
- **House Cards:** The central operational unit. Includes a House Code label in monospaced font, a progress indicator, and a "Smart Next Action" button.
- **Evidence Strip:** A horizontal scroll of thumbnail previews for photos, PDFs, and signatures, featuring a prominent [+] button for immediate capture.
- **Sync Status:** A persistent, low-profile indicator in the header or bottom bar using semantic icons (Cloud, Check, Alert) to indicate offline readiness.
- **Input Fields:** Outlined style with 16px roundedness. Labels are always visible, never floating inside the field, to ensure legibility in high-glare environments.
- **Operational Hero:** Not a decorative banner, but a "Production Pulse" container showing real-time counts of active houses and blockers.