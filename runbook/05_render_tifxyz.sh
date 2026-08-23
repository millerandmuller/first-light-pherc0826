#!/usr/bin/env bash
# F4 (part 2) — render the flattened tifxyz surface to a layered zarr.
# Source: https://scrollprize.substack.com/p/from-ct-scan-to-ancient-text-a-first
# NOT YET RUN. Guards against the sparse-pyramid all-black-render trap
# (dossier D-19, villa PR #1344): an absent --group-idx level used to render
# an all-black TIF with exit 0. Until that PR is confirmed merged on the villa
# commit we're pinned to, this script checks for a nonzero-pixel output itself.
set -euo pipefail

: "${SCROLL:?SCROLL required}"
: "${RUN_TAG:?RUN_TAG required}"
FLATTEN_DIR="$(pwd)/runbook/out/$SCROLL/$RUN_TAG/flatten"
SEGMENTATION="$FLATTEN_DIR/tifxyz/flatten.tifxyz"
OUT_DIR="$(pwd)/runbook/out/$SCROLL/$RUN_TAG/render"
mkdir -p "$OUT_DIR"

# TODO(F1/F2): point --volume at the scroll's actual OME-Zarr on the open S3
# bucket once the scroll pick (F1) and voxel size are confirmed — see
# runbook/01_scroll_selection.md. Placeholder path below WILL fail; that is
# intentional (fail loud, don't silently render the wrong volume).
VOLUME_ZARR="${VOLUME_ZARR:?set VOLUME_ZARR to the target s3://vesuvius-challenge-open-data/... zarr path from F1}"

vc_render_tifxyz \
  --volume "$VOLUME_ZARR" \
  --group-idx 0 \
  --scale 1 \
  --segmentation "$SEGMENTATION" \
  --num-slices 28 \
  --slice-step 1 \
  --cache-gb 16 \
  --zarr-output "$OUT_DIR/segment.zarr"

# Sanity check against the D-19 sparse-pyramid trap: refuse an all-black render.
python3 - "$OUT_DIR/segment.zarr" <<'PY'
import sys
import numpy as np
import zarr

path = sys.argv[1]
arr = zarr.open(path, mode="r")
sample = np.asarray(arr[0]) if hasattr(arr, "__getitem__") else None
if sample is None or not np.any(sample):
    raise SystemExit(
        f"{path} looks all-black (dossier D-19: absent --group-idx level can "
        f"render all-black with exit 0). Check the level exists before trusting this output."
    )
print(f"{path}: nonzero pixels found, OK")
PY

echo "render output: $OUT_DIR/segment.zarr"
