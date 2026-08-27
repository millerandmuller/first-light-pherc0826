# F1 — Scroll selection

Gate for F3 (project_brief.md Section 3: "Resolve the umbilicus path, write the
pick rationale. Gate for F3."). Everything below was checked directly against
primary sources on 2026-08-23 by the round session (main loop, no forks, after
the concurrency incident logged in `../../DECISION_LOG.md` in the Academy
workspace — the earlier claim that F1 "research done" was false; this is the
real research).

**Revision note (two rounds):** a first pass of this file missed two real
umbilicus-annotation repos that a peer session's review caught. That review
also stated "sean" (source of PHerc0125/0211/0826's reference umbilici) is
villa maintainer "bruniss," and that PHerc0826 has "63 points." I checked the
repo's **README** and found neither claim there, and corrected both out.
That was itself incomplete: the peer then pointed out the attribution lives
in the raw `qc/sean_reference.json` file's own `what`/`source` metadata
fields, not the README prose — I fetched that file directly and confirmed it
verbatim (below). So: the point-count correction (49, not 63 — the peer's
"63" was a misread of that file's separate `kink` field, 63.390179) stands.
The attribution correction was wrong on my part — restored below, now
correctly sourced to the JSON file rather than left unsourced or dropped.
Lesson, twice over: verify a specific claim against the primary source it
actually points to (the data file, not just the README that describes it)
before writing it into a cite-or-GAP artifact, or striking it out.

## Candidate pool

Nine eligible scrolls with published spiral tracks at
`dl.ash2txt.org/datasets/spiral_datasets/` (confirms expert_dossier.md D-20):
PHerc0125, PHerc0191, PHerc0211, PHerc0257, PHerc0268, PHerc0358, PHerc0800,
PHerc0813, PHerc0826.

## What was checked, and how

1. **Existing public surface/ink work** — direct S3 bucket listing,
   `https://vesuvius-challenge-open-data.s3.amazonaws.com/?list-type=2&delimiter=/&prefix=<scroll>/`,
   checked for a `segments/` prefix (existing published surfaces/tracks
   independent of the spiral-tracks dataset) alongside the always-present
   `photos/`, `representations/`, `volumes/`.
2. **Umbilicus availability** — the `spiral_datasets/<scroll>/<timestamp>/`
   folder contents, checked for `umbilicus.json` next to `tracks/`
   (dossier D-21 established this pattern for PHerc0125; here it's checked
   for all nine).
3. **Community umbilicus annotations (H-U hypothesis)** — initial web/GitHub
   search only surfaced `github.com/JamesDarby345/Umbilicus_Maker` (stale
   since October 2024, covers only Scroll 1-4). A peer session's field-recon
   scan (`.academy/field/latest.json` in the Academy workspace) had two repos
   this search missed; I independently re-verified both directly against
   their actual GitHub content (README + raw JSON), not the peer's summary of
   them — see below. **H-U is supported.**
4. **Volume ID / actual bucket key** — `scrollprize.org/prizes` shows a
   *displayed* volume ID per scroll, but that ID is not the actual S3 object
   path. Confirmed directly (PHerc1203: displayed
   `20250720004030-9.362um-1.2m-113keV`, actual bucket folder
   `20250820131727-9.362um-1.2m-113keV-masked.zarr`) — different timestamps
   entirely. Every candidate below was re-checked against the real
   `volumes/` folder name via direct S3 listing; the Results table now
   reports the resolved key, not the marketing-page one.
5. **Tracks file size** — direct file listing under each scroll's
   `spiral_datasets/.../tracks/` folder (the `.dbm` track file +
   `.crossings.npz`), as a rough proxy for spiral-fit cost/practicality —
   this is an indirect signal, not a measured wall-clock (that remains a GAP
   per expert_dossier.md, "Time-to-first-ink-TIF").

### The two umbilicus repos (verified directly, not from the peer's summary)

**`github.com/AlexeyDrobkovStrikesBack/herculaneum-umbilici`** (MIT license,
most recent visible README update 2026-08-20). Covers ten of the thirteen
prize scrolls with hand-annotated umbilicus polylines: PHerc 0191, 0257, 0268,
0358, 0800, 0813, 1203, 1218, 1447, 1545 — confirmed verbatim from its README:
"Manual umbilicus (winding-axis) polylines for ten of the thirteen First
Letters prize scrolls." Separately, its README states: "The other three the
prize page lists — PHerc 0125, 0211, 0826 — already had published umbilici
from sean, which §3 uses as the calibration reference," and: "As far as we
can establish they exist only as the three attachments sean posted in the
Vesuvius Challenge Discord `#general` on 2026-08-08." The README alone does
not further identify "sean" — but `qc/sean_reference.json` (fetched raw,
directly, not from a peer's summary) carries top-level metadata fields that
do: `"what": "Derived quantities for the three published reference umbilici
by sean (bruniss), so the smoothness comparison in README section 3 has a
value and a provenance on a bare clone..."` and `"source": "posted by bruniss
in the Vesuvius Challenge Discord, #general, 2026-08-08, as three file
attachments"`. So the repo itself — via that data file, not its README prose
— does attribute "sean" to "bruniss." This is the **community repo's
third-party claim**, not bruniss self-identifying anywhere verifiable by us;
treat it as sourced-but-unconfirmed-at-origin until someone on the team
actually sees the Discord post.

`qc/sean_reference.json`'s per-scroll fields, fetched raw directly (not
relayed): PHerc0125 — sha256 `458e6ecf...`, 83 points. **PHerc0826** — sha256
`ddf2ffa2ab91270b4ccc443d22f10587090f1c5b5561d34dfc4c838ed7a451f3`, 4379
bytes, **49 points** (the file's separate `kink` field is 63.390179 — a
misread of that field as a point count is where an earlier "63" came from),
z-range 1941-16262. `scripts/fetch_sean.py --from <dir>` verifies a
locally-supplied file against these hashes; re-derive the hash yourself
(`sha256sum`) once the file is actually retrieved from Discord — don't take
any AI-relayed copy of it, including this one, as the final check.

**`github.com/TAUIL-Abd-Elilah/umbilicus-cross-validation`** (code: MIT;
six manual curve JSONs + a "PHerc0358 v2 candidate": CC BY 4.0, attributed to
Abd Elilah). Covers PHerc0191, PHerc0257, PHerc0358, PHerc0800, PHerc0813,
PHerc1203 with independent manually-annotated curves, plus a preregistered
correction candidate for PHerc0358 ("a preregistered z=5500 correction
candidate under audit/corrections/").

Both repos are themselves community submissions to the same August Progress
Prize cycle we're entering — using and crediting them is legitimate reuse and
gives them a real community-usage signal, which the prize criteria reward
(dossier D-11).

## Results

"Displayed ID" is what `scrollprize.org/prizes` shows; "Resolved bucket key"
is the actual `volumes/` folder name in the S3 bucket (see item 4 above) —
use the resolved key in any script, never the displayed one.

| Scroll | Displayed ID | Resolved bucket key | Voxel | `segments/`? | Umbilicus | Tracks size | Verdict |
|---|---|---|---|---|---|---|---|
| PHerc0125 | 20250720091415-... | 20250821151825-9.362um-1.2m-113keV-masked.zarr | 9.362um | No | Published — "sean" ref, 458e6ecf..., 83 pts, via Discord #general 2026-08-08 (herculaneum-umbilici repo) | 8.9 + 2.6 = 11.5 GiB | candidate |
| PHerc0191 | 20250720024445-... | 20250821151635-9.362um-1.2m-113keV-masked.zarr | 9.362um | No | Community hand-annotated (herculaneum-umbilici + TAUIL cross-validation, both cover it) | 9.2 + 2.2 = 11.4 GiB | candidate |
| PHerc0211 | 20250720140115-... | 20250821151803-9.362um-1.2m-113keV-masked.zarr | 9.362um | No | Published — "sean" ref (herculaneum-umbilici repo) | 7.0 + 1.9 = 8.9 GiB | candidate |
| PHerc0257 | 20250720113058-... | 20250821151750-9.362um-1.2m-113keV-masked.zarr | 9.362um | No | Community hand-annotated (both repos) | 6.0 + 1.4 = 7.4 GiB | candidate |
| PHerc0268 | 20250511054932-... | 20251110183117-8.640um-1.2m-116keV-masked.zarr | 8.640um | No | Community hand-annotated (herculaneum-umbilici) | 12.3 + 2.4 = 14.7 GiB | candidate, but largest + only 8.640um scroll, processed later (Nov 2025 vs Aug 2025) |
| PHerc0358 | 20250719150703-... | 20250821151737-9.362um-1.2m-113keV-masked.zarr | 9.362um | No | Community hand-annotated, both repos (+ TAUIL preregistered v2 correction candidate) | 5.6 + 1.4 = 7.0 GiB | candidate — backup |
| PHerc0800 | 20250510225703-... | not resolved (excluded before checking) | 8.640um | **Yes — 6 `auto_grown_*` segments** (2025-10-28/29) | n/a | not checked | **excluded** — existing public surface work fails H4's "no public ink results" requirement |
| PHerc0813 | 20250720160015-... | 20250821151723-9.362um-1.2m-113keV-masked.zarr | 9.362um | No | Community hand-annotated (both repos) | 7.6 + 2.0 = 9.6 GiB | candidate |
| PHerc0826 | 20250720174915-... | 20250821151701-9.362um-1.2m-113keV-masked.zarr | 9.362um | No | Published — "sean (bruniss)" ref per repo's own metadata, ddf2ffa2..., **49 pts**, z 1941-16262, via Discord #general 2026-08-08 (herculaneum-umbilici repo) | ~~5.0 + 1.4 = 6.4 GiB~~ **measured 2026-08-27: 11.555 GiB, 12 files** — the estimate below missed the `.dbm`'s hidden `.dbm.vctracks/` companion subdirectory (9 more files, incl. a 5.19 GiB `coordinates.i32`); see corrected D-29 | **smallest of the sean-covered scrolls — top pick** (on umbilicus + no-public-ink grounds; the tracks-size figure was wrong, see below) |

New dossier-style entries (continue `expert_dossier.md` numbering from D-26;
not yet copied into that file — do that alongside a full re-verification pass
if this pick is kept, per `expert_check.py`'s CONFIRMED/MISREAD workflow):

Tier note: `execution/expert_check.py`'s `T1_HOSTS` allowlist (confirmed by
reading the script directly) is government/standards bodies only (`gov`,
`europa.eu`, `bund.de`, `who.int`, `iso.org`, etc.) — `amazonaws.com` and
`dl.ash2txt.org` are NOT on it, so every entry sourced from those hosts must
be T2, not T1 (a peer session's review caught this; confirmed independently
by reading the allowlist myself rather than taking that at face value).

| ID | Typ | Aussage | Quelle (URL · Tier · Zugriff) | Zitat (≤25 Wörter, verbatim) | Status |
|---|---|---|---|---|---|
| D-26 | FACT | Of the nine eligible scrolls with published spiral tracks, only PHerc0800 has a `segments/` prefix in the open-data S3 bucket (6 `auto_grown_*` folders, dated 2025-10-28/29); the other eight have only `photos/`, `representations/`, `volumes/`. | https://vesuvius-challenge-open-data.s3.amazonaws.com/?list-type=2&delimiter=/&prefix=PHerc0800/ (and the same query per scroll) · T2 · 2026-08-23 | "PHerc0800/segments/20251028213516-auto_grown_20251028213516907/" | PENDING |
| D-27 | FACT | None of the nine eligible scrolls' `spiral_datasets/<scroll>/<timestamp>/` folders contain an `umbilicus.json`; all contain only `tracks/` (a `.dbm` file, `.crossings.npz`, and a small `.extract.json`). | https://dl.ash2txt.org/datasets/spiral_datasets/ (checked per-scroll) · T2 · 2026-08-23 | "tracks/" (only entry shown at each folder level) | PENDING |
| D-28 | FACT | `github.com/JamesDarby345/Umbilicus_Maker` is a community umbilicus-annotation project, but its published files (`umbilicus_points/s1A...s4_*.json`) cover only Scroll 1-4, current "as of october 2024" per its own README — it does not cover any of the nine 2025-batch eligible scrolls. | https://github.com/JamesDarby345/Umbilicus_Maker · T2 · 2026-08-23 | "This repo provides .json files that specify umbilicus points for each of the major released scroll scans as of october 2024" | PENDING |
| D-29 | JUDGMENT | **Corrected 2026-08-27 (round terminal, real box):** the original estimate below was wrong. Spiral-tracks dataset sizes read off each scroll's directory listing as `.dbm` + `.crossings.npz` only, giving about 6.4 GiB (PHerc0826) to about 14.7 GiB (PHerc0268) — this missed each `.dbm` file's hidden `.dbm.vctracks/` companion subdirectory (9 additional files per scroll, including a large `coordinates.i32`), which a shallow directory listing does not expand. Measured directly for PHerc0826 after `make fetch-dataset`: **11.555 GiB actual, 12 files** (rclone's own transfer summary), not 6.4 GiB. The other seven candidates' figures in the table above are not re-measured — treat all of them as similarly undercounted until fetched. | https://dl.ash2txt.org/datasets/spiral_datasets/ (per-scroll tracks/ listings, shallow) · T2 · 2026-08-23; corrected against `first-light-pherc0826` pod, rclone transfer log, 2026-08-27 | n/a (JUDGMENT, no single verbatim quote applies) | n/a |
| D-30 | FACT | `github.com/AlexeyDrobkovStrikesBack/herculaneum-umbilici` provides manual umbilicus polylines for ten of the thirteen prize scrolls, and states the other three (PHerc 0125, 0211, 0826) already had umbilici published by "sean" via Discord. | https://github.com/AlexeyDrobkovStrikesBack/herculaneum-umbilici · T2 · 2026-08-23 | "Manual umbilicus (winding-axis) polylines for ten of the thirteen First Letters prize scrolls" | PENDING |
| D-31 | FACT | `qc/sean_reference.json`'s own `what`/`source` metadata fields (not the README) attribute the three reference umbilici to "sean (bruniss)," posted in the Vesuvius Discord `#general` on 2026-08-08 as three file attachments — a third-party claim by the community repo, not bruniss self-identifying anywhere we've directly seen. For PHerc0826: sha256 `ddf2ffa2ab91270b4ccc443d22f10587090f1c5b5561d34dfc4c838ed7a451f3`, 4379 bytes, 49 points, z 1941-16262. | https://raw.githubusercontent.com/AlexeyDrobkovStrikesBack/herculaneum-umbilici/main/qc/sean_reference.json · T2 · 2026-08-23 | "posted by bruniss in the Vesuvius Challenge Discord, #general, 2026-08-08, as three file attachments" | PENDING |

## Pick

**Top pick: PHerc0826 — unchanged, but the size tiebreaker was wrong.**
**Correction (round terminal, 2026-08-27, real box):** this section originally
called PHerc0826 the smallest tracks dataset at 6.4 GiB — that figure was
wrong (see corrected D-29 above); the measured size is 11.555 GiB. The pick
itself stands, but not on a size tiebreaker that no longer holds without
re-measuring the other seven candidates (not done). **The pick's real
grounds are the umbilicus (D-30/D-31: already published, sha256-verified)
and no existing public surface/ink work** — both independent of tracks size.
Also unchanged: standard 9.362um voxel size (native fit for the `ink_9um`
checkpoint per dossier D-24, no pooling step needed). It's also one of the three scrolls with an already
published umbilicus (D-31): 49-point reference attributed to "sean (bruniss)"
by the community repo's own metadata, posted as a Discord attachment on
2026-08-08. **This changes the F3 gate**, and makes it easier, not harder:
instead of hand-annotating in VC3D, the gate is now "register in the
Vesuvius Discord, retrieve sean's three attachments from `#general`
(2026-08-08), and verify the PHerc0826 file's sha256
(`ddf2ffa2ab91270b4ccc443d22f10587090f1c5b5561d34dfc4c838ed7a451f3` — re-derive
this yourself with `sha256sum`, don't trust an AI-relayed hash, mine
included) before trusting it, e.g. via
`herculaneum-umbilici/scripts/fetch_sean.py --from <dir>`." VC3D hand-annotation
is now Plan B, only if the Discord files can't be obtained or don't verify.
Discord registration is therefore on the critical path for F3, not just for
submission (F10) — do it day 1.

**Backup: PHerc0358.** Second-smallest (7.0 GiB), same 9.362um voxel size.
Not "sean"-covered, but has independent community hand-annotated umbilici
from *both* repos (herculaneum-umbilici and TAUIL's cross-validation, which
also carries a preregistered v2 correction candidate for this scroll) — a
different but still real umbilicus path, arguably better cross-checked since
it's two independent annotators rather than one Discord attachment. If
PHerc0826's Discord files can't be retrieved/verified, or a field-recon scan
shows another team has started on it, switch here — matches project_brief.md
H.W2 pivot-trigger 1's "switch scroll" cost estimate (4h).

**Excluded: PHerc0800.** Has 6 existing `auto_grown_*` segments already in
the open-data bucket — fails the H4/H.W requirement of "no public ink result"
and undercuts the bet's core claim ("nobody had walked the workflow here").

## GAPs (honest, not papered over)

- **The tutorial omits `spiral-scroll.json` entirely — likely tutorial
  drift, not a gap in our understanding.** `villa/spiral-fitting`'s actual
  `fit_session.py` (main branch) requires a `spiral-scroll.json` file in the
  dataset root and will not run without one (dossier D-32) — but
  `scrollprize.org/tutorial_spiral` never mentions this file at all. See
  `02c_f3_preflight.md` for the full schema, verified directly against the
  source. This reads as the codebase having moved past what the tutorial
  documents ("version 27" per a comment in `fit_session.py`), not as
  something we misunderstood — worth a documentation PR to villa pointing
  this out, which is exactly the kind of Progress Prize material the bet is
  built on (dossier D-11).
- **No eligible dataset ships a `spiral-scroll.json`.** Checked directly:
  none of the nine candidates' `spiral_datasets/` folders contain one (same
  method as D-27) — every team attempting this workflow on any of the
  eligible scrolls hits this same wall. Candidate for a villa issue, not
  just a documentation PR: either the tutorial needs updating, or the
  eligible-scroll datasets are missing a file their own tooling now
  requires.
- **"Sean (bruniss)"'s attribution is sourced but not independently
  confirmed.** It comes from `qc/sean_reference.json`'s own metadata fields
  in the community repo (D-31) — a third party's claim, not something
  bruniss has confirmed to us directly and not something we've seen the
  original Discord post for. Worth a quick Discord check once registered
  (who actually posted in `#general` on 2026-08-08) rather than treating a
  community repo's attribution as beyond question.
- **Umbilicus for PHerc0826 still requires an action, just an easier one
  than originally scoped.** It's "fetch from Discord + verify sha256," not
  "hand-annotate in VC3D" — but it's not done yet, and Discord access is a
  prerequisite that didn't exist before this correction. Don't treat this as
  resolved until the file is actually retrieved and its hash actually
  matches `qc/sean_reference.json`.
- **The sha256 values and point counts quoted here came from one AI fetch of
  a raw GitHub file, not a byte-for-byte local verification.** Re-derive them
  yourself (`sha256sum` on the downloaded file, compare to
  `qc/sean_reference.json`) before trusting this pipeline's F3 input — this
  file already caught one wrong number relayed by a different AI session
  (63 vs. actual 49 points for PHerc0826); don't assume this file's own
  numbers are immune to the same risk.
- **Tracks file size is a proxy for spiral-fit cost, not a measurement.** No
  source gives per-scroll wall-clock or GPU-memory figures; this pick could
  still turn out to be the harder fit once real work starts. If PHerc0826
  fails badly early, the backup exists specifically so that isn't a dead end.
- **Did not check `photos/` or `representations/` contents** for visual
  quality/damage assessment (would need image review, not just directory
  listing) — worth a human glance before spiral-fit hours are committed,
  especially since the Hero Moment (project_brief.md 1.5) depends on the
  render actually being legible.
- **PHerc0800's segments/ content was not inspected** (just confirmed it
  exists) — if it turns out those are empty/failed auto-grown attempts
  rather than real surfaces, the exclusion reasoning would need revisiting.
  Treated as excluded on the conservative reading (a segment folder existing
  at all is enough to violate "no public ink results").
