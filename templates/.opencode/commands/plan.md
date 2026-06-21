---
agent: plan
description: Use this command to create an implementation plan
---

# PLANNING

## Input

$ARGUMENTS

## Context

- You MUST read all references explicitly provided in the input.

## Objective

Start by running `explore` sub-agents to create a structured map of the project's architecture, components, and existing mechanisms.

Produce an execution-ready implementation plan:

1. A dependency-ordered list of implementation steps (actionable, scoped).
2. A human-readable plan summary with dependency chains + rationale.

## Strict Rules

### Planning Boundaries

- Use `explore` sub-agents for broad research or web investigations.
- Reuse existing architecture/mechanisms.
- Avoid redesigning systems unless strictly necessary and justified by current codebase constraints.
- Introduce new abstractions ONLY IF explicitly required by the scope and justified by the sources.

### Source Grounding

- Every step MUST be grounded in provided sources (`AGENTS.md` + referenced docs/code); no speculation.
- Assumptions MUST be explicit and minimal; prefer "Missing Context" over guessing.
- If any required context/reference is missing or inaccessible, REPORT "Missing Context" in the output and HALT — do not produce implementation steps.

## Output Format

```markdown
### Missing Context
- *List missing items here*

---

### Problem Statement

*State the problem in your own words*
*List of assumptions made (if any)*

### Implementation Steps

#### Step: S1

Title: Short, specific title
Intent: Implementation intent (what will be built/changed)
Affected Area: Domain / system / repo area impacted
Dependencies: Step IDs and/or external prerequisites

In Scope:
- *explicit bullets*

Out of Scope:
- *explicit bullets*

Acceptance Criteria:
- *explicit bullets*

Implementation Notes
- *Include file pointers if strongly supported by sources*
- *If file targets are uncertain, state that explicitly*

Source Trace
*Cite the exact references that justify this step; include paths/links/sections*

---

### Plan Summary

#### Dependency Chains

*Structured list of each dependency chain with step IDs, titles, relationships and rationale*
```
