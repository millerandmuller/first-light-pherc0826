<!--
Mirrors villa/.github/pull_request_template.md verbatim (fetched 2026-08-23).
One copy per PR, named 00_<short-slug>.md. Fill every section — CONTRIBUTING.md
(D-13, D-14, D-15 in expert_dossier.md) makes all of these mandatory:
  - motivation + error screenshot for any bugfix
  - real scroll data only, never synthetic/toy examples
  - human-written commentary if any part of the diagnosis was LLM-assisted
    (Section 8 dealbreaker: humans write the PR motivation prose, always)
Checklist before opening: does this PR touch >20 files? large-pr-review-gate.yml
gates that (observed in dossier, not yet entered as a D-xx — verify before relying
on it). PRs auto-close after 14 days no activity / 28 days unmerged (D-16) — plan
same-day review responses (F7).
-->

**In one sentence:** <!-- Explain what someone can do with this; don't list features. -->

**One real example:** Starting with [real data/input], I [action], and it produced [result].

**Before:** <!-- What happened without this PR? -->

**After this PR:** <!-- What happens now? -->

**Proof:** <!-- Attach the image, video, output, or benchmark. Use the same input/settings for comparisons and say what we should look at. -->

**Why / where this is useful:** <!-- Who would use this result, and what can they do next? -->

- [ ] I personally verified that the example and proof above were produced by this PR on the stated data.

## Details

<!-- Method, exact tested commit, commands, data, checkpoints, comparisons, limitations, etc. -->

---
### Internal checklist (not part of the upstream PR — delete before submitting)
- [ ] Error screenshot attached (terminal or in-tool) — required for any bugfix (D-13)
- [ ] Demonstrated on real scroll data, not synthetic/toy (D-14)
- [ ] If any part of this diagnosis or fix used an LLM: human-written commentary added explaining relevance (D-15) — the motivation prose above must be human-written regardless
- [ ] Candidate wall-log entry: `logs/` (E5)
- [ ] Linked from `README.md` PR list once opened
