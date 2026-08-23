#!/usr/bin/env bash
# F4 (part 2) — render the flattened tifxyz surface to a layered zarr.
# Source: https://scrollprize.substack.com/p/from-ct-scan-to-ancient-text-a-first
# NOT YET RUN. Guards against the sparse-pyramid all-black-render trap
# (dossier D-19, villa PR #1344): an absent --group-idx level used to render
# an all-black TIF with exit 0. Until that PR is confirmed merged on the villa
# commit we're pinned to, this script checks for a nonzero-pixel output itself.
#
# Fix (examiner_report.md P1): the sanity check below needs numpy+zarr, which
# nothing in 02_env_setup.sh installs anywhere the box provably has them —
# it was running as bare `python3`, so on a clean box it would crash with
# ModuleNotFoundError before checking a single pixel, defeating the point of
# the check. Run it via `uv run --with numpy --with zarr` instead: this is
# the maintainers' own documented pattern for one-off Python snippets that
# need specific packages without a project venv (tutorial5's own
# "Post-Processing Prediction Stack" step uses the identical
# `uv run --with numpy --with tifffile --with imagecodecs python -c ...`
# form — verified live 2026-08-23). Depends only on uv itself, which
# 02_env_setup.sh already requires; doesn't depend on either the
# spiral-fitting or vesuvius venv being active.
# The slice-0-only sampling and the dead hasattr() check (examiner_report.md
# P2/P3) are intentionally NOT redesigned here — that's real hardware-box
# work, deferred until the box exists.
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
uv run --with numpy --with zarr python3 - "$OUT_DIR/segment.zarr" <<'PY'
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
