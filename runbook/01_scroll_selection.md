# F1 — Scroll selection

Gate for F3 (project_brief.md Section 3: "Resolve the umbilicus path, write the
pick rationale. Gate for F3."). Everything below was checked directly against
primary sources on 2026-08-23 by the round session (main loop, no forks, after
the concurrency incident logged in `../../DECISION_LOG.md` in the Academy
workspace — the earlier claim that F1 "research done" was false; this is the
real research).

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
3. **Community umbilicus annotations (H-U hypothesis)** — searched for the
   "public repo, 2026-08-16, ten First Letters scrolls" referenced in
   project_brief.md's H-U. Found `github.com/JamesDarby345/Umbilicus_Maker`,
   the only community umbilicus-annotation project surfaced by search or by
   checking villa's own docs. Its actual file listing
   (`umbilicus_points/`, checked via GitHub API) contains only
   `s1A/s1B/s2A/s3/s4_*_umbilicus_points.json` — the four original named
   scrolls (Scroll 1-4), not any PHerc-numbered volume, and its README states
   coverage "as of october 2024," which predates all nine candidates (all
   scanned/released 2025). **H-U is not supported by anything found — GAP,
   not confirmed.** No repo matching "ten First Letters scrolls, 2026-08-16"
   was located.
4. **Voxel size / volume ID** — `scrollprize.org/prizes`, full ID string per
   scroll.
5. **Tracks file size** — direct file listing under each scroll's
   `spiral_datasets/.../tracks/` folder (the `.dbm` track file +
   `.crossings.npz`), as a rough proxy for spiral-fit cost/practicality —
   this is an indirect signal, not a measured wall-clock (that remains a GAP
   per expert_dossier.md, "Time-to-first-ink-TIF").

## Results

| Scroll | Volume ID | Voxel | `segments/` exists? | Umbilicus | Tracks size | Verdict |
|---|---|---|---|---|---|---|
| PHerc0125 | 20250720091415-9.362um-1.2m-113keV | 9.362um | No (photos/representations/volumes only) | Not published (D-21, reconfirmed) | 8.9 + 2.6 = 11.5 GiB | candidate |
| PHerc0191 | 20250720024445-9.362um-1.2m-113keV | 9.362um | No | Not published | 9.2 + 2.2 = 11.4 GiB | candidate |
| PHerc0211 | 20250720140115-9.362um-1.2m-113keV | 9.362um | No | Not published | 7.0 + 1.9 = 8.9 GiB | candidate |
| PHerc0257 | 20250720113058-9.362um-1.2m-113keV | 9.362um | No | Not published | 6.0 + 1.4 = 7.4 GiB | candidate |
| PHerc0268 | 20250511054932-8.640um-1.2m-116keV | 8.640um | No | Not published | 12.3 + 2.4 = 14.7 GiB | candidate, but largest + only 8.640um scroll (116keV batch, processed later — Nov 2025 vs Aug 2025 for the rest) |
| PHerc0358 | 20250719150703-9.362um-1.2m-113keV | 9.362um | No | Not published | 5.6 + 1.4 = 7.0 GiB | candidate |
| PHerc0800 | 20250510225703-8.640um-1.2m-116keV | 8.640um | **Yes — 6 `auto_grown_*` segments** (2025-10-28/29) | n/a | not checked | **excluded** — existing public surface work fails H4's "no public ink results" requirement |
| PHerc0813 | 20250720160015-9.362um-1.2m-113keV | 9.362um | No | Not published | 7.6 + 2.0 = 9.6 GiB | candidate |
| PHerc0826 | 20250720174915-9.362um-1.2m-113keV | 9.362um | No | Not published | 5.0 + 1.4 = 6.4 GiB | **smallest — top pick** |

New dossier-style entries (continue `expert_dossier.md` numbering from D-26;
not yet copied into that file — do that alongside a full re-verification pass
if this pick is kept, per `expert_check.py`'s CONFIRMED/MISREAD workflow):

| ID | Typ | Aussage | Quelle (URL · Tier · Zugriff) | Zitat (≤25 Wörter, verbatim) | Status |
|---|---|---|---|---|---|
| D-26 | FACT | Of the nine eligible scrolls with published spiral tracks, only PHerc0800 has a `segments/` prefix in the open-data S3 bucket (6 `auto_grown_*` folders, dated 2025-10-28/29); the other eight have only `photos/`, `representations/`, `volumes/`. | https://vesuvius-challenge-open-data.s3.amazonaws.com/?list-type=2&delimiter=/&prefix=PHerc0800/ (and the same query per scroll) · T1 (primary data host) · 2026-08-23 | "PHerc0800/segments/20251028213516-auto_grown_20251028213516907/" | PENDING |
| D-27 | FACT | None of the nine eligible scrolls' `spiral_datasets/<scroll>/<timestamp>/` folders contain an `umbilicus.json`; all contain only `tracks/` (a `.dbm` file, `.crossings.npz`, and a small `.extract.json`). | https://dl.ash2txt.org/datasets/spiral_datasets/ (checked per-scroll) · T1 · 2026-08-23 | "tracks/" (only entry shown at each folder level) | PENDING |
| D-28 | FACT | `github.com/JamesDarby345/Umbilicus_Maker` is a community umbilicus-annotation project, but its published files (`umbilicus_points/s1A...s4_*.json`) cover only Scroll 1-4, current "as of october 2024" per its own README — it does not cover any of the nine 2025-batch eligible scrolls. | https://github.com/JamesDarby345/Umbilicus_Maker · T2 (community project, not an allowlisted host) · 2026-08-23 | "This repo provides .json files that specify umbilicus points for each of the major released scroll scans as of october 2024" | PENDING |
| D-29 | FACT | Spiral-tracks dataset sizes (`.dbm` + `.crossings.npz`) across the eight non-excluded candidates range from 6.4 GiB (PHerc0826) to 14.7 GiB (PHerc0268); PHerc0826 is smallest, PHerc0268 is both largest and the only 8.640um/116keV scroll among the eight. | https://dl.ash2txt.org/datasets/spiral_datasets/ (per-scroll tracks/ listings) · T1 · 2026-08-23 | file sizes as shown in each directory index (e.g. "5.0 GiB", "1.4 GiB" for PHerc0826) | PENDING |

## Pick

**Top pick: PHerc0826.** Smallest tracks dataset (6.4 GiB) among the eight
candidates with no existing public surface/ink work, standard 9.362um voxel
size (native fit for the `ink_9um` checkpoint per dossier D-24, no pooling
step needed), same processing batch/date (2025-07-20) as most of the other
candidates so no unexplained outlier. Smaller tracks size is a proxy, not a
measured wall-clock — chosen specifically because the budget is tight (F3
alone is budgeted 30h) and a smaller dataset lowers the risk of the
first-run OOM/timeout scenario that D-23 and the H1 GAP both flag as
unmeasured. No umbilicus is published for it — same as every other
candidate — so F3 cannot start until the umbilicus is produced (VC3D manual
annotation; the community-repo shortcut in H-U does not apply, see D-28).

**Backup: PHerc0358.** Second-smallest (7.0 GiB), same 9.362um voxel size,
same 2025-07-19/20 batch. If PHerc0826's umbilicus proves unexpectedly hard
to annotate (e.g. a damaged or ambiguous cross-section) or a field-recon scan
later shows another team has started on it, switch here — matches
project_brief.md H.W2 pivot-trigger 1's "switch scroll" cost estimate (4h).

**Excluded: PHerc0800.** Has 6 existing `auto_grown_*` segments already in
the open-data bucket — fails the H4/H.W requirement of "no public ink result"
and undercuts the bet's core claim ("nobody had walked the workflow here").

## GAPs (honest, not papered over)

- **H-U is not supported.** No repo or dataset matching "community umbilicus
  annotations, public, 2026-08-16, ten First Letters scrolls" was found by
  search or by checking the one community umbilicus project that does exist
  (Umbilicus_Maker, stale since Oct 2024, wrong scrolls). If this reference
  exists, it wasn't surfaced by web search or GitHub search as run here — a
  Discord search (not accessible from this session) is the next place to
  check, per project_brief.md's own day-1 Discord action.
- **Umbilicus for PHerc0826 (or any candidate) is not resolved, only
  scoped.** It must be produced by hand in VC3D once the box is provisioned
  (F2) — no shortcut exists. This directly blocks F3; do not commit spiral-fit
  hours until this step is actually done and someone has looked at the
  scroll's cross-section in VC3D to confirm it's annotatable.
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
