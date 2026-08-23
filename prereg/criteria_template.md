<!--
E4: commit this file (filled in, renamed to criteria_<scroll>_<z-window>.md) to
prereg/ and to git BEFORE running inference on the target window. The commit
hash goes in the README "Proof" beat (1.6, beat 4) and in the false-positive
audit (F6, analysis/). Criteria adapted from the First Letters image/validation
rules (D-03 through D-08 in expert_dossier.md) even though this submission
targets the Progress Prize, not First Letters — see H.E condition 1 in
project_brief.md: every published render must be labeled and claim nothing
beyond what's preregistered here.
-->

# Preregistration — [scroll] [z-window]

Committed: [date, before target inference runs]
Commit hash: [fill after `git commit`, then reference it in README]

## What counts as a positive signal
[Written BEFORE seeing target results. E.g.: "ink probability >X in the model
output, spatially coherent over an area of at least Y px, aligned parallel to
the horizontal fiber direction visible in the same render (D-08), and
reproducible in both --direction values (D-25)."]

## What does NOT count
[E.g.: isolated bright pixels, artifacts at tile-blend seams, signal that
appears in only one of the two --direction outputs, signal that does not
survive the held-out check below.]

## Held-out check (D-06)
Positive-control region: [name/coordinates of the curated positive-control
region — real data, deliberately selected, always labeled "control" per
project_brief.md 1.6 Demo-Daten]
Published ground-truth ink labels used: [source URL]
Expected result on the control: [what the pipeline should show if it's working]

## Image requirements for any published render (D-03, D-05, D-08)
- [ ] 1 cm scale bar
- [ ] Pixel and millimeter dimensions of any called-out feature
- [ ] ML window size ≤ 0.5mm x 0.5mm, and the actual window size used is stated next to the image
- [ ] Overlaid on a fiber-visible rendering so annotators can check fiber-parallel alignment
- [ ] Control shown side-by-side, labeled "control"

## False-positive mitigation statement (D-07) — fill in AFTER inference, do not edit criteria above retroactively
[Why we are or are not confident any apparent signal is real, per the criteria above.]

## Verdict (one sentence, written after the check above, published verbatim in the README)
[This sentence is the entire "Reveal" beat of the demo script (1.6). It must be
human-written per project_brief.md Section 8 — no AI-generated verdict prose.]
