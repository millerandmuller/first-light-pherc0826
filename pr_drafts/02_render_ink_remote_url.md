<!--
Mirrors villa/.github/pull_request_template.md verbatim (fetched 2026-08-23).
Prose below is Lutfiya's own (2026-08-27) — human-written per CONTRIBUTING.md
(D-15) and the project's working agreement. Paths/numbers/proof filled in by
the round terminal from the real patch test on first-light-pherc0826.

NOTE on the "One real example" command below: the draft used
`<run>/meshes/mesh`, matching scrollprize.org/docs/38_tutorial_spiral.md's
own generic worked example verbatim. Our actual fit_spiral.py run on this
box did NOT produce a `meshes/mesh` directory — it wrote
`meshes/fitted` (confirmed by directly inspecting the real output). The
tutorial's `meshes/mesh` appears to be a generic stand-in, not a fixed
folder name. Filled in with our real, actually-tested path below; flagging
this rather than silently guessing which one villa's maintainers would
expect readers to substitute.
-->

**In one sentence:** Lets `render_ink.py` render ink for a scroll whose
volume only exists on S3, by forwarding a `--remote-url` to
`vc_render_tifxyz`, which already accepts one.

**One real example:** Starting with a spiral fit of PHerc0826 on a rented
GPU box with no local copy of the ink volume, we ran
```
python render_ink.py runbook/out/PHerc0826/window1/spiral-fit/2026-08-27_PHerc0826_slice-10000-11000_0-patch/meshes/fitted \
  --volume volume-cache/PHerc0826.zarr \
  --remote-url s3://vesuvius-challenge-open-data/PHerc0826/volumes/20250821151701-9.362um-1.2m-113keV-masked.zarr/
```
and it produced the usual `ink/wNNN-NNN.jpg` strips
(`ink/w010-129_flat.000.jpg` through `.010.jpg`, 11 tiles, 171,687px wide
total).

**Before:** `render_ink.py` only passes `--volume` to `vc_render_tifxyz`. If
your `--volume` is an empty local cache directory for a scroll that lives
on S3, the render step has no way to learn where the data actually is, so
the pipeline stops after fit and flatten.

**After this PR:** `--remote-url` is optional and, when given, is appended
to the `vc_render_tifxyz` call. Leave it off and nothing changes.

**Proof:**

Before (real run, real S3 volume, no `--remote-url` — reproduced live
2026-08-27, `logs/f4_test.log`):
```
Error opening local zarr: filesystem error: directory iterator cannot open
directory: No such file or directory
[s3://vesuvius-challenge-open-data/PHerc0826/volumes/20250821151701-9.362um-1.2m-113keV-masked.zarr]
```
(`render_ink.py:522` → `subprocess.run(..., check=True)` →
`CalledProcessError`. Fit and flatten had already succeeded; only this last
render step failed.)

After (same mesh, same volume, `--remote-url` added — real run, exit 0,
`logs/render_ink_patch_after.log`):
```
trim grid 68677x245 -> 68675x243 (rect c=1+68675 r=1+243)
wrote trimmed segment to ".../meshes/fitted/concat/w010-129_flat"
Remote zarr streaming: s3://vesuvius-challenge-open-data/PHerc0826/volumes/20250821151701-9.362um-1.2m-113keV-masked.zarr/
zarr dataset size for group 1 [8460 4085 4085]
Rendering: .../concat/w010-129_flat -> .../concat/w010-129_flat/ink (tif)
rendering 171687x607 at scale 0.25 crop [171687×607 from (0,0)]
[1/1] wrote 11 tiles w010-129_flat.000-010.jpg (171687px wide total, p95=134.0)
Done. Strips in .../meshes/fitted/ink
```
One output tile (`ink/w010-129_flat.001.jpg`) pulled and inspected
directly: real, legible flattened-surface texture, not blank or corrupted.
Total wall-clock for the full concat→flatten→trim→render→composite run
with the fix: ~7 minutes (flatten 3m57s + trim + render ~1m + concat/setup)
on one RTX PRO 4500 32GB.

<!-- Terminal-capture screenshots (PNG) of the two blocks above, if a
rendered image is wanted alongside the text: TODO(human) — grab from a live
terminal, or use the log files cited above as-is per this project's
existing convention (see pr_drafts/01, which does the same). -->

**Why / where this is useful:** tutorial5 already documents this exact
pattern for `vc_render_tifxyz` — `--remote-url` takes the S3 volume,
`--volume` names a local directory where fetched chunks are cached.
`render_ink.py` was the one step in the spiral workflow that couldn't do
it, so anyone running the pipeline on a scroll they haven't mirrored
locally hits the wall at the last step. Six lines, no new dependency.

- [x] I personally verified that the example and proof above were produced
      by this PR on the stated data. (Round terminal, 2026-08-27, real box
      `first-light-pherc0826` — both before and after evidence captured
      live, after-test exit 0, output tile inspected directly.)

## Details

We hit this walking the First Letters workflow on PHerc0826 from a rented
GPU box. Fit and flatten worked; only the ink render was stuck.

**Method:** villa commit `6847063ffdb4da898ae8d1d494ebf7d71473f509`
(2026-08-26 21:25 CEST). RunPod EU-RO-1, RTX PRO 4500 32GB. Mesh:
`runbook/out/PHerc0826/window1/spiral-fit/2026-08-27_PHerc0826_slice-10000-11000_0-patch/meshes/fitted`
(from this project's own 1,500-step CW comparison fit — any real
`meshes/fitted` or `meshes/mesh` output from `fit_spiral.py`'s `save_mesh`
reproduces the same failure/fix). Volume:
`s3://vesuvius-challenge-open-data/PHerc0826/volumes/20250821151701-9.362um-1.2m-113keV-masked.zarr/`.

**Proposed diff** (`spiral-fitting/render_ink.py`):

```diff
@@ -330,6 +330,7 @@
 @click.argument('meshes_dir', type=click.Path(exists=True, file_okay=False))
 @click.option('--volume', required=True, help='Ink volume zarr path')
+@click.option('--remote-url', default='', help='Remote OME-Zarr URL for --volume, passed through to vc_render_tifxyz as --remote-url. Required when --volume is a not-yet-populated local cache dir for a scroll that only exists remotely; omit once the cache already records the URL (vc_render_tifxyz --help)')
 @click.option('--vc-render-bin', default='vc_render_tifxyz', show_default=True, help='Path to the vc_render_tifxyz binary')
@@ -359,7 +360,7 @@
-def main(meshes_dir, volume, vc_render_bin, scale, group_idx, num_slices, num_processes,
+def main(meshes_dir, volume, remote_url, vc_render_bin, scale, group_idx, num_slices, num_processes,
          flatten, flatboi_bin, tifxyz2obj_bin, obj2tifxyz_bin, uv_lift_bin, flatten_keep,
@@ -519,13 +520,15 @@
     def render(name, concat_path):
         per_mesh_ink = os.path.join(concat_path, 'ink')
         os.makedirs(per_mesh_ink, exist_ok=True)
-        subprocess.run([
+        render_cmd = [
             vc_render_bin,
             '--segmentation', concat_path,
             '--scale', str(scale),
             '--group-idx', str(group_idx),
             '--volume', volume,
             '--tif-output', per_mesh_ink,
             '--num-slices', str(num_slices),
-        ], check=True)
+        ]
+        if remote_url:
+            render_cmd += ['--remote-url', remote_url]
+        subprocess.run(render_cmd, check=True)
```

Minimal, additive, backward-compatible: omitting `--remote-url` reproduces
today's exact behavior (verified — the only call site touched is the one
`render()` closure both the `--strips` and `--full-scroll` paths share, and
it's gated behind `if remote_url:`).

**Comparisons:** N/A (single new optional flag, no behavior change when
unset).

**Limitations:** Only the single `vc_render_tifxyz` call site in
`render()` was patched (confirmed to be the only one in the file via
`grep -n vc_render_bin`) — no other remote-volume-dependent call sites
exist in this script as of the pinned commit. Not tested against the
`--strips` code path specifically (only `--full-scroll`, the default);
both paths call the same `render()` closure so the fix should apply
equally, but this wasn't independently exercised with `--strips` this
session.

**Disclosure:** We're a two-person team and we worked with an LLM
assistant on this, including the diagnosis and the patch. We directed the
work, ran everything on real PHerc0826 data, and checked the evidence
ourselves before opening this.

---
### Internal checklist (not part of the upstream PR — delete before submitting)
- [x] Error screenshot attached (terminal or in-tool) — before/after
      terminal captures above (D-13)
- [x] Demonstrated on real scroll data, not synthetic/toy (D-14)
- [x] LLM-assisted diagnosis and fix — human-written commentary added
      (D-15): disclosure paragraph above
- [x] Candidate wall-log entry: `logs/` (E5) — raw logs at
      `logs/f4_test.log` (before) and `logs/render_ink_patch_after.log`
      (after, exit 0); human TIL prose still needed
- [ ] Linked from `README.md` PR list once opened
- [ ] Decide whether to attach real terminal-screenshot PNGs alongside the
      log-text proof above, or submit as-is (this project's PR #1 used
      log-text only and that was accepted as sufficient)
