# Spiral-fit run stats — PHerc0826, window1 (z 10000-11000)

Fact material for the human-written E5 TIL entries and the E3 cost table —
not itself an E5 entry (see `logs/README.md`: those are human-authored,
per-author, `YYYY-MM-DD-<author>.md`). Numbers below are what the round
terminal could verify directly; estimates are labeled as such.

| Run | RUN_TAG | Steps | Wall-clock | GPU-hours | Cost @ $0.72/hr | OOM/crash |
|---|---|---|---|---|---|---|
| CW (comparison) | `window1` | 1,500 | ~5-6 min (estimated from internal phase-elapsed markers: track load 2m01s + optimize ~1m28s + satisfaction/viz ~1m23s + mesh write 22s; no single wall-clock timestamp captured for this run) | ~0.1 | ~$0.07 | None |
| ACW (comparison) | `window1-ACW` | 1,500 | ~5-6 min (same estimation method as above) | ~0.1 | ~$0.07 | None |
| CW (full, converged) | `window1-full` | 30,000 | **29m49s** (precise: tmux launch 19:07:10 UTC → log last-write 19:36:59 UTC, 2026-08-27) | **0.497** | **$0.36** | None — clean convergence, no OOM, no silent death |

**Converged run detail (window1-full):** loss 955.9 → stable ~330-340 over the last several thousand steps (not still falling — genuine convergence, not a premature cutoff). `satisfied_tracks` 61,631/642,640 (9.6%) at 1,500 steps → 92,579/642,640 (14.4%) at 30,000 steps. `satisfied_track_points` 38.4% → 53.6%. Mesh written: winding range [10, 130), 240 tifxyz directories (120 windings × unspliced/spliced).

**Not included above:** the VC3D CLI build (`vc_render_tifxyz`, `flatboi`, etc. — one-time, ~15 min, CPU-only, not GPU-billed beyond idle pod time) and F4 pipeline verification runs (flatten + demo-composite render, real S3-streaming time, GPU-light) — those aren't spiral-fit runs and fall outside what the fit log's own reminder asked for. Flag if the E3 table wants them included too.
