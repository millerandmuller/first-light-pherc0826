#!/usr/bin/env bash
# F6 — positive control through the identical pipeline, labeled, plus a
# held-out check against published ground-truth ink labels.
# NOT YET RUN. CONTROL_SCROLL / CONTROL_SEGMENT / CONTROL_VOLUME_ZARR are not
# filled in here on purpose: which segment to use as the positive control is
# a domain decision (GAP in expert_dossier.md — "held-out data issue" is
# flagged as a pivot risk in project_brief.md 1.6). Resolve it via
# /academy-expert or manual research before running this for real, then pin
# the values below (or pass them as env vars) so the choice is reproducible.
#
# Fix (examiner_report.md P2): brought the OOM-detection fix from
# 06_ink_inference.sh over here too, since this runs the identical
# --batch-size 4 --direction both inference command and could hit the same
# real GPU-memory constraints. Source for the retry threshold itself:
# https://scrollprize.substack.com/p/from-ct-scan-to-ancient-text-a-first
# ("If you run out of GPU memory, reduce --batch-size to 1.") — the OOM
# signature grep is the same imperfect-but-real improvement documented in 06.
#
# Fix (round terminal, 2026-08-27, real box): same two bugs found and fixed
# live in 05_render_tifxyz.sh apply here verbatim — (1) bare `vc_render_tifxyz`
# relies on PATH, which a fresh non-login shell may not have picked up after
# the VC3D build (/usr/local/bin); (2) `--volume "$CONTROL_VOLUME_ZARR"` alone
# (a bare s3:// string) fails live with "Error opening local zarr: ...
# directory iterator cannot open directory" — --volume is a LOCAL path;
# remote streaming needs --remote-url alongside it (confirmed against
# scrollprize.org/docs/07_tutorial5.md's own worked example and verified
# live on this box). Not re-run against a real control segment this round
# (F1's control-segment pick, D-38, is source-verified but not yet fetched) —
# fixed by inspection against the same confirmed pattern, not independently
# re-executed for this specific script.
set -euo pipefail

: "${SCROLL:?SCROLL required — the target scroll, for output pathing}"
: "${CHECKPOINT:?CHECKPOINT required}"
CONTROL_SEGMENT="${CONTROL_SEGMENT:?set CONTROL_SEGMENT to a curated positive-control tifxyz path with published ground-truth ink labels}"
CONTROL_VOLUME_ZARR="${CONTROL_VOLUME_ZARR:?set CONTROL_VOLUME_ZARR to the control scroll OME-Zarr path}"
VILLA_DIR="${VILLA_DIR:-villa}"
VC_BIN_DIR="${VC_BIN_DIR:-/usr/local/bin}"
VOLUME_CACHE_DIR="${VOLUME_CACHE_DIR:-$(pwd)/volume-cache/control-$SCROLL.zarr}"
OUT_DIR="$(pwd)/analysis/control-$SCROLL"
mkdir -p "$OUT_DIR"

"$VC_BIN_DIR/vc_render_tifxyz" \
  --volume "$VOLUME_CACHE_DIR" \
  --remote-url "$CONTROL_VOLUME_ZARR" \
  --group-idx 0 \
  --scale 1 \
  --segmentation "$CONTROL_SEGMENT" \
  --num-slices 28 \
  --slice-step 1 \
  --cache-gb 16 \
  --zarr-output "$OUT_DIR/control.zarr"

ATTEMPT_LOG="$OUT_DIR/control_inference_attempt1.log"

pushd "$VILLA_DIR/vesuvius" >/dev/null
set +e
uv run --extra models python -m vesuvius.ink_detection.inference.infer \
  "$OUT_DIR/control.zarr" \
  "$CHECKPOINT" \
  "$OUT_DIR/control_prediction.tif" \
  --overlap 0.5 \
  --blend-mode hann \
  --batch-size 4 \
  --direction both 2>&1 | tee "$ATTEMPT_LOG"
STATUS=${PIPESTATUS[0]}
set -e
popd >/dev/null

if [ "$STATUS" -ne 0 ]; then
  if grep -qiE "out of memory|OutOfMemoryError" "$ATTEMPT_LOG"; then
    echo "control inference failed at --batch-size 4 with an out-of-memory signature — retrying at --batch-size 1 (D-25)"
    pushd "$VILLA_DIR/vesuvius" >/dev/null
    uv run --extra models python -m vesuvius.ink_detection.inference.infer \
      "$OUT_DIR/control.zarr" \
      "$CHECKPOINT" \
      "$OUT_DIR/control_prediction.tif" \
      --overlap 0.5 \
      --blend-mode hann \
      --batch-size 1 \
      --direction both
    popd >/dev/null
  else
    echo "control inference failed at --batch-size 4 with no out-of-memory signature in its output — NOT retrying blindly, see $ATTEMPT_LOG" >&2
    exit "$STATUS"
  fi
fi

echo "control predictions: $OUT_DIR/control_prediction.tif and $OUT_DIR/control_prediction_reverse.tif"
echo "(--direction both writes both files, per dossier D-25 — check both before writing the audit,"
echo "not just the forward one; examiner_report.md P2 flagged this as previously undocumented here.)"
echo "Next (manual, human-written per project dealbreaker): compare against the"
echo "published ground-truth labels for this segment and write the false-positive"
echo "audit in analysis/false_positive_audit.md — do not auto-generate that prose."
