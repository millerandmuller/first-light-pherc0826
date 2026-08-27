#!/usr/bin/env bash
# F2 — environment setup on the rented GPU box.
# Source: https://scrollprize.org/tutorial_spiral (spiral-fitting deps),
#         https://scrollprize.substack.com/p/from-ct-scan-to-ancient-text-a-first (vesuvius/models extra)
# RUN for real 2026-08-27 (round terminal) on first-light-pherc0826 (RunPod
# EU-RO-1, RTX PRO 4500, template "PyTorch 2.8.0 (cu128)"). Both uv envs
# resolved and ran (torch 2.11.0+cu128 / triton 3.6.0 for spiral-fitting;
# torch 2.12.1+cu130 / triton 3.7.1 for vesuvius[models]) only after the
# system packages below were installed by hand — this script did not
# originally include them.
#
# Fix (round terminal, 2026-08-27, real box): villa/volume-cartographer's
# CMake build (a dependency of both spiral-fitting's editable install and
# vesuvius[models]) needs 10 system libraries this RunPod template doesn't
# ship. Each failure was reproduced live, one CMake error at a time, in this
# exact order: Ceres -> OpenCV -> nlohmann_json -> CURL/TIFF/ZLIB (all found
# together once curl/tiff/zlib-dev were present) -> Blosc. Install all of
# them up front on a fresh box:
#   apt-get update
#   apt-get install -y \
#     libceres-dev libopencv-dev nlohmann-json3-dev libcurl4-openssl-dev \
#     libtiff-dev zlib1g-dev libzstd-dev liblz4-dev libcgal-dev libblosc-dev
#
# Also confirmed live: `docker` is not installed on this pod (`command not
# found`) — RunPod's Secure Cloud pods do not have Docker available inside
# them. This contradicts 02_provision_manual.md Section 4's assumption
# ("docker pull ghcr.io/.../volume-cartographer:stable") for on-pod use.
# volume-cartographer was instead built natively via `uv sync` /
# `uv pip install -e`, which works once the apt packages above are present.
# The container image may still be the right path for running VC3D's GUI
# from a machine that DOES have Docker (e.g. a local workstation) — this
# finding is specifically about doing it on the rented pod itself.
set -euo pipefail

VILLA_DIR="${VILLA_DIR:-villa}"

if [ ! -d "$VILLA_DIR" ]; then
  git clone https://github.com/ScrollPrize/villa.git "$VILLA_DIR"
fi

# --- system deps for volume-cartographer's CMake build (see header) ---
apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install -y \
  libceres-dev libopencv-dev nlohmann-json3-dev libcurl4-openssl-dev \
  libtiff-dev zlib1g-dev libzstd-dev liblz4-dev libcgal-dev libblosc-dev

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
