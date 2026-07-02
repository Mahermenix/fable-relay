#!/usr/bin/env bash
# estimate.sh — pre-session Fable 5 cost estimate for the fable-relay skill.
# Usage: estimate.sh BRIEF.md [KICKOFF.md] [--stories N] [--turns N] [--delegations N] [--overhead TOK]
# Tokens approximated as bytes/4. Cache-aware: context cache-written once,
# cache-read on later turns; the "worst case" line prices every turn uncached.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=rates.env
source "$HERE/rates.env"

BRIEF="${1:?usage: estimate.sh BRIEF.md [KICKOFF.md] [--stories N] [--turns N] [--delegations N] [--overhead TOK]}"
shift
KICKOFF=""
if [[ $# -gt 0 && "${1:0:2}" != "--" ]]; then KICKOFF="$1"; shift; fi

STORIES=4; TURNS=6; DELEG=6; OVERHEAD=25000
while [[ $# -gt 0 ]]; do
  case "$1" in
    --stories)     STORIES="$2"; shift 2;;
    --turns)       TURNS="$2"; shift 2;;
    --delegations) DELEG="$2"; shift 2;;
    --overhead)    OVERHEAD="$2"; shift 2;;
    *) echo "unknown flag: $1" >&2; exit 1;;
  esac
done

[[ -f "$BRIEF" ]] || { echo "brief not found: $BRIEF" >&2; exit 1; }
BRIEF_B=$(wc -c < "$BRIEF")
KICK_B=0; [[ -n "$KICKOFF" && -f "$KICKOFF" ]] && KICK_B=$(wc -c < "$KICKOFF")

AGE_DAYS=$(( ( $(date +%s) - $(date -j -f %Y-%m-%d "$RATES_DATE" +%s 2>/dev/null || date -d "$RATES_DATE" +%s) ) / 86400 ))
[[ "$AGE_DAYS" -gt 60 ]] && echo "⚠️  rates.env is ${AGE_DAYS} days old — verify current Fable pricing before trusting this." >&2

python3 - "$BRIEF_B" "$KICK_B" "$STORIES" "$TURNS" "$DELEG" "$OVERHEAD" \
          "$FABLE_IN" "$FABLE_OUT" "$FABLE_CACHE_WRITE" "$FABLE_CACHE_READ" "$RATES_DATE" <<'PY'
import sys
brief_b, kick_b, stories, turns, deleg, overhead = (int(float(x)) for x in sys.argv[1:7])
p_in, p_out, p_cw, p_cr = (float(x) for x in sys.argv[7:11])
rates_date = sys.argv[11]
M = 1_000_000

brief_t, kick_t = brief_b // 4, kick_b // 4
ctx0 = overhead + brief_t + kick_t                      # context every turn re-reads
fresh_in = deleg * 400 + turns * 200                    # subagent reports + owner msgs
out_t = 3000 + stories * 1500 + turns * 300             # plan + stories + chatter

cached = (ctx0*p_cw + (turns-1)*ctx0*p_cr + fresh_in*p_in + out_t*p_out) / M
worst  = (turns*ctx0*p_in + fresh_in*p_in + out_t*p_out) / M

print(f"Fable session estimate  (brief {brief_t/1000:.1f}k tok, kickoff {kick_t/1000:.1f}k tok, session overhead {overhead/1000:.0f}k tok)")
print(f"  expected              ${cached:.2f}")
print(f"  high (1.5x buffer)    ${cached*1.5:.2f}")
print(f"  worst case (no cache) ${worst:.2f}")
print(f"Assumptions: {stories} stories, {turns} Fable turns, {deleg} delegations. Rates dated {rates_date}.")
PY
