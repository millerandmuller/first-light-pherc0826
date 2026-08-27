#!/usr/bin/env bash
# F4 (part 1) — flatten the fitted spiral mesh into one full-scroll surface,
# and render the demo-facing composite JPG strips (F9's render section).
# Source: https://scrollprize.org/tutorial_spiral ("Rendering ink" section)
#
# REWRITTEN (round terminal, 2026-08-27, real box, verified against the real
# save_mesh output from a completed 1,500-step fit + render_ink.py --help on
# this box). The previous version of this script drove villa/lasagna's
# fit.py directly with two bare positional arguments (a config json and a
# hand-authored "segment_flatten_input.json" whose schema was never
# confirmed against source). Two real problems with that, found by reading
# fit.py itself: (1) fit.py has NO positional arguments at all — every value
# is a named flag (`cli_data.py`/`cli_model.py`/`cli_opt.py`); passing bare
# positional json paths only works because `cli_json.split_cfg_argv` treats
# any bare `.json` argv entry as a config file to merge, not as the
# "flatten input" this script's old comment assumed. (2) model-init=flatten
# actually reads its source mesh from `cfg["external_surfaces"][0]["path"]`
# (fit.py's `_run_flatten_mode`, ~line 1284) and explicitly rejects
# `--tifxyz-init` — a schema this script's old FLATTEN_INPUT never produced.
# Separately, our real fit output lands at
# $SPIRAL_OUT/<run-dir>/meshes/fitted/wNNN_spliced/{meta.json,x.tif,y.tif,z.tif}
# (one tifxyz mesh per winding) — not a single mesh at meshes/mesh as the old
# comment assumed (that path was the tutorial doc's own generic example).
#
# The maintainers' own tool for exactly this per-winding-mesh shape is
# spiral-fitting/render_ink.py (documented in the tutorial's "Rendering ink"
# section): it concatenates the `_spliced` windings, flattens the full
# scroll via lasagna's forward flattener itself (correctly wired — this
# script no longer drives lasagna directly), trims the flatten's
# output-margin border, and ink-renders the result as composite JPGs. Used
# here with its defaults (`--num-slices 5` matches project_brief.md 1.6's
# "Five-layer stack"; `--strips` omitted since the full-scroll composite is
# what the demo needs, not per-winding-range chunks).
#
# Requires the VC3D CLI binaries (vc_render_tifxyz, flatboi, vc_tifxyz2obj,
# vc_obj2tifxyz, vc_obj_uv_lift, vc_tifxyz_trim), built via
# villa/volume-cartographer/build_from_src_debian.sh (AGENTS_ALLOW_INSTALL=1
# required) — NOT part of the uv envs 02_env_setup.sh builds, and NOT
# installed by that script on a fresh box. Explicit --*-bin paths are passed
# below rather than relying on PATH, since a fresh non-login shell may not
# have picked up /usr/local/bin yet.
set -euo pipefail

: "${SCROLL:?SCROLL required}"
: "${RUN_TAG:?RUN_TAG required}"
: "${VOLUME_ZARR:?set VOLUME_ZARR to the target s3://vesuvius-challenge-open-data/... zarr path from F1}"
VILLA_DIR="${VILLA_DIR:-villa}"
VC_BIN_DIR="${VC_BIN_DIR:-/usr/local/bin}"

SPIRAL_OUT="$(pwd)/runbook/out/$SCROLL/$RUN_TAG/spiral-fit"
if [ ! -d "$SPIRAL_OUT" ]; then
  echo "No spiral-fit output at $SPIRAL_OUT — run runbook/03_spiral_fit.sh first." >&2
  exit 1
fi
# fit_spiral.py names its own dated run-dir inside $SPIRAL_OUT (e.g.
# 2026-08-27_PHerc0826_slice-10000-11000_0-patch/); pick the most recently
# modified one rather than assuming there's exactly one, in case RUN_TAG was
# reused across more than one fit attempt.
RUN_DIR=$(find "$SPIRAL_OUT" -mindepth 1 -maxdepth 1 -type d -printf '%T@ %p\n' 2>/dev/null \
  | sort -rn | head -1 | cut -d' ' -f2-)
if [ -z "$RUN_DIR" ] || [ ! -d "$RUN_DIR/meshes/fitted" ]; then
  echo "No meshes/fitted directory found under $SPIRAL_OUT — run runbook/03_spiral_fit.sh first." >&2
  exit 1
fi
MESHES_DIR="$RUN_DIR/meshes/fitted"

# Optional winding-range scope restriction (prereg/readout.md Scope section:
# F5's target run is restricted to the well-covered inner windings, not the
# full fitted range). render_ink.py concatenates every wNNN_spliced dir it
# finds directly under its meshes_dir argument, with no winding-range filter
# of its own (spiral-fitting/render_ink.py: `for name in os.listdir(meshes_dir)
# if '_spliced' in name`). To scope the render, point it at a directory of
# symlinks to only the wanted _spliced dirs instead of the full fitted dir —
# render_ink.py's is_tifxyz()/winding_idx() checks use os.path.isdir /
# os.path.exists, which resolve symlinks transparently, so this needs no
# copying. Set both WINDING_MIN and WINDING_MAX (e.g. 10 and 65) to scope;
# leave both unset to render the full fitted range (unscoped default).
if [ -n "${WINDING_MIN:-}" ] || [ -n "${WINDING_MAX:-}" ]; then
  : "${WINDING_MIN:?WINDING_MIN and WINDING_MAX must both be set to scope the winding range}"
  : "${WINDING_MAX:?WINDING_MIN and WINDING_MAX must both be set to scope the winding range}"
  SCOPE_TAG=$(printf 'w%03d-%03d' "$((10#$WINDING_MIN))" "$((10#$WINDING_MAX))")
  SCOPED_DIR="$RUN_DIR/meshes/fitted_scoped_$SCOPE_TAG"
  mkdir -p "$SCOPED_DIR"
  find "$SCOPED_DIR" -maxdepth 1 -type l -delete
  N_LINKED=0
  for d in "$MESHES_DIR"/w*_spliced; do
    [ -d "$d" ] || continue
    name=$(basename "$d")
    widx=$(echo "$name" | grep -oE '^w[0-9]+' | tr -d 'w')
    widx=$((10#$widx))
    if [ "$widx" -ge "$((10#$WINDING_MIN))" ] && [ "$widx" -le "$((10#$WINDING_MAX))" ]; then
      ln -sfn "$d" "$SCOPED_DIR/$name"
      N_LINKED=$((N_LINKED + 1))
    fi
  done
  if [ "$N_LINKED" -eq 0 ]; then
    echo "No _spliced windings found in [$WINDING_MIN, $WINDING_MAX] under $MESHES_DIR" >&2
    exit 1
  fi
  echo "Scoped render input: $N_LINKED windings ($SCOPE_TAG) symlinked into $SCOPED_DIR"
  MESHES_DIR="$SCOPED_DIR"
fi

# Fix (round terminal, 2026-08-27, real box): render_ink.py's own --volume
# flag has no --remote-url companion (confirmed by reading its full --help —
# no such option exists), so its internal vc_render_tifxyz call for the ink
# composite step CANNOT stream a remote-only S3 volume: verified live, it
# fails with the same "directory iterator cannot open directory" error
# 05_render_tifxyz.sh hit before its own --remote-url fix. This is a real
# gap in render_ink.py itself (villa PR candidate #1627), not something
# fixable from our side without patching villa's vendored script. A local
# --remote-url patch matching #1627 exists on this box's vendored copy
# (uncommitted `git diff` in $VILLA_DIR) and was verified standalone (exit
# 0, real S3 stream, full composite written) — but NOT through this script
# or against a scoped/restricted MESHES_DIR, so this script intentionally
# keeps using the fallback path below rather than switching to the patched
# one this close to the deadline: F4 already completed end-to-end on this
# exact fallback path (real legible composite output, window1-full 30k fit),
# and re-verifying a new code path isn't worth the risk right now. If time
# allows later, wiring VOLUME_CACHE_DIR + --remote-url into the render_ink.py
# call below and dropping this fallback would remove the redundant second
# render. render_ink.py's concat+flatten+trim stages do NOT depend on
# --volume at all and are verified working end-to-end on this box (produced
# a real w010-129_flat tifxyz mesh from the 1,500-step CW run). So: let
# render_ink.py run and do its real job (flatten); tolerate its own exit
# code being nonzero if that failure is confined to its internal render step
# (checked below by confirming *_flat exists regardless); then render the
# demo composite ourselves with the same --remote-url pattern 05 uses.
set +e
pushd "$VILLA_DIR/spiral-fitting" >/dev/null
uv run python render_ink.py "$MESHES_DIR" \
  --volume "$VOLUME_ZARR" \
  --vc-render-bin "$VC_BIN_DIR/vc_render_tifxyz" \
  --flatboi-bin "$VC_BIN_DIR/flatboi" \
  --tifxyz2obj-bin "$VC_BIN_DIR/vc_tifxyz2obj" \
  --obj2tifxyz-bin "$VC_BIN_DIR/vc_obj2tifxyz" \
  --uv-lift-bin "$VC_BIN_DIR/vc_obj_uv_lift" \
  --tifxyz-trim-bin "$VC_BIN_DIR/vc_tifxyz_trim"
RENDER_INK_STATUS=$?
popd >/dev/null
set -e

FLAT_DIR=$(find "$MESHES_DIR/concat" -maxdepth 1 -type d -name '*_flat' 2>/dev/null | head -1)
if [ -z "$FLAT_DIR" ]; then
  echo "render_ink.py did not produce a *_flat directory under $MESHES_DIR/concat (exit $RENDER_INK_STATUS) — check its output above; the flatten stage itself failed, not just the render step." >&2
  exit 1
fi
echo "flattened full-scroll mesh: $FLAT_DIR"

if [ "$RENDER_INK_STATUS" -ne 0 ]; then
  echo "render_ink.py exited $RENDER_INK_STATUS (expected: its internal render step can't stream a remote-only volume) — rendering the demo composite ourselves instead." >&2
fi

# Demo composite: same --remote-url local-cache pattern as
# 05_render_tifxyz.sh, --num-slices 5 to match project_brief.md 1.6's
# "Five-layer stack" beat (render_ink.py's own default), then max-composite
# + renormalise to 95th percentile, replicating render_ink.py's own
# compositing logic (read from its source) since its internal call can't
# run against our remote volume.
VOLUME_CACHE_DIR="${VOLUME_CACHE_DIR:-$(pwd)/volume-cache/$SCROLL.zarr}"
DEMO_TIF_DIR="$MESHES_DIR/ink_demo_tifs"
mkdir -p "$DEMO_TIF_DIR" "$MESHES_DIR/ink"
"$VC_BIN_DIR/vc_render_tifxyz" \
  --volume "$VOLUME_CACHE_DIR" \
  --remote-url "$VOLUME_ZARR" \
  --group-idx 0 \
  --scale 0.25 \
  --segmentation "$FLAT_DIR" \
  --num-slices 5 \
  --cache-gb 16 \
  --tif-output "$DEMO_TIF_DIR"

DEMO_NAME="$(basename "$FLAT_DIR")"
uv run --with numpy --with tifffile --with imagecodecs --with pillow python3 - "$DEMO_TIF_DIR" "$MESHES_DIR/ink" "$DEMO_NAME" <<'PY'
import sys
import glob
import numpy as np
import tifffile
from PIL import Image

# Chop into fixed-width tiles above MAX_STRIP_WIDTH, matching render_ink.py's
# own default (--max-strip-width 16384) and naming (<name>.NNN.jpg) — a
# single JPEG hard-fails past 65,500px per side (PIL's own limit) and our
# full-scroll flattened width (342,630px at scale 0.25) is nowhere close to
# fitting in one file.
MAX_STRIP_WIDTH = 16384

tif_dir, out_dir, name = sys.argv[1], sys.argv[2], sys.argv[3]
paths = sorted(glob.glob(f"{tif_dir}/*.tif"))
if not paths:
    raise SystemExit(f"no TIFs found in {tif_dir} — vc_render_tifxyz produced nothing")
stack = np.stack([tifffile.imread(p) for p in paths], axis=0).astype(np.float32)
comp = stack.max(axis=0)
p95 = np.percentile(comp, 95)
comp8 = (np.clip(comp / p95, 0, 1) * 255).astype(np.uint8) if p95 > 0 else comp.astype(np.uint8)
width = comp8.shape[1]
if width <= MAX_STRIP_WIDTH:
    out_path = f"{out_dir}/{name}.jpg"
    Image.fromarray(comp8).save(out_path, quality=95)
    print(f"wrote {out_path} ({width}px wide, p95={p95:.1f})")
else:
    n_tiles = (width + MAX_STRIP_WIDTH - 1) // MAX_STRIP_WIDTH
    for t in range(n_tiles):
        x0 = t * MAX_STRIP_WIDTH
        x1 = min(width, x0 + MAX_STRIP_WIDTH)
        tile_path = f"{out_dir}/{name}.{t:03d}.jpg"
        Image.fromarray(comp8[:, x0:x1]).save(tile_path, quality=95)
    print(f"wrote {n_tiles} tiles {name}.000-{n_tiles - 1:03d}.jpg ({width}px wide total, p95={p95:.1f})")
PY

echo "demo composite: $MESHES_DIR/ink/$DEMO_NAME*.jpg"
