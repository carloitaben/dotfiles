---
description: Perform a conceptual architecture audit of a TypeScript repo (packages, layers, systems, interactions)
agent: build
subtask: true
---

You are performing a **TypeScript repository architecture audit** focused on systems, layers, package topology, and interaction design.

This command is conceptual and architectural.  
It is NOT a feature review, PRD, or refactor proposal.

Assume the repository is already cloned in the current workspace.

Your task is to analyze the repo and write a structured architecture report to:.

/docs/architecture/audit.md

If the directory does not exist, create it.

---

# OBJECTIVES

- Map the monorepo or package topology
- Identify architectural layers and dependency directions
- Extract major systems and their responsibilities
- Explain how systems interact
- Infer why separations exist (clearly label inferences)
- Produce a durable architectural mental model

Ground all claims in observable evidence:
- folder structure
- package.json
- exports maps
- entrypoints
- dependency relationships
- runtime bootstrapping code

Do NOT:
- Summarize the README unless it clarifies runtime topology
- Propose large refactors unless a boundary is clearly broken
- Speculate without evidence (label inferences clearly)

---

# REQUIRED PROCESS (Follow In Order)

## 1) Repository Topology

Identify:

- Repo type (monorepo or single package)
- Workspace tooling (pnpm/yarn/npm/turbo/nx/lerna if present)
- Build tooling (tsc/tsup/rollup/vite/webpack/etc.)
- Published packages (if any)
- Entry points (server, CLI, worker, UI bootstrap)
- Package export surfaces (`exports` maps, index files, barrels)

Produce a package graph summary:
- For each internal package:
  - Purpose
  - Depends on
  - Used by
  - Public API surface

Highlight which packages appear to be:
- Core/domain
- Adapters
- Framework bindings
- UI/admin
- Tooling
- Utilities

---

## 2) Layer Model (Conceptual)

Infer and describe architectural layers such as:

- Core engine/domain
- Type system/schema
- Runtime services
- Adapters 
- Framework integrations
- UI/admin
- Tooling/CLI

For each layer:
- Responsibility
- What it is allowed to depend on
- What must not depend on it

Clearly state the intended dependency direction.

---

## 3) System Catalog

Identify major systems. For each system, provide:

- Responsibility
- Key directories/modules
- Main abstractions (interfaces/types/classes)
- Extension points (hooks, plugins, registries)
- Where configuration enters
- Runtime lifecycle (if applicable)

Typical system categories (only include if present):

- Configuration & bootstrapping
- Schema/content model
- Database/query layer
- Authentication & access control
- Validation/sanitization
- Upload/storage
- Admin/UI layer
- Background jobs/queues
- Migrations
- Plugin system
- Logging/telemetry
- Build/release tooling

---

## 4) Interaction Map

Describe:

### Runtime Topology
- Server runtime
- CLI runtime
- Worker runtime
- Admin/UI runtime
(only if applicable)

### Canonical Interaction Stories (Architectural, Not Product-Level)

Provide 2–4 interaction narratives such as:

- Config bootstraps core → core wires services → adapters injected
- UI → API → core services → DB adapter
- Plugin registers hooks → hook pipeline wraps core operations

Focus on system-to-system boundaries.

---

## 5) Separation Quality & Rationale

Assess architecture quality:

- Clean separations
- Strong seams (good extension points)
- Cross-cutting concerns
- Coupling hotspots
- Leaky abstractions

For inferred rationale, use this format:

Inference:
Evidence:
Confidence: High / Medium / Low

---

# OUTPUT FORMAT (STRICT)

Write the markdown file with the following structure:

# TypeScript Architecture Audit

## Snapshot
- Repo type:
- Workspace tool:
- Build tooling:
- Published packages:
- Runtimes:

## Package / Module Topology

### Internal Packages
- <package-name>:
  - Purpose:
  - Depends on:
  - Used by:
  - Public API:

### Dependency Graph Summary
- Core:
- Adapters:
- UI:
- Tooling:

## Layer Model
- Layer 1:
- Layer 2:
- Layer 3:

Dependency Direction Rules:
- X may depend on Y
- Y must NOT depend on X

## System Catalog

### <System Name>
- Responsibility:
- Key locations:
- Main abstractions:
- Extension points:
- Lifecycle:

(repeat per system)

## Interaction Map

### Runtime Topology

### Canonical Interaction Stories
1)
2)
3)

## Separation & Architectural Rationale
- Clean seams:
- Coupling hotspots:
- Cross-cutting concerns:

Inferred Rationale:
- Inference:
  - Evidence:
  - Confidence:

## Mental Model Summary
- If you change X, you likely touch:
- If you extend Y, start at:
- Safe extension seams:
- Risky areas:

## Open Questions / Unknowns

---

End the report with:

"Would you like this converted into a Mermaid diagram?"
