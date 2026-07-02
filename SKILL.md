---
name: fable-relay
description: Use when the owner wants Fable 5 involved in a task — planning a feature with Fable, preparing a brief or kickoff for a Fable session, estimating what a Fable session will cost, escalating a hard problem to Fable, or executing a Fable-authored plan with GLM/OpenCode workers. Also when the owner says "fable-relay", "prep for Fable", or "run the stories".
---

# fable-relay — spend Fable tokens only on thinking

Fable 5 bills per token from the owner's credit card (no subscription cover).
This skill splits work into three phases so Fable's tokens go ONLY to
synthesis, architecture, strategy, and story-writing — never to prep,
reading, research, execution, or review.

**Phase router:** `prep` (default when no PLAN.md exists for the task) runs in
the current cheap session. Phase 2 is the owner's separate Fable session —
this skill only generates its contract. `execute` runs after PLAN.md exists.

## Hard rules (binding in every phase)

- NEVER tell the owner to `/model`-switch an existing session to Fable — the
  whole transcript would re-bill at Fable rates. Fresh session + file handoff.
- Every paid Fable action passes a ⚠️ cost gate: estimate shown, owner
  approves first. Actuals recorded in `.fable/<slug>/COST.md` afterwards.
- GLM only via `scripts/glm-bridge.sh` — never ruflo/swarm delegation (they
  silently bill Claude).
- Max 2 GLM fix attempts per story, then escalate or stop. No unbounded loops.
  A timeout or crash is NOT a fix attempt — resume the same session with `-c`.
  Size `GLM_TIMEOUT` to the story: 600s default suits small edits; bulk
  generation or test-heavy stories need 1800s+.
- Subagents spawned from a Fable session MUST pin an explicit cheaper `model`.

## Phase 1 — prep (run here, on the cheap session)

1. Interview the owner: goal, constraints, success criteria (batched,
   click-to-pick). Targeted vault/memory search if the project has one.
2. Scope-split check: list anything the task needs that Fable won't author
   (explicit sexual content, and similar restricted material). Structure the
   brief so Fable designs the CONTRACTS for those parts (input format, output
   schema, validation gates) and an external tool the owner names (e.g. their
   Grok API) authors the content at execute time. A brief that asks Fable to
   author restricted content burns the session's one revision round on
   re-scoping.
3. Explore the repo YOURSELF (this session is cheap) and write
   `.fable/<task-slug>/BRIEF.md` from `templates/BRIEF.md`. It must be
   self-contained: inline the code excerpts Fable will need. Fable never
   opens the repo.
4. Generate `.fable/<slug>/KICKOFF.md` from `templates/KICKOFF.md`
   (substitute `{{TASK_SLUG}}`, `{{TASK_DIR}}`).
5. ⚠️ Cost gate: run `scripts/estimate.sh <BRIEF> <KICKOFF>` and show the
   owner the range. Wait for approval. Two caveats to state with it: the
   script assumes ~4 stories / 6 turns — scale the range up for visibly
   bigger plans — and it covers Fable ONLY; external authoring APIs (Grok
   etc.) are estimated and gated separately at execute time.
6. Tell the owner exactly this, then stop:
   ```
   cd <project> && claude --model claude-fable-5 --strict-mcp-config
   first message:  Read <TASK_DIR>/KICKOFF.md and follow it exactly.
   when it prints PLANNING COMPLETE: run /cost, paste the result to me later.
   ```

## Phase 2 — the Fable session (owner-driven)

Everything Fable may and may not do lives in KICKOFF.md. This skill is not
loaded there; the contract must stand alone. Owner reviews PLAN.md and gives
at most ONE consolidated revision round.

## Phase 3 — execute (run here, after PLAN.md exists)

1. Read `.fable/<slug>/PLAN.md` + `stories/`. Record the owner's pasted
   `/cost` into COST.md. Grep-verify any "corrections to the brief" the PLAN
   asserts before running stories that depend on them — Fable states
   corrections confidently and can be wrong about the repo. Confirm story
   order (one question).
2. Set up the workspace: if the owner may touch the repo while stories run
   (parallel sessions, IDE open), execute in a dedicated git worktree
   (`git worktree add ../<repo>-<slug> <branch>`) — on a shared tree, a
   parallel session's branch switch or discard deletes untracked story
   outputs and uncommitted fixes. Parallel story dispatch → one worktree
   per story (shared-tree attribution hazard).
3. Per story, sequentially by default:
   `GLM_LOGDIR=.fable/<slug>/logs scripts/glm-bridge.sh -f stories/NN-*.md`
4. Quality ladder per story: GLM's diff (PLUS `git status --short` — new
   files never show in the diffstat) → review it YOURSELF against the
   story's acceptance criteria (run its verification commands). Pass →
   scoped commit IMMEDIATELY (`git add <story paths> && git commit`), then
   next story. Fail → send fix note via `glm-bridge.sh -c` (max 2). Still
   failing, or architecture drift → escalation:
5. ⚠️ Escalation gate: write a ≤1-page distilled summary (never raw diffs),
   run `scripts/fable-call.sh -f summary.md` (dry-run: prints estimate),
   show owner, on approval re-run with `--yes`. Cost auto-appends to COST.md.
6. Third-party authoring APIs (Grok etc.): key goes in gitignored
   `.env.local`, never in stories or logs; pilot ONE record and show the
   owner measured per-record cost before un-gating the batch; append each
   wave's actual spend to COST.md.
7. Finish: project test/lint gates green → status report (Done / Needs you /
   Shipped / Skipped / Risks) + COST.md table (estimate vs actual, incl.
   third-party API rows).

## Files

| File | Purpose |
|---|---|
| `templates/BRIEF.md` | self-contained context pack format |
| `templates/KICKOFF.md` | the Fable-session contract (delegation table inside) |
| `templates/story.md` | context-complete story format |
| `scripts/estimate.sh` | Fable $ estimate from brief+kickoff sizes |
| `scripts/glm-bridge.sh` | opencode/GLM runner, logs full output, returns tail |
| `scripts/fable-call.sh` | gated headless Fable call, dry-run by default |
| `scripts/rates.env` | $/MTok rates table — check date, update if stale |

## Common mistakes

- Brief that references files instead of inlining excerpts → Fable session
  stalls on gap questions or (worse) explores. Inline the code.
- Brief that asks Fable to author restricted content (explicit prose) →
  Fable declines, the revision round is spent re-scoping. Split scope in
  prep (Phase 1 step 2).
- Skipping the estimate because "it's a small task" → gate is mandatory.
- Letting GLM "just fix one more thing" past 2 attempts → escalate or stop.
- Reading GLM's reasoning log instead of `git diff` → token waste; the
  bridge surfaces the tail on purpose.
- "It's just my branch, I'll commit at the end" → a parallel owner session's
  branch switch / discard deletes uncommitted work and untracked outputs.
  Commit after every accepted story; use a dedicated worktree.
- Trusting a PLAN "correction to the brief" without a grep → wrong facts
  propagate into stories (a Fable plan once "corrected" a column as
  nonexistent that the prompt builder actively consumes).
