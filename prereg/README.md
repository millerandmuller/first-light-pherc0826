# Preregistration

E4: candidate-ink criteria committed here **before** target inference runs
(not after — that's the whole point of a preregistered readout).

File: `readout.md`, one commit, timestamped, referenced by hash in the final
README (Section "Proof", per project_brief.md 1.6). Once committed, the
criteria don't move. If inference later needs different criteria, that's a
new preregistration with its own commit and an honest note about why the
first one didn't hold.

Contents to define before running F5 on the target scroll:
- What counts as candidate ink (threshold, region size, consistency across
  --direction both)
- What counts as a false positive (see `../analysis/false_positive_audit.md`
  once F6 controls are run)
- The held-out check this will be compared against

Not written yet — this is a placeholder until the scroll is picked (F1) and
the team is ready to commit to criteria before running F5.
