<!--
Mirrors villa/.github/pull_request_template.md verbatim (fetched 2026-08-23).
Facts and diff below are filled in by the round terminal (technical content
only, cite-or-GAP, all verified live against villa commit 6847063 on
first-light-pherc0826). The prose fields marked TODO(human) are NOT filled
in — motivation prose, "why useful", and the final PR description stay
strictly human-written per CONTRIBUTING.md (D-15) and the project's own
working agreement. This is a documentation PR (no code change) — CONTRIBUTING's
screenshot-gate for bugfix PRs (D-13) does not strictly apply, but the death
log below is included anyway since it landed for free while testing (D-41,
REVISED form in expert_dossier.md).
-->

**In one sentence:** TODO(human)

**One real example:** Running `fit_spiral.py` against PHerc0826 with no
`z_begin`/`z_end` override (villa's own default, `config.py:265-266`:
`z_begin = 4000`, `z_end = 17000`, the whole written region of the scroll)
died silently at 313/30,000 iterations with no Python traceback — not the
GPU out-of-memory error a newcomer would reasonably expect from a
`~60 GB` figure floating around for full-range fits.

**Before:** No documentation warns that the default fit window is the
*entire* scroll, nor what actually happens if you run it that way. The
`~60 GB, will OOM` figure some newcomers may have heard is not measured for
this pipeline's actual (patches-disabled, `dense_spacing_mode: grad_mag`,
zeroed shell-loss weights) config — real GPU memory stayed under 8 GiB of
32 GiB throughout our run, so a newcomer relying on that figure to justify
skipping the window override would not get the warning sign they expect.

**After this PR:** A note in `spiral-fitting/README.md` (placement TBD)
states the default window's real cost under a reduced/tutorial-style config:
minutes-scale reasonable-looking startup, then a multi-hour ETA and a
silent, untraceback'd death — not an OOM — and tells the reader to always
set `z_begin`/`z_end` explicitly for a first run regardless of which GPU
they have.

**Proof:**

Deliberate run with no window override, PHerc0826, this project's reduced
config (patches disabled, `dense_spacing_mode: grad_mag`, zeroed
shell-loss/dense-spacing weights), real box (`first-light-pherc0826`, RTX
PRO 4500 32GB), captured 2026-08-27 (`logs/d41_default_window_oom.log`):

```
scaled per-step counts by 1.368 for the 13000-slice z-range [4000, 17000) (reference 9500 slices):
  sample_count_tracks_per_step=65684
  ...
PROGRESS Optimizing — 1/30,000 iterations (0.0%) — 0.0 it/s — elapsed 2m 13s — ETA 1106h 48m
PROGRESS Optimizing — 113/30,000 iterations (0.4%) — 0.4 it/s — elapsed 4m 44s — ETA 20h 51m
PROGRESS Optimizing — 233/30,000 iterations (0.8%) — 0.7 it/s — elapsed 5m 15s — ETA 11h 09m
PROGRESS Optimizing — 313/30,000 iterations (1.0%) — 0.9 it/s — elapsed 5m 35s — ETA 8h 49m
/root/.local/share/uv/python/cpython-3.14.0-linux-x86_64-gnu/lib/python3.14/multiprocessing/resource_tracker.py:297: UserWarning: resource_tracker: There appear to be 2 leaked semaphore objects to clean up at shutdown: {'/mp-n4x9qydx', '/mp-0dh30lg4'}
  warnings.warn(
```
(Log ends there — no further output, no Python traceback, process gone.)
GPU memory throughout: under 8 GiB of 32 GiB (`nvidia-smi`, observed live,
not itself in this log excerpt). No `dmesg`/kernel-log access exists inside
a RunPod pod to confirm the exact cause; a host-RAM kill during preparation
of 8,384,681 tracks for the full 13,000-slice window is the leading
candidate, not confirmed — the resource-tracker warning immediately before
the log stops is consistent with an external process kill, not a Python
exception.

**Why / where this is useful:** TODO(human)

- [x] I personally verified that the example and proof above were produced
      by this PR on the stated data. (Round terminal, 2026-08-27, real box
      `first-light-pherc0826`.)

## Details

**Method:** villa commit `6847063ffdb4da898ae8d1d494ebf7d71473f509`
(2026-08-26 21:25 CEST). RunPod EU-RO-1, RTX PRO 4500 32GB (Blackwell,
sm_120). `SCROLL=PHerc0826`, no `Z_BEGIN`/`Z_END` override (villa's own
`config.py` default). Command: `fit_spiral.py` with `03_spiral_fit.sh`'s
other config overrides (patches disabled, `dense_spacing_mode: grad_mag`,
zeroed shell/spacing weights) but `z_begin`/`z_end` left unset.

**Proposed diff** (new note in `villa/spiral-fitting/README.md`, placement
TBD by whoever reviews the README's actual structure):

```markdown
## A note on the default fit window

If you don't set `z_begin`/`z_end`, `fit_spiral.py` defaults to the entire
written region of the scroll (`config.py`'s `z_begin = 4000`, `z_end =
17000`). This is not what the tutorial's first-run example uses, and for
good reason: under a reduced config (patches disabled, `dense_spacing_mode:
grad_mag`, zeroed shell-loss weights — this repo's own tutorial-style
setup), a full-range PHerc0826 run reached real optimization, accelerated
past 0.9 it/s, and then died silently around 300 iterations with no
traceback and an ETA that had climbed past 8 hours — not the GPU
out-of-memory error a "~60 GB, will OOM" figure might lead you to expect
(actual GPU memory use stayed under 8 GiB of a 32 GiB card throughout).
Whatever kills the process at this scale is not confirmed (a host-RAM kill
during the ~8.4M-track preparation for the full window is the leading
candidate). Set `z_begin`/`z_end` to a smaller window (the tutorial's own
~1,000-slice recommendation is a reasonable first run) regardless of your
GPU's VRAM headroom.
```

**Comparisons:** N/A (documentation-only change).

**Limitations:** The exact cause of the silent death (host-RAM OOM vs.
something else) is not confirmed — this PR documents the observed symptom
and its real cost (multi-hour ETA, no clean error) honestly as unconfirmed,
not as a diagnosed root cause. Only tested against PHerc0826 and this
project's specific reduced config; behavior under villa's own full default
config (patches enabled, `dense_spacing_mode: phase`, nonzero shell
weights) was not tested and may differ.

---
### Internal checklist (not part of the upstream PR — delete before submitting)
- [x] Error screenshot attached (terminal or in-tool) — death log excerpt
      above; not strictly required (D-13 scopes the gate to bugfix PRs,
      this is docs), included since it was captured for free
- [x] Demonstrated on real scroll data, not synthetic/toy (D-14)
- [x] LLM-assisted diagnosis and fix — human-written commentary required
      (D-15): motivation prose above (TODO(human)) is that commentary
- [x] Candidate wall-log entry: `logs/d41_default_window_oom.log` (raw log,
      already captured); human TIL prose still needed for E5
- [ ] Linked from `README.md` PR list once opened
- [ ] Human reviews the proposed diff's placement in the real README.md
      structure before opening (this file only proposes the content)
