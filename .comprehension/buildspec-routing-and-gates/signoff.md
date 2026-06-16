# Comprehension Sign-Off

- **Date:** 2026-06-15
- **Commit:** 12a75a8 (skills repo); paired with claw-playbook worktree b9efda9 (build-specs/README.md)
- **Change set:** full-path-github orchestrator hardening (#105 findings) + new comprehension-artifact skill + build-specs delegation routing (cloud-build vs local-only)
- **Components covered:** C1 routing model, C2 comprehension-artifact gate, C3 spec-grounding gate, (C4 discoverability — folded into C1's exchange), C5 the open Bosque-side seam

## Pre-ratings vs outcome
| Component | First-try SOLO | Final SOLO | Iterations |
|---|---|---|---|
| C1 — cloud-build vs local-only routing | L1 (label right, causal model inverted) | L3 | 3 |
| C2 — comprehension-artifact gate | L3 | L3 | 1 |
| C3 — spec-grounding gate | L1 | L3 | 2 |
| C5 — open Bosque-side seam | L2 | **L4** | 2 |

## What the gate caught (worth keeping)
- **C1:** initial mental model was inverted twice — believed `cloud-build` → server, then believed a wrong label "defaults to cloud-build". Corrected to: `cloud-build` → Claude-on-web; server cron handles **only** `local-only`; the server exists for the one thing cloud can't do (reach uncommitted OpenClaw config/secrets). **There is no automatic default** — a mislabeled/unlabeled spec sits inert until a human acts. The label is load-bearing on the human, not enforced by code.
- **C2:** sharpened "gate" from "doesn't block merge" to the full property: **forced decision at SHIP 3.5 + recorded outcome (render OR explicit "skipped (trivial)") + no hard block.** A skip must be a logged visible judgment, never a silent omission — that's what would have caught #105.
- **C3:** gate behavior is **correct the spec → document the deviation → continue** (pre-flight, not halt). Better than #105 because #105 caught wrong paths reactively mid-build; pre-flight catches them before EXECUTE, when the cost of a wrong assumption is lowest.

## Residual gaps (signed off with awareness)
- None on the change set itself. The open *work* item (not a comprehension gap) is the Bosque-side seam below.

## Recommended follow-ups
- **(Insight from C5, L4):** Bosque's delegation skill lives in `bosque/skills/` in claw-playbook → it is **checked in and committable** (a `cloud-build` change itself), deployed via `sync.sh` self-update. NOT the unverifiable server chore it was first framed as. Write that change to: apply `cloud-build`/`local-only` by the "could a fresh clone implement this?" rule, and post the launch prompt on cloud-build PRs.
- **The one genuinely server-side bit:** the spec-watcher cron's filter — confirm it watches `local-only` (new: just the exception), not `build-spec` (old: everything), else it will wrongly grab cloud-build specs. Check where the watcher filter is defined; may not be in-repo.
- Push skills commit + open the claw-playbook README PR (pending user approval).
