# UX Figma Handoff — Technical Instructions

## Overview

This document provides detailed technical guidance for executing a **design-to-code handoff from Figma**. The handoff process is:

1. Framework-agnostic (React, Vue, Angular, Svelte, etc.)
2. Styling-choice aware (CSS, SCSS, CSS Modules, Tailwind, etc.)
3. i18n-preserving (no hardcoded text, all keys maintained)
4. Functionality-preserving (no business logic changes)
5. Token-driven (design system alignment)

## Key Principles

### 1. Preserve First
- Business logic, services, API calls, routing, state management untouched
- All data bindings, event handlers, directives intact
- i18n keys and patterns preserved exactly
- Accessibility attributes (ARIA, semantic HTML) maintained
- Component contracts (props, events) unchanged

### 2. Token-Driven
- Every color from `var(--color-name)` (CSS) or `$color-name` (SCSS)
- Every spacing value from `var(--spacing-unit)` or `$spacing-unit`
- Every typography from `var(--font-*)` or `$font-*`
- Every radius, shadow, and effect from tokens
- If Figma value has no token: use closest token and note as UNMAPPED

### 3. Minimal Changes
- DOM structure changes ONLY when required for layout fidelity
- Prefer CSS/SCSS updates over markup refactoring
- Reuse existing classes and component nesting where possible
- Add wrapper divs only when necessary (and document why)

### 4. Framework Respect
- Use framework idioms and conventions
- Follow project's existing patterns (hooks, stores, lifecycle, etc.)
- Use native or Material component libraries when appropriate
- Preserve testing hooks, data attributes, and debugging aids

## Phase 0: Context Detection

### 0.1 Framework Detection

Check package.json and project structure:

```javascript
// React: Has react, react-dom
// Vue: Has vue
// Angular: Has @angular/core
// Svelte: Has svelte
// Check also for build tool: webpack, vite, esbuild, etc.
```

### 0.2 Styling Detection

Check imports and file extensions:

```
CSS Modules:  .module.css / .module.scss files
SCSS:         .scss files, node-sass or dart-sass in package.json
CSS:          .css files
Tailwind:     tailwindcss in package.json, classNames with tailwind tokens
Styled-comp:  styled-components in package.json
Emotion:      @emotion/react in package.json
Shadow DOM:   Custom Elements with :host
```

**User decision**: Ask if CSS or SCSS preferred if project supports both.

### 0.3 i18n Detection

Check for translation patterns:

```
Angular i18n:      i18n attributes in templates, localize() in TS
Transloco:         transloco pipe, t() function, scoped JSON files
i18next:           useTranslation hook, i18n.t()
ngx-translate:     translate pipe, instant/get methods
Custom service:    injected translation service with t() or get() method
No i18n:           Hardcoded strings only (unlikely in production)
```

### 0.4 Design Tokens Detection

Check for token files or patterns:

```
CSS variables:     Root :root { --color-primary: ...; } in CSS
SCSS variables:    $color-primary: ... in _variables.scss
Tailwind config:   tailwind.config.js with colors, spacing, etc.
Design system lib: @company/design-tokens package
token JSON file:   tokens.json with structured values
Figma Tokens:      Check for Figma Tokens plugin integration
```

## Phase 1: Figma MCP Analysis

### 1.1 Retrieve Frame

Using Figma MCP, read the target frame/node and extract:

**Layout structure:**
- Frame dimensions (width, height)
- Auto-layout direction (horizontal/vertical)
- Auto-layout spacing (gap)
- Padding/margins per edge
- Alignment (h-center, v-center, etc.)
- Wrap/distribute settings

**Component hierarchy:**
- Parent-child relationships
- Component names and instances
- Component properties/variants applied
- Nested auto-layout groups

**Constraints & resizing:**
- How elements resize (fixed, fill, hug)
- Responsive breakpoints or viewport sizes

### 1.2 Extract Styling

**Colors:**
- Read color fills for backgrounds, text, borders, icons
- Read color styles (if using Figma color library)
- Extract hex/RGB values

**Typography:**
- Font family, weight, size, line height, letter spacing
- Read typography styles if using Figma typography library
- Text alignment, text decoration

**Effects & details:**
- Border: width, color, style (solid, dashed, etc.)
- Shadow: x, y, blur, spread, color, opacity
- Radius: corner radius per corner or uniform

**Sizing & spacing:**
- Component width, height
- Padding: top, right, bottom, left
- Margin: top, right, bottom, left
- Gap (between items in auto-layout)

### 1.3 Generate Figma Design Spec

Print a markdown spec for review:

```markdown
# Figma Design Spec: [Component Name]

## Layout Structure
- **Parent container:** Auto-layout, vertical, gap: 16px, padding: 24px
- **Header section:** Flex, gap: 8px, align-items: center
  - Title: fixed width
  - Icon: 24x24, fixed
- **Content section:** Flex, column, gap: 12px
  - Item 1: variable height
  - Item 2: variable height

## Colors
- **Background:** #FFFFFF (heading-bg)
- **Text (primary):** #1a1a1a (text-primary)
- **Text (secondary):** #666666 (text-secondary)
- **Border:** #EEEEEE (border-light)
- **Action (primary):** #0066CC (action-primary)

## Typography
- **Heading:** 20px, 600 weight, line-height 24px, color: text-primary
- **Body:** 14px, 400 weight, line-height 20px, color: text-secondary

## Spacing
- **Padding:** 24px top/right/bottom, 20px left
- **Gap:** 16px (vertical)
- **Margin (heading):** 0 bottom 12px

## Effects
- **Shadow:** 0 2px 8px rgba(0,0,0,0.1)
- **Radius:** 4px

## Components Used
- Button (primary)
- Icon (info)
- Divider
```

### 1.4 Map Figma Styles to Project Tokens

Create mapping table:

```markdown
| Figma Element | Figma Value | Closest Token | CSS Variable | Notes |
|---|---|---|---|---|
| Background | #FFFFFF | bg-white | var(--color-bg-white) | ✓ Exact match |
| Text heading | #1a1a1a, 20px, 600 | heading-1 | var(--font-heading-1) | ✓ Exact match |
| Gap | 16px | spacing-md | var(--spacing-md) | ✓ Exact match |
| Border | #EEEEEE, 1px | border-light | var(--color-border-light) | ✓ Exact match |
| Shadow | 0 2px 8px rgba(0,0,0,0.1) | shadow-sm | var(--shadow-sm) | ✓ Close match |
| Radius | 4px | radius-sm | var(--radius-sm) | ✓ Exact match |
| **UNMAPPED** | **#0055DD** (custom blue) | action-primary (#0066CC) | var(--color-action-primary) | ⚠ Close but not exact; use action-primary and note variance |
```

## Phase 2: Component Analysis

### 2.1 Read Existing Component

Extract:

**Markup structure:**
- Element hierarchy
- Component nesting
- CSS classes/scoping approach
- Framework-specific syntax (JSX, v-for, *ngIf, etc.)

**State & bindings:**
- Props/inputs and their types
- State/reactive data
- Two-way bindings
- Event handlers and their names

**i18n usage:**
- Translation pipe/function syntax
- Translation key format and naming
- Placeholder parameters
- Locale fallbacks

**Styling approach:**
- CSS/SCSS/CSS Modules/Tailwind
- Class naming convention (BEM, camelCase, etc.)
- How tokens are referenced

### 2.2 Detect Markup Pattern

Identify framework template syntax:

```jsx
// React/JSX
return <div className="container">...</div>

// Vue 3
<template><div class="container">...</div></template>

// Angular
<div class="container">...</div> or <div [class]="dynamicClass">...</div>

// Svelte
<div class="container">...</div>

// Handlebars/EJS/etc.
<div class="container">...</div>
```

### 2.3 Identify i18n Pattern

```jsx
// Angular i18n
<h1 i18n="@@app.title">Title</h1>

// Transloco
<h1>{{ 'app.title' | transloco }}</h1>

// i18next
<h1>{ t('app.title') }</h1>

// ngx-translate
<h1>{{ 'app.title' | translate }}</h1>

// Custom service
<h1>{{ titleLabel }}</h1> (with titleLabel = translate.get('app.title'))
```

### 2.4 Check for Breaking Changes

Verify:
- Component props/inputs remain unchanged
- Event outputs/emissions unchanged
- No changes to routing or navigation
- No changes to service calls
- No changes to state management integration

**If breaking changes detected: HALT and report.**

## Phase 3: Refactor Strategy

### 3.1 Identify Layout Changes

Compare Figma layout to existing:

```markdown
**EXISTING:**
<div class="card">
  <h1 class="title">{{ title }}</h1>
  <p class="description">{{ description }}</p>
</div>

**FIGMA:**
- Title and description in column layout with gap
- Title has larger padding

**CHANGES NEEDED:**
- Add gap between title and description ✓ (CSS only)
- Adjust title padding ✓ (CSS only)
- No markup changes required
```

### 3.2 Identify Styling-Only Changes

Mark opportunities for CSS/SCSS-only updates:

```css
/* EXISTING */
.card-header {
  display: flex;
  gap: 8px;
}

/* FIGMA (larger gap) */
.card-header {
  display: flex;
  gap: 16px; /* Changed from 8px → var(--spacing-md) */
}
```

### 3.3 Identify Markup Changes

If markup must change (minimal cases):

```html
<!-- EXISTING -->
<button class="btn">
  <span class="btn-icon"></span>
  <span class="btn-text">{{ label }}</span>
</button>

<!-- FIGMA (icon + text side-by-side with specific alignment) -->
<!-- Change needed: add wrapper for alignment control -->
<button class="btn">
  <span class="btn-content">
    <span class="btn-icon"></span>
    <span class="btn-text">{{ label }}</span>
  </span>
</button>
```

**Document:** Why each markup change is necessary.

### 3.4 Verify Functionality Preservation

Checklist:
- [ ] All @click/@ngClick/v-on:click handlers preserved
- [ ] All v-model/ngModel/two-way bindings preserved
- [ ] All *ngIf/@if/v-if conditionals preserved
- [ ] All *ngFor/@for/v-for loops preserved
- [ ] All pipe/filter transformations preserved
- [ ] All interpolations {{ }} preserved
- [ ] All data binding paths (obj.property) unchanged
- [ ] All directives/attributes preserved
- [ ] All i18n keys intact (not replaced with hardcoded text)

## Phase 4: Code Generation

### 4.1 Generate Markup

**For React/JSX:**

```jsx
export const CardComponent = ({ title, description, onAction }) => {
  return (
    <article className="card">
      <header className="card-header">
        <h1 className="card-title">{title}</h1>
      </header>
      <section className="card-content">
        <p className="card-description">{description}</p>
      </section>
      <footer className="card-footer">
        <button className="btn btn-primary" onClick={onAction}>
          {/* i18n preserved */}
        </button>
      </footer>
    </article>
  );
};
```

**For Vue 3:**

```vue
<template>
  <article class="card">
    <header class="card-header">
      <h1 class="card-title">{{ title }}</h1>
    </header>
    <section class="card-content">
      <p class="card-description">{{ description }}</p>
    </section>
    <footer class="card-footer">
      <button class="btn btn-primary" @click="onAction">
        {{ $t('app.action') }}
      </button>
    </footer>
  </article>
</template>
```

**For Angular:**

```html
<article class="card">
  <header class="card-header">
    <h1 class="card-title">{{ title }}</h1>
  </header>
  <section class="card-content">
    <p class="card-description">{{ description }}</p>
  </section>
  <footer class="card-footer">
    <button class="btn btn-primary" (click)="onAction()">
      {{ 'app.action' | transloco }}
    </button>
  </footer>
</article>
```

### 4.2 Generate Styling (CSS)

```css
/* Layout */
.card {
  display: flex;
  flex-direction: column;
  padding: var(--spacing-lg);
  gap: var(--spacing-md);
  border: 1px solid var(--color-border-light);
  border-radius: var(--radius-sm);
}

/* Typography & colors */
.card-title {
  font-size: var(--font-size-lg);
  font-weight: var(--font-weight-600);
  color: var(--color-text-primary);
  line-height: var(--line-height-heading);
}

.card-description {
  font-size: var(--font-size-base);
  color: var(--color-text-secondary);
  line-height: var(--line-height-body);
}

/* Button */
.btn {
  padding: var(--spacing-sm) var(--spacing-md);
  background-color: var(--color-action-primary);
  color: white;
  border: none;
  border-radius: var(--radius-sm);
  cursor: pointer;
}

.btn:hover {
  background-color: var(--color-action-primary-hover);
}

/* Responsive */
@media (max-width: 768px) {
  .card {
    padding: var(--spacing-md);
  }
}
```

### 4.3 Generate Styling (SCSS)

```scss
// Use SCSS variables or CSS variables
// Example with SCSS variables:

$spacing-lg: 24px;
$spacing-md: 16px;
$spacing-sm: 8px;
$color-primary: #1a1a1a;
$color-secondary: #666666;
$color-border: #eeeeee;
$radius-sm: 4px;

.card {
  display: flex;
  flex-direction: column;
  padding: $spacing-lg;
  gap: $spacing-md;
  border: 1px solid $color-border;
  border-radius: $radius-sm;

  // Nested selectors
  &-title {
    font-size: 20px;
    font-weight: 600;
    color: $color-primary;
  }

  &-description {
    font-size: 14px;
    color: $color-secondary;
  }

  @media (max-width: 768px) {
    padding: $spacing-md;
  }
}

.btn {
  padding: $spacing-sm $spacing-md;

  &-primary {
    background-color: #0066cc;

    &:hover {
      background-color: #0052a3;
    }
  }
}
```

### 4.4 Handle i18n

**If adding new translation keys:**

1. Define key following project convention:
   ```
   app.component.label
   app.component.description
   app.component.action
   ```

2. Update all locale files:
   ```json
   // en.json (or en/common.json, depending on structure)
   {
     "app": {
       "component": {
         "label": "Component Label",
         "description": "Component Description",
         "action": "Action Button Text"
       }
     }
   }

   // es.json
   {
     "app": {
       "component": {
         "label": "Etiqueta del Componente",
         "description": "Descripción del Componente",
         "action": "Texto del Botón de Acción"
       }
     }
   }

   // fr.json
   // ... and so on for all supported locales
   ```

3. Reference in markup:
   ```jsx
   // React + i18next
   <h1>{t('app.component.label')}</h1>

   // Vue + Transloco
   <h1>{{ 'app.component.label' | transloco }}</h1>

   // Angular + Transloco
   <h1>{{ 'app.component.label' | transloco }}</h1>
   ```

## Phase 5: Output Format

### Output A: Updated Markup

Provide full component code with:
- Framework-native syntax
- All original bindings and handlers
- i18n keys preserved or clearly mapped
- Comments for non-obvious changes

### Output B: Updated Styling

Provide full stylesheet with:
- Token-based values throughout (CSS or SCSS)
- Comments for complex layout rules
- Responsive breakpoints documented
- No hardcoded colors, sizes, or spacing

### Output C: Design-to-Code Mapping

```markdown
### Colors
| Figma | Project Token | CSS Variable | Applied to |
|---|---|---|---|
| #1a1a1a | text-primary | var(--color-text-primary) | .card-title, .card-label |
| #666666 | text-secondary | var(--color-text-secondary) | .card-description, .card-meta |
| #0066CC | action-primary | var(--color-action-primary) | .btn-primary |

### Typography
| Figma | Project Token | CSS Variable | Applied to |
|---|---|---|---|
| 20px, 600 weight | heading-lg | var(--font-heading-lg) | .card-title |
| 14px, 400 weight | body | var(--font-body) | .card-description |

### Spacing
| Figma | Project Token | CSS Variable | Applied to |
|---|---|---|---|
| 24px | spacing-lg | var(--spacing-lg) | .card padding |
| 16px | spacing-md | var(--spacing-md) | .card gap |
```

### Output D: i18n Mapping (if applicable)

```markdown
### New Translation Keys Added
- `app.component.label`: "Component Label" (used in heading)
- `app.component.description`: "Component Description" (used in body text)
- `app.component.action`: "Action Button Text" (used in button)

### Locale Files Updated
- `src/i18n/en.json`
- `src/i18n/es.json`
- `src/i18n/fr.json`
- `src/i18n/de.json`

### Key Mapping
| Figma Text | Translation Key | Notes |
|---|---|---|
| "Component Label" | app.component.label | New key; added to all locales |
| "Component Description" | app.component.description | New key; added to all locales |
```

### Output E: Structural Changes

```markdown
### New Wrappers Introduced
- `.card-content`: Added wrapper around description to manage flex layout
  - **Reason:** Figma design requires specific vertical gap between title and description without affecting footer

### Removed Elements
- None

### Modified Hierarchy
- Title: moved from direct child to card-header child
  - **Reason:** Figma design groups title with icon in header section
```

### Output F: Verification Checklist

```markdown
- [x] Layout matches Figma visually
  - Spacing, gaps, alignment verified
  - Responsive behavior tested at 1280px, 768px, 480px
- [x] All interactive elements functional
  - Button click handlers work
  - Form inputs bind correctly
- [x] i18n preserved
  - No hardcoded text; all using translation keys
  - All placeholders preserved
- [x] Accessibility maintained
  - ARIA labels intact
  - Semantic HTML used
  - Keyboard navigation works
- [x] Responsive breakpoints implemented
  - Mobile (< 768px): single column
  - Tablet (768px - 1024px): 2-column
  - Desktop (> 1024px): 3-column
- [x] All tokens used from design system
  - Colors: 100% from var(--color-*)
  - Spacing: 100% from var(--spacing-*)
  - Typography: 100% from var(--font-*)
- [x] No business logic changes
  - Services untouched
  - State management unchanged
  - API calls preserved
- [x] Framework conventions followed
  - React: component props, hooks used correctly
  - Vue: template syntax, reactivity preserved
  - Angular: dependency injection, lifecycle hooks intact
```

## Framework-Specific Guidelines

### React/JSX
- Use consistent component naming (PascalCase)
- Use className for styling
- Preserve prop types and TypeScript interfaces
- Use hooks (useState, useEffect) as already used in project
- Import i18n hook (useTranslation from i18next, etc.)
- Use fragment <> when appropriate
- Preserve ref usage if present

### Vue 3
- Use Composition API if project uses it, Options API otherwise
- Use scoped styles by default
- Preserve reactive(), ref(), computed() as used
- Use v-bind for dynamic attributes
- Preserve slot definitions
- Use Teleport if modals present
- Import i18n composable correctly

### Angular (17+)
- Use control-flow syntax (@if, @for, @switch) if project standard
- Use OnPush change detection if already applied
- Inject services correctly (constructor or inject())
- Preserve lifecycle hooks
- Use trackBy in @for loops
- Preserve async pipe usage
- Import transloco/i18next/ngx-translate module

### Svelte
- Use reactive declarations ({#if}, {#each}, {#await})
- Use stores (writable, readable) as project pattern
- Preserve component events (dispatch)
- Use Svelte scoped styles
- Bind directives correctly (bind:value, bind:checked)
- Animation/transition directives preserved

## Common Patterns

### Design Token Variables

**CSS:**
```css
:root {
  --color-primary: #0066cc;
  --color-primary-hover: #0052a3;
  --spacing-xs: 4px;
  --spacing-sm: 8px;
  --spacing-md: 16px;
  --spacing-lg: 24px;
  --font-size-sm: 12px;
  --font-size-base: 14px;
  --font-size-lg: 20px;
  --font-weight-400: 400;
  --font-weight-600: 600;
}
```

**SCSS:**
```scss
// _tokens.scss
$color-primary: #0066cc;
$color-primary-hover: #0052a3;
$spacing-xs: 4px;
$spacing-sm: 8px;
$spacing-md: 16px;
$spacing-lg: 24px;
$font-size-sm: 12px;
$font-size-base: 14px;
$font-size-lg: 20px;
```

### Flexbox Layouts

```css
/* Horizontal center */
display: flex;
align-items: center;
justify-content: center;

/* Vertical center */
display: flex;
flex-direction: column;
align-items: center;
justify-content: center;

/* Space-between */
display: flex;
justify-content: space-between;
align-items: center;
```

### CSS Grid Layouts

```css
/* 3-column responsive grid */
display: grid;
grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
gap: var(--spacing-md);

@media (max-width: 768px) {
  grid-template-columns: 1fr;
}
```

### i18n Patterns

```jsx
// React + i18next
import { useTranslation } from 'react-i18next';

function MyComponent() {
  const { t } = useTranslation();
  return <h1>{t('app.title')}</h1>;
}

// Angular + Transloco
import { TranslocoService } from '@ngneat/transloco';

export class MyComponent {
  constructor(private transloco: TranslocoService) {}

  // In template:
  // <h1>{{ 'app.title' | transloco }}</h1>
}

// Vue + i18next
import { useI18n } from 'vue-i18n';

export default {
  setup() {
    const { t } = useI18n();
    return { t };
  }
  // In template:
  // <h1>{{ t('app.title') }}</h1>
}
```

## Troubleshooting

### Problem: Figma value has no matching token
**Solution:** Use closest token and document as UNMAPPED. Propose new token if variance is significant.

### Problem: Component has conflicting styles
**Solution:** Check for !important overrides, scoping issues. Verify token mapping. Consider specificity.

### Problem: i18n keys don't match between locales
**Solution:** Audit all locale files. Regenerate missing keys from template locale (usually English).

### Problem: Markup changes break functionality
**Solution:** Revert markup changes. Use CSS-only approach. If impossible, add wrapper sparingly.

### Problem: No design tokens defined
**Solution:** Extract values from Figma, create token system in project. Propose to design team.

## Sign-Off

Before marking handoff complete:

1. ✅ Code reviewed for markup/styling correctness
2. ✅ All Figma specs matched visually
3. ✅ i18n verified (no hardcoded text)
4. ✅ Functionality tested (bindings, events, state)
5. ✅ Accessibility verified (ARIA, semantic HTML)
6. ✅ Performance checked (no unnecessary renders/reflows)
7. ✅ Browser compatibility checked
8. ✅ Responsive behavior tested

**Handoff complete.** Code is ready for integration.
