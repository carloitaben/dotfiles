---
name: motion-css-animation-audit
description: Audit every Motion & CSS animation, classify performance, generate report with improvements. Use when asked to "audit animations", "animation performance", "motion performance report", "CSS animation audit", or "motion audit".
license: MIT
---

# Motion & CSS animation audit

Inventory all motion, classify performance risk, and produce a prioritized report with concrete fixes.

## How it works

1. Inventory every animation and transition
2. Classify each by performance tier and risk
3. Collect evidence (trace + visual checks)
4. Produce report with fixes and priorities

## Audit inputs

- CSS transitions and keyframe animations
- JS-driven animations (requestAnimationFrame, setInterval)
- Web Animations API usage
- Motion library usage (Motion One, Motion-based wrappers)
- Scroll-tied, hover, and continuous ambient motion

## Render pipeline basics

The browser renders in order: **style -> layout -> paint -> composite**. Triggering a step triggers all later steps. Composite-only work is cheapest; layout is most expensive.

Main thread work can block layout/paint/composite. Compositor-thread animations can stay smooth even when main thread is busy.

## Performance tiers

Use these tiers to classify techniques and set priority:

| Tier | Definition                         | Typical techniques                                                     |
| ---- | ---------------------------------- | ---------------------------------------------------------------------- |
| S    | Compositor-thread animations       | CSS/WAAPI transform/opacity/clip-path/filter when compositor supported |
| A    | Main-thread driven, composite-only | rAF/JS animation of transform/opacity on promoted layers               |
| B    | A/S with upfront measurements      | FLIP/layout animations with batched reads/writes                       |
| C    | Paint-triggering                   | background-color, border-radius, gradients, masks                      |
| D    | Layout-triggering                  | width/height/top/left/margin/grid/flex changes                         |
| F    | Thrash                             | read/write/read loops, sync layout each frame                          |

## Inventory workflow

Capture each animation in a single row:

| Field        | Details                              |
| ------------ | ------------------------------------ |
| Animation ID | Stable, human-readable identifier    |
| Location     | File + selector or component         |
| Trigger      | Interaction, lifecycle, scroll, loop |
| Properties   | Animated CSS properties              |
| Duration     | ms + easing                          |
| Iterations   | Once, N, infinite                    |
| API          | CSS, WAAPI, JS, Motion               |
| Context      | Above-fold, list, modal, hero        |

## Classification rubric

| Property group                    | Tier | Risk     | Symptoms                    | Typical fixes                          |
| --------------------------------- | ---- | -------- | --------------------------- | -------------------------------------- |
| transform, opacity                | S/A  | Low      | Smooth, stable              | Keep, ensure layer, avoid layout reads |
| filter, clip-path, box-shadow     | C    | Medium   | Jank on hover/scroll        | Reduce area, simplify, isolate layer   |
| background-color, gradients, mask | C    | Medium   | Paint spikes                | Reduce repaint area                    |
| width, height, top, left, margin  | D    | High     | Reflow, CLS, INP regress    | Use transform, reserve space           |
| scrollTop-read loops              | D/F  | High     | Frame drops, delayed scroll | Use ScrollTimeline/IO                  |
| read/write thrash                 | F    | Critical | Long tasks, stutter         | Batch reads/writes                     |

## Evidence collection

- DevTools Performance: long tasks, frame drops, style/layout costs
- Rendering tools: FPS meter, paint flashing, layout shift regions
- Layers panel: compositor layers and promotion
- Repro steps: slow device, throttled CPU

## Report template

| ID            | Location             | Trigger | Properties | Duration   | Risk   | Evidence            | Fix                              | Priority |
| ------------- | -------------------- | ------- | ---------- | ---------- | ------ | ------------------- | -------------------------------- | -------- |
| anim-hero-cta | src/ui/Hero.tsx .cta | hover   | box-shadow | 200ms ease | Medium | 12ms paint on hover | Replace with transform + opacity | P2       |

## Improvements playbook

### Prefer compositor-friendly properties

```css
/* ❌ Layout + paint */
.card {
  transition:
    width 200ms,
    box-shadow 200ms;
}

/* ✅ Compositor */
.card {
  transition:
    transform 200ms,
    opacity 200ms;
}
```

### Prefer compositor scroll animations

Avoid `scrollTop` loops. Prefer ScrollTimeline/ViewTimeline or IntersectionObserver-triggered animations.

### Avoid layout thrash in JS

```javascript
// ❌ Interleaved reads/writes
el.style.width = el.offsetWidth + 10 + "px";

// ✅ Batch reads, then writes
const width = el.offsetWidth;
el.style.transform = `scale(${(width + 10) / width})`;
```

### Reduce paint area

```css
/* ✅ Limit paint scope */
.card {
  contain: paint;
}
```

### Use will-change sparingly

```css
/* ✅ Apply briefly during interaction only */
.menu.is-animating {
  will-change: transform;
}
```

### Avoid CSS variable inheritance bombs

```css
/* ❌ Global var invalidates large trees */
html {
  --progress: 0;
}

/* ✅ Scope close to usage */
.section {
  --progress: 0;
}

/* ✅ Prefer non-inherited variables */
@property --progress {
  syntax: "";
  inherits: false;
  initial-value: 0;
}
```

### Honor prefers-reduced-motion

```css
@media (prefers-reduced-motion: reduce) {
  * {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}
```

## Checklists

### Audit checklist

```markdown
- [ ] Every animation and transition inventoried
- [ ] Property groups classified by risk tier
- [ ] Traces captured for high-risk items
- [ ] CLS/INP impact noted where relevant
- [ ] Accessibility motion settings verified
```

### Remediation checklist

```markdown
- [ ] Layout properties replaced with transform/opacity
- [ ] Paint-heavy effects reduced or isolated
- [ ] Scroll-tied animations throttled or simplified
- [ ] Motion reduced mode tested
- [ ] Before/after traces captured
```

## Measurement

- Record Performance traces for each high-risk animation
- Validate CLS/INP changes with Web Vitals tracking
- Compare before/after FPS and long task counts
