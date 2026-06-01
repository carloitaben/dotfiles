# Skill: Next.js Bundle Analysis

Analyze Next.js build diagnostics to find client-side bundle size reduction opportunities.

---

## Environment Setup

```
<app-dir>/
├── .next/
│   ├── diagnostics/
│   │   ├── route-bundle-stats.json   # route first-load sizes
│   │   ├── build-diagnostics.json    # build stage + options
│   │   ├── framework.json            # Next.js version
│   │   └── analyze/                  # Bundle Analyzer UI
│   │       ├── data/modules.data     # binary module data
│   │       └── data/routes.json      # route entries
│   ├── static/chunks/                # actual JS files (no source maps)
│   └── build-manifest.json           # rootMainFiles, polyfillFiles
└── src/
```

Requires a local production build — `.next/` is gitignored.

**Note:** `firstLoadUncompressedJsBytes` is uncompressed. Actual gzip/brotli transfer is ~3–4x smaller.

---

## Step 0: Locate the App Directory

```bash
APP_DIR=$(find . -name ".next" -maxdepth 4 -type d | head -1 | xargs dirname)
echo $APP_DIR
```

All subsequent steps use `$APP_DIR` in place of a hardcoded path.

---

## Step 1: Rank Routes by First-Load Size

```bash
grep -E '"route"|"firstLoadUncompressedJsBytes"' $APP_DIR/.next/diagnostics/route-bundle-stats.json \
  | paste - - \
  | sort -t: -k4 -rn \
  | head -40
```

Look for the spread between lightweight routes (e.g., `/_not-found`, API routes) and content routes. A large uniform jump across all content routes signals a shared-chunk problem.

**Red flag pattern:**
- `<minimal-route>` (e.g. 404, API route): small size, few chunks
- Every content route: much larger, many more chunks — same N extra chunks everywhere

---

## Step 2: Identify What's in the Shared Chunks

Find what chunks a minimal route loads vs. a content route:

```python
import json

with open(".next/diagnostics/route-bundle-stats.json") as f:
    data = json.load(f)

routes = {r["route"]: set(r["firstLoadChunkPaths"]) for r in data}
baseline = routes["<minimal-route>"]   # e.g. "/_not-found"
content  = routes["<content-route>"]   # e.g. a typical page

extra = content - baseline
print(sorted(extra))
```

Then rank the extra chunks by size:

```bash
ls -lh $APP_DIR/.next/static/chunks/ | sort -k5 -rh | head -30
```

---

## Step 3: Grep Chunks for Known Library Signatures

No source maps in production → grep for known strings in chunk files.

```bash
cd $APP_DIR/.next/static/chunks

# Find which chunk contains a library
grep -rl "framer-motion\|use-animation-frame" . | head
grep -rl "embla" .
grep -rl "split-type\|SplitType" .
grep -rl "motion" . | head

# Check how many chunks contain a library
grep -l "framer-motion" *.js | wc -l
```

These are common heavy libraries — adapt to whatever's in your `package.json`.

---

## Step 4: Find Dynamic Import Patterns

Variable-string dynamic imports cause Turbopack to bundle the entire directory.

```bash
# Find all dynamic imports
grep -rn "import(" $APP_DIR/src --include="*.tsx" --include="*.ts" | grep -v "node_modules"

# Specifically look for variable-string imports (the bad pattern)
grep -rn 'import(`' $APP_DIR/src --include="*.tsx" --include="*.ts"
```

**Bad (bundles entire directory):**
```ts
import(`@/modules/${name}`)  // variable string
```

**Good (Turbopack can code-split):**
```ts
import("@/modules/Hero")     // static string literal
```

---

## Step 5: Audit `"use client"` Components

Client components in the root layout (or anything it imports) are in the critical bundle.

```bash
# List all client components
grep -rn '"use client"' $APP_DIR/src --include="*.tsx" -l

# Check root layout imports
cat $APP_DIR/src/app/layout.tsx
```

For each client component ask:
1. Is it imported in the root layout (or something the layout imports)?
2. Is it wrapped in `next/dynamic` or `<ClientOnly>`?
3. Does it use a heavy library (`framer-motion`, `gsap`, etc.)?

---

## Step 6: Check Library Import Patterns

Prefer subpath imports (`pkg/core`, `pkg/react`) over root imports where the package's `exports` field supports it — this enables better tree-shaking.

```bash
# Check what subpath exports a package offers
# With opensrc (personal CLI):
ls $(opensrc path <pkg>)/dist
# Or directly:
cat node_modules/<pkg>/package.json | python3 -m json.tool | grep -A20 '"exports"'

# Example: motion imports — subpaths are better
grep -rn "from 'motion\|from \"motion" $APP_DIR/src --include="*.tsx" --include="*.ts"

# Example: use-intl — prefer subpath imports where possible
grep -rn "from 'use-intl'" $APP_DIR/src --include="*.ts" --include="*.tsx"
# Better: from 'use-intl/core' where possible
```

---

## Step 7: Check Framework Baseline

```bash
cat $APP_DIR/.next/build-manifest.json | python3 -m json.tool | grep -A20 '"rootMainFiles"'
```

Lists the JS files every route loads before any app code. Useful for understanding the irreducible baseline.

---

## Common Quick Wins (Ranked by Impact)

1. **Variable-string dynamic imports** — convert `import(\`@/modules/${name}\`)` to a static switch/map of literal imports. This is the highest-impact fix when many modules are bundled into every route.

2. **Heavy client components in root layout** — wrap with `next/dynamic({ ssr: false })`:
   - Animation backgrounds
   - Toast/notification systems
   - Modals loaded at startup
   - Analytics SDKs

3. **Library subpath imports** — use `pkg/core` or `pkg/react` instead of root `pkg` where available.

4. **DevTools in `dependencies`** — move to `devDependencies` so bundlers can exclude them.

5. **Module-level imports that should be lazy** — libraries only needed after interaction (e.g., rich text editors, chart libs).

---

**Note:** Server components (no `"use client"`) using heavy libs do NOT contribute to the client bundle.
