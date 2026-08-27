<!--
Mirrors villa/.github/pull_request_template.md verbatim (fetched 2026-08-23).
Facts and diff below are filled in by the round terminal (technical content
only, cite-or-GAP, all verified live against villa commit 6847063 on
first-light-pherc0826). The prose fields marked TODO(human) are NOT filled
in — motivation prose, "why useful", and the final PR description stay
strictly human-written per CONTRIBUTING.md (D-15) and the project's own
working agreement. This is a bugfix/feature PR — CONTRIBUTING's screenshot
gate (D-13) applies: before-failure and after-success terminal captures are
both included below, both real, both against the same real data.
-->

**In one sentence:** TODO(human)

**One real example:** Running `render_ink.py` against a real spiral-fit
mesh output (PHerc0826, villa commit `6847063`) with `--volume` pointing at
a scroll that only exists on S3 fails immediately — `render_ink.py` has no
way to tell its internal `vc_render_tifxyz` call the remote URL, even
though `vc_render_tifxyz` itself supports exactly this via its own
`--remote-url` flag (used in `scrollprize.org`'s own `tutorial5.md` worked
example).

**Before:** `render_ink.py --volume <s3-url-or-empty-local-dir>` (no other
option exists for pointing it at a remote volume) fails at its internal
render step:
```
Error opening local zarr: filesystem error: directory iterator cannot open
directory: No such file or directory
[s3://vesuvius-challenge-open-data/PHerc0826/volumes/20250821151701-9.362um-1.2m-113keV-masked.zarr]
```
(Full traceback: `render_ink.py:522` → `subprocess.run(..., check=True)` →
`CalledProcessError`, reproduced live 2026-08-27,
`logs/f4_test.log`.) The concat+flatten stages before this point succeed
fine — only the final ink-render step, which needs the volume, fails.

**After this PR:** A new `--remote-url` option, passed straight through to
`vc_render_tifxyz`'s own `--remote-url` flag (only when set — omitting it
preserves the exact current behavior/failure mode for local-only volumes).
Same command, `--remote-url` added, real S3 volume, same real mesh — ran to
completion for the first time (`logs/render_ink_patch_after.log`, real,
captured 2026-08-27):

```
trim grid 68677x245 -> 68675x243 (rect c=1+68675 r=1+243)
wrote trimmed segment to ".../meshes/fitted/concat/w010-129_flat"
Remote zarr streaming: s3://vesuvius-challenge-open-data/PHerc0826/volumes/20250821151701-9.362um-1.2m-113keV-masked.zarr/
zarr dataset size for group 1 [8460 4085 4085 ]
Rendering: .../concat/w010-129_flat -> .../concat/w010-129_flat/ink (tif)
rendering 171687x607 at scale 0.25 crop [171687×607 from (0,0)]
[1/1] wrote 11 tiles w010-129_flat.000-010.jpg (171687px wide total, p95=134.0)
Done. Strips in .../meshes/fitted/ink
```
Exit 0. Pulled one output tile (`w010-129_flat.001.jpg`) and inspected it
directly: real, legible flattened-surface texture, not blank or corrupted.

**Proof:** see Before/After above — both real terminal captures, same
input mesh (`meshes/fitted` from the 1,500-step CW comparison fit on
PHerc0826), same villa commit, same box (`first-light-pherc0826`). Total
wall-clock for the full concat→flatten→trim→render→composite pipeline with
the fix: ~7 minutes (flatten 3m57s + trim + render ~1m + concat/setup).

**Why / where this is useful:** TODO(human)

- [x] I personally verified that the example and proof above were produced
      by this PR on the stated data. (Round terminal, 2026-08-27, real box
      `first-light-pherc0826` — both before and after evidence captured
      live, after-test exit 0, output tile inspected directly.)

## Details

**Method:** villa commit `6847063ffdb4da898ae8d1d494ebf7d71473f509`
(2026-08-26 21:25 CEST). RunPod EU-RO-1, RTX PRO 4500 32GB. Mesh:
`runbook/out/PHerc0826/window1/spiral-fit/2026-08-27_PHerc0826_slice-10000-11000_0-patch/meshes/fitted`
(from the project's own 1,500-step CW comparison fit). Volume:
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

---
### Internal checklist (not part of the upstream PR — delete before submitting)
- [x] Error screenshot attached (terminal or in-tool) — before/after
      terminal captures above (D-13)
- [x] Demonstrated on real scroll data, not synthetic/toy (D-14)
- [x] LLM-assisted diagnosis and fix — human-written commentary required
      (D-15): motivation prose above (TODO(human)) is that commentary
- [x] Candidate wall-log entry: `logs/` (E5) — raw logs at
      `logs/f4_test.log` (before) and `logs/render_ink_patch_after.log`
      (after, exit 0); human TIL prose still needed
- [ ] Linked from `README.md` PR list once opened
- [x] After-evidence filled in for real (patch test completed, exit 0,
      output tile visually confirmed) — ready to open
