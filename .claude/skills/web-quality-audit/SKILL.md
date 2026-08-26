---
name: web-quality-audit
description: Comprehensive web quality audit covering performance, accessibility, SEO, and best practices. Use when asked to "audit my site", "review web quality", "run lighthouse audit", "check page quality", or "optimize my website".
license: MIT
metadata:
  author: web-quality-skills
  version: "1.0"
---

# Web quality audit

Comprehensive quality review based on Google Lighthouse's four pillars. Composes the dedicated skills for each pillar, then synthesizes their findings into one prioritized report.

## How it works

1. Call the Skill tool for each pillar in turn: "performance", "core-web-vitals", "accessibility", "seo". Each returns findings for its area.
2. Merge all findings, categorize by severity (Critical, High, Medium, Low) using the table below.
3. Provide specific, actionable recommendations with code examples for fixes.
4. Structure the combined output per the format below — don't just concatenate each skill's raw output.

Rough weight when prioritizing: Performance ~40% of typical issues, Accessibility ~30%, SEO ~15%, other best practices (security, modern standards, UX patterns — not covered by the composed skills, assess directly) ~15%.

## Severity levels

| Level | Description | Action |
|-------|-------------|--------|
| **Critical** | Security vulnerabilities, complete failures | Fix immediately |
| **High** | Core Web Vitals failures, major a11y barriers | Fix before launch |
| **Medium** | Performance opportunities, SEO improvements | Fix within sprint |
| **Low** | Minor optimizations, code quality | Fix when convenient |

## Audit output format

When performing an audit, structure findings as:

```markdown
## Audit results

### Critical issues (X found)
- **[Category]** Issue description. File: `path/to/file.js:123`
  - **Impact:** Why this matters
  - **Fix:** Specific code change or recommendation

### High priority (X found)
...

### Summary
- Performance: X issues (Y critical)
- Accessibility: X issues (Y critical)
- SEO: X issues
- Best Practices: X issues

### Recommended priority
1. First fix this because...
2. Then address...
3. Finally optimize...
```

## Quick checklist

### Before every deploy
- [ ] Core Web Vitals passing
- [ ] No accessibility errors (axe/Lighthouse)
- [ ] No console errors
- [ ] HTTPS working
- [ ] Meta tags present

### Weekly review
- [ ] Check Search Console for issues
- [ ] Review Core Web Vitals trends
- [ ] Update dependencies
- [ ] Test with screen reader

### Monthly deep dive
- [ ] Full Lighthouse audit
- [ ] Performance profiling
- [ ] Accessibility audit with real users
- [ ] SEO keyword review

## Composed skills

- [Performance Optimization](../performance/SKILL.md)
- [Core Web Vitals](../core-web-vitals/SKILL.md)
- [Accessibility](../accessibility/SKILL.md)
- [SEO](../seo/SKILL.md)
