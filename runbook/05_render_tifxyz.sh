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
VC_BIN_DIR="${VC_BIN_DIR:-/usr/local/bin}"

# Fix (round terminal, 2026-08-27, real box): this used to assume
# villa/lasagna's fit.py writes $FLATTEN_DIR/tifxyz/flatten.tifxyz. That path
# was never confirmed against source and is now known wrong — 04's rewrite
# uses render_ink.py, which does its own full-scroll concat + lasagna
# flatten and writes the trimmed result to
# meshes/fitted/concat/<winding-range>_flat/{meta.json,x/y/z.tif} (exact
# winding-range name depends on the fit's actual winding span, hence the
# glob below rather than a hardcoded name). Run 04_lasagna_flatten.sh first.
SPIRAL_OUT="$(pwd)/runbook/out/$SCROLL/$RUN_TAG/spiral-fit"
RUN_DIR=$(find "$SPIRAL_OUT" -mindepth 1 -maxdepth 1 -type d -printf '%T@ %p\n' 2>/dev/null \
  | sort -rn | head -1 | cut -d' ' -f2-)
# Fix (round terminal, 2026-08-28): 04_lasagna_flatten.sh's WINDING_MIN/MAX
# scoping writes its output under meshes/fitted_scoped_wNNN-NNN/concat/ (see
# that script), not meshes/fitted/concat/ — a bare 'fitted' glob here finds
# nothing for a scoped run and fails silently downstream. Search two levels
# under meshes/ (meshes/<fitted-or-scoped-dir>/concat/<range>_flat) so this
# works for both, and pick the most recently written match by mtime, same
# convention as RUN_DIR above, in case more than one exists.
SEGMENTATION=$(find "${RUN_DIR:-/nonexistent}/meshes" -mindepth 3 -maxdepth 3 -type d -name '*_flat' -printf '%T@ %p\n' 2>/dev/null \
  | sort -rn | head -1 | cut -d' ' -f2-)
if [ -z "$SEGMENTATION" ]; then
  echo "No *_flat tifxyz directory found under $SPIRAL_OUT/*/meshes/{fitted,fitted_scoped_*}/concat — run runbook/04_lasagna_flatten.sh first." >&2
  exit 1
fi
OUT_DIR="$(pwd)/runbook/out/$SCROLL/$RUN_TAG/render"
mkdir -p "$OUT_DIR"

# TODO(F1/F2): point VOLUME_ZARR at the scroll's actual OME-Zarr on the open
# S3 bucket once the scroll pick (F1) and voxel size are confirmed — see
# runbook/01_scroll_selection.md. Placeholder value below WILL fail; that is
# intentional (fail loud, don't silently render the wrong volume).
VOLUME_ZARR="${VOLUME_ZARR:?set VOLUME_ZARR to the target s3://vesuvius-challenge-open-data/... zarr path from F1}"

# Fix (round terminal, 2026-08-27, real box): `--volume "$VOLUME_ZARR"` alone
# (a bare s3:// string) fails live: `Error opening local zarr: filesystem
# error: directory iterator cannot open directory: No such file or
# directory [s3://...]` — vc_render_tifxyz's --volume is a LOCAL path; remote
# streaming needs --remote-url alongside it. Confirmed against
# scrollprize.org/docs/07_tutorial5.md's own worked example (`--volume
# volume-cache/<name>.zarr --remote-url s3://...`) and verified live on this
# box: a real render against PHerc0826's raw volume progressed normally with
# both flags set together. `--volume` names a local directory that vc_render
# streams needed chunks into: does not need to pre-exist or be pre-populated.
VOLUME_CACHE_DIR="${VOLUME_CACHE_DIR:-$(pwd)/volume-cache/$SCROLL.zarr}"

"$VC_BIN_DIR/vc_render_tifxyz" \
  --volume "$VOLUME_CACHE_DIR" \
  --remote-url "$VOLUME_ZARR" \
  --group-idx 0 \
  --scale 1 \
  --segmentation "$SEGMENTATION" \
  --num-slices 28 \
  --slice-step 1 \
  --cache-gb 16 \
  --zarr-output "$OUT_DIR/segment.zarr"

# Sanity check against the D-19 sparse-pyramid trap: refuse an all-black render.
#
# Fix (round terminal, 2026-08-28, real box): vc_render_tifxyz's --zarr-output
# writes a multiscale GROUP (levels "0".."5", string keys), not a plain
# array — confirmed live, same structure seen on every other --zarr-output
# in this project (control.zarr, the published w035 surface volume). The
# original `arr[0]` (integer index) tried to path-join an int into a zarr
# Group key and crashed with a real Python TypeError (not a caught
# D-19-style failure) — meaning this check has never actually run
# successfully since 05 was written; it silently made 05 report a false
# STAGE_EXIT even on a genuinely valid render. Index the level-0 array by
# its string key instead.
uv run --with numpy --with zarr python3 - "$OUT_DIR/segment.zarr" <<'PY'
import sys
import numpy as np
import zarr

path = sys.argv[1]
root = zarr.open(path, mode="r")
level0 = root["0"] if hasattr(root, "__getitem__") and "0" in root else root
sample = np.asarray(level0[0])
if not np.any(sample):
    raise SystemExit(
        f"{path} looks all-black (dossier D-19: absent --group-idx level can "
        f"render all-black with exit 0). Check the level exists before trusting this output."
    )
print(f"{path}: nonzero pixels found, OK")
PY

echo "render output: $OUT_DIR/segment.zarr"
