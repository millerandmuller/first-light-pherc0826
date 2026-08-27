<!--
Mirrors villa/.github/pull_request_template.md verbatim (fetched 2026-08-23).
Prose below is Lutfiya's own (2026-08-27) — human-written per CONTRIBUTING.md
(D-15) and the project's working agreement. Paths/numbers/proof filled in by
the round terminal, all verified live against villa commit 6847063 on
first-light-pherc0826.
-->

**In one sentence:** Writes down the schema of the `spiral-scroll.json` file
that `fit_spiral.py` requires, including the `lasagna_scale` value that is
easy to get wrong and fails in a confusing way.

**One real example:** Setting up PHerc0826 from scratch, we had to
reconstruct this file one key at a time from the errors each missing field
produced. Then we copied a `normal_zarr_group` / `lasagna_scale` pairing
from an example elsewhere, and the run died with
`RuntimeError: lasagna z-ROI [...] is empty` — because on this scroll's
store, group `"2"` is the 4x downsample, not the group the example used.

**Before:** The README refers to `spiral-scroll.json` (the service won't
start without it; it's called the only source of the scroll's name, voxel
size and Lasagna store layout) but never says what goes in it, and the
spiral tutorial doesn't mention the file at all. `lasagna_scale` appears
once, in a list of fields the service rejects if a client sends them.

**After this PR:** A short section in `spiral-fitting/README.md` giving the
required keys, the optional `paths` overrides, and a worked PHerc0826
example. The `lasagna_scale` paragraph says what the value has to match —
the actual downsample factor of the group you picked, read from that
store's own `.zattrs` — and both ways a wrong value shows up: silently
reading normal maps at the wrong resolution with no error at all, or the
empty-z-ROI `RuntimeError` if the mismatch is big enough.

**Proof:**

1. Missing-file error (real run, before the file existed):
```
fit_session.ScrollSpecError: No scroll specification found at
/workspace/vesuvius-first-light/spiral_datasets/PHerc0826/20250821151701/spiral-scroll.json.
Create spiral-scroll.json in the dataset root with schema_version, name,
voxel_size_um, and spiral_outward_sense (plus any non-conventional path
overrides).
```
(`fit_session.py:705`, reproduced live 2026-08-27.)

2. `normal_zarr_group`/`lasagna_scale` mismatch, reproduced live:
```
RuntimeError: lasagna z-ROI [5000, 4230) is empty (store z size 4230)
```
   with `lasagna_scale: 2` (the workflow post's own example value) against
   PHerc0826's actual lasagna store — group `"2"` is a real 4x downsample
   for this scroll (confirmed from `PHerc0826_nx.ome.zarr`'s own `.zattrs`
   multiscales metadata, not assumed), not 2x.

3. Same run completing after fixing `lasagna_scale: 4`, all the way to
   convergence (real, captured 2026-08-27, `logs/real_windowed_fit_CW_30k.log`):
   no remaining `ScrollSpecError`, no OOM, no silent death:
   ```
   PROGRESS Optimizing — 0/30,000 iterations (0.0%) — elapsed 0s
   ...
   step 29800: loss = 333.1, umbilicus = 0.0, sym_dirichlet = 38.2, dense_normals = 7.0, min_spacing = 0.0, track_radius = 185.7, track_dt = 102.3
   satisfied_tracks = 92579/642640 (14.4%)
   satisfied_track_points = 18215660/33967984 (53.6%)
   save_mesh fitted: winding range [10, 130)
   ```
   Loss fell 955.9 → stable ~330-340 (plateaued, not still descending —
   genuine convergence). Wall-clock 29m49s on one RTX PRO 4500 32GB.
   (642,640 tracks loaded; the first end-to-end confirmation at 1,500 steps
   was loss 955.9→747.7 — cited here as the earlier checkpoint of the same
   fix, superseded by the full convergence run above.)

**Why / where this is useful:** Anyone bringing up a scroll other than the
published PHercParis4 dataset has to write this file, and right now the
fastest route to it is guessing from error messages. The silent-wrong-
resolution case is the one worth documenting: it doesn't fail, it just fits
against the wrong data. This section would have saved us most of a day.

- [x] I personally verified that the example and proof above were produced
      by this PR on the stated data. (Round terminal, 2026-08-27, real box
      `first-light-pherc0826`.)

## Details

**Method:** villa commit `6847063ffdb4da898ae8d1d494ebf7d71473f509`
(2026-08-26 21:25 CEST). RunPod EU-RO-1, RTX PRO 4500 32GB (Blackwell,
sm_120), torch 2.11.0+cu128 / triton 3.6.0. `SCROLL=PHerc0826`,
`Z_BEGIN=10000 Z_END=11000`. Commands: see `runbook/02c_f3_preflight.md`
and `runbook/03_spiral_fit.sh`.

**Proposed diff** (new section in `villa/spiral-fitting/README.md`,
placement TBD by whoever reviews the README's actual structure):

```markdown
## Scroll specification (spiral-scroll.json)

`fit_spiral.py` requires a `spiral-scroll.json` file in the dataset root.
This is not covered by scrollprize.org/tutorial_spiral. Required keys:

- `schema_version` — must equal `1`.
- `name`, `voxel_size_um` — required, no validation beyond presence.
- `spiral_outward_sense` — must be `"CW"` or `"ACW"` (case-insensitive).
  No automated method determines this; it is read off the CT data by a
  person in VC3D, or computed from an already-fitted spiral (see below).

Optional `paths` object for per-input overrides when a dataset's file names
don't match the catalog's conventional defaults (e.g. `tracks_dbm`).

Also optional, and easy to get wrong silently: `normal_zarr_group`
(default `"4"`) and `lasagna_scale` (default `4`) select which OME-Zarr
pyramid level the `normal_x`/`normal_y` lasagna stores are read at.
**`lasagna_scale` must equal the actual downsample factor of whichever
group you pick for this specific scroll's lasagna store** — read it from
the store's own `.zattrs` multiscales metadata, do not assume it from
another scroll's example or from a generic recommendation. A mismatched
value either silently reads the wrong-resolution normal maps (no error) or
throws `RuntimeError: lasagna z-ROI [...] is empty` if the mismatch is
large enough to push the requested z-range outside the (wrongly-scaled)
store bounds.

Example (PHerc0826, group "2" == 4x downsample for this scroll specifically):
{
  "schema_version": 1,
  "name": "PHerc0826",
  "voxel_size_um": 9.362,
  "spiral_outward_sense": "CW",
  "normal_zarr_group": "2",
  "lasagna_scale": 4,
  "paths": {
    "tracks_dbm": "tracks/PHerc0826_20250821151701_surface_m7_L0_th0.2.dbm"
  }
}
```

**Comparisons:** N/A (documentation-only change).

**Limitations:** The `spiral_outward_sense` determination method itself
remains undocumented upstream (dossier D-33) — this PR documents the
schema requirement, not a determination procedure. See `02c_f3_preflight.md`
in this repo's "CW/ACW: settled — the full determination saga" section for
how we resolved it for our own scroll — offered as a worked example, not a
general procedure this PR claims to establish.

**Disclosure:** We're a two-person team and we worked with an LLM assistant
on this, including the diagnosis and the patch. We directed the work, ran
everything on real PHerc0826 data, and checked the evidence ourselves
before opening this.

---
### Internal checklist (not part of the upstream PR — delete before submitting)
- [ ] Error screenshot attached (terminal or in-tool) — not required for a
      docs PR per CONTRIBUTING (D-13 scopes this to bugfix PRs), included
      as proof items 1-3 above anyway since it was captured for free
- [x] Demonstrated on real scroll data, not synthetic/toy (D-14)
- [x] LLM-assisted diagnosis and fix — human-written commentary added
      (D-15): disclosure paragraph above
- [x] Candidate wall-log entry: `logs/` (E5) — fact material at
      `logs/2026-08-27-spiral-fit-run-stats.md`; human TIL prose still needed
- [ ] Linked from `README.md` PR list once opened
- [ ] Human reviews the proposed diff's placement in the real README.md
      structure before opening (this file only proposes the content)
