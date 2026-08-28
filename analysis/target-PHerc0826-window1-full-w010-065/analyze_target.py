import sys
import json
import numpy as np
import tifffile
from scipy import ndimage

BASE = "/workspace/vesuvius-first-light/runbook/out/PHerc0826/window1-full/predictions"
THRESHOLD = 0.7843  # forward-direction median-ink calibration value, prereg/readout.md
NATIVE_UM_PER_PX = 9.362
FLOOR_PX = 0.5 * 1000 / NATIVE_UM_PER_PX  # 0.5mm floor in px at native res

fwd = tifffile.imread(f"{BASE}/segment.tif")
rev = tifffile.imread(f"{BASE}/segment_reverse.tif")
print("fwd shape/dtype", fwd.shape, fwd.dtype, "min/max", fwd.min(), fwd.max())
print("rev shape/dtype", rev.shape, rev.dtype, "min/max", rev.min(), rev.max())
assert fwd.shape == rev.shape

fwdf = fwd.astype(np.float64) / 255.0 if fwd.dtype == np.uint8 else fwd.astype(np.float64)
revf = rev.astype(np.float64) / 255.0 if rev.dtype == np.uint8 else rev.astype(np.float64)

mask_fwd = fwdf >= THRESHOLD
mask_rev = revf >= THRESHOLD
mask_both = mask_fwd & mask_rev

print(f"\nTHRESHOLD = {THRESHOLD}")
print(f"pixels >= threshold, forward:  {mask_fwd.sum()} ({100*mask_fwd.mean():.4f}%)")
print(f"pixels >= threshold, reverse:  {mask_rev.sum()} ({100*mask_rev.mean():.4f}%)")
print(f"pixels >= threshold, BOTH (co-located): {mask_both.sum()} ({100*mask_both.mean():.4f}%)")
print(f"0.5mm floor = {FLOOR_PX:.2f}px at {NATIVE_UM_PER_PX}um/px native resolution")

def analyze(mask, name):
    labeled, n = ndimage.label(mask, structure=np.ones((3, 3)))  # 8-connectivity
    print(f"\n=== {name}: {n} connected components (8-connectivity) ===")
    results = []
    if n == 0:
        return results
    objs = ndimage.find_objects(labeled)
    for i, sl in enumerate(objs, start=1):
        if sl is None:
            continue
        row_slice, col_slice = sl
        h = row_slice.stop - row_slice.start
        w = col_slice.stop - col_slice.start
        long_axis = max(h, w)
        short_axis = min(h, w)
        area = int((labeled[sl] == i).sum())
        results.append({
            "component_id": i,
            "row_range": [int(row_slice.start), int(row_slice.stop)],
            "col_range": [int(col_slice.start), int(col_slice.stop)],
            "bbox_h_px": int(h),
            "bbox_w_px": int(w),
            "long_axis_px": int(long_axis),
            "short_axis_px": int(short_axis),
            "long_axis_mm": round(long_axis * NATIVE_UM_PER_PX / 1000, 3),
            "aspect_ratio": round(long_axis / max(short_axis, 1), 2),
            "area_px": area,
            "passes_size_floor": bool(long_axis >= FLOOR_PX),
        })
    n_pass = sum(1 for r in results if r["passes_size_floor"])
    print(f"  {n_pass} of {n} components have long_axis >= {FLOOR_PX:.1f}px (0.5mm floor)")
    return results

res_fwd = analyze(mask_fwd, "forward-only (>= threshold)")
res_rev = analyze(mask_rev, "reverse-only (>= threshold)")
res_both = analyze(mask_both, "BOTH directions co-located (>= threshold in both)")

passing_both = [r for r in res_both if r["passes_size_floor"]]
print(f"\n=== FULL MECHANICAL PASS (threshold + both-direction co-location + >=0.5mm/53px floor) ===")
print(f"{len(passing_both)} components")
for r in sorted(passing_both, key=lambda r: -r["area_px"]):
    print(json.dumps(r))

out = {
    "threshold": THRESHOLD,
    "native_um_per_px": NATIVE_UM_PER_PX,
    "floor_px": round(FLOOR_PX, 2),
    "image_shape": list(fwd.shape),
    "pixels_ge_threshold_forward": int(mask_fwd.sum()),
    "pixels_ge_threshold_reverse": int(mask_rev.sum()),
    "pixels_ge_threshold_both": int(mask_both.sum()),
    "components_forward_only": res_fwd,
    "components_reverse_only": res_rev,
    "components_both_colocated": res_both,
    "full_mechanical_pass": passing_both,
}
with open(f"{BASE}/mechanical_analysis.json", "w") as f:
    json.dump(out, f, indent=2)
print(f"\nwrote {BASE}/mechanical_analysis.json")
