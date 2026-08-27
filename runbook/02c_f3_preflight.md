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
  "spiral_outward_sense": "TODO_DETERMINE_IN_VC3D",
  "paths": {
    "tracks_dbm": "tracks/PHerc0826_20250821151701_surface_m7_L0_th0.2.dbm",
    "normal_x": "lasagna/PHerc0826_nx.ome.zarr",
    "normal_y": "lasagna/PHerc0826_ny.ome.zarr",
    "gradient_magnitude": "lasagna/PHerc0826_grad_mag.ome.zarr"
  }
}
```

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
