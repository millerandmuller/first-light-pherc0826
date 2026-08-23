# Runbook

Mirrors the maintainers' own First Letters workflow, one script per step.
Entry point is the repo-root `Makefile` — run `make help`.

| Step | Script | Feature | Status |
|---|---|---|---|
| Scroll selection | `01_scroll_selection.md` | F1 | done — pick: PHerc0826, backup: PHerc0358. Umbilicus NOT resolved (GAP — must be hand-annotated in VC3D, F2) |
| Provisioning (manual) | `02_provision_manual.md` | F2 | checklist written, needs your RunPod console + payment |
| Environment setup | `02_env_setup.sh` | F2 | written, not yet run |
| Spiral fit | `03_spiral_fit.sh` | F3 | written, not yet run — blocked on umbilicus annotation (see 01_scroll_selection.md GAPs) |
| Lasagna flatten | `04_lasagna_flatten.sh` | F4 (part 1) | written, not yet run |
| Render tifxyz | `05_render_tifxyz.sh` | F4 (part 2) | written, not yet run |
| Ink inference | `06_ink_inference.sh` | F5 | written, not yet run |
| Controls | `07_controls.sh` | F6 | written, not yet run — control segment still a GAP |

See `pr_drafts/TEMPLATE.md` (mirrors villa's actual PR template) and
`pr_drafts/PR_CHECKLIST.md` (pre-flight checklist) for F7; `prereg/criteria_template.md`
for E4; `analysis/false_positive_audit_template.md` for F6's written audit;
`renders/README.md` for F9.

Commands inside each script are sourced from the maintainers' own tutorials
(cited in each script's header comment), not invented. None have been run
against the real GPU box or real scroll data yet — that's the next concrete
step once RunPod is provisioned (F2) and a scroll is picked (F1).

Every actual run gets a same-day entry in `../logs/` (E5, TIL-style, written
by the person who ran it — timings and cost go in the README's cost table,
prose stays human-written).
