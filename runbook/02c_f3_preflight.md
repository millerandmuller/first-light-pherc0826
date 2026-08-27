# F3 pre-flight — what `fit_spiral.py` actually requires (villa main, not the tutorial)

Read this before running `make spiral-fit`. `scrollprize.org/tutorial_spiral`
describes an older/simpler input shape than what `villa/spiral-fitting`'s
current `fit_session.py` actually enforces — this file documents the gap,
verified directly against villa's source (not the tutorial, not a relayed
summary of it — every claim below was independently re-fetched and
cross-checked before being written here; see the dossier entries this file
cites for exact quotes and URLs).

**Nothing below has been run.** This is what the code requires, worked out
by reading it — not a report of a successful fit.

## 1. `spiral-scroll.json` is mandatory and the tutorial never mentions it

Since a change the source comments call "version 27," `fit_spiral.py` will
not run at all without a `spiral-scroll.json` file in the dataset root
(dossier D-32). Required top-level keys, enforced in two separate checks in
`parse_scroll_spec()`:

- `schema_version` — must be present, and must equal `1` (a module constant
  `SCROLL_SPEC_SCHEMA_VERSION = 1`; a different value raises `ScrollSpecError`).
- `name`, `voxel_size_um`, `spiral_outward_sense` — checked together; any
  missing key raises `ScrollSpecError: missing required keys: [...]`.
- `spiral_outward_sense` must be exactly `"CW"` or `"ACW"` (case-normalized
  to uppercase) — anything else raises `ScrollSpecError`.

Optional keys: a nested `umbilicus` object with `coordinate_scale` (default
`1.0`) — this is metadata *about* the umbilicus, not the umbilicus data
itself (that's still the separate `umbilicus.json` file, always required,
see Section 2); `normal_zarr_group` / `surf_sdt_zarr_group` (defaults `"4"`
/ `"1"`); and a `paths` object for per-input path overrides (dossier D-33).

**Correction to an earlier draft of this section:** the override object's
top-level key is `paths`, not `path_overrides` — confirmed directly from
`parse_scroll_spec()`'s own `document.get("paths", {})` line. Use `paths`.

### Template for PHerc0826

```json
{
  "schema_version": 1,
  "name": "PHerc0826",
  "voxel_size_um": 9.362,
  "spiral_outward_sense": "CW",
  "normal_zarr_group": "2",
  "lasagna_scale": 4,
  "paths": {
    "tracks_dbm": "tracks/PHerc0826_20250821151701_surface_m7_L0_th0.2.dbm",
    "normal_x": "lasagna/PHerc0826_nx.ome.zarr",
    "normal_y": "lasagna/PHerc0826_ny.ome.zarr",
    "gradient_magnitude": "lasagna/PHerc0826_grad_mag.ome.zarr"
  }
}
```

`spiral_outward_sense: "CW"` above is a **sourced first guess** (the
maintainers' own workflow-post example), not a scroll-specific measurement —
see "The picture read failed too" below for why, and for the empirical
validation procedure that actually determines it. `normal_zarr_group` and
`lasagna_scale` are explicit overrides of config defaults that would
otherwise silently read the wrong pyramid level — see "Correctness check"
below.

**Fix (round terminal, 2026-08-27, real box):** the `tracks_dbm` value above was
missing its `tracks/` prefix in an earlier draft of this template. Confirmed
from `fit_session.py`'s own conventional default,
`conventional_relative="tracks/2um_ds2_ps256_surf_v2.dbm"` — an override
*replaces* the full path relative to the dataset root, it does not get
`tracks/` prepended automatically. The downloaded file lives at
`<dataset_root>/tracks/PHerc0826_...dbm`, so the override must include that
prefix or `fit_spiral.py` looks in the wrong place. Reproduced live: without
the prefix this key resolves to a path that doesn't exist; with it, the fit
correctly reaches the next validation step (spiral_outward_sense).

Save this as `spiral-scroll.json` inside the dataset root
(`spiral_datasets/PHerc0826/20250821151701/` — the same folder
`03_spiral_fit.sh` discovers dynamically; confirm the actual timestamp after
`make fetch-dataset` rather than trusting this one hardcoded here).

**`spiral_outward_sense` is a real human decision, not a lookup.** No source
found documents how to determine whether a scroll winds clockwise or
counterclockwise from the CT data alone — this has to be read off the scan
in VC3D by a person looking at it. Do this before running `make spiral-fit`,
not after; replace the placeholder above with `"CW"` or `"ACW"`.

### Alternative to VC3D: slice-render read (round terminal, 2026-08-27)

VC3D needs a GUI and (per the Docker finding above) doesn't build/run
directly on this pod. `runbook/render_cw_acw_slices.py` is a legitimate
alternative: it reads the volume zarr straight from the open-data S3 bucket
(anonymous, via `s3fs`+`zarr`, no local copy of the ~17-135 GB full volume),
at pyramid level 2 (4x downsample per the zarr's own OME multiscales
metadata), and renders three labeled axial-slice PNGs at full-res z ≈
5000/9000/13000 (inside the umbilicus's verified 1941-16262 range). Each PNG
marks the umbilicus point (linearly interpolated between the two nearest
`umbilicus.json` control points bracketing that z — our own interpolation
choice, not a villa-documented method, but a standard one) and prints the
assumed viewing convention directly in the image margin, so the convention
travels with the picture rather than living in a separate note someone could
lose track of.

Run it (from `villa/spiral-fitting`, whose uv venv already has
`zarr`/`s3fs`/`matplotlib`):

```bash
cd villa/spiral-fitting
uv run python /workspace/vesuvius-first-light/runbook/render_cw_acw_slices.py
```

Output: `/workspace/vesuvius-first-light/renders_tmp/PHerc0826_z{5000,9000,13000}_level2.png`
(~0.5-0.7 MB each). Pull them to a local machine over the same direct-TCP
port used for SSH (works for `scp`, no extra port-forwarding needed):

```bash
scp -P 27614 -i ~/.ssh/id_ed25519 "root@<POD_IP>:/workspace/vesuvius-first-light/renders_tmp/*.png" ~/Desktop/
```

or view them in the pod's own Jupyter Lab (already running, port 8888) —
construct the URL as `https://<POD_ID>-8888.proxy.runpod.net/lab?token=<token from the Jupyter process args>`;
**this exact proxy URL was not independently confirmed to resolve this
session** (only that Jupyter is listening locally on the pod) — verify it
loads before relying on it, `scp` is the confirmed-working path.

**Convention honesty (villa's own frame is undocumented, dossier D-33):** no
source states which way `fit_spiral.py` itself expects `"CW"`/`"ACW"` to be
measured from. The renders assume "viewed looking along +z; +x right, +y
down (native array orientation, row=y, col=x, no flip applied)" — a stated,
self-consistent choice, not a confirmed one. **Treat the answer read off
these images as a first guess, not ground truth**, and validate it
empirically rather than trusting it blind: after the first windowed fit
completes (Section "First fit attempt" below), overlay the fit's own output
spiral track on the same axial-slice render (reusing this script's slice-
loading code) and check by eye whether the tracked path actually follows the
visible papyrus wraps or cuts across them. If it cuts across them, flip
`spiral_outward_sense` and re-run — cheap (minutes, not hours) since the
z-window is small. **The exact field/array to pull the fit's spiral-track
points from is not yet known** — `fit_spiral.py`'s output structure hasn't
been inspected against a completed run yet; note the actual field name here
once the first fit produces output, rather than guessing it now.

### The picture read failed too — and why per-track computation doesn't recover the sense either

**The slice-render read above turned out not to be readable.** A
three-model cross-check on the rendered images split (CW / ACW / ambiguous),
and a zoomed-crop re-read concluded the call is genuinely unresolvable at
this resolution: heavy deformation makes both winding senses locally look
alike, and the umbilicus marker glyph itself occluded the one decisive
feature (the innermost sheet termination). **Runbook note for future
renders: use a small open circle + offset crosshair, never a solid cross
over the center** — it hides exactly the pixels that matter most.

**Tried computing it from the track data instead, and that failed too —
worth recording precisely, since it's a real methodological finding, not
just a null result.** Method: `villa/spiral-fitting/tracks.py`'s own
`load_tracks_from_dbm` (verified live: track arrays are stored **zyx**, not
xyz — the function's own docstring and its `z_column = entry[:, 0]` line
confirm this) loaded every track lying entirely within 200-slice bands at
z=5000/9000/13000 (194267 / 159173 / 73201 tracks respectively). Per track:
`dx/dy` from the interpolated umbilicus (same interpolation as the render
script), `r = hypot(dx, dy)`, `theta = unwrap(atan2(dy, dx))`, least-squares
slope `dr/dtheta`. **Result: ~50/50 split in every band** (48.6/51.4%,
51.6/48.4%, 47.8/52.2%), majority sign flipping between bands, no band
above 80% agreement. Ruled out a sample-size/noise explanation directly
before accepting this as a real negative: filtering to only the longest,
most angularly-swept tracks (top ~1% by angular sweep, up to 17°) did not
improve agreement — stayed at 50-52% across every threshold tested from 0
to 0.3 rad. Two unconfirmed candidate causes: (1) these are short,
disconnected local track fragments (median sweep <1°, 99th percentile only
~39° — a small fraction of a full 2π turn), where real physical coil
waviness in a damaged/creased papyrus layer likely dominates the tiny true
secular per-turn radius growth at that short a baseline; (2) a track's own
point order may not be consistently outward-oriented, making the slope's
sign an artifact of extraction order rather than winding direction.
Distinguishing them, or getting a real per-track signal, would need
connecting tracks across their crossings into a longer coherent path —
villa's own track-graph/crossing machinery (`grow_track_graph.py`,
`PackedTracks`, crossing-partner CSR) does this internally, but that's real
additional engineering, not attempted here.

**Resolution: a sourced first guess, validated empirically by the fit
itself.** The maintainers' own First Letters workflow post
(scrollprize.substack.com/p/from-ct-scan-to-ancient-text-a-first) ships an
example `spiral-scroll.json` with `"spiral_outward_sense": "CW"`, and states
its own method for determining this is "manually inspecting some slices in
VC3D" — i.e. the exact method that just failed a human, three AI models, and
a 180k-point regression. That contrast is itself worth keeping in mind for
PR #1's documentation motivation. **Entered `"CW"` as a first guess, sourced
to the workflow example, not scroll-specific evidence** — not a measurement,
a starting point for the overlay-fit validation described above, which
remains the actual determination procedure. If the overlay shows the fitted
spiral cutting across the visible wraps, flip to `"ACW"` and re-run; the
runbook records whichever run actually tracks the wraps as the empirical
determination.

### Correctness bugs found in `normal_zarr_group` / `lasagna_scale` — one static, one only by actually running the fit

The same workflow post's example JSON also carries
`"normal_zarr_group": "2"` and `"lasagna_scale": 2`, stated as suitable for
the 8/9um prize volumes. Checked against `fit_session.py` directly (not
assumed): both default to different values — `normal_zarr_group` defaults to
`"4"`, `lasagna_scale` defaults to `4` (`fit_session.py:594-596`). **These
control which OME-Zarr pyramid level the lasagna `normal_x`/`normal_y`
stores are read at** (confirmed from the file's own version-27 changelog
comment: making these dataset-root facts specifically prevents a client from
"read[ing] the Lasagna stores at the wrong zarr level"). Checked our actual
downloaded `PHerc0826_nx.ome.zarr`'s own `.zattrs`: group `"2"` = 4x
downsample, group `"4"` (the default) = **16x downsample** — a real 4x
resolution gap, not a trivial one. Without setting these keys explicitly,
the fit would have silently loaded the normal maps at 16x downsample instead
of the intended 4x, with no error raised. Added both keys to
`spiral-scroll.json` (see the template above), cited to the workflow post
rather than trusting either the post or the code defaults blind.

**Second correctness bug, caught by actually running the fit, not by static
review:** `lasagna_scale: 2` (the post's value) fails at runtime —
`prepare_lasagna_volume` computes `z_lo = floor(z_begin/lasagna_scale)`,
`z_hi = min(store_z_size, ceil(z_end/lasagna_scale))`
(`lasagna_data.py:219-222`); with `z_begin=10000`, `lasagna_scale=2`, that's
`z_lo=5000`, clamped against the store's actual z-size of 4230, giving
`z_hi=4230 < z_lo` and a hard `RuntimeError: lasagna z-ROI [5000, 4230) is
empty`. Root cause: `lasagna_scale` must equal the *actual* downsample
factor of whichever `normal_zarr_group` you pick, and this dataset's group
`"2"` is a 4x downsample (confirmed directly from `PHerc0826_nx.ome.zarr`'s
own `.zattrs` multiscales metadata — group `"2"` -> scale `[4,4,4]`, group
`"4"` -> scale `[16,16,16]`), not 2x. **The post's `"2"`/`2` pairing does not
hold for this scroll's lasagna pyramid** — the template above now uses
`lasagna_scale: 4` to match group `"2"`'s real scale, verified working: the
fit ran end-to-end after this fix. Lesson for the PR: verify a value taken
from someone else's worked example against your own dataset's actual
structure before trusting it, even when it's the maintainers' own post.

### First real windowed fit: ran end-to-end, real Triton kernels, no OOM — and a load-bearing negative result on CW/ACW

With the fixes above, `make spiral-fit SCROLL=PHerc0826 Z_BEGIN=10000
Z_END=11000` (equivalently, `03_spiral_fit.sh`'s `uv run python fit_spiral.py`
invocation) **ran successfully to completion** — the actual, real thing this
whole runbook has been building toward. 642,640 tracks loaded within the
z-ROI, loss dropped smoothly (955.9 at step 1000 -> 747.7 at step 1400 with
`optimizer_num_training_steps` overridden to 1500 for a fast first check;
`output_save_png_visualizations: true` also set to get the built-in
finalization renders), `satisfied_tracks = 61631/642640 (9.6%)`,
`satisfied_track_points = 13039268/33967984 (38.4%)`. This is villa's actual
production optimizer running its real Triton kernels (`gap_triton.py`/
`flow_triton.py` are imported by the flow-field model this run constructs)
on sm_120 for the first time this project — **Blackwell all-clear for the
real fit path**, not just the generic JIT-kernel smoke test from box setup.

**Separately, deliberately ran the D-41 default-window case** (no
`Z_BEGIN`/`Z_END` override, villa's own `z_begin=4000`/`z_end=17000`
default) to capture the predicted OOM. It did **not** OOM — GPU memory
stayed under 8 GiB of the card's 32 GiB throughout, Triton kernels compiled,
and it reached real optimization (313/30,000 iterations, accelerating past
0.9 it/s) before dying silently with no traceback after ~5.5 minutes. No
`dmesg`/kernel-log access exists inside this pod to confirm a cause; the
silent-death signature (a `resource_tracker` cleanup warning immediately
before the log stops, no Python exception) is consistent with an external
kill (system RAM OOM from preparing 8,384,681 tracks for the full window, or
the `timeout` wrapper, though the wrapper's cap was 900s and the process
died around ~330s of its own elapsed time) but this is **not confirmed**.
**Revises D-41, doesn't confirm it as originally stated**: the predicted
GPU-VRAM OOM did not reproduce for this pipeline's actual (patches-disabled,
`grad_mag`-mode) config; whatever killed the process is a different,
unconfirmed failure mode.

**CW/ACW: still unresolved, and now by a second independent method.** Ran
the identical 1500-step fit with `spiral_outward_sense: "ACW"` (all other
config unchanged) for a direct comparison: `loss` at step 1400 = 736.2 vs.
747.7 for CW (under 2% apart), `satisfied_tracks = 61399/642640 (9.6%)` vs.
61631/642640 (9.6%) for CW — **statistically indistinguishable**. The fit's
own loss and satisfaction metrics do not distinguish CW from ACW at all;
the optimizer converges equally well labeled either way. This means the
per-track `dr/dtheta` computation, the picture read, *and* a loss-based
comparison have now all failed to resolve this — only a genuine geometric
comparison of the two fits' actual output shapes could, and the built-in
`render_spiral_on_tracks_for_slice` visualization wasn't usable for this:
with patches disabled (`fitting 0 patches`), the `snapped_tracks` argument
this call site passes is always empty, so every track renders with an
arbitrary hash-based colour instead of being colour-coded by fit
quality/winding — the resulting image (saved, see
`spiral_on_tracks_s10525_fitted.png`) shows real track density but isn't
legible for a CW/ACW call. **Not pursued further this round**: reconstructing
the model's actual predicted geometry from the raw checkpoint tensors
(`spiral_and_transform`'s `flow_field.flows.*` etc.) to compare the two fits'
literal output shapes directly would resolve this properly, but is
real additional engineering — checked in before attempting it.

**Path override values are relative to the dataset root** if not absolute
(confirmed in `fit_session.py`'s `_normalise_path()` — a relative override
gets joined to the dataset root; an absolute path is also accepted as-is).
The template above assumes you download the three lasagna zarrs (Section 3)
into a `lasagna/` subfolder inside the dataset root; an absolute path works
identically if you'd rather keep them elsewhere.

**`tracks_dbm` needs an override at all** because the actual file on
`dl.ash2txt.org` is named `PHerc0826_20250821151701_surface_m7_L0_th0.2.dbm`
(confirmed by direct listing, matches this repo's own F1 research), not the
catalog's conventional default `tracks/2um_ds2_ps256_surf_v2.dbm` (dossier
D-33). Without the override, `fit_spiral.py` looks for a file that doesn't
exist under that name.

## 2. `umbilicus.json` — separate from the above, always required

Confirmed: the umbilicus is its own catalog entry
(`conventional_relative="umbilicus.json"`, `resolve_required=True`) —
unconditionally required regardless of any config. This is what
`00_before_you_start.md` Section 4 already covers (fetch bruniss's file from
Discord, verify its sha256, place it as `umbilicus.json` in the same dataset
root as the `spiral-scroll.json` above).

## 3. What `03_spiral_fit.sh`'s actual config does and doesn't need

`03_spiral_fit.sh`'s `FIT_SPIRAL_CONFIG_OVERRIDES` (already in the script,
sourced from the tutorial) sets `dense_spacing_mode: "grad_mag"`,
`loss_weight_dense_spacing: 0`, `loss_weight_shell_outer: 0`,
`loss_weight_shell_patch_radius: 0`. Tracing villa's actual requirement
predicates against exactly these values (dossier D-34, D-35):

| Input | Required given this config? | Why |
|---|---|---|
| `umbilicus.json` | **Yes, always** | unconditional catalog entry |
| `tracks_dbm` | **Yes, always** | enabled by default, no toggle set |
| `normal_x`, `normal_y` | **Yes** | `loss_weight_dense_normals` defaults to `100.0` (not overridden by this script) and is `>0`, which alone makes normals required regardless of `dense_spacing_mode` |
| `gradient_magnitude` | **No, given this config** | required only if `dense_spacing_mode == "grad_mag"` AND `loss_weight_dense_spacing > 0` — the script sets that weight to exactly `0`, so this condition is false |
| `surf_sdt` | **No, given this config** | required only if `dense_spacing_mode == "phase"` (the *default* if you ever ran without this script's overrides) — this script sets `"grad_mag"` instead, so the phase-bundle requirement never triggers |
| `outer_shell` | **No, given this config** | required only if shell-loss weights are `>0`, or a winding-model mode is active — this script zeroes both shell weights and never sets `dense_spacing_mode: "winding_model"` |

**This differs from what you'd need running `fit_spiral.py` with villa's
own defaults** (which would need `surf_sdt` and `outer_shell`, since the
default `dense_spacing_mode` is `"phase"` and the default shell-loss weight
is `1.0`) — the tutorial's own override values happen to sidestep both,
which is presumably *why* the tutorial never mentions `surf_sdt` or
`outer_shell` at all, not because they don't exist in the codebase.

**Practical recommendation:** `normal_x`/`normal_y` are the only genuinely
required addition beyond tracks + umbilicus, given the current script — get
those from Section 3 below regardless. `gradient_magnitude` is sitting in
the same S3 folder at zero extra cost, worth grabbing alongside the normals
even though it's not strictly required by this exact config, in case anyone
later changes `loss_weight_dense_spacing` back to nonzero. `surf_sdt` and
`outer_shell` are the ones this pre-flight originally set out to build —
Sections 4 and 5 cover how, but per the table above, neither is actually
load-bearing for a first run with this script's existing config. Build them
only if you want a hedge against changing the config later, not because
`03_spiral_fit.sh` as it stands needs them.

## 4. Fetching normal_x, normal_y, gradient_magnitude for PHerc0826

Confirmed live on the open-data bucket (dossier D-36):

```
s3://vesuvius-challenge-open-data/PHerc0826/representations/predictions/lasagna/20250821151701-lasagna-20260419180421/
  PHerc0826_nx.ome.zarr/
  PHerc0826_ny.ome.zarr/
  PHerc0826_grad_mag.ome.zarr/
  PHerc0826_cos.ome.zarr/
  PHerc0826.lasagna.json
```

No `surf_sdt` and no `outer_shell` folder anywhere under
`PHerc0826/representations/predictions/` — confirmed, this bucket location
does not have them (matches Section 5/6 below).

Download `PHerc0826_nx.ome.zarr`, `PHerc0826_ny.ome.zarr`, and (optionally,
per Section 3) `PHerc0826_grad_mag.ome.zarr` into
`spiral_datasets/PHerc0826/20250821151701/lasagna/`, matching the
`spiral-scroll.json` template's `paths` values above. `PHerc0826_cos.ome.zarr`
and `PHerc0826.lasagna.json` are not in the fit_spiral input catalog —
leave them where they are, no need to copy them.

## 5. If you ever need `surf_sdt`: building it with `make_surf_sdt.py`

Not required for a first run per Section 3's table — build this only if you
change the config to use `dense_spacing_mode: "phase"` (villa's default).

The surface-prediction zarr this needs already exists on the bucket
(dossier D-37):

```
s3://vesuvius-challenge-open-data/PHerc0826/representations/predictions/surfaces/20250821151701-surface-20260413222639-surface-m7-L0-th0.2.zarr/
```

`villa/spiral-fitting/make_surf_sdt.py` (confirmed to exist, click-based
CLI) builds a signed-distance zarr from it:

```bash
python make_surf_sdt.py build \
  --surf /path/to/20250821151701-surface-20260413222639-surface-m7-L0-th0.2.zarr \
  --group 1 \
  --out spiral_datasets/PHerc0826/20250821151701/lasagna/PHerc0826_surf_sdt.ome.zarr \
  --threshold <TODO — not confirmed, see below>
```

**`--group 1` is a guess, not confirmed** — the script's own help text says
`--group` wants "the source group to read (e.g. 1)"; whether the surfaces
zarr above actually has a group named `1` wasn't checked (would need the
file open, not just its listing). **`--threshold` is not sourced at all** —
the surfaces zarr's own filename includes `th0.2`, which may or may not be
the right threshold for *this* script specifically (it binarizes a surface
prediction, a different step from whatever produced the `th0.2` in the
upstream filename) — do not assume `0.2` is correct without checking
`make_surf_sdt.py --help` yourself or asking in Discord. If you build this,
add `paths.surf_sdt` pointing at the output in the `spiral-scroll.json`
template above.

## 6. `outer_shell`: not required, explicit override added anyway

Per Section 3's table, `outer_shell` is already not required given
`03_spiral_fit.sh`'s existing zero shell-loss weights. `03_spiral_fit.sh`
now also sets `input_use_outer_shell: false` explicitly in
`FIT_SPIRAL_CONFIG_OVERRIDES` — confirmed this is a real, correctly-named
config key (`_INPUT_TOGGLE_KEYS["outer_shell"] = "input_use_outer_shell"`
in `fit_session.py`), so the addition is valid, just redundant given the
weights are already zero. Kept anyway as an explicit, self-documenting
statement of intent — if anyone changes the shell-loss weights back to
nonzero later without noticing this line, the explicit `false` still blocks
outer_shell from being silently required again. **Trade-off:** disabling
shell losses (via either the zero weights or this flag) means the fit
doesn't get whatever constraint `outer_shell` normally provides — no source
found quantifies what's lost, only that it's optional given this config.
PHerc0826 has no `outer_shell/` folder anywhere on the bucket, so building
one from scratch (rather than disabling it) was not attempted or scoped
here.

## Dossier entries (see `expert_dossier.md` D-32 through D-37 for verbatim
sourcing on every claim above; run `expert_check.py --dossier` before
trusting the CONFIRMED status.)
