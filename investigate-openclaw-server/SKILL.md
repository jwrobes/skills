---
name: investigate-openclaw-server
description: >-
  Investigate the OpenClaw server and its agents (Bosque/trust, DangerClaw/danger)
  without friction — find files, read agent memory/handoffs, diagnose auth/token
  and deploy issues across the three SSH users and the container workspace. Use
  when the user asks to "look into what Bosque did", "ssh into the server / trust /
  danger", "check the server", "diagnose the github/token/deploy issue on the box",
  or to verify server-side deliverables the repo can't show.
---

# Investigate the OpenClaw Server

Read-only-first diagnostics on Jon's OpenClaw box (a MacBook running the agents).
This skill encodes the host/user/path/token map and the SSH patterns that are
otherwise fiddly, so investigation is fast and you don't re-derive them each time.

## The host + three SSH users (from ~/.ssh/config)
Same machine (`100.78.181.41` / `JwrobesBotMacbookPro.local`), three users:

| SSH alias | User | Who | Use for |
|-----------|------|-----|---------|
| `server` / `server-admin` | `jonathanwrobel` | ops/admin | git pushes (has the WORKING gh auth), cron, server scripts |
| `trust` / `trust-claw` | `jwrobes_trustclaw` | **Bosque** (the main agent) | Bosque's workspace, memory, skills, .env |
| `danger` / `danger-claw` | `jwrobes_dangerclaw` | **DangerClaw** | DangerClaw's workspace |

`server` and `trust`/`danger` see **different filesystems** — agent files live under
the agent's user, NOT under `jonathanwrobel`. (This is the #1 thing that wastes time.)

## Key paths
- **Bosque workspace (container):** `~/.openclaw/workspace-trust/` (as `trust`). Contains:
  - `repos/claw-playbook/` (and sometimes `claw-playbook/`) — the working clone
  - `.env` — agent env incl. `GITHUB_TOKEN`
  - `memory/` — daily memory files (`YYYY-MM-DD-evening.md` etc.) + handoff docs
  - skills/scripts under the claw-playbook clone's `bosque/`
- **DangerClaw:** the analogous `~/.openclaw/workspace-danger/` (as `danger`).
- **Server-admin:** `~/workspace/claw-playbook` (a separate clone), `~/workspace/scripts/spec-watcher.sh`, `~/.config/gh/.token`.

## GitHub auth map (the token gotcha — learned 2026-06-24)
There are MULTIPLE credential sources; they are NOT the same:
- **`server` (jonathanwrobel):** `~/.config/gh/.token` + a logged-in `gh` CLI → **the WORKING auth.** The spec-watcher uses this token.
- **`trust` (Bosque):** ONLY a `GITHUB_TOKEN` in `~/.openclaw/workspace-trust/.env` (and `bosque/.env`). No gh CLI, no `~/.config/gh/.token`. If that PAT expires, Bosque can't push and there's no fallback.
- So a "Bosque can't push (401)" blocker is almost always **the container's `.env` PAT is dead**, while `server` can push fine. Fix = refresh the `.env` PAT (contents:write on the target repo), or push from `server`.

## Run commands without SSH-quoting hell
Nested quotes in `ssh trust 'bash -lc "…"'` break easily. Pipe a heredoc to `bash -s` instead:

```bash
ssh -o ConnectTimeout=10 -o BatchMode=yes trust 'bash -s' <<'REMOTE'
# normal bash here — quotes, $(...), loops all work
find ~ -maxdepth 6 -name "2026-*-evening.md" 2>/dev/null | head
REMOTE
```

Use `-o BatchMode=yes -o ConnectTimeout=10`. **`.local` mDNS can be slow** — if a
call hangs, the `server`/`trust`/`danger` aliases over Tailscale-style IP may be
faster; or retry.

## Caveats that waste time (avoid)
- **`docker ps` / docker socket often hangs or is denied** over these SSH sessions — it stalls the whole command. Avoid docker steps in a diagnostic sweep; inspect files/config directly instead. If you truly need container runtime state, ask the user to run it, or check for a docker-free signal first.
- Files you "expect" under `jonathanwrobel` are usually under the agent user — always search as `trust`/`danger`.

## Common investigations (recipes)

### "What did Bosque do last night / read its handoff + memory"
```bash
ssh -o ConnectTimeout=10 -o BatchMode=yes trust 'bash -s' <<'REMOTE'
find ~ -maxdepth 6 \( -name "*HANDOFF*" -o -name "$(date -v-1d +%Y-%m-%d)-evening.md" -o -name "$(date +%Y-%m-%d)-*.md" \) 2>/dev/null | head
# then sed -n '1,60p' the file(s)
REMOTE
```

### "Diagnose the GitHub/token blocker"
Test every candidate token by HTTP code (200 = good, 401 = dead):
```bash
ssh -o ConnectTimeout=10 -o BatchMode=yes trust 'bash -s' <<'REMOTE'
for ENV in ~/.openclaw/workspace-trust/.env ~/claw-playbook/bosque/.env ~/.env; do
  T=$(grep -hE '^(GITHUB_TOKEN|GH_TOKEN)=' "$ENV" 2>/dev/null | head -1 | cut -d= -f2- | tr -d "\"'")
  [ -n "$T" ] && echo "$ENV → $(curl -s -o /dev/null -w '%{http_code}' -H "Authorization: token $T" https://api.github.com/repos/Jwrobes-Magic/claw-playbook)" || echo "$ENV → none"
done
REMOTE
```
Compare against `server`'s working token (`~/.config/gh/.token`).

### "Is unpushed work safe?"
In the agent's clone: `git -C <clone> log --oneline -5` and `git -C <clone> status -sb`
— committed-but-unpushed work is safe; report the commit + that it needs a push.

### "Verify a server-side plan deliverable" (the repo can't show it)
Check the agent's actual config files (e.g. `~/.openclaw/workspace-trust/.env`,
openclaw.json, compose) directly — NOT via docker. Report what's present vs.
needs-the-container.

## Output
Lead with the **diagnosis** (root cause + is-anything-lost), then evidence
(the file paths / HTTP codes), then the **fix options** — and never apply a
credential change or push without the user's say-so (these are outward/secret-
touching). See also [[spec-watcher-server-location]], [[three-claude-code-instance-types]].
