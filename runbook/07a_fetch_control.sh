#!/usr/bin/env bash
# F6 (part 0) — fetch the positive control segment's published tifxyz mesh
# and ground-truth ink labels from the HF bucket (D-38's confirmed location:
# huggingface.co/buckets/scrollprize/datasets/tree/ink/<scroll-id>/<segment>).
#
# Separate, explicit step from 07_controls.sh on purpose: which segment to
# use as the control is a domain decision (see 07_controls.sh's own header),
# and the bucket's `ink/` tree is ~804 GB total across all its scrolls (per
# the fact package) — this fetches only the six files this pipeline actually
# needs (the tifxyz mesh + the two ground-truth label tifs), never the
# pre-extracted surface-volume zarr (tens of thousands of chunk files under
# <segment>.zarr/, not needed since 07_controls.sh re-renders the control
# volume itself via vc_render_tifxyz --remote-url, same as the target
# pipeline) or other researchers' preds/ outputs (their own model runs).
#
# Requires: HF auth (huggingface_hub reads its token from HF_HOME's cache
# file; `hf auth login` sets this up — see logs/README.md's own convention
# for who runs auth, not this script).
set -euo pipefail

: "${CONTROL_HF_SCROLL:?e.g. 0139 (bucket path segment, no PHerc prefix)}"
: "${CONTROL_HF_SEGMENT:?e.g. w035_2026031718}"

DEST_DIR="$(pwd)/spiral_datasets/PHerc${CONTROL_HF_SCROLL}/${CONTROL_HF_SEGMENT}"
mkdir -p "$DEST_DIR"

uv run --with huggingface_hub python3 - "$CONTROL_HF_SCROLL" "$CONTROL_HF_SEGMENT" "$DEST_DIR" <<'PY'
import sys
from huggingface_hub import HfApi

scroll, segment, dest = sys.argv[1], sys.argv[2], sys.argv[3]
base = f"ink/{scroll}/{segment}"
wanted = [
    f"{base}/meta.json",
    f"{base}/x.tif",
    f"{base}/y.tif",
    f"{base}/z.tif",
    f"{base}/{segment}_inklabels.tif",
    f"{base}/{segment}_supervision_mask.tif",
]
pairs = [(p, f"{dest}/{p.rsplit('/', 1)[-1]}") for p in wanted]

api = HfApi()
print(f"downloading {len(pairs)} files from bucket scrollprize/datasets ({base}/) to {dest}")
api.download_bucket_files(bucket_id="scrollprize/datasets", files=pairs, raise_on_missing_files=True)
for _, local in pairs:
    import os
    print(f"  {local}  ({os.path.getsize(local)} bytes)")
PY

echo "control segment tifxyz + ground truth staged at: $DEST_DIR"
echo "set CONTROL_SEGMENT=$DEST_DIR before running runbook/07_controls.sh"
