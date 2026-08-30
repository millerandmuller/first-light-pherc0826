<!--
E4 preregistration. Reviewed and approved by Lutfiya 2026-08-27; the
initial commit of this file is the preregistration act, made BEFORE any
inference on the target window. The Calibration section is filled from the
control run (which precedes target inference); the False-positive statement
and the Verdict are written after inference. The criteria themselves are
never edited retroactively.
-->

# Preregistration — PHerc0826, window1 (z 10000-11000, inner windings w010-w065)

Committed: 2026-08-27 (before any target inference; see git log)
Commit hash of the preregistration act: `2b9425e47bcc477ccc0986c06578c29b5730cc1a` (this line added in the immediate follow-up commit; the hash above is the binding one, referenced in the README's Proof beat).

## Scope

Target: PHerc0826, z-window 10000-11000 (window1), **restricted to the
well-covered inner winding range, approximately w010-w065** — not the full
w010-w129 fitted range. Rationale (round terminal, 2026-08-27): the
converged 30k-step fit's coverage is not uniform — dense through roughly
the inner half of the fitted winding range, thinning sharply beyond that,
down to small disconnected fragments in the outer quarter. Committing the
criteria to the region we already know has real, continuous surface data
avoids the two bad outcomes: silently including a region that will just
read as "no data" rather than "no ink," or spending more GPU-hours trying
to fix what looks like a real data-availability limit, not a fitting
problem, this close to freeze.

**Implementation note for whoever runs F5:** the existing `04_lasagna_flatten.sh`
concatenates the FULL w010-w129 range by default. Producing a render scoped
to just w010-w065 needs either a restricted input directory (copy/symlink
only the `w010_spliced` .. `w065_spliced` folders before running
`render_ink.py`) or a post-hoc crop of the flattened output once the
winding-index-to-pixel mapping in flattened space is known. Not yet built —
flagging so it isn't rediscovered as a surprise mid-run.

## What counts as a positive signal (PROPOSED — edit before committing)

- Ink probability at or above the control-derived calibration level: the
  median ink probability that the identical pipeline (same checkpoint, same
  settings) assigns to the control segment's labeled ink-stroke pixels.
  This number is computed from the control run — which happens BEFORE any
  target inference — and recorded in the Calibration section below at that
  time. It is not chosen by eye and never adjusted after target results
  exist.
- Spatially coherent over a contiguous, stroke-like (elongated, not
  blob-shaped) region at least 0.5 mm (~53 px at native 9.362 um/px) along
  its long axis — the floor tied to D-05's own minimum meaningful ML-image
  scale. Single pixels and sub-0.5 mm specks do not qualify.
- Aligned parallel to the horizontal fiber direction visible in the same
  render (D-08).
- Reproducible in **both** `--direction` outputs (`segment.tif` and
  `segment_reverse.tif`) — sourced directly, D-25.
- Row-annotatable: if a candidate signal exists, it should be markable as a
  baseline or rectangle without overwriting the letters themselves (D-08's
  annotation convention).

## What does NOT count (PROPOSED — edit before committing)

- Isolated bright pixels or single-cell blobs with no coherent shape.
- Artifacts at tile-blend seams (relevant given the composite/tiling
  pipeline chops wide renders into `--max-strip-width` tiles — a seam
  artifact is a rendering boundary effect, not a surface signal).
- Signal that appears in only one of the two `--direction` outputs.
- Signal that does not survive the held-out check below.
- Any signal inside the sparse outer region excluded by the Scope section
  above, even if visually suggestive — out of scope by this
  preregistration, not evaluated either way.

## Held-out check (D-06)

Positive-control segment: **PHerc0139/w035** (`w035_2026031718`), per D-38.
Ground truth: `w035_2026031718_inklabels.zarr`/`.tif`, confirmed to exist
2026-08-27 (advisor, authenticated HF session) at
`https://huggingface.co/buckets/scrollprize/datasets/tree/ink/0139/w035_2026031718`.

**Important caveat to state explicitly in the writeup (tutorial5, verbatim:
"a PHerc. 0139 segment from the models' own training set"):** w035 is in
the `ink_9um` model's own training set. This control validates that the
*pipeline* runs correctly end-to-end (fit → flatten → render → inference →
compare against known ground truth) — it does NOT test whether the model
generalizes to unseen data. Label it that way, not as a generalization
check.

**Run order (binding):** the control run precedes any target inference —
it produces the calibration numbers below.

Expected result on the control: elevated probability visually matching the
published label locations side-by-side, AND the two calibration medians
below clearly separated. If the control fails either part, the pipeline is
declared uncalibrated and no claim of any kind is made about the target
window.

## Calibration (filled from the control run, BEFORE target inference — an addition, not an edit of the criteria above)

Forward direction (matches the published render's and training labels' fixed
orientation — see Deviation note below):
- Median ink probability on the control's labeled ink-stroke pixels: **0.7843**
- Median ink probability on the control's non-labeled background pixels: **0.2235**
- Separation: 0.5608

Reverse direction (`--direction both`'s second output, same run):
- Median ink probability on the control's labeled ink-stroke pixels: 0.2706
- Median ink probability on the control's non-labeled background pixels: 0.2667
- Separation: 0.0039 (no separation — expected: this render's orientation is
  fixed and already matches training, so the reverse pass is the
  "upside-down" direction for this specific control, not an ambiguous case
  the way an unread target segment is)

**Signal threshold (this prereg's criterion) = 0.7843**, the forward-direction
median ink probability, computed identically from both (a) the officially
published surface-volume render and (b) this repo's own `07_controls.sh`
render of the same segment — the two agree to 4 decimal places.

Both numbers cross-checked visually: the raw forward prediction
independently reproduces legible letterforms, and the human ground-truth
annotations land on top of them without being told where to look
(`analysis/control-PHerc0139/side_by_side.png`, forward prediction |
prediction with labels overlaid in red | labels alone).

- Date/commit of this addition: 2026-08-28

## Deviation note (added before any target inference, per the prereg's own commit-before-you-look rule; does not edit the Scope or criteria sections above)

The control segment (PHerc0139/w035) was first fetched from the HF
`scrollprize/datasets` bucket's `ink/0139/w035_2026031718/` path (per D-38).
That mesh turned out to be registered to a different, ~2.4 µm PHerc0139
volume, not the 9.362 µm volume this prereg's Scope targets — the first
control run correctly came back all-zero in both directions (0% occupancy,
0 patches selected), which is the control system working as designed: it
caught a coordinate-frame mismatch before any target inference could run.

Root cause and fix, verified against villa's own `scrollprize.org/docs/07_tutorial5.md`
(the source the original w035 pick was based on) and a live S3 listing:
segment geometry on the open-data bucket is registered per-volume, at
`PHerc0139/segments/20260317000000-w035_2026031718/mesh/<id>-on-<volume>.tifxyz/`.
Re-fetched the `-on-20250728140407-9.362um` registration (the correct one)
and added the tutorial's `--flip-normals` flag to `07_controls.sh` (also
missing from the original script). This eliminated the mismatch.

Calibration source: rather than hand-writing a geometric remap between two
differently-registered meshes (new, unverified code, rejected as the
weakest option under deadline), used the model's own training-label tree
(`scrollprize/datasets`, `ink_9um/labels/native9-scrollprizeorg-21slices/w035/`)
together with the officially published, pre-rendered 9.362 µm surface
volume for this exact segment
(`PHerc0139/segments/20260317000000-w035_2026031718/surface-volumes/...zarr/`).
Both are the model's own training data for this segment — zero new geometry
code, labels valid by construction. Ran this repo's own inference runtime
(same checkpoint, same CLI, `--direction both`) on that volume; independently
re-ran the full `07_controls.sh` pipeline (our own render, `--flip-normals`,
against the correctly-registered mesh) and got numerically identical medians
— cross-validating both the calibration source and this repo's render step.

## Image requirements for any published render (D-03, D-05, D-08)
- [ ] 1 cm scale bar. Derived: at native 9.362 µm/px, 1 cm ≈ 1,068 px; at
      this pipeline's `--scale 0.25` renders, 1 cm ≈ 267 px. **State the
      render's actual scale factor next to the bar** — do not reuse the
      native-resolution number on a scaled image.
- [ ] Pixel and millimeter dimensions of any called-out feature (D-03).
- [ ] ML window size ≤ 0.5×0.5 mm (D-05) — derived: ≈53 px at native
      resolution. This is the ink model's own inference patch/stride size,
      not the display scale; **not independently verified this session**
      that `vesuvius.ink_detection.inference.infer`'s default patch size is
      under this bound — check before publishing.
- [ ] Overlaid on a fiber-visible rendering (D-08) — **GAP**: no dedicated
      fiber-direction overlay render was produced this session; either
      confirm the standard flattened-surface render is sufficient for a
      human to judge fiber alignment, or produce one before publishing.
- [ ] Control shown side-by-side, labeled "control" (project_brief.md 1.6).

## False-positive mitigation statement (D-07) — fill in AFTER inference, do not edit criteria above retroactively
(Written 2026-08-30, after target inference; the criteria above are
unedited. Source requirement, re-verified live 2026-08-27: "If there is
any risk of your model producing spurious patterns — apparent letterforms
that are not actually supported by the data — please let us know how you
mitigated that risk. Tell us why you are confident that the results you
are getting are real.")

The risk in this readout runs in both directions: counting an artifact as
ink, and missing real ink. We addressed both before looking at the target.

Against missing real ink: the identical pipeline (same checkpoint, same
settings, same threshold logic) was first run on a control segment with
published ground-truth ink labels (PHerc0139/w035, from the model's own
training set — a pipeline check, not a generalization test, as stated
above). It reproduced legible letterforms, the human-drawn labels landed
on top of them without being told where to look, and the labeled-ink
versus background medians separated 0.7843 to 0.2235. The threshold
applied to the target is that control-derived 0.7843, fixed before target
inference (see Calibration).

Against counting artifacts as ink: the criteria were applied mechanically
to both direction outputs. Of ~1.79 billion rendered pixels, 23,569
exceeded the threshold in both directions; these formed 1,282 connected
components, of which nine passed the 0.5 mm size floor. Eight of the nine
are sharp-edged, near-vertical bands at the rendered array's edges or at
winding boundaries, identical in position and shape in both directions, on
regions with no papyrus texture. They fail two preregistered exclusions
(mesh/winding-boundary artifacts; parallel-to-fiber orientation), and we
classify them as rendering-boundary artifacts. The ninth (candidate 458,
crop published alongside) is a diffuse region 0.552 mm along its long axis
against the 0.5 mm floor, aspect ratio 1.97, with no stroke-like
morphology; side by side with the control's letterforms it does not
resemble writing, and per the criteria's requirement that a signal be
stroke-like and survive comparison with the control, we do not count it.

Disclosure required by our own image checklist: the checkpoint's inference
patch is 128x128 px = 1.198 mm at native resolution, which exceeds the
prize page's 0.5x0.5 mm guidance for images generated by ML models. This
is the published checkpoint's fixed patch size; we make no letter claims
from these outputs, and the number is stated next to every published image
rather than silently checked off.

We are confident the nine above-threshold candidates are not ink because
each fails at least one criterion adopted before target inference. We are
confident the pipeline would have shown real ink because the same
pipeline, minutes earlier, showed it clearly on the control.

## Verdict (one sentence, written after the check above, published verbatim in the README)
[Not written. Cannot be written yet — no inference has run. This is the
entire "Reveal" beat of the demo script (1.6) and must be human-written,
after real results exist, per project_brief.md Section 8. No AI-generated
verdict prose, no exceptions.]
