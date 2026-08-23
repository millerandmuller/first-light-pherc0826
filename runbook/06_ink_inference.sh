#!/usr/bin/env bash
# F5 — ink inference with the ink_9um checkpoint, both directions.
# Source: https://scrollprize.substack.com/p/from-ct-scan-to-ancient-text-a-first
#         https://huggingface.co/scrollprize/ink_9um (checkpoint)
# NOT YET RUN. --direction both writes segment.tif and segment_reverse.tif
# (dossier D-25). OOM fallback documented by the maintainers: rerun with
# --batch-size 1 (this script starts at 4, matching the tutorial default).
#
# Fix (examiner_report.md P2): the retry used to fire on ANY nonzero exit and
# unconditionally claim "possible OOM" — a bad argument, a corrupt checkpoint,
# a network blip, anything, would get relabeled as OOM and burn a second real
# GPU-inference attempt before the true error ever surfaced. Now the first
# attempt's stderr is captured and grepped for a CUDA-OOM signature
# ("out of memory" / "OutOfMemoryError" — the common PyTorch/CUDA OOM
# wording; the exact string this specific tool emits is NOT independently
# confirmed, since it can't be run without a GPU box, so this is a real but
# imperfect improvement, not a guaranteed-accurate detector) before deciding
# to retry. A non-OOM failure now propagates immediately with the real
# captured error instead of a misleading retry.
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

ATTEMPT_LOG="$(pwd)/runbook/out/$SCROLL/$RUN_TAG/inference_attempt1.log"
mkdir -p "$(dirname "$ATTEMPT_LOG")"

pushd "$VILLA_DIR/vesuvius" >/dev/null
set +e
uv run --extra models python -m vesuvius.ink_detection.inference.infer \
  "$RENDER_DIR/segment.zarr" \
  "$CHECKPOINT" \
  "$OUT_DIR/segment.tif" \
  --overlap 0.5 \
  --blend-mode hann \
  --batch-size 4 \
  --direction both 2>&1 | tee "$ATTEMPT_LOG"
STATUS=${PIPESTATUS[0]}
set -e
popd >/dev/null

if [ "$STATUS" -ne 0 ]; then
  if grep -qiE "out of memory|OutOfMemoryError" "$ATTEMPT_LOG"; then
    echo "inference failed at --batch-size 4 with an out-of-memory signature — retrying at --batch-size 1 per maintainer guidance (D-25)"
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
  else
    echo "inference failed at --batch-size 4 with no out-of-memory signature in its output — NOT retrying blindly, see $ATTEMPT_LOG" >&2
    exit "$STATUS"
  fi
fi

echo "predictions: $OUT_DIR/segment.tif and $OUT_DIR/segment_reverse.tif"
