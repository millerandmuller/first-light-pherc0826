#!/usr/bin/env bash
# F5 — ink inference with the ink_9um checkpoint, both directions.
# Source: https://scrollprize.substack.com/p/from-ct-scan-to-ancient-text-a-first
#         https://huggingface.co/scrollprize/ink_9um (checkpoint)
# NOT YET RUN. --direction both writes segment.tif and segment_reverse.tif
# (dossier D-25). OOM fallback documented by the maintainers: rerun with
# --batch-size 1 (this script starts at 4, matching the tutorial default).
set -euo pipefail

: "${SCROLL:?SCROLL required}"
: "${RUN_TAG:?RUN_TAG required}"
: "${CHECKPOINT:?CHECKPOINT required}"
VILLA_DIR="${VILLA_DIR:-villa}"
RENDER_DIR="$(pwd)/runbook/out/$SCROLL/$RUN_TAG/render"
OUT_DIR="$(pwd)/runbook/out/$SCROLL/$RUN_TAG/predictions"
mkdir -p "$OUT_DIR" "$(dirname "$CHECKPOINT")"

if [ ! -f "$CHECKPOINT" ]; then
  echo "Downloading checkpoint to $CHECKPOINT ..."
  uvx --from huggingface_hub hf download scrollprize/ink_9um \
    hybrid_3d2d-seed42/step-075000.pth \
    --local-dir "$(dirname "$(dirname "$CHECKPOINT")")"
fi

pushd "$VILLA_DIR/vesuvius" >/dev/null
set +e
uv run --extra models python -m vesuvius.ink_detection.inference.infer \
  "$RENDER_DIR/segment.zarr" \
  "$CHECKPOINT" \
  "$OUT_DIR/segment.tif" \
  --overlap 0.5 \
  --blend-mode hann \
  --batch-size 4 \
  --direction both
STATUS=$?
set -e
popd >/dev/null

if [ $STATUS -ne 0 ]; then
  echo "inference failed at --batch-size 4 (possible OOM) — retrying at --batch-size 1 per maintainer guidance (D-25)"
  pushd "$VILLA_DIR/vesuvius" >/dev/null
  uv run --extra models python -m vesuvius.ink_detection.inference.infer \
    "$RENDER_DIR/segment.zarr" \
    "$CHECKPOINT" \
    "$OUT_DIR/segment.tif" \
    --overlap 0.5 \
    --blend-mode hann \
    --batch-size 1 \
    --direction both
  popd >/dev/null
fi

echo "predictions: $OUT_DIR/segment.tif and $OUT_DIR/segment_reverse.tif"
