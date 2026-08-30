# TIL — Lutfiya, 2026-08-27

TIL that a network volume locks the region, not the GPU. Created the volume
and deployed the pod (RTX PRO 4500, EU-RO-1), and the first-boot check
passed on Blackwell. Asked in #general whether no-ink renders of an
eligible scroll can be published — bruniss answered "yep!" within the hour.
The winding-sense question ate most of the day: I couldn't read CW vs ACW
off the slices by eye, three different AI models gave contradicting
answers, and a regression over 180k track points had no signal — the answer
finally came from the code itself (ACW is literally a mirror flip) plus
overlaying both fitted meshes on the real slice. Opened three villa PRs by
midnight and committed our readout criteria before any inference ran.
