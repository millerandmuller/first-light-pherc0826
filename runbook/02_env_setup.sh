#!/usr/bin/env bash
# F2 — environment setup on the rented GPU box.
# Source: https://scrollprize.org/tutorial_spiral (spiral-fitting deps),
#         https://scrollprize.substack.com/p/from-ct-scan-to-ancient-text-a-first (vesuvius/models extra)
# NOT YET RUN on the real RunPod box. Verify each step manually the first time;
# this script exists so the second run (second team member's reproduction, F8)
# is one command instead of a memory test.
set -euo pipefail

VILLA_DIR="${VILLA_DIR:-villa}"

if [ ! -d "$VILLA_DIR" ]; then
  git clone https://github.com/ScrollPrize/villa.git "$VILLA_DIR"
fi

# --- spiral-fitting deps ---
pushd "$VILLA_DIR/spiral-fitting" >/dev/null
uv sync
# Pick the torch build matching the box's CUDA version by hand the first time —
# do not blindly trust this default; confirm against `nvidia-smi`.
uv pip install torch torchvision
uv pip install -e ../volume-cartographer
popd >/dev/null

# --- vesuvius (ink inference) deps ---
pushd "$VILLA_DIR/vesuvius" >/dev/null
uv sync --extra models
uv run --extra models python -c "import torch; print(torch.__version__, '| cuda:', torch.cuda.is_available())"
popd >/dev/null

echo "setup done — confirm the torch/cuda print above shows cuda: True before continuing."
