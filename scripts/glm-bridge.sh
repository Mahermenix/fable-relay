#!/usr/bin/env bash
# glm-bridge.sh — delegate a task to GLM (z.ai unlimited coding plan) via opencode headless.
# A generic opencode/GLM delegation bridge for the fable-relay skill.
#
# TOKEN ECONOMY: GLM's full (verbose) output goes to a log file; the caller sees
# only a short tail + a git diffstat. The orchestrator then reads `git diff`
# selectively — never GLM's reasoning transcript.
#
# Usage:
#   glm-bridge.sh "implement story 02 exactly as specified in .fable/x/stories/02-*.md"
#   glm-bridge.sh -f .fable/<slug>/stories/02-cooldown-api.md   # brief from file
#   glm-bridge.sh -c "fix: the countdown must use English numerals"  # continue session
#
# Env:
#   GLM_MODEL    default zai-coding-plan/glm-5.2 (the unlimited plan)
#   GLM_TAIL     trailing log lines to surface (default 25)
#   GLM_TIMEOUT  seconds, fail-fast (default 600)
#   GLM_LOGDIR   default .fable/glm-logs
set -euo pipefail

MODEL="${GLM_MODEL:-zai-coding-plan/glm-5.2}"
TAIL="${GLM_TAIL:-25}"
TIMEOUT="${GLM_TIMEOUT:-600}"
LOGDIR="${GLM_LOGDIR:-.fable/glm-logs}"
mkdir -p "$LOGDIR"
LOG="$LOGDIR/glm-$(date +%Y%m%d-%H%M%S).log"

CONTINUE=""
if [[ "${1:-}" == "-c" ]]; then CONTINUE="-c"; shift; fi

if [[ "${1:-}" == "-f" ]]; then
  [[ -f "${2:-}" ]] || { echo "brief file not found: ${2:-}" >&2; exit 1; }
  BRIEF="$(cat "$2")"
else
  BRIEF="$*"
fi
[[ -n "${BRIEF// /}" ]] || { echo "empty brief" >&2; exit 1; }

echo "→ Delegating to $MODEL  (full log: $LOG)" >&2

# macOS ships no GNU timeout; prefer timeout/gtimeout, else perl alarm (always present).
TIMEOUT_BIN="$(command -v timeout || command -v gtimeout || true)"
if [[ -n "$TIMEOUT_BIN" ]]; then
  RUNNER=("$TIMEOUT_BIN" "$TIMEOUT")
else
  RUNNER=(perl -e 'alarm shift; exec @ARGV' "$TIMEOUT")
fi

# --dangerously-skip-permissions so the headless run never blocks on approval prompts.
set +e
"${RUNNER[@]}" opencode run "$BRIEF" $CONTINUE -m "$MODEL" --dangerously-skip-permissions > "$LOG" 2>&1
RC=$?
set -e
# 124 = GNU timeout, 142 = perl SIGALRM
[[ "$RC" == "124" || "$RC" == "142" ]] && echo "(GLM timed out after ${TIMEOUT}s)" >> "$LOG"

echo "── GLM last ${TAIL} lines ─────────────────────────────"
tail -n "$TAIL" "$LOG"
echo "── git diff --stat ───────────────────────────────────"
git diff --stat 2>/dev/null || echo "(not a git repo)"
echo "── new/untracked (diffstat misses these) ─────────────"
git status --short 2>/dev/null | grep '^??' | head -20 || true
echo "──────────────────────────────────────────────────────"
echo "exit=$RC  full_log=$LOG"
exit "$RC"
