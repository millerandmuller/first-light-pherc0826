<!--
F6: written false-positive audit, run through the identical pipeline as the
target on a curated positive-control region (labeled, never presented as
target data) plus a held-out check against published ground-truth ink labels.
Fill in after inference, cite the prereg criteria this was judged against.
-->

# False-positive audit — [scroll] [z-window]

Prereg criteria used: `prereg/criteria_<scroll>_<z-window>.md` (commit [hash])

## Control run
Positive-control region: [name/coordinates]
Result on control: [pass/fail against the criteria — the control should show
signal if the pipeline is working; if it doesn't, the pipeline is suspect
before the target result means anything]

## Held-out check
Ground-truth labels: [source URL, published]
Pipeline output vs. ground truth: [what matched, what didn't]

## Target result vs. criteria
[Apply the "what counts" / "what does NOT count" sections from prereg/ to the
actual target output. Be specific about which criterion each observed
feature does or doesn't meet.]

## Known failure modes checked
- [ ] Tile-blend seam artifacts (--overlap 0.5, --blend-mode hann) — checked at seam boundaries?
- [ ] Sparse-pyramid all-black render (D-19) — confirmed non-zero pixels before trusting this run?
- [ ] Direction disagreement — does --direction both agree?
- [ ] Fiber-parallel alignment (D-08) — does any called-out feature run parallel to horizontal fibers in the same render?

## Conclusion
[One paragraph. If this becomes the public verdict sentence, it must be
human-written per project_brief.md Section 8 — draft here, but the final
wording in README.md and prereg/ is not an agent's to write.]
