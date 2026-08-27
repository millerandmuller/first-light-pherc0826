<!--
Mirrors villa/.github/pull_request_template.md verbatim (fetched 2026-08-23).
Facts and diff below are filled in by the round terminal (technical content
only, cite-or-GAP, all verified live against villa commit 6847063 on
first-light-pherc0826). The prose fields marked TODO(human) are NOT filled
in — motivation prose, "why useful", and the final PR description stay
strictly human-written per CONTRIBUTING.md (D-15) and the project's own
working agreement. This PR targets `villa/spiral-fitting/README.md`
(documentation only, no code change) -- CONTRIBUTING's screenshot-gate for
bugfix PRs (D-13) does not apply to a docs PR, but the schema-validation
screenshot below is included anyway as it landed for free while testing.
-->

**In one sentence:** TODO(human)

**One real example:** Running `fit_spiral.py --dataset` against real
PHerc0826 data (villa commit `6847063`, 2026-08-26) without a
`spiral-scroll.json` in the dataset root raised `ScrollSpecError` at
`fit_session.py:705` — the tutorial (scrollprize.org/tutorial_spiral) never
mentions this file is required.

**Before:** No documentation anywhere (tutorial or this repo's `README.md`)
states that `spiral-scroll.json` is mandatory, what its required schema is,
or that `normal_zarr_group`/`lasagna_scale` must be set explicitly for
9um-class prize volumes.

**After this PR:** A new `## Scroll specification (spiral-scroll.json)`
section in `spiral-fitting/README.md` documents the required schema,
verbatim error text, and the `normal_zarr_group`/`lasagna_scale` gotcha
below.

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

2. Schema-validation-passing screenshot: once `spiral-scroll.json` was
   written correctly, re-running got past all schema checks and into real
   optimization (`PROGRESS Optimizing — .../30,000 iterations`) — no
   remaining `ScrollSpecError`. Screenshot TODO(human) — take from
   `logs/real_windowed_fit2.log` or a fresh terminal capture.

3. `normal_zarr_group`/`lasagna_scale` bug, reproduced live:
```
RuntimeError: lasagna z-ROI [5000, 4230) is empty (store z size 4230)
```
   with `lasagna_scale: 2` (the workflow post's own example value) against
   PHerc0826's actual lasagna store — group `"2"` is a real 4x downsample
   for this scroll (confirmed from `PHerc0826_nx.ome.zarr`'s own `.zattrs`
   multiscales metadata, not assumed), not 2x. Fixed with `lasagna_scale: 4`
   — verified: the fit ran end-to-end afterward, 642,640 tracks loaded, loss
   955.9→747.7 over 1500 steps.

**Why / where this is useful:** TODO(human)

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
in this repo for the round terminal's own (inconclusive, honestly reported)
attempts at computing it from track data and comparing fit loss between
`"CW"`/`"ACW"`.

---
### Internal checklist (not part of the upstream PR — delete before submitting)
- [ ] Error screenshot attached (terminal or in-tool) — not required for a
      docs PR per CONTRIBUTING (D-13 scopes this to bugfix PRs), included
      as proof item 1/3 above anyway since it was captured for free
- [x] Demonstrated on real scroll data, not synthetic/toy (D-14)
- [x] LLM-assisted diagnosis and fix — human-written commentary required
      (D-15): motivation prose above (TODO(human)) is that commentary
- [ ] Candidate wall-log entry: `logs/` (E5)
- [ ] Linked from `README.md` PR list once opened
- [ ] Human reviews the proposed diff's placement in the real README.md
      structure before opening (this file only proposes the content)
