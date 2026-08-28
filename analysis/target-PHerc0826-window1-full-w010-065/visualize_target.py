import json
import numpy as np
import tifffile
from PIL import Image, ImageDraw

BASE = "/workspace/vesuvius-first-light/runbook/out/PHerc0826/window1-full/predictions"
ANALYSIS_DIR = "/workspace/vesuvius-first-light/analysis/target-PHerc0826-window1-full-w010-065"
CONTROL_TIF = "/workspace/vesuvius-first-light/analysis/control-PHerc0139/control_prediction.tif"
NATIVE_UM_PER_PX = 9.362
PX_PER_CM = 10000 / NATIVE_UM_PER_PX  # scale=1 (native), 1cm = 1068px

import os
os.makedirs(ANALYSIS_DIR, exist_ok=True)

with open(f"{BASE}/mechanical_analysis.json") as f:
    analysis = json.load(f)

fwd = tifffile.imread(f"{BASE}/segment.tif")
rev = tifffile.imread(f"{BASE}/segment_reverse.tif")


def rescale(arr):
    f = arr.astype(np.float64) / 255.0
    f = np.clip((f - 0.25) / 0.5, 0, 1)
    return (f * 255).astype(np.uint8)


def draw_scale_bar(img_arr, px_per_cm, label_mm_text):
    im = Image.fromarray(img_arr).convert("RGB")
    draw = ImageDraw.Draw(im)
    bar_len = min(int(px_per_cm), im.width - 10)
    y = im.height - 8
    draw.line([(5, y), (5 + bar_len, y)], fill=(255, 255, 0), width=3)
    draw.text((5, y - 12), "1 cm", fill=(255, 255, 0))
    if label_mm_text:
        draw.text((5, 2), label_mm_text, fill=(255, 255, 0))
    return im


# --- Full-width overview (heavily downscaled, coverage context only) ---
fwd_r = rescale(fwd)
rev_r = rescale(rev)
ov_fwd = Image.fromarray(fwd_r).resize((3000, max(1, fwd_r.shape[0] * 3000 // fwd_r.shape[1])))
ov_rev = Image.fromarray(rev_r).resize((3000, max(1, rev_r.shape[0] * 3000 // rev_r.shape[1])))
gap = Image.new("L", (3000, 10), 255)
overview = Image.new("L", (3000, ov_fwd.height + 10 + ov_rev.height))
overview.paste(ov_fwd, (0, 0))
overview.paste(gap, (0, ov_fwd.height))
overview.paste(ov_rev, (0, ov_fwd.height + 10))
overview.save(f"{ANALYSIS_DIR}/overview_forward_over_reverse.png")
print("wrote overview_forward_over_reverse.png", overview.size)

# --- Per-candidate crops, both directions (forward | forward+bbox | reverse) ---
PAD = 80
for comp in analysis["full_mechanical_pass"]:
    cid = comp["component_id"]
    r0, r1 = comp["row_range"]
    c0, c1 = comp["col_range"]
    rr0, rr1 = max(0, r0 - PAD), min(fwd.shape[0], r1 + PAD)
    cc0, cc1 = max(0, c0 - PAD), min(fwd.shape[1], c1 + PAD)

    crop_fwd = rescale(fwd[rr0:rr1, cc0:cc1])
    crop_rev = rescale(rev[rr0:rr1, cc0:cc1])

    # mark the component's bbox in red on a copy of forward
    fwd_marked = np.stack([crop_fwd] * 3, axis=-1)
    bb_r0, bb_r1 = r0 - rr0, r1 - rr0
    bb_c0, bb_c1 = c0 - cc0, c1 - cc0
    fwd_marked[max(0, bb_r0 - 1):bb_r0 + 1, bb_c0:bb_c1] = [255, 0, 0]
    fwd_marked[bb_r1 - 1:bb_r1 + 1, bb_c0:bb_c1] = [255, 0, 0]
    fwd_marked[bb_r0:bb_r1, max(0, bb_c0 - 1):bb_c0 + 1] = [255, 0, 0]
    fwd_marked[bb_r0:bb_r1, bb_c1 - 1:bb_c1 + 1] = [255, 0, 0]

    panel_fwd = Image.fromarray(crop_fwd).convert("RGB")
    panel_marked = Image.fromarray(fwd_marked)
    panel_rev = Image.fromarray(crop_rev).convert("RGB")
    gap12 = 12
    combo_w = panel_fwd.width * 3 + gap12 * 2
    combo = Image.new("RGB", (combo_w, panel_fwd.height), (255, 255, 255))
    x = 0
    for panel in [panel_fwd, panel_marked, panel_rev]:
        combo.paste(panel, (x, 0))
        x += panel.width + gap12

    draw = ImageDraw.Draw(combo)
    draw.text((5, 2), "forward", fill=(255, 255, 0))
    draw.text((panel_fwd.width + gap12 + 5, 2), "forward+bbox", fill=(255, 255, 0))
    draw.text((2 * (panel_fwd.width + gap12) + 5, 2), "reverse", fill=(255, 255, 0))
    bar_len = int(PX_PER_CM)
    if bar_len < combo_w - 20:
        y = combo.height - 8
        draw.line([(5, y), (5 + bar_len, y)], fill=(255, 255, 0), width=2)
        draw.text((5, y - 12), "1cm", fill=(255, 255, 0))

    fname = f"{ANALYSIS_DIR}/candidate_{cid:04d}_row{r0}-{r1}_col{c0}-{c1}.png"
    combo.save(fname)
    print("wrote", fname, combo.size)

# --- Overview side-by-side with control (control labeled "control"), same normalization ---
control = tifffile.imread(CONTROL_TIF)
control_r = rescale(control)
ctrl_thumb = Image.fromarray(control_r).resize((1400, max(1, control_r.shape[0] * 1400 // control_r.shape[1])))

target_stack = Image.open(f"{ANALYSIS_DIR}/overview_forward_over_reverse.png").convert("RGB")
ctrl_panel = ctrl_thumb.convert("RGB")
h = max(target_stack.height, ctrl_panel.height)
sbs = Image.new("RGB", (target_stack.width + 20 + ctrl_panel.width, h), (255, 255, 255))
sbs.paste(target_stack, (0, 0))
sbs.paste(ctrl_panel, (target_stack.width + 20, 0))
draw = ImageDraw.Draw(sbs)
draw.text((5, 2), "target: PHerc0826 window1-full w010-w065, forward (top) / reverse (bottom)", fill=(255, 0, 0))
draw.text((target_stack.width + 25, 2), "control (PHerc0139/w035, forward)", fill=(255, 0, 0))
sbs.save(f"{ANALYSIS_DIR}/target_vs_control_side_by_side.png")
print("wrote target_vs_control_side_by_side.png", sbs.size)

print("done")
