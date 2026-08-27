<!--
Fact material for Lutfiya to write prereg/readout.md herself (E4, hard gate
on F5 — no ink inference on the target window until readout.md is committed).
Not the prereg itself: this is sourced facts and derived numbers only, no
criteria, no verdict, no prose. Compiled by the round terminal, 2026-08-27,
from expert_dossier.md and this session's own live-verified findings.
-->

# Prereg fact package — PHerc0826, window1 (z 10000-11000)

## D-03 — scale bar + letter dimensions (CONFIRMED, scrollprize.org/prizes)
> "Include a scale bar showing the size of 1 cm on the submission image, and
> the pixel and millimeter dimensions of a few representative letters."

Derived (computed, not sourced — check before trusting): PHerc0826 native
voxel size is 9.362 µm/px (confirmed, dossier + `spiral-scroll.json`). At
native resolution, 1 cm = 10,000 µm ÷ 9.362 µm/px ≈ **1,068 px**. Our demo
composite renders were written at `--scale 0.25` (see
`04_lasagna_flatten.sh`), so on THOSE specific images 1 cm ≈ 1,068 × 0.25 ≈
**267 px** — the scale bar must be computed against whatever scale the
*published* image actually uses, not assumed from the native voxel size
directly. State the render's scale factor next to the scale bar.

## D-05 — ML window size ≤ 0.5×0.5 mm (CONFIRMED, scrollprize.org/prizes)
> "We strongly discourage submissions that use window sizes larger than
> 0.5×0.5 mm to generate images from machine learning models."

Derived: 0.5 mm = 500 µm ÷ 9.362 µm/px ≈ **53 px** at native resolution.
This is the ink_9um model's own inference window/patch size, NOT the
display/render scale — check `vesuvius.ink_detection.inference.infer`'s
actual patch/stride behavior (its `--overlap`/`--stride` flags) against
this 53px figure before claiming compliance; not independently verified
this session that the model's default patch size is under this bound.

## D-08 — fiber-parallel rows (CONFIRMED, scrollprize.org/prizes)
> "letters in read samples run overwhelmingly parallel to the horizontal
> papyrus fibers"

Any published render needs to be checkable against fiber orientation. We
have `normal_x`/`normal_y` lasagna maps (used as fit inputs) but have not
produced a dedicated fiber-direction overlay render this session — flag as
a GAP if the published image needs one explicitly, rather than assuming the
flattened surface render alone makes fiber alignment checkable.

## D-25 — both directions (CONFIRMED, scrollprize.substack.com workflow post)
> "If you run out of GPU memory, reduce --batch-size to 1."
(source also documents `--direction both`, writing `segment.tif` and
`segment_reverse.tif`)

`06_ink_inference.sh` already runs `--direction both` correctly (CLI
verified live against `vesuvius.ink_detection.inference.infer --help` this
session, no fix needed). Preregistered criteria should require the signal
to reproduce in BOTH direction outputs, not just one, per this source.

## D-06 — held-out validation (re-verified live 2026-08-27 by the advisor: wording current)
> "Run your method on the public input renders/volumes with known ground
> truth (using k-fold validation if you trained on them) and include the
> results."
Re-fetched live 2026-08-27 (advisor): quote matches the current page verbatim. Safe to quote.

## D-07 — false-positive mitigation statement (re-verified live 2026-08-27; fuller current wording below)
> "If there is any risk of your model producing spurious patterns — apparent letterforms that are not actually supported by the data — please let us know how you mitigated that risk. Tell us why you are confident that the results you are getting are real."
(Re-fetched live 2026-08-27, advisor; this is the full current wording.) The `criteria_template.md` already has a
section for this, to be filled in AFTER inference without editing the
criteria retroactively.

## D-38 — positive-control segment recommendation (CONFIRMED for the
resolution match; two open caveats)
Recommended: **PHerc0139/w035** — natively 9.362 µm (no pooling needed),
the exact segment `tutorial5` itself uses as its worked ink_9um example.
**Open, not resolved this session:**
1. Whether `w035` specifically carries ink ground-truth labels in
   HuggingFace's `scrollprize/ink-labels` dataset was not independently
   verified (that dataset needs HF auth this session didn't have) — confirm
   before treating it as the control's ground truth.
2. It's a scroll segment, not a detached fragment — `ink-labels`' scroll
   ground truth is hand-annotated ink strokes, less rigorous than the
   infrared-photo-aligned fragment labels. None of the dataset's three
   detached fragments are natively near 9 µm (checked: 4.320 / 2.215-4.317 /
   2.215-4.320 µm), so this trades fragment-grade ground truth for
   resolution-native match and tutorial precedent — a real tradeoff, not a
   free win.

## Window-1 coverage is NOT uniform — relevant to scoping the target window
(New finding, this session, from the converged 30k-step CW fit.) Pulling
composite tiles across the full fitted winding range (w010-w129, 21 tiles
at `--max-strip-width 16384`) shows a clear quality gradient, not uniform
coverage:
- **Windings ~w010-w065 (tiles 000-~010, inner half):** dense, continuous,
  well-textured surface coverage.
- **Windings ~w065-w085 (tiles ~011-014):** transitional — thinner
  connections, visible gaps, still-legible structure.
- **Windings ~w085-w129 (tiles ~015-020, outer quarter):** sparse — small
  disconnected fragments against mostly-invalid background.

Aggregate `satisfied_tracks` is 14.4% (92,579/642,640) — this single number
averages over a region that is much better than 14.4% on the inside and
much worse on the outside. The fit converged genuinely (loss plateaued
~330-340 over the final several thousand steps, not still descending), and
both track density and normal maps are fixed inputs the optimizer can't
manufacture more of — the outer region's sparseness reads as a real
data-availability limit, not an under-optimization one.

**Recommendation for scoping the preregistered target window:** commit the
criteria to the well-covered inner region (roughly windings w010-w065) as
the primary ink-inference target, not the full w010-w129 range. Note the
outer region's sparse coverage as an honest limitation in the writeup —
consistent with the project's "ink or no ink, honestly" framing — rather
than silently including a region we already know is too thin to trust, or
spending more GPU-hours trying to fix a likely data-limited gap this close
to freeze.

## Not yet resolved / needs a human decision
- Exact x/y/z sub-window and winding range the preregistered criteria will
  commit to (recommendation above; final call is Lutfiya's).
- Whether the control segment caveats above (D-38) are acceptable as-is or
  need someone with HF access to check `ink-labels` ground truth for w035
  first.
