# Ship Phase

Push the branch, open a draft PR with a complete execution log, and
mark it ready for review when validation is green. Post the execution
history as a comment on the issue.

## Pre-conditions

- Validate phase complete (all layers passed)
- Code committed in the worktree
- Execution log accumulated from all previous phases
- Access to `~/.cursor/skills/gh-pr-create/SKILL.md`

## Step 1: Prepare Commits

```bash
cd {worktree_path}
git log --oneline main..HEAD
```

Verify commits follow project conventions:

- Issue reference where the team expects it (e.g., `#NNN` in subject or body)
- Imperative mood subject lines
- Body on non-obvious changes ("why" + tradeoffs)

If commits need cleanup, reorganize with interactive rebase or amend.
Check `CONTRIBUTING.md` for project conventions.

## Step 2: Push the Branch

```bash
cd {worktree_path}
git push -u origin HEAD
```

## Step 3: Compose PR Description

Build the description from the execution log + validation results:

```markdown
{Summary paragraph — what this PR does and why, 2–3 sentences}

{Multi-line technical description of the approach:
- Architecture chosen and why
- Key components added/modified
- Integration points
- Feature flags}

### Observability
- **Logs:** {what gets logged and at what level}
- **Metrics:** {metrics added}
- **Traces:** {external tracing if applicable}

### Config
- {config files added or modified}
- Feature flag: `{flag_name}` (if any)

Closes #{issue_number}

## Validation Results

- **Tests:** {pass_count} passing ({new_count} new)
- **ACs:** {covered}/{total} verified
- **Review score:** {band} ({pct}%)
- **E2E:** {pass/fail/n/a}

## Test Plan

- [ ] {test step derived from ACs}
- [ ] {test step derived from ACs}
- [ ] {E2E validation step}

## Review Notes

{Should-fix items deferred to human reviewer}
{Consider items noted}
{Any medium-confidence decisions flagged for override}

<details>
<summary>Orchestrator Execution Log</summary>

{Full execution log from all phases:
- Intake summary
- Enrich summary (decisions, confidence, patterns evaluated)
- Plan summary (task count, parallel groups)
- Execute summary (strategy, test results)
- Validate summary (all four layers)}

</details>
```

## Step 4: Create the Draft PR

Read `~/.cursor/skills/gh-pr-create/SKILL.md` for the exact `gh pr create`
recipe. The orchestrator opens the PR as a **draft** initially:

```bash
cat > /tmp/pr-body.md <<'EOF'
{Composed description from Step 3}
EOF

gh pr create \
  --repo {owner/repo} \
  --base main \
  --head {branch_name} \
  --draft \
  --title "{summary of change} (closes #{issue_number})" \
  --body-file /tmp/pr-body.md
```

Record the PR URL.

## Step 5: Mark PR Ready for Review

If all validation layers passed cleanly, mark the PR ready:

```bash
gh pr ready {pr_number} --repo {owner/repo}
```

If any layer was deferred (e.g., should-fix items left for human, or
E2E was n/a with no hook), keep the PR as draft and note that in the
issue comment in Step 6.

## Step 6: Post Execution Summary to Issue

```bash
gh issue comment {NNN} --repo {owner/repo} --body "$(cat <<EOF
## Orchestrator Complete

**PR:** ${PR_URL}
**Branch:** \`${BRANCH}\`
**Status:** ${PR_STATUS}  (draft / ready for review)

### What was built
${ONE_PARAGRAPH_SUMMARY}

### Decisions made
| Decision | Choice | Confidence |
|----------|--------|------------|
| ${DECISION} | ${CHOICE} | ${TIER} |

### Validation
- Tests: ${PASS_COUNT} passing (${NEW_COUNT} new)
- Acceptance criteria: ${COVERED}/${TOTAL} verified
- Code review: ${BAND}
- E2E: ${E2E_RESULT}

### For reviewer
${HUMAN_FLAGS}
EOF
)"
```

## Step 7: Final Report

```text
Full-path orchestrator complete.

  Issue:     {repo}#{number} — {title}
  PR:        {pr_url} ({draft|ready})
  Branch:    {branch_name}
  Worktree:  {worktree_path}

  Tasks:     {completed}/{total}
  Tests:     {pass_count} passing ({new_count} new)
  ACs:       {covered}/{total} verified
  Review:    {band} ({pct}%)
  E2E:       {pass/fail/n/a}

  Decisions: {high_count} high-confidence, {medium_count} medium (flagged)
  Blocks:    {block_count} encountered, {resolved_count} resolved

Review the PR when ready.
```

## Output

- Branch pushed to origin
- PR created (draft) with execution log in description
- PR marked ready for review (if validation fully clean)
- Summary comment posted on issue
- Final report presented to user
- Proceed to `retrospect.md`
