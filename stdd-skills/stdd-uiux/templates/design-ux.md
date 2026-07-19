---
change: example-user-dashboard
type: design-ux
language: en
---

# Design UX — example-user-dashboard

This is a worked example only — copy the STRUCTURE, not the content, into a
real change's `STDD/<name>/design-ux.md`. Every section cites the `REQ-ID`(s)
it supports; a section that doesn't apply to this change is marked `N/A`
rather than omitted.

## Requirements checklist

Derived in Step 2 (before design-reference gathering), checked off in Step 7
(before requesting approval). List every item; never silently drop an unmet
one.

- [x] Dashboard shows the user's active subscriptions (REQ-01)
- [x] Empty state defined for zero-subscription accounts (REQ-01)
- [ ] Bulk-export button — deferred to a later change, noted here so it isn't
      silently forgotten (REQ-02)

## MASTER

Global rules that apply across every page/flow in this change. If a project
canonical design guideline already exists (`wiki/design_guideline/`), this
section becomes "cite guideline + record only this change's delta" instead
of the full text below.

### User flows (REQ-01, REQ-02)

```mermaid
flowchart TD
    A[Landing page] --> B{Logged in?}
    B -- No --> C[Login form]
    C --> D[Submit credentials]
    D -- Failure --> C
    D -- Success --> E[Dashboard]
    B -- Yes --> E
    E --> F[View subscription list]
    F --> G{Any subscriptions?}
    G -- No --> H[Empty state: "No active subscriptions yet"]
    G -- Yes --> I[Subscription cards]
```

> Banned Mermaid constructs for this diagram type: single source of truth is
> `stdd-lint`'s `references/checklist.md` — not restated here. Plain
> `flowchart`/`graph` syntax only.

### Information architecture (REQ-01)

- Dashboard (top level)
  - Subscription list
    - Subscription card (per item)
  - Account settings (N/A for this change — no changes here)

### Layout (REQ-01)

| Region | Content | Notes |
|---|---|---|
| Header | Logo, user menu | Sticky on scroll |
| Main | Subscription cards, grid on desktop / stack on mobile | See breakpoints below |
| Empty state | Illustration + CTA | Only when card list is empty |

### Component hierarchy (REQ-01)

- `DashboardPage`
  - `SubscriptionList`
    - `SubscriptionCard` (× N)
    - `EmptyState` (shown instead of the list when N = 0)

### Design tokens (REQ-01)

| Token | Value | Usage |
|---|---|---|
| `color.brand.primary` | `#3A5BA0` | Primary CTA background |
| `color.surface.default` | `#FFFFFF` | Card background |
| `color.text.muted` | `#6B7280` | Empty-state caption |
| `space.card-gap` | `16px` | Gap between subscription cards |
| `type.heading-1` | `24px / 32px, semibold` | Page title |

### States (REQ-01)

- **Empty**: illustration + "No active subscriptions yet" + a CTA to browse
  plans.
- **Error**: inline banner above the list, "Couldn't load subscriptions,
  retry" with a retry button; never a silent blank screen.
- **Loading**: skeleton cards matching the `SubscriptionCard` layout, not a
  generic spinner.

## Override — Subscription list page (REQ-01)

Only the deltas from MASTER for this specific page; anything not listed here
inherits MASTER as-is.

- Mobile breakpoint (<640px): cards stack single-column, `space.card-gap`
  reduces to `12px`.

## Override — Login form (N/A)

N/A — this change does not touch the login flow; listed explicitly rather
than omitted so a reader knows it was considered.
