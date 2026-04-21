---
name: explain-code
description: Write technical documentation with a styleguide. Use when the user asks to write a Markdown documentation file with their styleguide.
---

# Documentation Style Guide

## Tone & Voice

- **Direct & Conversational**: Use "you" throughout, speak directly to the developer
- **Terse**: Short, direct sentences with minimal words
- **Action-oriented**: Imperative verbs, instructional focus
- **No fluff**: Eliminate conversational filler and elaborate introductions
- **Practical**: Emphasize "how to do" over theoretical explanations
- **Code-heavy**: Shows examples instead of just describing
- **Clear structure**: Headers, lists, and tables for scannability
- **Context-first**: Explain "why you'd use it" before "how to do it"

## Opening Style

Start immediately with the topic. No "Welcome to…" intros.

```
# Forms

This chapter helps you build accessible forms.
```

```
# Styling

This chapter helps you apply consistent styling patterns.
```

Or start with a direct statement:

```
# Modules

This chapter covers modules, which are self-contained UI blocks…
```

## Content Organization

### Section Structure

1. **Clear, descriptive titles**
2. **Brief intro** (2-3 sentences max)
3. **Sections with clear headings**
4. **Bullet points or tables for lists**
5. **Code examples with minimal explanation**
6. **Tips only when essential**

### Problem/Solution Pattern

Use this structure for explaining concepts:

```
### The Problem

Component libraries usually hardcode their elements:

```

// code example

```

This works fine until you need:

- Point 1
- Point 2
- Point 3

### The Solution

Polymorphism separates **behavior** from **rendering**…

```

// solution code

```

```

## Code Examples

### Code Blocks

Use triple backticks **without language hints**:

✅ Good:

```
function Button() {
  return <button>Click</button>
}
```

🚫 Bad:

```tsx
function Button() {
  return <button>Click</button>;
}
```

### File Paths

Include file paths in comments when helpful:

```
// src/components/Button.tsx

function Button() {}
```

```
// @/components/Button.tsx

function Button() {}
```

### Imports

Show imports as separate blocks when relevant:

```
// src/components/LoginForm.tsx

import { z } from "zod"
import FieldCheckbox from "@/components/FieldCheckbox"
import FieldInput from "@/components/FieldInput"
```

## Voice & Address Patterns

### Direct Address Style

Always use "you" when speaking to the reader. Frame explanations around reader needs.

**Before (Impersonal):**

> "Typography plugin generates flexible `text-*` classes that combine multiple utilities"

**After (Direct & Contextual):**

> "You can use our typography classes when you need complete text styling. These classes combine everything you need into one simple class."

**Before (Dry):**

> "Control animation properties:"

**After (Conversational):**

> "You can also control how long animations take:"

### Sentence Structure

- Use imperative verbs: "Install…", "Run…", "Use…"
- Address reader directly: "You can install…", "You'll need to…"
- Avoid passive voice: "This is used by…" → "You can use…"
- Keep sentences under 15 words when possible
- Be direct: "This does X" not "This is designed to do X"

### Content Flow Pattern

1. **Context first**: "When you need X…"
2. **Solution**: "You can use Y…"
3. **Example**: Show practical code
4. **Variations**: "You can also…"

## Tips and Indicators

### Tips

Use 💡 for helpful tips sparingly. Keep them short and actionable.

```
> 💡 Extract common schemas into `src/lib/schemas.ts`. Prefix them with `FormField` for consistency.
```

### Good/Bad Practices

Use ✅/🚫 for good/bad practices:

```
✅ Good:
```

// example

```

🚫 Bad:
```

// example

```

```

## Tables

Use tables for organized information:

```
| When you need… | Use asChild with… |
|------------------|---------------------|
| Navigation | `<a>` or `<Link>` from your router |
| Form submission | `<button type="submit">` |
```

## Lists

Use bullet points for:

- Feature lists
- Options
- Requirements

Use numbered lists for:

- Step-by-step instructions
- Ordered processes

## Examples of Style Changes

### Before (Verbose)

> "In this section, we're going to explore the fascinating world of data sources. You'll learn how these powerful mechanisms allow you to seamlessly transition between mock and real data, which is incredibly useful for development workflows."

### After (Terse)

> "Data sources determine whether requests use mock data, real API data, or both. This lets you start development before the backend exists."

### Before (Impersonal)

> "Typography plugin generates flexible `text-*` classes that combine multiple utilities"

### After (Direct & Contextual)

> "You can use our typography classes when you need complete text styling. These classes combine everything you need into one simple class."

### Before (Passive)

> "The fetch function is enhanced with additional capabilities that allow it to intercept requests."

### After (Active & Personal)

> "The custom fetch wrapper intercepts requests and resolves mock data when configured."

## Key Principles

1. **Start with context**: Explain what it is before how to use it
2. **Show, don't tell**: Code examples over lengthy explanations
3. **Be scannable**: Headers, lists, and tables break up content
4. **Stay practical**: Focus on real-world usage
5. **Keep it brief**: Every word should earn its place
