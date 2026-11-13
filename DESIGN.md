# Nexora — Design System & Constraints (`DESIGN.md`)

*Established via Impeccable Design Standards for Flutter*

---

## 1. Color Palette & Tokens (`NexoraTheme`)

| Token | Hex Value | Semantic Role |
|---|---|---|
| `primary` | `#0066FF` | Electric Blue: Key brand action, CTA buttons, active indicators |
| `primaryContainer` | `#E0F2FE` | Soft blue tint: Subtle pill selections, active tab backgrounds |
| `darkNavy` | `#050B28` | Deep luxury anchor: Headers, high-contrast badges, dark accents |
| `secondary` | `#00D2FF` | Vivid Cyan: Energy accents, progress bar highlights, live tags |
| `tertiary` | `#E11D48` | Rose / Coral: Wishlist hearts, discount chips, destructive actions |
| `surface` | `#F6F8FC` | Off-white canvas background |
| `surfaceContainerLowest` | `#FFFFFF` | Card & sheet surfaces, floating elevated containers |
| `price` / `onSurface` | `#0F172A` | Slate 900: High-legibility text & primary price readouts |
| `onSurfaceVariant` | `#64748B` | Slate 500: Secondary descriptions, metadata, subtitles |
| `outlineVariant` | `#E2E8F0` | Subtle hairline borders (1px) |

---

## 2. Typography Rules

- **Primary Font Family:** `Plus Jakarta Sans` (with fallbacks `Noto Sans`, `sans-serif`).
- **Hierarchy:**
  - **Display / Hero Titles:** Bold (w700), 24–32sp, letter spacing -0.5px.
  - **Section Headers:** SemiBold (w600), 18–20sp.
  - **Product Card Titles:** Medium (w500), 14–15sp, max 2 lines with ellipsis.
  - **Price:** Bold (w700), 16–18sp, tabular figures.
  - **Body / Metadata:** Regular (w400) to Medium (w500), 12–14sp, line-height 1.4.

---





## 3. Layout, Spacing & Corner Radii

- **Grid Spacing Units:** 4dp, 8dp, 12dp, 16dp, 24dp, 32dp.
- **Card Padding:** Minimum 16dp horizontal, 16dp vertical.
- **Border Radii:**
  - Badges & Chips: `100dp` (full pill)
  - Product Cards & Action Buttons: `16dp` to `20dp`
  - Floating Navigation Dock & Search Bar: `24dp` to `32dp`
  - Modal Bottom Sheets: Top `24dp`

---

## 4. Impeccable Anti-Slop Rules (Strict Enforcement)

1. **No Inert Affordances:** Every visible button, icon, and chip MUST perform an action. Never leave `onPressed: () {}` or placeholder snackbars in production.
2. **No Card Stacking:** Avoid nesting rounded cards inside rounded cards with identical borders. Use background contrast, dividers, or whitespace to separate information.
3. **No Uncalibrated Gradients:** No generic diagonal purple-to-cyan gradients. Gradients are restricted to soft linear ambient glows behind hero showcases.
4. **Touch Target Accessibility:** All tappable controls must have at least `48x48dp` hit boundaries and explicit `Semantics` / `tooltip` labels.
5. **Text Scale Resilience:** Sizing and layout containers must tolerate 150%–200% system accessibility text scale without clipping or `RenderFlex` overflows.

