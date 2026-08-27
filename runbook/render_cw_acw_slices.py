#!/usr/bin/env python
"""
Render three labeled axial slices of PHerc0826 for a CW/ACW spiral-winding
read, as an alternative to opening VC3D. Round terminal, 2026-08-27.

Reads the volume zarr directly from the open-data S3 bucket (anonymous,
via s3fs) at a downsampled pyramid level, marks the umbilicus point
(interpolated from the verified umbilicus.json) on each slice, and prints
the assumed viewing convention directly on the image so the convention is
never separated from the picture it was read against.

Usage: uv run python render_cw_acw_slices.py
(run from villa/spiral-fitting, whose venv has zarr/s3fs/matplotlib)
"""
import json
import warnings

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import s3fs
import zarr

warnings.filterwarnings("ignore")

VOLUME_PATH = "vesuvius-challenge-open-data/PHerc0826/volumes/20250821151701-9.362um-1.2m-113keV-masked.zarr"
UMBILICUS_PATH = "/workspace/vesuvius-first-light/spiral_datasets/PHerc0826/20250821151701/umbilicus.json"
OUT_DIR = "/workspace/vesuvius-first-light/renders_tmp"
PYRAMID_LEVEL = "2"  # scale factor 4x per the zarr's own multiscales metadata
TARGET_Z_FULLRES = [5000, 9000, 13000]

CONVENTION_TEXT = (
    "Convention (round terminal, 2026-08-27, GAP not documented by villa/D-33): "
    "viewed looking along +z; +x right, +y down (native array orientation, "
    "row=y col=x, no flip applied). This is an assumption, not a villa-confirmed "
    "frame -- validate empirically against the first fit's spiral tracks."
)


def load_umbilicus_xy(z_target):
    doc = json.load(open(UMBILICUS_PATH))
    pts = sorted(doc["control_points"], key=lambda p: p["z"])
    zs = [p["z"] for p in pts]
    if z_target <= zs[0]:
        p = pts[0]
        return p["x"], p["y"]
    if z_target >= zs[-1]:
        p = pts[-1]
        return p["x"], p["y"]
    for i in range(len(pts) - 1):
        z0, z1 = pts[i]["z"], pts[i + 1]["z"]
        if z0 <= z_target <= z1:
            t = (z_target - z0) / (z1 - z0) if z1 != z0 else 0.0
            x = pts[i]["x"] + t * (pts[i + 1]["x"] - pts[i]["x"])
            y = pts[i]["y"] + t * (pts[i + 1]["y"] - pts[i]["y"])
            return x, y
    raise RuntimeError(f"z={z_target} not bracketed (range {zs[0]}-{zs[-1]})")


def main():
    import os

    os.makedirs(OUT_DIR, exist_ok=True)

    fs = s3fs.S3FileSystem(anon=True)
    store = zarr.storage.FsspecStore(fs, path=VOLUME_PATH)
    group = zarr.open_group(store=store, mode="r")
    arr = group[PYRAMID_LEVEL]
    scale = 4  # level "2" == 4x downsample per multiscales coordinateTransformations
    print(f"level {PYRAMID_LEVEL} shape={arr.shape} dtype={arr.dtype} scale={scale}x")

    saved = []
    for z_full in TARGET_Z_FULLRES:
        z_idx = round(z_full / scale)
        z_idx = max(0, min(arr.shape[0] - 1, z_idx))
        print(f"reading slice z_full={z_full} -> level{PYRAMID_LEVEL} z_idx={z_idx} ...")
        slab = np.asarray(arr[z_idx, :, :])

        ux_full, uy_full = load_umbilicus_xy(z_full)
        ux, uy = ux_full / scale, uy_full / scale

        lo, hi = np.percentile(slab, [1, 99])
        disp = np.clip((slab.astype(np.float32) - lo) / max(hi - lo, 1), 0, 1)

        fig, ax = plt.subplots(figsize=(9, 10.5), dpi=150)
        ax.imshow(disp, cmap="gray", origin="upper")
        ax.plot(ux, uy, marker="+", color="red", markersize=22, markeredgewidth=2.5)
        ax.plot(ux, uy, marker="o", color="red", markersize=10, markerfacecolor="none", markeredgewidth=2)
        ax.annotate(
            f"umbilicus (interpolated)\nz_full={z_full}  x={ux_full:.0f} y={uy_full:.0f}",
            xy=(ux, uy), xytext=(ux + 60, uy - 60), color="red", fontsize=9,
            arrowprops=dict(arrowstyle="->", color="red"),
        )
        ax.set_title(
            f"PHerc0826  |  full-res z={z_full}  |  level {PYRAMID_LEVEL} "
            f"(x{scale} downsample)  |  z_idx={z_idx}",
            fontsize=11,
        )
        ax.set_xlabel("x (right ->)")
        ax.set_ylabel("y (down v)")
        fig.text(0.02, 0.01, CONVENTION_TEXT, fontsize=7, wrap=True, va="bottom")
        fig.tight_layout(rect=[0, 0.045, 1, 1])

        out_path = f"{OUT_DIR}/PHerc0826_z{z_full}_level{PYRAMID_LEVEL}.png"
        fig.savefig(out_path)
        plt.close(fig)
        saved.append(out_path)
        print(f"saved {out_path}")

    print("DONE:", saved)


if __name__ == "__main__":
    main()
