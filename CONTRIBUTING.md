# Contributing to fable-relay

Thanks for helping improve fable-relay. It's a small, focused skill, so
contributions stay small and focused too.

## Ways to contribute

- **Retarget the worker bridge.** `scripts/glm-bridge.sh` defaults to GLM via
  opencode. A clean adapter for another headless CLI worker (or a documented
  env-var swap) is high-value.
- **Provider rate tables.** `scripts/rates.env` is Anthropic-priced. Drop-in
  rate files for other providers help everyone estimate.
- **Sharper templates.** Improvements to `BRIEF.md` / `KICKOFF.md` /
  `story.md` that make premium sessions stall less or delegate more.
- **Docs & examples.** A well-sanitized worked example is worth a lot.

## Ground rules

- **Keep the core principle intact:** the premium model spends tokens only on
  thinking; everything mechanical routes to a cheaper model.
- **Never commit secrets.** No API keys, no private paths, no real business
  context in examples. Sanitize before you push.
- **Bash must pass `shellcheck`.** CI runs it; run it locally first:
  `shellcheck scripts/*.sh`.
- **Prose changes:** keep the skill's rules crisp and testable. If you add a
  rule, add the failure it prevents.

## Workflow

1. Fork and branch (`feat/…` or `fix/…`).
2. Make the change; run `shellcheck scripts/*.sh`.
3. Open a PR describing the failure your change prevents or the capability it
   adds. Screenshots or a before/after cost delta are welcome.

By contributing you agree your work is licensed under the repo's [MIT License](LICENSE).
