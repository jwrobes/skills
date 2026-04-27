# Guardrails

Read this FIRST before any other `full-path-github` phase.
These are hard rules — violating any one is a stop-and-report condition.

## GitHub Issue Rules

- The issue is the **single source of truth**. All state lives there.
- **Always** overwrite the issue body with enriched content via `gh issue edit --body-file …` (GitHub keeps the previous body in the edit history).
- **Never** create child issues or sub-tasks as separate GitHub issues. Tasks live as files in the worktree under `backlog/tasks/`.
- **Always** comment before blocking — the comment explains what's needed and adds the `orchestrator-blocked` label.

## Confidence Rules

When self-interrogating (answering your own grill-me questions):

| Tier | Signal | Action |
|------|--------|--------|
| **High** | Codebase has a direct precedent that passes `code-review` phases 1, 3, 4, 5 | Decide. Document reasoning in issue body. |
| **Medium** | Multiple valid approaches, one is lower-risk or better-aligned with conventions | Decide. Add a flag comment: "Chose X over Y because Z — override in a comment if you disagree." |
| **Low** | No precedent, multiple approaches with different tradeoffs, or irreversible consequence (DB schema, public API shape) | **Stop** (label + comment) OR **split** into parallel plans (mode-dependent). |

**Never** claim high confidence without citing a specific file path and explaining why it passes the review rubric.

**Never** proceed past a low-confidence decision without either blocking or splitting.

## Pattern Evaluation Rules

Before following any codebase pattern:

1. Read the candidate file(s).
2. Evaluate against `code-review` phases 1 (architecture), 3 (naming), 4 (error handling), 5 (testing).
3. Score each phase 0–3.

| Score | Action |
|-------|--------|
| All phases ≥ 2 | Follow the pattern. Cite it in the plan. |
| Any phase = 1 | Follow with noted improvements. Document what you'd change. |
| Any phase = 0 | **Do not follow.** Find a better pattern or flag as greenfield. |

## Vagueness Gate (Intake)

After reading the issue AND searching the codebase, the orchestrator must answer three questions:

1. **What** — Can you describe the desired behavior change in one paragraph?
2. **Where** — Do you know at least one directory/module where the work lives?
3. **How to verify** — Can you state at least one testable acceptance criterion?

All three must be "yes" to proceed. Any "no" → add `orchestrator-blocked` label with a comment listing which questions can't be answered.

## E2E Validation Rules

- E2E validation hooks are a **soft prerequisite**. For personal projects, the orchestrator can ship without one only if no automated end-to-end check is feasible (e.g., a pure refactor with full unit-test coverage).
- If hooks don't exist for this feature and they make sense, building them is **task-001** in the structured backlog.
- If hooks can't be built (infrastructure missing, credentials unavailable), document the gap in the PR description and proceed.

## Hard Stops

Stop and report immediately if:

| Condition | Action |
|-----------|--------|
| Issue is private and access is denied | Do not proceed. |
| No project identifier provided | Ask the user which repo this targets. |
| Codebase is inaccessible (no clone, no worktree) | Stop. Cannot evaluate patterns or search for context. |
| Tests fail after 2 fix attempts at the same phase | Stop. Human debugging needed. |
| `code-review` scores any phase at 0 after retry | Stop. Structural issue needs human judgment. |
| `gh` CLI not authenticated (`gh auth status` fails) | Stop. Run `gh auth login` first. |

## Execution Log

Every phase must append to the execution log. The log tracks:

- Phase name and timestamp
- Decisions made (with confidence tier)
- Patterns evaluated (with scores)
- Questions asked (if blocked)
- Test results
- State transitions (assigned → draft PR → ready for review)

The log lives in memory during the run and is written into the PR description AND posted as an issue comment in the SHIP phase.
