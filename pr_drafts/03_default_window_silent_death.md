<!--
Mirrors villa/.github/pull_request_template.md verbatim (fetched 2026-08-23).
Prose below is Lutfiya's own (2026-08-27) — human-written per CONTRIBUTING.md
(D-15) and the project's working agreement. Paths/numbers/proof filled in by
the round terminal, all verified live against villa commit 6847063 on
first-light-pherc0826.

NOTE on the nvidia-smi proof requested below: no saved nvidia-smi terminal
capture exists for this specific run — the "<8 GiB of 32 GiB" figure comes
from a prior session watching nvidia-smi live while the run happened (see
DECISION_LOG.md 2026-08-27, "First real fit ran end-to-end..."), not from a
captured log file. Checked `d41_default_window_oom.log` directly for any
GPU-memory line — it has none (only unrelated host-side "GiB" figures for
the normals pool). Flagging this honestly rather than fabricating a
plausible-looking nvidia-smi block: if you have a real terminal capture
from that session, drop it in below; otherwise this PR should either cite
the figure as an observed-not-recorded fact, or we re-run the deliberate
default-window test once more with `nvidia-smi --loop` or `dstat`
capturing to a file before opening upstream.
-->

**In one sentence:** Records what actually happens if you run
`fit_spiral.py` without setting `z_begin`/`z_end`, which is not the failure
the tutorial prepares you for.

**One real example:** On PHerc0826, under a reduced config (patches off,
`dense_spacing_mode: grad_mag`, shell-loss weights zeroed), we left the
z-range at its default and the run reached real optimization, accelerated
past 0.9 it/s, and then died around 300 iterations — no traceback, no
error, ETA by then over 8 hours. GPU memory never went above 8 GiB of a
32 GiB card. <!-- see note above: the memory figure is an observed-live
fact from a prior session, not a captured log this PR attaches directly. -->

**Before:** The README says nothing about the default window. The tutorial
says to consider a small range because fitting all of Scroll 1 needs
"around 60 GB" of GPU memory — which reads as "you're fine if you have
enough VRAM." We had enough VRAM, so we ran it, and got a silent death
instead of an OOM. A silent death is much harder to diagnose than the error
you were told to expect.

**After this PR:** One paragraph noting that `config.py` defaults to
`z_begin = 4000`, `z_end = 17000` (the range inherited from the PHercParis4
production dataset, not something derived from the scroll you're fitting),
what we saw at that scale, and the honest state of the diagnosis — we don't
know what kills the process; a host-RAM kill during the ~8.4M-track
preparation is our leading candidate. The advice is to set a smaller window
regardless of your card's VRAM.

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

<!-- nvidia-smi memory-use capture: TODO(human) — not in hand as a saved
file; see the note at the top of this draft for options. -->

No `dmesg`/kernel-log access exists inside a RunPod pod to confirm the
exact cause; a host-RAM kill during preparation of 8,384,681 tracks for the
full 13,000-slice window is the leading candidate, not confirmed — the
resource-tracker warning immediately before the log stops is consistent
with an external process kill, not a Python exception.

**Why / where this is useful:** The existing guidance frames the risk as
GPU memory, so someone on a big card reasonably skips it. One README
paragraph turns a day of "why did my job vanish" into a non-event.

- [x] I personally verified that the example and proof above were produced
      by this PR on the stated data. (Round terminal, 2026-08-27, real box
      `first-light-pherc0826`; GPU-memory claim is observed-live, not from a
      saved capture — see note above.)

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
17000` — the range inherited from the PHercParis4 production dataset, not
something derived from the scroll you're fitting). This is not what the
tutorial's first-run example uses, and for good reason: under a reduced
config (patches disabled, `dense_spacing_mode: grad_mag`, zeroed
shell-loss weights — this repo's own tutorial-style setup), a full-range
PHerc0826 run reached real optimization, accelerated past 0.9 it/s, and
then died silently around 300 iterations with no traceback and an ETA that
had climbed past 8 hours — not the GPU out-of-memory error a "~60 GB, will
OOM" figure might lead you to expect (GPU memory use stayed under 8 GiB of
a 32 GiB card throughout). Whatever kills the process at this scale is not
confirmed (a host-RAM kill during the ~8.4M-track preparation for the full
window is the leading candidate). Set `z_begin`/`z_end` to a smaller
window (the tutorial's own ~1,000-slice recommendation is a reasonable
first run) regardless of your GPU's VRAM headroom.
```

**Comparisons:** N/A (documentation-only change).

**Limitations:** The exact cause of the silent death (host-RAM OOM vs.
something else) is not confirmed — this PR documents the observed symptom
and its real cost (multi-hour ETA, no clean error) honestly as unconfirmed,
not as a diagnosed root cause. Only tested against PHerc0826 and this
project's specific reduced config; behavior under villa's own full default
config (patches enabled, `dense_spacing_mode: phase`, nonzero shell
weights) was not tested and may differ. The GPU-memory figure is an
observed-live fact, not backed by a saved terminal capture (see note at
top).

**Disclosure:** We're a two-person team and we worked with an LLM
assistant on this, including the diagnosis and the patch. We directed the
work, ran everything on real PHerc0826 data, and checked the evidence
ourselves before opening this.

---
### Internal checklist (not part of the upstream PR — delete before submitting)
- [x] Error screenshot attached (terminal or in-tool) — death log excerpt
      above; not strictly required (D-13 scopes the gate to bugfix PRs,
      this is docs), included since it was captured for free
- [x] Demonstrated on real scroll data, not synthetic/toy (D-14)
- [x] LLM-assisted diagnosis and fix — human-written commentary added
      (D-15): disclosure paragraph above
- [x] Candidate wall-log entry: `logs/d41_default_window_oom.log` (raw log,
      already captured); human TIL prose still needed for E5
- [ ] Linked from `README.md` PR list once opened
- [ ] Decide on the nvidia-smi evidence gap (see note at top): cite as
      observed-not-recorded, or re-run once more with memory logging
      before opening upstream
