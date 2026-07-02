#!/usr/bin/env bash
# fable-call.sh — cost-gated headless Fable 5 escalation call.
#
# DEFAULT IS DRY-RUN: prints the exact command + a cost estimate and exits 0.
# Nothing is billed until the owner-approved re-run with --yes.
#
# Usage:
#   fable-call.sh -f summary.md              # dry-run: show estimate only
#   fable-call.sh --yes -f summary.md [-o reply.md]
#
# The summary must be self-contained (≤1 page, distilled — never raw diffs).
# The call runs with --strict-mcp-config and a no-tools instruction so Fable
# reasons from the summary alone. Actual cost is appended to COST.md next to
# the summary file.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=rates.env
source "$HERE/rates.env"

YES=0; IN=""; OUT=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --yes) YES=1; shift;;
    -f) IN="$2"; shift 2;;
    -o) OUT="$2"; shift 2;;
    *) echo "unknown arg: $1" >&2; exit 1;;
  esac
done
[[ -n "$IN" && -f "$IN" ]] || { echo "usage: fable-call.sh [--yes] -f summary.md [-o reply.md]" >&2; exit 1; }
OUT="${OUT:-${IN%.md}.reply.md}"

IN_TOK=$(( ( $(wc -c < "$IN") / 4 ) + 12000 ))   # +headless system-prompt overhead
EST_OUT_TOK=2500
EST=$(python3 -c "print(f'{($IN_TOK*$FABLE_IN + $EST_OUT_TOK*$FABLE_OUT)/1_000_000:.2f}')")

echo "Fable escalation call"
echo "  input : $IN (~$(( IN_TOK / 1000 ))k tok incl. overhead)"
echo "  est   : ~\$$EST  (rates $RATES_DATE)"

if [[ "$YES" != "1" ]]; then
  echo "  DRY-RUN — nothing billed. Re-run with --yes after owner approval."
  exit 0
fi

PROMPT="Answer from the summary below alone. Do not use any tools, do not explore. Be decisive and concise.

$(cat "$IN")"

RAW="$(mktemp)"
claude -p --model claude-fable-5 --strict-mcp-config --output-format json "$PROMPT" > "$RAW"

python3 - "$RAW" "$OUT" "$(dirname "$IN")/COST.md" "$EST" <<'PY'
import json, sys, datetime
raw, out, costmd, est = sys.argv[1:5]
d = json.load(open(raw))
open(out, "w").write(d.get("result", ""))
cost = d.get("total_cost_usd")
u = d.get("usage", {})
row = f"| {datetime.date.today()} | execute | escalation call | ~${est} | ${cost:.2f} | in {u.get('input_tokens','?')} out {u.get('output_tokens','?')} cache_r {u.get('cache_read_input_tokens','?')} |\n" if cost is not None else \
      f"| {datetime.date.today()} | execute | escalation call | ~${est} | (no cost field) | see raw |\n"
open(costmd, "a").write(row)
print(f"reply → {out}")
print(f"actual cost ${cost:.2f}" if cost is not None else "cost field missing — check raw JSON")
PY
rm -f "$RAW"
