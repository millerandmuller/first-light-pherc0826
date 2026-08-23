#!/usr/bin/env bash
# F6 — positive control through the identical pipeline, labeled, plus a
# held-out check against published ground-truth ink labels.
# NOT YET RUN. CONTROL_SCROLL / CONTROL_SEGMENT / CONTROL_VOLUME_ZARR are not
# filled in here on purpose: which segment to use as the positive control is
# a domain decision (GAP in expert_dossier.md — "held-out data issue" is
# flagged as a pivot risk in project_brief.md 1.6). Resolve it via
# /academy-expert or manual research before running this for real, then pin
# the values below (or pass them as env vars) so the choice is reproducible.
set -euo pipefail

: "${SCROLL:?SCROLL required — the target scroll, for output pathing}"
: "${CHECKPOINT:?CHECKPOINT required}"
CONTROL_SEGMENT="${CONTROL_SEGMENT:?set CONTROL_SEGMENT to a curated positive-control tifxyz path with published ground-truth ink labels}"
CONTROL_VOLUME_ZARR="${CONTROL_VOLUME_ZARR:?set CONTROL_VOLUME_ZARR to the control scroll OME-Zarr path}"
VILLA_DIR="${VILLA_DIR:-villa}"
OUT_DIR="$(pwd)/analysis/control-$SCROLL"
mkdir -p "$OUT_DIR"

vc_render_tifxyz \
  --volume "$CONTROL_VOLUME_ZARR" \
  --group-idx 0 \
  --scale 1 \
  --segmentation "$CONTROL_SEGMENT" \
  --num-slices 28 \
  --slice-step 1 \
  --cache-gb 16 \
  --zarr-output "$OUT_DIR/control.zarr"

pushd "$VILLA_DIR/vesuvius" >/dev/null
uv run --extra models python -m vesuvius.ink_detection.inference.infer \
  "$OUT_DIR/control.zarr" \
  "$CHECKPOINT" \
  "$OUT_DIR/control_prediction.tif" \
  --overlap 0.5 \
  --blend-mode hann \
  --batch-size 4 \
  --direction both
popd >/dev/null

echo "control prediction: $OUT_DIR/control_prediction.tif"
echo "Next (manual, human-written per project dealbreaker): compare against the"
echo "published ground-truth labels for this segment and write the false-positive"
echo "audit in analysis/false_positive_audit.md — do not auto-generate that prose."
