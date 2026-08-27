#!/usr/bin/env python
"""
Overlay the fitted spiral mesh's z=10500 cross-section on the real axial
slice, for both the CW and ACW fit runs, so the visible papyrus wraps can be
compared directly against each fit's actual output geometry -- not a loss
number, not a random-hue track scatter. Round terminal, 2026-08-27.

z=10500 (not 9000/5000/13000) because both fits' meshes are hard-clipped to
their z_begin/z_end ROI [10000, 11000) -- confirmed by reading every
winding's z.tif range directly before writing this script, not assumed.
"""
import glob
import json
import warnings

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import s3fs
import tifffile
import zarr

warnings.filterwarnings("ignore")

VOLUME_PATH = "vesuvius-challenge-open-data/PHerc0826/volumes/20250821151701-9.362um-1.2m-113keV-masked.zarr"
UMBILICUS_PATH = "/workspace/vesuvius-first-light/spiral_datasets/PHerc0826/20250821151701/umbilicus.json"
OUT_DIR = "/workspace/vesuvius-first-light/renders_tmp"
PYRAMID_LEVEL = "2"
SCALE = 4  # level 2 == 4x downsample
TARGET_Z = 10500

RUNS = {
    "CW": "/workspace/vesuvius-first-light/runbook/out/PHerc0826/window1/spiral-fit/2026-08-27_PHerc0826_slice-10000-11000_0-patch/meshes/fitted",
    "ACW": "/workspace/vesuvius-first-light/runbook/out/PHerc0826/window1-ACW/spiral-fit/2026-08-27_PHerc0826_slice-10000-11000_0-patch/meshes/fitted",
}

CONVENTION_TEXT = (
    "Convention (round terminal, 2026-08-27): viewed looking along +z; +x right, +y down "
    "(native array orientation, no flip). Curve = fitted spiral mesh's z=10500 cross-section, "
    "colour = winding index. Umbilicus marked with an open circle + offset crosshair "
    "(not a solid cross -- avoids occluding the innermost termination, per the earlier read failure)."
)


def load_umbilicus_xy(z_target):
    doc = json.load(open(UMBILICUS_PATH))
    pts = sorted(doc["control_points"], key=lambda p: p["z"])
    zs = np.array([p["z"] for p in pts], dtype=np.float64)
    xs = np.array([p["x"] for p in pts], dtype=np.float64)
    ys = np.array([p["y"] for p in pts], dtype=np.float64)
    return float(np.interp(z_target, zs, xs)), float(np.interp(z_target, zs, ys))


def mesh_curve_at_z(meshes_dir, target_z):
    winding_dirs = sorted(
        d for d in glob.glob(f"{meshes_dir}/w*")
        if "_spliced" not in d
    )
    points = []  # (x, y, winding_idx)
    for wdir in winding_dirs:
        widx = int(wdir.split("/")[-1].lstrip("w"))
        z = tifffile.imread(f"{wdir}/z.tif")
        x = tifffile.imread(f"{wdir}/x.tif")
        y = tifffile.imread(f"{wdir}/y.tif")
        for col in range(z.shape[1]):
            zc = z[:, col]
            valid = zc > -1
            if valid.sum() < 2:
                continue
            zc_v = zc[valid]
            order = np.argsort(zc_v)
            zc_sorted = zc_v[order]
            if not (zc_sorted[0] <= target_z <= zc_sorted[-1]):
                continue
            xc_sorted = x[:, col][valid][order]
            yc_sorted = y[:, col][valid][order]
            xi = np.interp(target_z, zc_sorted, xc_sorted)
            yi = np.interp(target_z, zc_sorted, yc_sorted)
            points.append((xi, yi, widx))
    return np.array(points) if points else np.empty((0, 3))


def render_base_slice():
    fs = s3fs.S3FileSystem(anon=True)
    store = zarr.storage.FsspecStore(fs, path=VOLUME_PATH)
    group = zarr.open_group(store=store, mode="r")
    arr = group[PYRAMID_LEVEL]
    z_idx = round(TARGET_Z / SCALE)
    z_idx = max(0, min(arr.shape[0] - 1, z_idx))
    slab = np.asarray(arr[z_idx, :, :])
    lo, hi = np.percentile(slab, [1, 99])
    disp = np.clip((slab.astype(np.float32) - lo) / max(hi - lo, 1), 0, 1)
    return disp


def main():
    import os
    os.makedirs(OUT_DIR, exist_ok=True)
    base = render_base_slice()
    ux_full, uy_full = load_umbilicus_xy(TARGET_Z)
    ux, uy = ux_full / SCALE, uy_full / SCALE

    for sense, meshes_dir in RUNS.items():
        pts = mesh_curve_at_z(meshes_dir, TARGET_Z)
        print(f"{sense}: {len(pts)} curve points from mesh at z={TARGET_Z}")

        fig, ax = plt.subplots(figsize=(9, 10.5), dpi=150)
        ax.imshow(base, cmap="gray", origin="upper")
        if len(pts):
            xs, ys, widx = pts[:, 0] / SCALE, pts[:, 1] / SCALE, pts[:, 2]
            sc = ax.scatter(xs, ys, c=widx, cmap="hsv", s=3, linewidths=0)
            cbar = fig.colorbar(sc, ax=ax, fraction=0.03, pad=0.02)
            cbar.set_label("winding index")
        # umbilicus: open circle + offset crosshair, not a solid cross over the center
        ax.plot(ux, uy, marker="o", color="red", markersize=14,
                 markerfacecolor="none", markeredgewidth=2)
        ax.plot([ux - 25, ux - 12], [uy, uy], color="red", linewidth=1.5)
        ax.plot([ux + 12, ux + 25], [uy, uy], color="red", linewidth=1.5)
        ax.plot([ux, ux], [uy - 25, uy - 12], color="red", linewidth=1.5)
        ax.plot([ux, ux], [uy + 12, uy + 25], color="red", linewidth=1.5)
        ax.set_title(
            f"PHerc0826  |  z={TARGET_Z}  |  spiral_outward_sense = {sense}  |  "
            f"fitted mesh cross-section over real slice",
            fontsize=11,
        )
        ax.set_xlabel("x (right ->)")
        ax.set_ylabel("y (down v)")
        fig.text(0.02, 0.01, CONVENTION_TEXT, fontsize=6.5, wrap=True, va="bottom")
        fig.tight_layout(rect=[0, 0.05, 1, 1])
        out_path = f"{OUT_DIR}/mesh_overlay_z{TARGET_Z}_{sense}.png"
        fig.savefig(out_path)
        plt.close(fig)
        print(f"saved {out_path}")


if __name__ == "__main__":
    main()
