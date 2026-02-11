---
description: Trace an architectural flow through the TypeScript repo
agent: build
subtask: true
---

You are tracing a specific architectural flow through this TypeScript repository.

Flow to trace:
$ARGUMENTS

If no flow is provided, stop and ask the user to provide one.

Examples of valid flows:
- "Server startup"
- "API request lifecycle"
- "User authentication"
- "Plugin registration"
- "Database write path"
- "Admin UI data fetch"
- "Background job execution"

Your task is to follow this flow end-to-end across:
- Entry points
- System boundaries
- Key abstractions
- Dependency transitions
- Runtime wiring

Do not summarize product behavior.
Focus strictly on architectural and system-level interactions.

Write the output to:

/docs/architecture/flow-$1.md

If the directory does not exist, create it.

---

# REQUIRED PROCESS

## 1) Identify Entry Point

- Where does this flow begin?
- What file/module triggers it?
- Is it runtime boot, HTTP request, CLI invocation, plugin load, etc.?

List exact file paths.

---

## 2) Trace Call Chain

Follow the execution path:

- Which modules are called?
- Which services are constructed?
- Where are interfaces crossed?
- Where are adapters invoked?
- Where does configuration enter?

Document the sequence in order.

---

## 3) System Boundary Transitions

For each transition, identify:

- System A →
- System B →
- Interface or abstraction used →
- Why this boundary exists (if inferable)
- Whether dependency direction is respected

---

## 4) Data & Control Flow

Explain:

- What data shape enters the system
- How it transforms
- Where validation occurs
- Where side effects happen
- Where persistence happens (if applicable)

---

## 5) Extension & Hook Points

Identify:

- Hooks
- Plugin interceptors
- Middleware
- Event emitters
- Injection points

Explain how a developer could extend this flow safely.

---

## 6) Coupling & Risk Analysis

Highlight:

- Tight coupling points
- Global state usage
- Cross-layer leakage
- Hidden assumptions

Label speculative conclusions clearly.

---

# OUTPUT FORMAT (STRICT)

# Flow Trace: $ARGUMENTS

## Entry Point
- File:
- Trigger type:
- Runtime:

## Step-by-Step Execution Trace

1) Module:
   - Responsibility:
   - Calls into:
   - Notes:

(repeat for each major step)

## System Transitions

- System A → System B
  - Interface:
  - Boundary quality:
  - Dependency direction valid? (yes/no)

(repeat)

## Data & Control Flow
- Input shape:
- Transformations:
- Validation:
- Side effects:
- Persistence:

## Extension Points
- Hook:
- Location:
- Purpose:
- Safe to extend? (yes/no/with care)

## Architectural Observations
- Clean seams:
- Leaky seams:
- Coupling hotspots:

## Mental Model Summary
- Core spine of this flow:
- Where to modify behavior safely:
- Where not to modify without deep review:

---

End the report with:

"Would you like a Mermaid sequence diagram of this flow?"
