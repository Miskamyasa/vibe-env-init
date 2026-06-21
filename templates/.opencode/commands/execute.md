---
agent: lead
description: Use this command to coordinate implementation through the lead agent.
---

# EXECUTION

## Additional Input

$ARGUMENTS

## Objective

Execute the implementation steps via sub-agents.

For each step in the plan:
1. Generate a self-contained implementation-only prompt for the step, including all necessary context and references for implementation.
2. Run the implementation sub-agent with the generated prompt.
3. Halt/skip/remediate correctly on failures (per rules below).
4. Aggregate results with full traceability to the original plan.

## Global Execution Rules

- Prefer parallel execution of independent steps, but do NOT execute any step before all its dependencies have succeeded.
- Sub-agents MAY read additional repository files as needed to implement, BUT they MUST implement ONLY what their prompt objective requests.
- If a step is `failed` or `blocked` for reasons resolvable by repository changes, do NOT execute downstream dependents. Add intermediate remediation steps (e.g., `S1.1`, `S1.2`) and resume from the original failed/blocked step after remediation succeeds.
- Each inserted remediation step MUST declare: (a) parent step ID, (b) blocker being resolved, (c) minimal scope strictly limited to unblocking the parent step.
- Inserted remediation steps MUST NOT introduce unrelated feature work or refactors.
- Aggregate outputs after all runnable steps complete.
- Do not report list of files changed.

## Sub-Agent Prompt Template

### Inputs for This Prompt

- Step Title: ${TITLE}.
- Step Intent: ${INTENT}.

### Objective

Implement exactly this step: ${TITLE}

### Context

- You MUST read all references explicitly provided: ${STEP_REFERENCES}.

### In Scope

${IN_SCOPE}

### Out of Scope

${OUT_OF_SCOPE}

#### Acceptance Criteria

${ACCEPTANCE_CRITERIA}

#### Implementation Notes

${IMPLEMENTATION_NOTES}

### Non-Negotiable Rules

- Change only what the scope requires.
- Follow existing codebase conventions, including `AGENTS.md`.
- Do not test implementation details or edge cases that are not explicitly required by the acceptance criteria.
- If any required context/reference is missing or inaccessible, REPORT "Missing Context" and HALT (no implementation).
- Meet all acceptance criteria. If any cannot be met, return `Status: failed` with the reason.
- Do not report list of files changed.

### Execution Context

#### Step Identity

- Step ID: ${STEP_ID}.
- Depends On: ${DEPENDENCIES}.
- Steps Index: ${STEPS_INDEX}.
- Execution Order: ${STEPS_INDEX}.

#### Dependency Context

*List upstream IDs/titles only, no duplication*
```
${UPSTREAM_ID_TITLE_LIST}
```

### Output Format

```markdown
Status: `success` \| `failed` \| `blocked`
Result: What was done (concise, verifiable).

Missing Context:
- *List missing items here*

Open Issues:
- *Unresolved problems or follow-ups*
```

---

## Orchestration Output Format

```markdown
### Execution Summary

### Execution Plan Updates
- Inserted Steps: [list or empty]
- Dependency Changes: [list or empty]

#### Step S1: ${TITLE}
- Status: ...
- Files Modified: [list]
- Notes: [any issues or assumptions made]

#### Step S2: ...
...

### Final Result
[Aggregated outcome across successful steps]
```
