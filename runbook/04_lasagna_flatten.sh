#!/usr/bin/env bash
# F4 (part 1) — flatten the fitted spiral mesh via villa/lasagna.
# Source: https://scrollprize.substack.com/p/from-ct-scan-to-ancient-text-a-first
# NOT YET RUN. Expects the spiral-fit mesh from runbook/03_spiral_fit.sh at
# $SPIRAL_OUT/meshes/mesh (per tutorial_spiral's render_ink.py usage) — confirm
# the actual output path once a real spiral-fit run has completed; villa's own
# output layout is the source of truth, not this comment.
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
python fit.py \
  configs/flatten_fast_nofilter.json \
  "$FLATTEN_INPUT" \
  --out-dir "$OUT_DIR" \
  --device cuda
popd >/dev/null

echo "flatten output: $OUT_DIR"
