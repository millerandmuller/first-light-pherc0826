import sys
import numpy as np
import tifffile
from PIL import Image, ImageDraw

BASE = "/workspace/vesuvius-first-light/runbook/out/PHerc0826/window1-full/predictions"
OUT = "/workspace/vesuvius-first-light/analysis/target-PHerc0826-window1-full-w010-065"
NATIVE_UM_PER_PX = 9.362
N = 13
DISPLAY_WIDTH = 3200
SEP_PX = 4


def rescale(arr):
    f = arr.astype(np.float64) / 255.0
    f = np.clip((f - 0.25) / 0.5, 0, 1)
    return (f * 255).astype(np.uint8)


def build_slab(path, direction_label, out_name):
    img = tifffile.imread(path)
    h, w = img.shape
    row_w = w // N
    disp_h = round(h * DISPLAY_WIDTH / row_w)
    v_compression = h / disp_h  # relative to true (undistorted) proportion at this display width

    rows_disp = []
    for i in range(N):
        c0 = i * row_w
        c1 = w if i == N - 1 else (i + 1) * row_w
        strip = rescale(img[:, c0:c1])
        pil = Image.fromarray(strip).resize((DISPLAY_WIDTH, disp_h), Image.BILINEAR)
        rows_disp.append((pil, c0, c1))

    total_h = N * disp_h + (N - 1) * SEP_PX
    canvas = Image.new("RGB", (DISPLAY_WIDTH, total_h + 40), (30, 30, 30))
    draw = ImageDraw.Draw(canvas)
    y = 0
    for i, (pil, c0, c1) in enumerate(rows_disp):
        canvas.paste(pil.convert("RGB"), (0, y))
        label = f"row {i+1}/{N}  (cols {c0}-{c1}, left-to-right)"
        draw.rectangle([0, y, 260, y + 12], fill=(0, 0, 0))
        draw.text((2, y), label, fill=(255, 255, 0))
        y += disp_h
        if i < N - 1:
            draw.line([(0, y), (DISPLAY_WIDTH, y)], fill=(255, 255, 255), width=SEP_PX)
            y += SEP_PX

    # effective scale after downscaling: display px -> native px -> um
    effective_um_per_px = NATIVE_UM_PER_PX * (row_w / DISPLAY_WIDTH)
    px_per_cm_display = 10000 / effective_um_per_px
    bar_y = total_h + 20
    bar_len = int(px_per_cm_display)
    draw.line([(10, bar_y), (10 + bar_len, bar_y)], fill=(255, 255, 0), width=3)
    draw.text((10, bar_y - 14), "1cm (horizontal axis only)", fill=(255, 255, 0))
    caption = (
        f"{direction_label} | native render 9.362um/px, scale=1 | "
        f"{N} rows x ~{row_w}px wide, rows top-to-bottom left-to-right | "
        f"downscaled {row_w/DISPLAY_WIDTH:.2f}x horizontal, {v_compression:.2f}x vertical "
        f"(vertically compressed ~{v_compression/(row_w/DISPLAY_WIDTH):.2f}x more than horizontal "
        f"to fit a compact overview -- NOT to true scale vertically, see same-scale comparison figure)"
    )
    draw.text((10 + bar_len + 15, bar_y - 8), caption, fill=(200, 200, 200))

    canvas.save(f"{OUT}/{out_name}")
    print(f"wrote {out_name} size={canvas.size} row_native={row_w}x{h} row_disp={DISPLAY_WIDTH}x{disp_h} "
          f"h_scale={row_w/DISPLAY_WIDTH:.3f} v_scale={h/disp_h:.3f} overall_aspect={DISPLAY_WIDTH/(total_h+40):.3f}")


build_slab(f"{BASE}/segment.tif", "forward", "slab_view_forward.png")
build_slab(f"{BASE}/segment_reverse.tif", "reverse", "slab_view_reverse.png")
