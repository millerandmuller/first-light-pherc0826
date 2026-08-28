import numpy as np
import tifffile
from PIL import Image, ImageDraw

BASE = "/workspace/vesuvius-first-light/runbook/out/PHerc0826/window1-full/predictions"
OUT = "/workspace/vesuvius-first-light/analysis/target-PHerc0826-window1-full-w010-065"
CONTROL_TIF = "/workspace/vesuvius-first-light/analysis/control-PHerc0139/control_prediction.tif"
NATIVE_UM_PER_PX = 9.362
TILE = 500  # px, ~4.68mm -- identical for every tile, same physical scale (both renders are native scale=1)

fwd = tifffile.imread(f"{BASE}/segment.tif")
control = tifffile.imread(CONTROL_TIF)


def rescale(arr):
    f = arr.astype(np.float64) / 255.0
    f = np.clip((f - 0.25) / 0.5, 0, 1)
    return (f * 255).astype(np.uint8)


def crop_centered(img, center_r, center_c, size=TILE):
    h, w = img.shape
    r0 = max(0, min(h - size, center_r - size // 2))
    c0 = max(0, min(w - size, center_c - size // 2))
    return img[r0:r0 + size, c0:c0 + size], r0, c0


tiles = []

# 1. control letterform region (computed: densest 500px ink window, see analysis log)
crop, r0, c0 = crop_centered(control, 2305, 2549)
tiles.append(("control", crop, f"PHerc0139/w035, rows {r0}-{r0+TILE}, cols {c0}-{c0+TILE}"))

# 2. candidate 458 neighborhood (row 1706-1736, col 65410-65469)
crop, r0, c0 = crop_centered(fwd, (1706 + 1736) // 2, (65410 + 65469) // 2)
tiles.append(("target: candidate 458", crop, f"forward, rows {r0}-{r0+TILE}, cols {c0}-{c0+TILE}"))

# 3. vertical-band artifact -- component 17 (row 372-564, col 354560-354570), per Lutfiya's
#    determination reviewing the raw report -- labeled as she directed, not this agent's own call
crop, r0, c0 = crop_centered(fwd, (372 + 564) // 2, (354560 + 354570) // 2)
tiles.append(("target: excluded artifact (component 17)", crop, f"forward, rows {r0}-{r0+TILE}, cols {c0}-{c0+TILE}"))

# 4. plain-texture patch, away from all 9 candidates (nearest candidate column is >100k px away)
crop, r0, c0 = crop_centered(fwd, 2280, 150000)
tiles.append(("target: plain texture (no candidate)", crop, f"forward, rows {r0}-{r0+TILE}, cols {c0}-{c0+TILE}"))

gap = 16
n = len(tiles)
canvas_w = TILE * n + gap * (n - 1)
scale_bar_row_h = 24
caption_row_h = 16
canvas_h = TILE + scale_bar_row_h + caption_row_h
canvas = Image.new("RGB", (canvas_w, canvas_h), (30, 30, 30))
draw = ImageDraw.Draw(canvas)

px_per_cm = 10000 / NATIVE_UM_PER_PX  # native scale=1 for both control and target renders
px_per_2mm = px_per_cm / 5

x = 0
for label, crop, sub in tiles:
    tile_img = Image.fromarray(rescale(crop)).convert("RGB")
    canvas.paste(tile_img, (x, 0))
    draw.rectangle([x, 0, x + TILE, 14], fill=(0, 0, 0))
    draw.text((x + 3, 1), label, fill=(255, 255, 0))
    draw.rectangle([x, TILE - 12, x + TILE, TILE], fill=(0, 0, 0))
    draw.text((x + 3, TILE - 11), sub, fill=(150, 150, 150))
    bar_len = int(px_per_2mm)
    y = TILE + 12
    draw.line([(x + 5, y), (x + 5 + bar_len, y)], fill=(255, 255, 0), width=3)
    draw.text((x + 5 + bar_len + 8, y - 6), "2mm", fill=(255, 255, 0))
    x += TILE + gap

draw.text((5, TILE + scale_bar_row_h + 1),
          "all tiles: identical native scale (9.362um/px), identical (p-0.25)/0.5 normalization",
          fill=(200, 200, 200))
canvas.save(f"{OUT}/same_scale_comparison.png")
print("wrote same_scale_comparison.png", canvas.size)
