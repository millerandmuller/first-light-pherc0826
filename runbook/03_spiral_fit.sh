#!/usr/bin/env bash
# F3 — spiral fit on a ~1,000-slice Z-window.
# Source: https://scrollprize.org/tutorial_spiral,
#         https://scrollprize.substack.com/p/from-ct-scan-to-ancient-text-a-first
# NOT YET RUN. Requires: SCROLL, Z_BEGIN, Z_END, RUN_TAG (set by the Makefile).
# Also requires a resolved umbilicus for $SCROLL — see runbook/01_scroll_selection.md
# (F1). The tutorial default config assumes an umbilicus is present in the dataset
# dir; if ours is community-annotated or hand-produced, confirm its path matches
# what fit_spiral.py expects before running this for real.
set -euo pipefail

: "${SCROLL:?SCROLL required}"
: "${Z_BEGIN:?Z_BEGIN required}"
: "${Z_END:?Z_END required}"
: "${RUN_TAG:?RUN_TAG required}"
VILLA_DIR="${VILLA_DIR:-villa}"
DATASET_DIR="$(pwd)/spiral_datasets/$SCROLL"
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
  "loss_weight_dense_spacing": 0
}
JSON
)
export FIT_SPIRAL_OUT_DIR="$OUT_DIR"

pushd "$VILLA_DIR/spiral-fitting" >/dev/null
python fit_spiral.py --dataset "$DATASET_DIR"
popd >/dev/null

echo "spiral fit output: $OUT_DIR"
echo "log this run in logs/$(date -u +%Y-%m-%d)-spiral-fit-$SCROLL.md (E5): wall-clock, GPU-hours, any OOM/crash."
