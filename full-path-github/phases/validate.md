# Validate Phase

Three (or four) layers: tests pass, ACs verified, `code-review` scores
the diff, and E2E hooks confirm the feature works end-to-end (when
available).

## Pre-conditions

- Execute phase complete (all tasks done, tests passing locally)
- Code committed in the worktree
- Task files with acceptance criteria available
- Access to `~/.cursor/skills/code-review/SKILL.md`

## Layer 1: Test Suite

Run the full test suite in the worktree:

```bash
cd {worktree_path}
{test_command}
```

### Pass criteria

- [ ] All tests pass (zero failures)
- [ ] No pending tests that should be implemented
- [ ] No regressions (existing tests still pass)

If tests fail:

1. Read the failure output.
2. Fix the failures.
3. Re-run the suite.
4. If still failing after 2 attempts → stop and report per guardrails.

## Layer 2: Acceptance Criteria Verification

Walk every AC from the enriched issue body. For each:

1. Find the corresponding test(s) in the new tests.
2. Verify the test exercises the specific AC (not just adjacent behavior).
3. Check the AC off if a passing test covers it.

```markdown
### AC Verification

| AC | Description | Test File | Test Name | Status |
|----|-------------|-----------|-----------|--------|
| #1 | {criterion} | {test_path} | {test name} | pass/fail/missing |
| #2 | {criterion} | {test_path} | {test name} | pass/fail/missing |
```

### Pass criteria

- [ ] Every AC has at least one corresponding test
- [ ] All corresponding tests pass
- [ ] No AC is uncovered

If any AC is uncovered:

1. Write the missing test(s).
2. Implement if needed to make them pass.
3. Re-run the full suite.

## Layer 3: code-review Rubric

Spawn a fresh-context reviewer (subagent or new conversation) to score
the diff against `code-review`:

> Read `~/.cursor/skills/code-review/SKILL.md` for the framework.
>
> Review the diff: `git diff main...HEAD` in the worktree at
> {worktree_path}.
>
> Score each applicable phase (1–7) on the 0–3 scale:
> - Phase 1: Architecture / organization
> - Phase 2: Pairing & collaboration (score the PR description and
>   commit narrative; this is agent-generated, no human pairing)
> - Phase 3: Naming & domain alignment
> - Phase 4: Error handling & defensive coding
> - Phase 5: Testing completeness
> - Phase 6: Frontend quality (n/a if backend-only)
> - Phase 7: Commit discipline & change narrative
>
> For each phase, list:
> - Score (0–3)
> - Specific findings (file + line + what to change)
> - Classification: must-fix, should-fix, consider
>
> Return the scored rubric and overall band.

### Pass criteria

- [ ] No phase scores 0
- [ ] Overall band is "Solid" (≥70%) or better
- [ ] No must-fix items remain

### Processing review results

| Finding | Action |
|---------|--------|
| Must-fix | Fix immediately in the worktree. Re-run tests. |
| Should-fix | Fix if straightforward. Note in PR description if deferred. |
| Consider | Note in PR description for human reviewer. |

After addressing must-fix items, re-run the review **once**:

- If must-fix items remain after retry → stop and report per guardrails.
- If all must-fix resolved → proceed.

## Layer 4: E2E Validation (optional, soft-blocking)

If the feature has an E2E hook (identified in PLAN), the orchestrator
**must attempt** the E2E pipeline before declaring validation complete.
Specs green ≠ feature works; the extra few minutes here catches the
bugs that survive unit tests.

### Step 4a: Determine whether E2E applies

If no hook exists and none was feasible (PLAN documented this), Layer 4
is `n/a`. Note it in the log and proceed.

### Step 4b: Run the E2E pipeline

Invoke the project's E2E skill or script. Test at least one positive
case and (where applicable) one negative case.

### Pass criteria

- [ ] E2E run reports `PASS` on at least one positive case
- [ ] E2E run reports `PASS` on at least one negative case (where applicable)
- [ ] Every hard assertion passed (status, output shape, round-trip)
- [ ] No ERROR-level entries in logs for the feature during the E2E window

### Iterate loop

If the E2E run reports `FAIL`:

1. **Diagnose.** Read the failure output and any logs / traces.
2. **Fix the code.** Apply the minimal change. If the fix reveals a
   test gap (the unit tests stubbed the wrong shape), **update the
   test fixture to match the real shape** — this is as important as
   the fix itself.
3. **Re-run unit tests.** Must stay green.
4. **Re-run E2E.**
5. **Count iterations.** Iterate up to **3** times. If E2E still fails
   after the 3rd iteration, stop and ask the user whether this is a
   code problem to keep working on, an environment problem you can't
   see, or a test that needs relaxing.

### Soft-block, not hard-block

The user can say "ship it anyway" with an explicit override. Default
behavior:

- E2E PASS → proceed to ship.
- E2E FAIL after iteration budget exhausted → **stop before ship**, add
  `orchestrator-blocked` label, write diagnostic context into the
  draft PR description, and report.

Never ship after an E2E FAIL without explicit user consent.

### Recording the outcome

Append per iteration:

```markdown
### E2E Iteration {n}

- Positive case: PASS / FAIL ({details})
- Negative case: PASS / FAIL ({details})
- Friction observed: {list}
- Fixes applied: {list of commits}
```

## Parallel Plans: Winner Selection

If EXECUTE ran parallel plans (build-first mode), run Layers 1–4 on
both. Compare:

| Metric | Plan A | Plan B |
|--------|--------|--------|
| Tests passing | {count} | {count} |
| ACs covered | {count}/{total} | {count}/{total} |
| Review score | {band} ({pct}%) | {band} ({pct}%) |
| E2E result | {pass/fail} | {pass/fail} |
| New test count | {count} | {count} |
| Diff size (lines) | {count} | {count} |

**Winner selection priority:**

1. E2E passes (hard gate — disqualify if E2E fails)
2. Higher AC coverage
3. Higher review score
4. More tests
5. Smaller diff (simpler is better, all else equal)

Discard the losing plan's worktree. Proceed with the winner.

## Step 5: Comment Validation Summary

```bash
gh issue comment {NNN} --repo {owner/repo} --body "$(cat <<EOF
**Validation complete.**

- Tests: ${PASS_COUNT} passing (${NEW_COUNT} new)
- ACs: ${COVERED}/${TOTAL} verified
- Review: ${BAND} (${SCORE}%)
- E2E: ${E2E_RESULT}

${REVIEW_NOTES}
EOF
)"
```

## Step 6: Record Validate Summary

```markdown
## Validate

**Layer 1 — Tests:** {pass_count} passing, {fail_count} failing
**Layer 2 — ACs:** {covered}/{total} verified
**Layer 3 — Review:**
| Phase | Score | Findings |
|-------|-------|----------|
| 1. Architecture | {score}/3 | {summary} |
| 2. Collaboration | {score}/3 | {summary} |
| 3. Naming | {score}/3 | {summary} |
| 4. Error handling | {score}/3 | {summary} |
| 5. Testing | {score}/3 | {summary} |
| 6. Frontend | {score}/3 or n/a | {summary} |
| 7. Commits | {score}/3 | {summary} |
| **Overall** | **{pct}%** | **{band}** |

**Layer 4 — E2E ({iterations} iteration(s)):** {pass/fail/n/a}

**Must-fix items addressed:** {count}
**Should-fix deferred:** {count}
**Consider noted:** {count}
```

## Output

- All applicable validation layers passed
- Must-fix items resolved
- Should-fix and consider items documented
- Issue commented with validation summary
- Execution log updated
- Proceed to `ship.md`
