<div align="center">

# fable-relay

### Spend your premium model's tokens only on *thinking*.

A [Claude Code](https://docs.claude.com/en/docs/claude-code) skill that routes a
top-tier reasoning model onto strategy, architecture, and planning — and hands
every cheap task (reading, research, code, review) to cheaper models. Same
quality of thinking, a fraction of the bill.

[![License: MIT](https://img.shields.io/badge/License-MIT-black.svg)](LICENSE)
[![ShellCheck](https://github.com/Mahermenix/fable-relay/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/Mahermenix/fable-relay/actions/workflows/shellcheck.yml)
[![Built for Claude Code](https://img.shields.io/badge/built%20for-Claude%20Code-d97757)](https://docs.claude.com/en/docs/claude-code)
[![PRs welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

</div>

---

## The problem

Premium reasoning models bill per token, and a planning session quietly spends
most of its tokens on work that doesn't need a premium model at all: opening
files, grepping the repo, digesting docs, running builds, writing boilerplate,
reviewing diffs. You pay flagship rates to read a config file.

**One read at flagship rates can cost more than a cheap model's entire run.**

## The idea

fable-relay splits any large task into three phases so the expensive model's
tokens go **only** to synthesis, architecture, strategy, and writing the plan —
never to prep, reading, research, execution, or review.

```
  ┌─────────────┐      ┌──────────────────┐      ┌─────────────────┐
  │  1. PREP     │      │  2. PLAN          │      │  3. EXECUTE      │
  │  cheap sess. │ ───▶ │  premium model    │ ───▶ │  cheap workers   │
  │              │      │  (thinking only)  │      │  + your review   │
  ├─────────────┤      ├──────────────────┤      ├─────────────────┤
  │ interview    │      │ reads ONE self-  │      │ one story at a   │
  │ explore repo │      │ contained brief   │      │ time, verified   │
  │ write BRIEF  │      │ delegates all     │      │ against its own  │
  │ + KICKOFF    │      │ lookups downward  │      │ acceptance tests │
  │ cost gate ⚠️ │      │ writes PLAN +     │      │ escalate only    │
  │              │      │ executable stories│      │ when truly stuck │
  └─────────────┘      └──────────────────┘      └─────────────────┘
     you + cheap           premium ($$$)              cheap + free
```

The premium model **never opens your repo.** It reads one self-contained brief
you prepared on a cheap session, and every information need it has during
planning is delegated *downward* to a cheaper model. It spends its expensive
tokens on the one thing only it can do well: thinking.

> Named for Anthropic's **Fable** tier, but the pattern is model-agnostic — it
> works for any expensive-planner / cheap-executor pair (Opus ↔ Haiku,
> a frontier model ↔ a local one). Swap the model names in the scripts.

## Quickstart

fable-relay is a **Claude Code skill**. Install it where Claude Code looks for skills:

```bash
git clone https://github.com/Mahermenix/fable-relay.git
mkdir -p ~/.claude/skills
cp -r fable-relay ~/.claude/skills/fable-relay
```

Then, in any Claude Code session:

```
fable-relay prep: <describe the big task you want planned and executed>
```

Claude interviews you, explores the repo itself (cheap), writes a self-contained
`BRIEF.md` + a `KICKOFF.md` contract, shows you a **cost estimate**, and stops.
You start a fresh premium session, point it at the kickoff, and it returns a
`PLAN.md` plus a set of context-complete stories. Back on the cheap session,
`fable-relay execute` runs each story through a cheap worker and verifies it.

## The three phases

### 1 · Prep (cheap session)
- Interviews you for goal, constraints, success criteria.
- **Explores the repo itself** — this session is cheap, so it does the reading.
- Writes `BRIEF.md`: a self-contained context pack with the actual code
  excerpts inlined. The premium model never has to go looking.
- Generates `KICKOFF.md`: the standalone contract that governs the premium
  session (delegation rules, budget, output format).
- ⚠️ **Cost gate:** prints an estimate and waits for your approval before you
  spend a cent.

### 2 · Plan (premium session, you drive)
- A fresh premium session reads only the kickoff + brief.
- It **delegates every lookup, read, and research task to a cheaper model** —
  it reads distilled reports, not raw files.
- It writes `PLAN.md` (strategy, sequencing, risks) and one context-complete
  story per unit of work — each detailed enough that a cheap model can
  implement it with zero repo exploration.

### 3 · Execute (cheap session)
- Runs each story through a cheap worker (GLM via [opencode](https://opencode.ai),
  by default) using the included bridge.
- **You review each diff** against the story's own acceptance criteria and run
  its verification commands. Pass → next story. Fail → one bounded fix note.
- Genuinely stuck or drifting? An explicit, cost-gated escalation puts a
  ≤1-page distilled summary back in front of the premium model — never raw diffs.

## Why it saves money

The premium session is cache-aware: your brief and kickoff are cache-written
once, then cache-read on every later turn, and all the token-heavy reading
happens on cheap models. A planning session that would sprawl across dozens of
expensive file reads collapses to a handful of premium *thinking* turns.

`estimate.sh` prices it before you commit:

```
$ scripts/estimate.sh BRIEF.md KICKOFF.md
Fable session estimate  (brief 4.4k tok, kickoff 1.0k tok, session overhead 25k tok)
  expected              $1.11
  high (1.5x buffer)    $1.66
  worst case (no cache) $2.40
```

Rates live in [`scripts/rates.env`](scripts/rates.env) — update them for your
provider and the estimate re-prices itself.

## What's in the box

| Path | Purpose |
|---|---|
| [`SKILL.md`](SKILL.md) | The skill itself — the three-phase workflow and its hard rules. |
| [`templates/BRIEF.md`](templates/BRIEF.md) | Self-contained context-pack format the premium model reads. |
| [`templates/KICKOFF.md`](templates/KICKOFF.md) | The premium-session contract (delegation table, budget, output spec). |
| [`templates/story.md`](templates/story.md) | Context-complete story format a cheap worker can execute blind. |
| [`templates/COST.md`](templates/COST.md) | Estimate-vs-actual ledger per task. |
| [`scripts/estimate.sh`](scripts/estimate.sh) | Cache-aware cost estimate from brief + kickoff size. |
| [`scripts/glm-bridge.sh`](scripts/glm-bridge.sh) | Runs a cheap worker (GLM/opencode) headless; logs full output, returns a tail + diffstat. |
| [`scripts/fable-call.sh`](scripts/fable-call.sh) | Cost-gated headless premium escalation call (dry-run by default). |
| [`scripts/rates.env`](scripts/rates.env) | $/MTok rate table — the single place to update pricing. |

See [`docs/how-it-works.md`](docs/how-it-works.md) for the design rationale and
[`examples/`](examples/) for a worked brief.

## Requirements

- **[Claude Code](https://docs.claude.com/en/docs/claude-code)** — this is a Claude Code skill.
- A **premium reasoning model** available to your CLI (the planner).
- A **cheap execution model** for the workers. The default bridge targets
  **GLM** via **[opencode](https://opencode.ai)**; swap in any headless CLI worker.
- `bash`, `python3`, and `git`. macOS/Linux.

## Design principles

- **Tokens are spent only on thinking.** Everything mechanical routes down to a
  cheaper model.
- **The brief is the contract.** The premium model knows only what you inlined —
  so inline the code, don't reference it.
- **Every paid action passes a cost gate.** Estimate first, approve, then spend.
  Actuals are recorded next to the plan.
- **Bounded fixes, no infinite loops.** A worker gets a fixed number of fix
  attempts, then the work escalates or stops.
- **Fresh session + file handoff, never a model-switch.** Switching an existing
  session to the premium model would re-bill the whole transcript at premium rates.

## FAQ

**Is this Anthropic-only?** The skill and default scripts are built for Claude
Code, but the *pattern* is model-agnostic. Point the scripts at any
expensive-planner / cheap-executor pair.

**Do I need GLM specifically?** No — it's just the default cheap worker. The
bridge is a thin wrapper around a headless CLI; retarget it to any worker you
have.

**Does the premium model really never read my repo?** That's the whole point.
If it needs something, it delegates a scoped question to a cheap model and reads
the distilled answer. The brief you prepared should already contain what it needs.

**What if a task is tiny?** Then don't use this — the three-phase overhead only
pays off on substantial, multi-step work (migrations, audits, big features,
large batches).

## Transparency & safety

Be an informed user before running any agent tooling:

- **Network calls.** The default worker bridge (`glm-bridge.sh`) sends your
  task and code context to a **non-Anthropic** model provider — GLM via
  [opencode](https://opencode.ai) — and the premium phase calls your Claude
  provider. No other network calls, no telemetry, no analytics.
- **Permission bypass.** `glm-bridge.sh` runs the worker with
  `--dangerously-skip-permissions` so headless runs don't block on approval
  prompts. That means the worker can edit files without asking. Run it inside a
  git repo (the workflow assumes this), review every diff, and prefer a
  dedicated branch/worktree.
- **No secrets in the skill.** Provider keys live in your own environment/CLI,
  never in these files. Keep them out of briefs, stories, and logs.
- **Every shell script is commented** to explain exactly what it does — read
  them before running.

## Contributing

Issues and PRs welcome — see [CONTRIBUTING.md](CONTRIBUTING.md). If fable-relay
saved you tokens, a ⭐ helps others find it.

## License

[MIT](LICENSE) © Mahermenix
