#!/usr/bin/env bash
# F4 (part 1) — flatten the fitted spiral mesh via villa/lasagna.
# Source: https://scrollprize.substack.com/p/from-ct-scan-to-ancient-text-a-first
#         https://github.com/ScrollPrize/villa/blob/main/lasagna/README.md
#         (bootstrap commands, verified live 2026-08-23 — added below;
#         examiner_report.md P1: this step was previously missing entirely)
# NOT YET RUN. Expects the spiral-fit mesh from runbook/03_spiral_fit.sh at
# $SPIRAL_OUT/meshes/mesh (per tutorial_spiral's render_ink.py usage) — confirm
# the actual output path once a real spiral-fit run has completed; villa's own
# output layout is the source of truth, not this comment.
#
# lasagna has its OWN bootstrap, separate from the uv-based setup in
# 02_env_setup.sh (which only covers spiral-fitting and vesuvius) — the
# substack workflow post says to run this before the fit.py command below;
# the lasagna README gives the exact commands. Without it, fit.py either
# fails with a bare ModuleNotFoundError or silently runs against whichever
# python/venv happens to be active from an earlier pipeline step.
set -euo pipefail

: "${SCROLL:?SCROLL required}"
: "${RUN_TAG:?RUN_TAG required}"
VILLA_DIR="${VILLA_DIR:-villa}"
SPIRAL_OUT="$(pwd)/runbook/out/$SCROLL/$RUN_TAG/spiral-fit"
FLATTEN_INPUT="$(pwd)/runbook/out/$SCROLL/$RUN_TAG/segment_flatten_input.json"
OUT_DIR="$(pwd)/runbook/out/$SCROLL/$RUN_TAG/flatten"
mkdir -p "$OUT_DIR"

if [ ! -f "$FLATTEN_INPUT" ]; then
  echo "Missing $FLATTEN_INPUT — this JSON must point at the spiral-fit mesh under $SPIRAL_OUT." >&2
  echo "Write it by hand the first time; its exact schema isn't documented in the tutorial we sourced." >&2
  exit 1
fi

pushd "$VILLA_DIR/lasagna" >/dev/null
if [ ! -d .venv ]; then
  python3 scripts/bootstrap_venv.py --venv .venv
fi
# shellcheck disable=SC1091
source .venv/bin/activate
python fit.py \
  configs/flatten_fast_nofilter.json \
  "$FLATTEN_INPUT" \
  --out-dir "$OUT_DIR" \
  --device cuda
deactivate
popd >/dev/null

echo "flatten output: $OUT_DIR"
