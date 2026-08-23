# First Light — PHerc. 0[TODO: scroll ID after F1]

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
| Env setup (F2) | | | |
| Spiral fit (F3) | | | |
| Flatten + render (F4) | | | |
| Ink inference (F5) | | | |
| Controls (F6) | | | |
| **Total** | | | (cap: $150) |

Filled in from `logs/` after each real run — not estimated in advance.

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
Zero Academy components in this repo, ever (project_brief.md Section 8).
