---
agent: build
description: Use this command to execute the implementation plan created in the previous phase.
---

# EXECUTION

## Additional Input

$ARGUMENTS

## Objective

Execute the implementation steps.

## Global Execution Rules

- You MUST execute in dependency order; a step runs only if all dependencies succeeded;
- If a step is `failed` or `blocked` for reasons resolvable by repository changes, do NOT execute downstream dependents. Add intermediate remediation steps (e.g., `S1.1`, `S1.2`) and resume from the original failed/blocked step after remediation succeeds;
- Each inserted remediation step MUST declare: (a) parent step ID, (b) blocker being resolved, (c) minimal scope strictly limited to unblocking the parent step;
- Inserted remediation steps MUST NOT introduce unrelated feature work or refactors;
- Aggregate outputs after all runnable steps complete;

## Output Format

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

### Result
[Aggregated outcome across successful steps]
```
