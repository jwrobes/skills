# skills

Jon's personal shelf of [Cursor](https://cursor.com/) agent skills. Workflow patterns, planning skills, and engineering practices I use day-to-day, scrubbed of work-specific context and shared publicly.

## Philosophy

Skills here are **alpha** — I've authored them, I use them at work, but they don't carry a stability contract. I'm sharing them because they might save someone else the time of writing the same thing, not because I claim they're polished.

This follows [Simon Willison's "alpha" convention](https://simonwillison.net/) for AI-assisted code: things can look polished — tests, docs, a real README — without being *proven*. The signal of quality is that someone has used the skill for real work. Each skill below has been used by me in real Cursor sessions; I can't promise it'll work the same way for you.

The implicit contract: "Jon uses this. He hasn't hardened it for others. Read the SKILL.md, copy what makes sense, adjust paths, fix anything broken."

## What is a Cursor skill?

A skill is a markdown file (`SKILL.md`) plus optional supporting files that the Cursor agent loads when the user invokes it (e.g. `/grill-me` or `/scaffold-workspace`). Skills live at `~/.cursor/skills/<skill-name>/SKILL.md`. The agent reads the file and follows the workflow described inside.

For more on the format, see [Anthropic's skills repo](https://github.com/anthropics/skills) and [Simon Willison's notes on skills](https://simonwillison.net/2025/Oct/16/claude-skills/).

## Skills in this repo

| Skill | Purpose |
|---|---|
| [`tdd-pocock/`](./tdd-pocock/) | Test-driven development with red-green-refactor. Includes companion docs on mocking, deep modules, interface design, refactoring, and tests. |
| [`grill-me/`](./grill-me/) | Stress-test a plan or design through a relentless interview until shared understanding is reached. |
| [`improve-codebase-architecture/`](./improve-codebase-architecture/) | Explore a codebase for architectural friction, find coupling, propose module-deepening refactors. Includes a `REFERENCE.md` with the conceptual framework. |
| [`extract-engineering-style/`](./extract-engineering-style/) | Mine git history (and optionally MR comments) to extract coding conventions and review voice for named engineers. |
| [`generate-skill-doc/`](./generate-skill-doc/) | Turn a debugging or investigation session into a structured codebase skill doc for future engineers and LLMs. |
| [`continue-workflow/`](./continue-workflow/) | Resume a previous working session by finding and loading the most recent continuation prompt. |
| [`close-out-session/`](./close-out-session/) | Wrap up a session — summarize progress, capture uncommitted changes, write a continuation prompt, commit. |
| [`scaffold-workspace/`](./scaffold-workspace/) | Create a new project workspace folder with workbench, worktree, Cursor rules, and `.code-workspace` file. |
| [`scaffold-docs-folder/`](./scaffold-docs-folder/) | Create a new project folder or subfolder inside a documentation repo with README scaffolding and index updates. |
| [`structured-backlog/`](./structured-backlog/) | Decompose a plan into structured backlog task files with acceptance criteria and TDD workflows. Includes a task template. |
| [`prd-to-issues/`](./prd-to-issues/) | Break a PRD into independently-grabbable issues using tracer-bullet vertical slices. |
| [`enforce-integration-test/`](./enforce-integration-test/) | Plan and validate end-to-end integration tests before running them. Prevents mock-heavy tests from masquerading as integration tests. |
| [`playwright-capture-flow/`](./playwright-capture-flow/) | Capture an MCP-driven Playwright exploration as a reusable script. |
| [`setup-nvim-tmux/`](./setup-nvim-tmux/) | Replicate my Neovim + tmux dev environment on a new macOS machine. |

## Install

Each skill is a folder. Cursor loads skills from `~/.cursor/skills/<name>/SKILL.md`.

### Quick install (symlink the skills you want)

```bash
git clone git@github.com:jwrobes/skills.git ~/personal/skills
cd ~/personal/skills

# Symlink an individual skill
ln -s "$(pwd)/grill-me" ~/.cursor/skills/grill-me

# Or symlink all of them
./install.sh
```

`install.sh` symlinks every skill folder in this repo into `~/.cursor/skills/`. It refuses to overwrite existing folders or symlinks (run with `--force` to overwrite).

### Manual install (copy)

If you want to fork a skill and own your version, just copy the folder into `~/.cursor/skills/` and edit. There's no runtime dependency on this repo.

## What's NOT here (yet)

These skills exist in my local toolkit but aren't published yet. Each requires more than a textual scrub:

- **`playwright-send-message`** — a Playwright wrapper for a specific Rails-app messaging flow at work. Not generic; would need to be re-authored as a "playwright wrapper template" skill rather than scrubbed.
- **`draft-gitlab-issue`** — heavily GitLab-flavored. Plan is to generalize into a `draft-issue` skill that handles GitHub and GitLab, or split into `draft-github-issue` and `draft-gitlab-issue` with a shared core.
- **`full-path-orchestrator`** — chains intake → planning → execution → MR for a GitLab issue. The shape is generic but the implementation composes several work-only skills and assumes GitLab. Needs a design pass before publishing as a GitHub-friendly version.

The migration plan for these and future skills lives in my private docs (gist of it: pure copies, scrub on publish, no symlinks back to source).

## Companion: workshop

For runnable tools (CLI utilities, browser HTML tools, scripts), see [`jwrobes/workshop`](https://github.com/jwrobes/workshop). Skills here that *teach the agent how to use a tool* travel with that tool — they live inside the tool's folder in the workshop repo.

## License

MIT — see [`LICENSE`](./LICENSE). Use, fork, modify, redistribute. Attribution appreciated but not required.

## Inspiration

- [Simon Willison's tools repo](https://github.com/simonw/tools) — the alpha convention and the "personal-shelf-shared-publicly" pattern.
- [Anthropic's skills repo](https://github.com/anthropics/skills) — the canonical reference for skill format.
