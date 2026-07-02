# How fable-relay works

## The economic premise

A premium reasoning model is worth its price for one thing: judgment under
ambiguity — architecture, sequencing, trade-offs, taste. Everything else in a
"planning session" is mechanical: reading files, grepping, digesting docs,
running builds, writing boilerplate, reviewing diffs. Those tasks don't get
better on a premium model; they just cost more.

fable-relay is the discipline of never letting the premium model do the cheap
work. It structures a task so premium tokens land only on thinking.

## The three phases in detail

### Phase 1 — Prep (cheap session)

You describe the task. The cheap session does the legwork a premium session
would otherwise waste money on:

- Interviews you for goal, constraints, and success criteria.
- Explores the repo and **inlines the relevant code** into `BRIEF.md`. This is
  the key move: the premium model will never open the repo, so anything it
  needs must already be in the brief.
- Emits `KICKOFF.md`, a standalone contract that tells the premium session
  exactly how to behave — what to read, what to delegate, its turn budget, and
  the exact output format.
- Runs `estimate.sh` and shows you the cost **before** you spend anything.

### Phase 2 — Plan (premium session)

You open a fresh premium session (never a model-switch of an existing one — that
re-bills the whole transcript). It reads the kickoff and brief, and then:

- **Delegates every information need downward.** Needs a fact? A cheap subagent
  fetches it. Needs a file digested? A cheap subagent returns a distilled
  summary. The premium model reads reports, not raw material.
- Writes `PLAN.md` — strategy, sequencing, risks, and a story index.
- Writes one `story-NN.md` per unit of work, each **context-complete**: a cheap
  model can implement it with zero repo exploration.

The contract caps its turns and forbids the expensive anti-patterns (reading the
repo itself, ending a turn just to wait on a subagent, delegating without
pinning a cheaper model).

### Phase 3 — Execute (cheap session)

Back on the cheap session:

- Each story runs through a cheap worker via `glm-bridge.sh` (GLM/opencode by
  default). The bridge logs the worker's full verbose output to a file and
  returns only a short tail plus a diffstat — so the orchestrator reads
  `git diff`, never the worker's reasoning transcript.
- You review each diff against the story's own acceptance criteria and run its
  verification commands.
- A failing story gets a bounded number of fix notes. If it still fails, or the
  work drifts architecturally, an explicit **cost-gated** escalation
  (`fable-call.sh`, dry-run by default) puts a ≤1-page distilled summary — never
  raw diffs — back in front of the premium model.

## Why the cost model works

The premium session is cache-aware. The brief and kickoff are cache-written on
the first turn and cache-read on every subsequent one, so the large static
context is cheap after turn one. The only genuinely new premium tokens per turn
are a few small subagent reports and the plan text the model writes. Meanwhile
every token-heavy read happened on a cheap model. `estimate.sh` models exactly
this — cache-write once, cache-read thereafter — and also prints a no-cache
worst case so you're never surprised.

## Retargeting to other models

Nothing here is Anthropic-specific except the default model names and rates:

- **Planner:** any premium reasoning model your CLI can invoke.
- **Worker:** any headless CLI worker. `glm-bridge.sh` is a thin wrapper —
  point it at yours.
- **Rates:** edit `scripts/rates.env`; the estimator re-prices itself.

The pattern — expensive planner, cheap executors, hard cost gates, bounded
fixes — is the product. The model names are just defaults.
