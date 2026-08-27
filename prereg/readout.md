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

- Median ink probability on the control's labeled ink-stroke pixels: [fill
  after control run]
- Median ink probability on the control's non-labeled background pixels:
  [fill after control run]
- Date/commit of this addition: [fill]

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
[Current full source wording, re-verified live 2026-08-27: "If there is any
risk of your model producing spurious patterns — apparent letterforms that
are not actually supported by the data — please let us know how you
mitigated that risk. Tell us why you are confident that the results you
are getting are real." Write this after seeing the actual results, against
the criteria above.]

## Verdict (one sentence, written after the check above, published verbatim in the README)
[Not written. Cannot be written yet — no inference has run. This is the
entire "Reveal" beat of the demo script (1.6) and must be human-written,
after real results exist, per project_brief.md Section 8. No AI-generated
verdict prose, no exceptions.]
