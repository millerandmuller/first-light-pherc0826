# First Light — PHerc. 0826

> Scroll pick from F1 (`runbook/01_scroll_selection.md`), backup PHerc0358.
> Not locked: the umbilicus is unresolved (GAP) and pivot-trigger 1 in
> project_brief.md H.W2 allows a scroll switch before feature freeze. Update
> this title and the [TODO]s below only once F3 actually succeeds on the
> chosen scroll — don't let the README get ahead of the pipeline.

> STRUCTURE ONLY. Every narrative section below is `[TODO: human-written]` —
> project_brief.md Section 8 (Dealbreakers) is explicit: "No AI-written prose
> in PR motivations, README narrative, or verdicts — humans write all public
> text." This file lays out where things go; a human fills in what actually
> happened. Do not ship this file with any TODO still in it.

We tried to read PHerc. 0[TODO] with the tools the Vesuvius team published on
[TODO: workflow post date]. This is what worked, what broke, what it cost,
and what we saw.

## First public look

[TODO: human-written] Banner render with a 1 cm scale bar. One sentence:
scroll, Z-window, pipeline version. Nothing suggestive — see
`prereg/readout.md` for what "ink" means here before you read the sentence
under this image.

## What broke on the way

[TODO: human-written] Links to the villa PRs this run produced, before/after
thumbnails per PR. Openness is the point, not a polished number — link open
PRs too if that's honestly where things stand.

## What we actually see

[TODO: human-written] Five-layer stack + both-direction predictions
(`segment.tif`, `segment_reverse.tif`) beside the labeled positive control.
One preregistered verdict sentence, committed in `prereg/readout.md` before
this inference ran. State it plainly. If there's no ink signal, the verdict
is the honest absence — say that, don't hedge it into sounding like more.

## Proof

[TODO: human-written] `prereg/` commit hash · audit table (link
`analysis/false_positive_audit.md`) · time/cost table (below).

### Time and cost (E3)

| Step | Wall-clock | GPU-hours | Cost (USD) |
|---|---|---|---|
| Env setup (F2) | not logged individually [1] | — | — |
| Spiral fit (F3) | ~40-42 min* [2] | ~0.70* | ~$0.50* |
| Flatten + render (F4) | ~56 min* (combined with F5) [3] | ~0.93* (combined) | ~$0.67* (combined) |
| Ink inference (F5) | see F4 [3] | see F4 | see F4 |
| Controls (F6) | not logged [4] | — | — |
| **Total** | ~71h pod uptime | idle-dominated, not a compute-hours figure | **$55.70** (cap: $150) |

Filled in from `logs/` and the RunPod account balance after each real run.
Cells marked `*` are estimates, not precise log timestamps.

[1] `02_env_setup.sh` (apt-get + two `uv sync` runs) has no wall-clock captured anywhere.

[2] Sum of all three real spiral-fit attempts: CW comparison (`window1`,
1,500 steps, ~5-6 min, estimated from internal phase markers) + ACW
comparison (`window1-ACW`, 1,500 steps, ~5-6 min, same estimation method) +
the converged run actually used downstream (`window1-full`, 30,000 steps,
precise: 29m49s / 0.497 GPU-hr / $0.36, tmux launch 19:07:10 UTC → log
last-write 19:36:59 UTC, 2026-08-27). Source: `logs/2026-08-27-spiral-fit-run-stats.md`.

[3] Render (F4 part 2) and inference (F5) ran together as one pipeline pass
against the converged `window1-full`, w010-w065 scope, 2026-08-28. The only
record is a wall-clock range, "roughly 17:12-18:08 UTC," without a
per-stage split — the precise log this estimate would come from was never
committed to this repo.

[4] `07_controls.sh` was run for real at least twice against PHerc0139/w035
(one attempt failed with an all-zero result from a mesh/volume registration
mismatch; a second succeeded after fixing the mesh path and adding
`--flip-normals`) — no wall-clock or cost was captured for either attempt.

**Total spend:** account balance $80.19 → $24.49 = **$55.70** against the
$150 cap. Pod was up continuously for ~71h at $0.72/hr ≈ $51 of that — the
large majority of it idle, not running any of the pipeline steps above; the
itemized real pipeline time in this table sums to under 2 hours. Network
volume (200GB, prorated) ≈ $1.40. The remainder (~$3) is other minor
pod-ledger disk charges, negligible. Lesson for the next person: stop your
pod between sessions — nearly all of this project's spend was idle rental
time, not compute.

## Reproduce it yourself

```
make first-render SCROLL=PHerc0[TODO] Z_BEGIN=[TODO] Z_END=[TODO]
```

One command, F3 through F5, from the pinned config. See `runbook/` for the
per-step scripts and their sources; see `Makefile` for the full target list.

## Real data, real fixes, documented for the next person

[TODO: human-written] Links: runbook, PRs, Discord thread, submission form
date.

---

License: MIT (from first commit, per project_brief.md Section H — Eligibility/Compliance).

## Zero Academy components, ever

This repo has its own git history, separate from the private Academy workspace,
specifically so this rule is structural, not a promise: never `git add`
anything from `directives/`, `execution/`, `Student (Prompt Architect)/`,
`The Examiner/`, `The Revision/`, `The Creative Director/`, `The Expert/`,
`academy_memory/`, `.academy/`, `expert_dossier.md`, `expert_consultations.md`,
`project_brief.md`, `examiner_report.md`, `revision_log.md`, `DECISION_LOG.md`,
or any other Academy-orchestration file. Those describe how the team worked,
not the scientific result, and the brief bans them from any public surface.
