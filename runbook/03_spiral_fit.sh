#!/usr/bin/env bash
# F3 — spiral fit on a ~1,000-slice Z-window.
# Source: https://scrollprize.org/tutorial_spiral,
#         https://scrollprize.substack.com/p/from-ct-scan-to-ancient-text-a-first
# NOT YET RUN. Requires: SCROLL, Z_BEGIN, Z_END, RUN_TAG (set by the Makefile).
# Also requires a resolved umbilicus for $SCROLL — see runbook/01_scroll_selection.md
# (F1). The tutorial default config assumes an umbilicus is present in the dataset
# dir; if ours is community-annotated or hand-produced, confirm its path matches
# what fit_spiral.py expects before running this for real.
#
# READ runbook/02c_f3_preflight.md BEFORE running this for real — it documents
# what villa main's fit_session.py actually requires beyond what the tutorial
# above describes: a mandatory spiral-scroll.json (schema_version, name,
# voxel_size_um, spiral_outward_sense — the last one is a human VC3D decision,
# not something this script can determine), and normal_x/normal_y overrides
# pointing at the S3 lasagna folder. Verified live against villa's actual
# source (fit_session.py, config.py), not the tutorial.
#
# Fix (examiner_report.md P1, verified live 2026-08-23 against
# https://dl.ash2txt.org/datasets/spiral_datasets/PHerc0826/ — the real
# remote layout nests one timestamped folder under each scroll, e.g.
# spiral_datasets/PHerc0826/20250821151701/tracks/, not tracks/ directly
# under spiral_datasets/PHerc0826/. make fetch-dataset's rclone mirrors that
# nesting locally, so --dataset must point at the timestamped subfolder, not
# the scroll root. Discovered dynamically below rather than hardcoded, since
# every one of the 9 candidates in runbook/01_scroll_selection.md has exactly
# one such subfolder, and the exact timestamp differs per scroll.
#
# Fix (round terminal, 2026-08-27, real box): this script was invoking bare
# `python`, which on the RunPod PyTorch template resolves to the box's global
# env (/usr/local/bin/python), not the uv-managed venv `02_env_setup.sh`
# builds in villa/spiral-fitting. Reproduced live: `ModuleNotFoundError: No
# module named 'zarr'` before spiral-scroll.json was even read. Same bug
# class as the D-19 fix already applied in 05_render_tifxyz.sh. Switched to
# `uv run python`, which uses the project's own pyproject/lockfile venv.
set -euo pipefail

: "${SCROLL:?SCROLL required}"
: "${Z_BEGIN:?Z_BEGIN required}"
: "${Z_END:?Z_END required}"
: "${RUN_TAG:?RUN_TAG required}"
VILLA_DIR="${VILLA_DIR:-villa}"
DATASET_ROOT="$(pwd)/spiral_datasets/$SCROLL"
if [ ! -d "$DATASET_ROOT" ]; then
  echo "No dataset found at $DATASET_ROOT — run 'make fetch-dataset SCROLL=$SCROLL' first." >&2
  exit 1
fi
# 'find | head' under set -e/pipefail would otherwise abort the script
# silently (no message) if find fails for any reason after the root check
# above passes — verified empirically, this is not a hypothetical. The
# `|| true` is a required safety net, not decoration.
DATASET_DIR=$(find "$DATASET_ROOT" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | head -1) || true
if [ -z "$DATASET_DIR" ]; then
  echo "No timestamped subfolder found under $DATASET_ROOT — run 'make fetch-dataset SCROLL=$SCROLL' first." >&2
  exit 1
fi
OUT_DIR="$(pwd)/runbook/out/$SCROLL/$RUN_TAG/spiral-fit"
mkdir -p "$OUT_DIR"

export FIT_SPIRAL_CONFIG_OVERRIDES
FIT_SPIRAL_CONFIG_OVERRIDES=$(cat <<JSON
{
  "z_begin": $Z_BEGIN,
  "z_end": $Z_END,
  "input_disable_patches": true,
  "loss_weight_shell_outer": 0,
  "loss_weight_shell_patch_radius": 0,
  "dense_spacing_mode": "grad_mag",
  "loss_weight_dense_spacing": 0,
  "input_use_outer_shell": false
}
JSON
)
export FIT_SPIRAL_OUT_DIR="$OUT_DIR"

pushd "$VILLA_DIR/spiral-fitting" >/dev/null
uv run python fit_spiral.py --dataset "$DATASET_DIR"
popd >/dev/null

echo "spiral fit output: $OUT_DIR"
echo "log this run in logs/$(date -u +%Y-%m-%d)-spiral-fit-$SCROLL.md (E5): wall-clock, GPU-hours, any OOM/crash."
