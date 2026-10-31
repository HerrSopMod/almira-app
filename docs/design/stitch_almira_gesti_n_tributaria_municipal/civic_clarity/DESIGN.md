---
name: Civic Clarity
colors:
  surface: '#edfcff'
  surface-dim: '#c3dfe4'
  surface-bright: '#edfcff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#dcf9fe'
  surface-container: '#d7f3f8'
  surface-container-high: '#d1edf2'
  surface-container-highest: '#cbe8ed'
  on-surface: '#031f23'
  on-surface-variant: '#3e494a'
  inverse-surface: '#1a3438'
  inverse-on-surface: '#d9f6fb'
  outline: '#6e797a'
  outline-variant: '#bdc9c9'
  surface-tint: '#00696f'
  primary: '#00646a'
  on-primary: '#ffffff'
  primary-container: '#0b7f86'
  on-primary-container: '#e8fdff'
  inverse-primary: '#79d5dc'
  secondary: '#006a67'
  on-secondary: '#ffffff'
  secondary-container: '#6ef7f1'
  on-secondary-container: '#00706d'
  tertiary: '#4c5d5d'
  on-tertiary: '#ffffff'
  tertiary-container: '#647675'
  on-tertiary-container: '#eafdfc'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#96f1f9'
  primary-fixed-dim: '#79d5dc'
  on-primary-fixed: '#002022'
  on-primary-fixed-variant: '#004f54'
  secondary-fixed: '#6ef7f1'
  secondary-fixed-dim: '#4cdad5'
  on-secondary-fixed: '#00201f'
  on-secondary-fixed-variant: '#00504d'
  tertiary-fixed: '#d3e6e5'
  tertiary-fixed-dim: '#b8cac9'
  on-tertiary-fixed: '#0d1e1e'
  on-tertiary-fixed-variant: '#394a4a'
  background: '#edfcff'
  on-background: '#031f23'
  surface-variant: '#cbe8ed'
typography:
  display-currency:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 38px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  headline-sm:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-lg-medium:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '500'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-md-medium:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
  button:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 20px
  label-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.02em
  tab-label:
    fontFamily: Inter
    fontSize: 11px
    fontWeight: '500'
    lineHeight: 14px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1rem
  margin: 1.25rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.25rem
  space-xl: 1.5rem
---

## Brand & Style

This design system is tailored for an institutional, mobile-first civic application dedicated to municipal tax administration and citizen services in Lima, Peru. The design direction prioritizes radical clarity, civic trust, institutional sobriety, and high accessibility across all generations, specifically addressing senior citizens who require legible, forgiving, and predictable interfaces.

The aesthetic adheres strictly to modern civic minimalism: pure white foundations, structured negative space, crisp hairline dividers, and high-contrast typography. Decorative clutter, skeuomorphism, non-essential gradients, and nested card abstractions are strictly eliminated. Every UI surface exists solely to communicate municipal status, facilitate compliance, or process citizen claims with zero ambiguity.

## Colors

The palette establishes an authoritative yet welcoming municipal identity anchored in teal tones:

- **Primary (`#0B7F86`)**: Used exclusively for high-intent interactions, primary actions, text links, active tab indicators, and critical navigational cues.
- **Light Accent (`#2CC5C0`)**: Reserved for non-interactive visual progress, step tracking bars, and dynamic status meters.
- **Soft Highlight Surface (`#E3F6F5`)**: High-restraint fill color used to contextualize high-priority notices or active summary banners. Strictly limited to at most one surface per screen.
- **Canvas (`#FFFFFF`)**: The global base background for all screens and sheets.
- **Primary Text (`#0F2A2E`)**: Deep petrol slate ensuring AAA contrast against pure white backgrounds for senior-friendly readability.
- **Secondary Text (`#5B6B70`)**: Neutral slate used for metadata, field labels, timestamps, and secondary descriptions.
- **Structural Borders (`#D6E3E4`)**: Subtle hairline tone for component outlines, dividers, and card boundaries.
- **Semantic Indicators**:
  - Valid / Resolved: `#2E9E6B`
  - In Progress / Pending: `#C98A00`
  - Overdue / Critical: `#D64545`
  Semantic colors are strictly restricted to badges, status tags, and inline state alerts; never use them as full-width solid container backgrounds.

## Typography

Typography relies entirely on `Inter` to provide structural neutral clarity and optimal legibility at both small scales and large numeric sizes.

- **Baseline Scale**: Minimum body text is set to 14px; 16px is used as standard for transactional text, form labels, and instructions to ensure readability for elderly users.
- **Monetary Representation**: The Peruvian Sol currency symbol (`S/`) must precede numerical amounts with a non-breaking space (e.g., `S/ 142.50`). Monetary figures in balance sheets, pending invoices, and payment summaries must always be right-aligned using tabular figures to enable immediate visual scanning.
- **Headlines & Text Wrapping**: Display amounts over 32px must preserve numeric integrity and wrap smoothly with reduced line height on small viewport widths.

## Layout & Spacing

The layout is built upon an 8pt mobile grid system framed by an unyielding horizontal canvas margin of 20px (`1.25rem`). 

- **Canvas & Sections**: Outer screens maintain consistent left and right 20px margins. Vertical content stacks vertically using `space-md` (16px) or `space-xl` (24px) gaps to prevent cognitive overload.
- **Container Strategy**: Avoid deep nesting. Content sections are single-level groups outlined with clean borders rather than layered stacks.
- **Touch Safe Areas**: Interactive elements maintain a minimum target height of 48px to 52px, leaving generous breathing room between tap targets to mitigate mis-taps.
- **Bottom Navigation Offset**: Scroll views must contain bottom padding equal to the height of the fixed navigation bar (64px) plus safe area inset plus `space-lg` to prevent primary content from being occluded.

## Elevation & Depth

This design system does not use ambient drop shadows or heavy blur surfaces. Depth is established through planar separation and hairline borders:

- **Flat Border Model**: Elevation tiers are conveyed via a 1px solid border (`#D6E3E4`) on pure white surfaces (`#FFFFFF`).
- **Focus & Selection**: Interactive active states and focused fields transition their border to 1.5px solid `#0B7F86`, eliminating the need for outer glowing rings.
- **Overlays & Modals**: Bottom sheets and system notifications emerge over a solid `#0F2A2E` scrim with 40% opacity. The sheet surface remains flat white with a top border radius and no shadow.

## Shapes

The geometric framework is calculated and uniform:

- **Buttons & Form Fields**: Standardized to a constant corner radius of 12px (`0.75rem`), providing a tactile and approachable feel without becoming a pill shape.
- **Cards & Containment Modules**: Styled with a 12px or 16px corner radius, bound by hairline borders.
- **Badges & Semantic Chips**: Use compact 6px to 8px rounded corners to maintain structural distinction from primary clickable controls.
- **Bottom Navigation**: Top corners carry a 16px radius, coupled with a 1px border on the top edge.

## Components

### Buttons
- **Primary Button**: Full width (screen margin 20px), fixed height 52px, 12px border radius. Filled with `#0B7F86`, labeled with 16px Semibold text in `#FFFFFF`. No drop shadows.
- **Secondary Button**: Full width, height 52px, 12px border radius. Transparent background with a 1.5px border in `#0B7F86` or `#D6E3E4`, labeled with 16px Semibold text in `#0B7F86`.
- **Tertiary / Text Button**: Height 48px, background transparent, text `#0B7F86`, 16px Medium.

### Input Fields
- Height 52px with 16px internal padding. Background `#FFFFFF`, border 1px solid `#D6E3E4`, border radius 12px.
- Labels sit above the input field in 14px Medium `#0F2A2E`.
- Placeholder text in 16px Regular `#5B6B70`.
- Focused state transitions the border to 1.5px solid `#0B7F86`.

### Cards & Group Rows
- Flat white containers surrounded by 1px solid `#D6E3E4` with 12px corner radius.
- Padding inside cards is standard 16px or 20px. 
- Never place a bordered card inside another bordered card. Group related items within a single container using subtle 1px internal dividers.

### Badges & Semantic Tags
- Inline status tags for claims and payments: height 24px, horizontal padding 8px, 6px radius.
- Vigente / Resuelto: `#2E9E6B` text on `#EAF6F0` background.
- En atención: `#C98A00` text on `#FBF5E6` background.
- Vencida: `#D64545` text on `#FAEAEA` background.

### Fixed Bottom Navigation Bar
- Fixed 5-tab bar docked to viewport bottom: **Inicio**, **Pagar**, **Reclamos**, **Obras**, **Asistente**.
- Height: 64px + device bottom safe area. Background `#FFFFFF` with a 1px border-top `#D6E3E4`.
- Active state: Icon and 11px label colored `#0B7F86`.
- Inactive state: Icon and 11px label colored `#5B6B70`.

### Civic Claim & Tax Specific Components
- **Progress Trackers**: Linear step indicator using `#2CC5C0` for filled progress bars and `#D6E3E4` for track background. Height 6px, rounded cap.
- **Tax Due Row**: Horizontal layout with tribute title on the left (16px Medium `#0F2A2E`) and right-aligned amount in display format (`S/ XX.XX` in 18px Bold `#0F2A2E`).
- **Highlight Container**: A single, prominent alert block per view using `#E3F6F5` background, 12px radius, and `#0B7F86` typography/iconography for important fiscal announcements or tax discounts.