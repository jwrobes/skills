---
name: scaffold-workspace
description: Create a new project workspace folder with workbench, worktree, Cursor rules, and .code-workspace file. Use when the user wants to set up a new project workspace, create a workspace for a new project, or start working on a new project initiative. Also handles adding new initiatives to an existing workspace.
---

# Scaffold Project Workspace

Set up a standardized project workspace at `~/workspace/<project>_workspace/` with a workbench, git worktree, Cursor rules, and multi-root `.code-workspace` file.

## Prerequisites

The main project repository must already be cloned at `~/workspace/<project>/`. This skill does NOT clone from GitLab.

## When to Use

- User wants to create a new `<project>_workspace/` folder
- User mentions "set up a workspace for \<project\>"
- User wants to add a new initiative/feature to an existing workspace

## Step 1: Gather Information

Ask the user for the following. Use sensible defaults where noted.

1. **Project name** — The name of the project repo (e.g., `my-app`, `api-service`). Verify it exists at `~/workspace/<project>/`.
2. **Initiative name** — What's the first unit of work? (e.g., `auth_refactor`, `dark_mode`). This becomes both the workbench subfolder and part of the worktree directory name. Use `lowercase_with_underscores`.
3. **Branch name** — Git branch for the worktree. Default: `build-<username>-<initiative-name-with-hyphens>`. Detect `<username>` from `git config user.name` or `whoami`.
4. **Reference projects** — Other repos the agent should have access to while working on this initiative. List of project names. The user can skip this.

## Step 2: Validate

1. Confirm `~/workspace/<project>/` exists and is a git repo
2. Check whether `~/workspace/<project>_workspace/` already exists
   - If it does → skip to **Add Initiative to Existing Workspace** (at the bottom of this doc)
   - If it doesn't → proceed with full workspace creation
3. Confirm the branch name doesn't already exist in the project repo: `cd ~/workspace/<project> && git branch --list <branch_name>`

## Step 3: Create the Workspace Structure

```bash
mkdir -p ~/workspace/<project>_workspace
cd ~/workspace/<project>_workspace
git init
mkdir -p workbench/<initiative_name>
mkdir -p .cursor/rules
mkdir -p .cursor/skills
```

### Write `.gitignore`

```
# Worktree directories (created from ~/workspace/<project>)
<project>-*/

# OS files
.DS_Store
*.swp
*.swo

# Large data files
*.csv
*.parquet
```

## Step 4: Create the Git Worktree

```bash
cd ~/workspace/<project>
git worktree add ~/workspace/<project>_workspace/<project>-<initiative_slugified> -b <branch_name>
```

Where `<initiative_slugified>` converts underscores to hyphens (e.g., `coverage_transfer_bug` → `coverage-transfer-bug`).

## Step 5: Create the `.code-workspace` File

Write to `~/workspace/<project>_workspace/workbench/<initiative_name>/<initiative_name>.code-workspace`:

```json
{
  "folders": [
    {
      "name": "worktree: <project>-<initiative_slugified>",
      "path": "../../<project>-<initiative_slugified>"
    },
    {
      "name": "workbench: <initiative_name>",
      "path": "."
    }
  ],
  "settings": {}
}
```

If the user specified reference projects, add entries for each:

```json
{
  "name": "ref: <ref_project> (read-only)",
  "path": "../../../<ref_project>"
}
```

The path `../../../<ref_project>` navigates from `workbench/<initiative>/` up to `~/workspace/` and into the reference project.

## Step 6: Create the Cursor Rule

Write to `~/workspace/<project>_workspace/.cursor/rules/commit-only-in-worktree.mdc`:

```markdown
# Commit Only in Worktrees

When working in this workspace, ONLY commit code changes to git worktree directories (folders matching `<project>-*/`). Never commit directly to the main project repository at `~/workspace/<project>/`.

## Rules

1. All code changes (features, bug fixes, refactors) MUST be committed in the worktree directory for the current initiative.
2. The workbench directory is tracked by this workspace's own git repo — workbench changes (docs, plans, output) are committed to the workspace repo at `~/workspace/<project>_workspace/`.
3. Never run `git push` from within a worktree without explicit user approval.
4. When creating new files, place them in the correct git context:
   - Code files → worktree directory
   - Documentation, plans, analysis output → workbench initiative folder
5. Before committing, verify you are in the correct directory by checking `git remote -v` — the worktree remote should point to the project's GitLab origin, not the workspace repo.
```

## Step 7: Check for Project-Specific Setup Skill

Check if `~/workspace/<project>_workspace/.cursor/skills/<project>-worktree-setup/SKILL.md` exists.

- **If it exists:** Tell the user: "Found a project-specific worktree setup skill for `<project>`. Running it now..." and follow its instructions to configure the new worktree.
- **If it doesn't exist:** Ask the user: "No project-specific setup skill found for `<project>`. Some projects need special worktree setup (Docker config, `.env` files, credential scripts, etc.). Want to create a setup skill now?" If yes, scaffold a `SKILL.md` at `.cursor/skills/<project>-worktree-setup/SKILL.md` by asking what setup steps are needed for this project's worktrees.

## Step 8: Create the Workspace README

Write to `~/workspace/<project>_workspace/README.md`:

```markdown
# <project>-workspace

Workspace for <project>-focused investigations and feature work. Worktrees are created from `~/workspace/<project>/` (the main clone).

## Structure

- `workbench/` — Planning docs, analysis scripts, experiments (tracked in this repo)
- `<project>-<branch>/` — Git worktrees for active work (created from main clone)
- `.cursor/rules/` — Workspace-level Cursor rules
- `.cursor/skills/` — Project-specific Cursor skills

## Setup

```bash
# Open an initiative in Cursor with scoped context
cursor ~/workspace/<project>_workspace/workbench/<initiative_name>/<initiative_name>.code-workspace

# Create a new worktree for a feature/bug
cd ~/workspace/<project>
git worktree add ~/workspace/<project>_workspace/<project>-<feature> -b build-<username>-<feature>
```

## Active Worktrees

| Worktree | Branch | Initiative |
|----------|--------|------------|
| `<project>-<initiative_slugified>/` | `<branch_name>` | [<initiative_name>](workbench/<initiative_name>/) |

## Git Repositories

| Location | Tracks |
|----------|--------|
| `<project>_workspace/.git` | workbench/ contents |
| `~/workspace/<project>/.git` | Project code (worktree parent) |

## Cleanup

When done with a worktree:

```bash
cd ~/workspace/<project>
git worktree remove ~/workspace/<project>_workspace/<project>-<feature>

# Update the Active Worktrees table above
# Remove its entry from the relevant .code-workspace file
```
```

## Step 9: Initial Commit

```bash
cd ~/workspace/<project>_workspace
git add .
git commit -m "Initialize <project> workspace with <initiative_name> workbench"
```

## Step 10: Summary

Tell the user:
1. Workspace created at `~/workspace/<project>_workspace/`
2. Worktree created at `~/workspace/<project>_workspace/<project>-<initiative_slugified>/` on branch `<branch_name>`
3. Open in Cursor: `cursor ~/workspace/<project>_workspace/workbench/<initiative_name>/<initiative_name>.code-workspace`
4. Workbench initiative folder: `~/workspace/<project>_workspace/workbench/<initiative_name>/`

---

## Add Initiative to Existing Workspace

If `~/workspace/<project>_workspace/` already exists, add a new initiative without re-creating the workspace:

1. **Ask** for initiative name, branch name, and reference projects (same as Step 1)
2. **Create** `workbench/<initiative_name>/` directory
3. **Create the worktree:**
   ```bash
   cd ~/workspace/<project>
   git worktree add ~/workspace/<project>_workspace/<project>-<initiative_slugified> -b <branch_name>
   ```
4. **Create** the `.code-workspace` file in `workbench/<initiative_name>/`
5. **Update** `.gitignore` — add the new worktree directory pattern if not already covered by the glob
6. **Update** `README.md` — add a row to the Active Worktrees table
7. **Run** the project-specific setup skill if it exists at `.cursor/skills/<project>-worktree-setup/SKILL.md`
8. **Commit:**
   ```bash
   cd ~/workspace/<project>_workspace
   git add .
   git commit -m "Add <initiative_name> initiative with worktree <project>-<initiative_slugified>"
   ```
