# villa PR checklist

Every PR against `ScrollPrize/villa` must clear this before it's opened, per
`CONTRIBUTING.md` (verbatim quotes below, fetched 2026-08-23 — reconfirm
against the live file before relying on this for a real submission, it can
change):

- [ ] **Motivation section** present: "detailing what it is you were
      attempting to do when this issue arose"
- [ ] **Error screenshot** (bugfix PRs): "a screenshot of the error (either
      terminal or within the tool), and the script/tool running without error
      afterward"
- [ ] **Before/after evidence**: "images or videos must be provided comparing
      results against current methods"
- [ ] **Real scroll data only**: "Bugfixes or improvements must be run on
      real scroll data. Synthetic or toy examples are not accepted" — no
      fixture/synthetic data anywhere near the PR (project dealbreaker, see
      project_brief.md Section 8)
- [ ] **Human-written commentary** if any part of the PR is LLM-assisted:
      "Any LLM generated PR must be accompanied by human-written commentary
      explaining why this PR is relevant or useful"
- [ ] Self-reviewed for simplicity/accuracy: "We expect that you have
      reviewed the code yourself for simplicity/accuracy"
- [ ] Follows `.github/pull_request_template.md`: "a concise explanation, one
      real example, and direct before/after evidence before any additional
      detail"
- [ ] PR motivation, narrative, and any verdict text is **human-written** —
      not AI-generated (project dealbreaker). Agents may draft the technical
      diff and error screenshot; a human writes the words.

## Auto-close risk (dossier D-16)

PRs are auto-closed after 14 days with no activity, or 28 days unmerged
(`.github/workflows/pr-time-limits.yml`, merged via PR #1521). Watch every
open PR and respond same-day if a maintainer comments (project_brief.md
Section H: "same-day review responses"). Whether an auto-closed PR still
counts for the monthly Progress Prize is an open GAP (H-A in
`expert_dossier.md`) — ask on Discord day 1, don't assume either way.

## One file per PR draft

Name each draft `pr_drafts/<villa-path>-<short-slug>.md` with sections
`## Motivation`, `## Error (before)`, `## Fix`, `## After`, `## Real-data
evidence`. Keep the actual PR body on GitHub as the source of truth once
opened; this file is the staging draft.
