---
agent: lead
description: Use this command for executing the code review of the implementation.
---

# CODE REVIEW

## Objective

Run an independent code review via a dedicated sub-agent to verify:
1. No regressions introduced by executed changes.
2. Execution fidelity to the plan (no dropped requirements, no scope creep).
3. Acceptance criteria coverage and risk hotspots.

## Review Orchestration Rules

- Spawn exactly TWO `review` sub-agents in parallel.
- Each sub-agent MUST receive the same inputs and rules.

---

## Review Sub-Agent Prompt

### Context

Inputs available:
- Problem Statement: ${PROBLEM_STATEMENT_FROM_PLANNING_PHASE}.
- Plan: ${PLAN_SUMMARY_FROM_PLANNING_PHASE}.
- Steps details: ${PLAN_STEPS_FROM_PLANNING_PHASE}.
- Execution summary: ${EXECUTION_FROM_EXECUTION_PHASE}.
- Changed files list: ${CHANGED_FILES}.

You MAY read repository code freely to assess impact.

### Objective

Perform a code review to detect regressions and confirm the implementation matches the plan.

### Review Checks

#### Plan Fidelity
- For each planned action/step: verify it was completed as specified (scope + acceptance criteria).
- Detect omissions: planned items not implemented or partially implemented.
- Detect drift: changes implemented that are not justified by plan scope.

#### Regression Risk
- Check behavior changes at boundaries (APIs, state transitions, error paths);
- Check invariants and assumptions noted in the plan (are they enforced / still true?);
- Check backwards compatibility where relevant (callers, configs, persisted data);
- Check tests: coverage of new/changed behavior; risk-based test gaps;
- Check for "silent breaks": renamed exports, changed signatures, altered defaults;

#### Maintainability Sanity
- Obvious complexity spikes, unclear naming, hidden side effects, dead code introduced;
- Alignment with AGENTS.md conventions (only for the touched areas);

## Main Agent Post-processing

- If verdict is REQUEST_CHANGES:
  - Do NOT declare completion;
  - Add new execution steps to fix the identified issues (scope strictly limited to addressing review concerns);
  - Report: ```markdown
    ## Code Review
    [Structured review report from the review sub-agent]

    ### Proposed Fixes
    [Bullet list of proposed fixes to address the review concerns]
  ```
- Otherwise:
  - Report: ```markdown
    ## Execution Summary
    [Summary of execution results from Phase 2]

    ### Proposed Commit Message
    [Title no more than 72 characters, body - bullet list of changes made after all steps and review. Prefer explaining the "why" over the "what". Each bullet should be no more than 72 characters. Without headings]
  ```
