# RC SOW — Control of Works Reference Design

This screen is a faithful Flutter replication of the supplied RC SOW Control of Works reference.

## Extracted visual tokens

```css
:root {
  --rc-page-background: #F4F7FC;
  --rc-surface: #FFFFFF;
  --rc-hero: #F9EBEB;
  --rc-hero-border: #F1DCDD;
  --rc-primary: #C91F2C;
  --rc-primary-soft: #FEDBD9;
  --rc-text-primary: #241B1C;
  --rc-text-secondary: #665B5D;
  --rc-border: #DDE1E8;
  --rc-card-border: #E2E5EA;
  --rc-icon-well: #EEF4FF;
  --rc-module-blue: #2D69C4;
  --rc-open-bg: #F8D9DC;
  --rc-success-bg: #E6EFEA;
  --rc-closed-bg: #E8F1EC;
  --rc-success: #2E7A60;
  --rc-radius-hero: 30px;
  --rc-radius-card: 26px;
  --rc-radius-tab: 28px;
  --rc-radius-button: 18px;
  --rc-radius-chip: 999px;
}
```

## Composition

- Page background: cool near-white blue.
- Eyebrow: uppercase red, heavy weight, increased tracking.
- Control of Works: heavy display title.
- New action: soft-pink rounded rectangle.
- Hero: pale-red surface with Controlled delivery chain.
- Status: compact pills for Open, Attention and Closed.
- CTA pair: red filled Completion plus outlined Payment.
- Lifecycle filter: connected segmented rail.
- Workflow modules: white rounded cards in a responsive 2-column tablet grid.
- Module icon well: pale blue with blue line icon.
- Module count: strong right-aligned number plus records.
- Existing production module routing, counts, export and database functionality are preserved.

## Responsive behavior

- >= 980 logical px: 3 module columns.
- >= 540 logical px: 2 module columns.
- < 540 logical px: 1 module column.
- Phase rail becomes horizontally scrollable on narrow phones.
- Header stacks safely on small phones.
