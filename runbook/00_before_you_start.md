# Before you start

Human-facing checklist for provisioning and the first real run. Nothing in
this pipeline has executed yet — everything below is what to do next, not a
record of what happened. Fill in the wall-clock/cost blanks as you go; they
feed the README's time/cost table (E3) later.

RunPod's own console has changed its deploy flow more than once recently
(there's a "legacy" and an "early access" layout circulating as of
2026-08-23) — the steps below describe the *intent* of each screen, not
guaranteed exact button text. If a label doesn't match what you see, look
for the nearest equivalent rather than assuming something's wrong.

## 1. Provision the RunPod box

Target: **Secure Cloud**, data center **EU-RO-1**, **200GB network volume**,
GPU chosen at deploy time — the volume locks the *region*, not the card, so
any EU-RO-1 GPU can attach to the same volume and be swapped between sessions
for free. First pick: **RTX PRO 4500 32GB** ($0.72/hr as of 2026-08-27) if
its Blackwell (sm_120) stack passes a first-boot check (torch imports, one
small fit step runs, the Triton kernels compile); otherwise fall back to the
**RTX 4090 24GB** ($0.74/hr), Ada (sm_89), whose wheel-level compatibility is
already verified. Budget cap: 150 USD total, per the brief. Network volume:
$0.07/GB/month for the first 1TB (~$14/month for 200GB, prorated). Re-verify
prices and capacity on the deploy page immediately before deploying; both
drift within hours.

> **Why not the A6000 48GB this file originally specified:** on 2026-08-25 it
> was unavailable (N/A) in all three data centers that carry it, so it could
> not be rented at any price. The 48GB L40S alternative exists only in EU-NL-1
> and costs $0.99/hr, which is $172 to the deadline and breaches the 150 USD
> cap. 24GB is sufficient for this workload: the largest step is the spiral
> fit, at an inferred 5-9 GiB for a ~1,000-slice window; ink inference needs
> 1-2 GB; flatten and render are not GPU-bound. EU-RO-1 was chosen over
> US-IL-1 (closer to the us-east-1 data bucket) because a RunPod network
> volume is region-locked at creation and the deploy page's Available tab
> showed six deployable cards in EU-RO-1 versus zero in US-IL-1 (2026-08-25,
> re-confirmed 2026-08-27). Do not trust the storage page's per-GPU
> availability badges: they disagree with the deploy page in both directions
> (a card badged "Low" was undeployable everywhere; a card badged "N/A" was
> deployable); only the deploy page, read immediately before deploying, is
> actionable. RunPod charges nothing for ingress, so a slow
> first sync costs hours once, whereas a volume stranded in a data center with
> no attachable GPU during deadline week costs the deliverable.

> **Trap before your first fit** (`spiral-fitting/config.py:265-266`): the fit
> window defaults to `z_begin = 4000`, `z_end = 17000` — the whole written
> region, which needs ~60 GB of GPU memory. You MUST set `Z_BEGIN`/`Z_END`
> explicitly or the run will OOM on any rentable consumer card.

1. **Create the network volume first, before deploying a pod** — RunPod
   requires this: a network volume can only be attached at pod-deployment
   time, not added or removed afterward without deleting the pod.
   - Console → **Storage** → **New Network Volume**.
   - Pick a data center (EU if available — this also constrains which GPUs
     you can later attach, since volumes are region-locked).
   - Size: **200 GB**.
   - Storage tier: **Standard** (not "High-Performance" — no need for it
     here, and it costs more).
   - Name it something you'll recognize, e.g. `first-light-PHerc0826`.
   - Create it. Note the region you picked — the pod has to go in the same one.
2. **Deploy the pod.**
   - Console → **+ New** (top right) → **Pod**, or the **Pods** sidebar item.
   - On the deploy/GPU-selection screen, find the **Network volume** filter
     and select the volume you just created — this narrows the GPU list to
     what's actually available in that same data center.
   - Make sure **Secure Cloud** is selected (not Community Cloud — Community
     Cloud pods cannot use network volumes at all).
   - Pick an **RTX A6000 (48GB)** card from the filtered list.
   - Template/container image: pick a template with CUDA + Python already
     set up (search for something like "PyTorch" in the template picker) —
     `02_env_setup.sh` and `runbook/02_provision_manual.md` handle the rest
     of the Python/uv setup on top of whatever base image you choose. There's
     no specific template pinned yet; note which one you actually used once
     you pick it, so the second run (F8 reproduction) uses the same one.
   - Under the SSH/access options, enable SSH terminal access and paste your
     public key.
   - Review the pricing summary (GPU $/hr + volume $/mo), then deploy.
3. **Confirm the volume is actually mounted.** RunPod's docs say a network
   volume replaces the pod's default volume disk and typically appears at
   `/workspace` inside the pod — confirm this yourself once connected
   (`df -h` or `ls /workspace`) rather than assuming it matches the docs
   exactly; mount paths have been known to vary by template.
4. **Connect via SSH.** Console → **Pods** → your pod → **Connect** → SSH
   tab has the exact `ssh` command with your pod's host/port. (HTTP-exposed
   services, if you add any later, show up under the same Connect panel as
   proxy URLs like `https://<POD_ID>-<PORT>.proxy.runpod.net`.)
5. **Do all your work under `/workspace`** (or wherever step 3 confirms the
   network volume actually mounted) — anything outside that path lives on
   the pod's ephemeral container disk and is lost if the pod is deleted,
   defeating the whole point of renting a volume that persists across
   stop/start cycles.

**Cost log (fill in as you go):**

| Item | Rate | Time/amount used | Cost |
|---|---|---|---|
| GPU (A6000 48GB) | $___/hr | ___ hr | $___ |
| Network volume (200GB) | $___/mo | ___ days | $___ |
| **Total so far** | | | **$___ / $150 cap** |

## 2. Environment variables the scripts expect

Every script fails loudly and tells you which one is missing if you forget
it — this table is just so you're not surprised. Set these as shell exports
(`export SCROLL=PHerc0826`) or pass them inline with `make`.

| Variable | Required by | Example / where it comes from |
|---|---|---|
| `SCROLL` | all steps | `PHerc0826` (top pick) or `PHerc0358` (backup) — see `01_scroll_selection.md` |
| `Z_BEGIN`, `Z_END` | `spiral-fit` | Slice window in full-resolution voxels, e.g. `Z_BEGIN=10000 Z_END=11000` (a ~1,000-slice band per `tutorial_spiral`'s own recommendation for a first run — not yet chosen for PHerc0826 specifically, pick this before running) |
| `RUN_TAG` | all steps | Defaults to `window1` in the Makefile — leave it unless you're running a second window (F12, conditional) |
| `VILLA_DIR` | most steps | Defaults to `villa` (relative to wherever you run `make` from) — only set it if you cloned villa somewhere else |
| `CHECKPOINT` | `infer`, `controls` | Defaults to `checkpoints/ink_9um/hybrid_3d2d-seed42/step-075000.pth` in the Makefile; `06_ink_inference.sh` downloads it automatically if missing |
| `VOLUME_ZARR` | `render` (`05_render_tifxyz.sh`) | **Not passed by the Makefile — you must export this yourself before `make render`.** The scroll's actual OME-Zarr path on the open bucket, e.g. `s3://vesuvius-challenge-open-data/PHerc0826/volumes/20250821151701-9.362um-1.2m-113keV-masked.zarr/` — confirm the exact resolved key for whichever scroll you're running against the live S3 listing before setting this, the way `01_scroll_selection.md` did for the candidates it checked (marketing-page IDs and real bucket keys differ — see that file's "volume-ID trap" note) |
| `CONTROL_SEGMENT`, `CONTROL_VOLUME_ZARR` | `controls` (`07_controls.sh`) | **Also not passed by the Makefile.** Recommended: **PHerc0139, segment `w035`** — see Section 6 below for the full rationale and the two things about this pick that are NOT independently confirmed |

## 3. Discord registration (both team members, day 1)

Both of you need to register before submitting — this is a Vesuvius
Challenge rule, not optional, and per the brief it's also now on F3's
critical path (the PHerc0826 umbilicus can only be fetched from Discord).

1. Join: https://discord.gg/V4fJhvtaQn (invite link, `scrollprize.org/faq`,
   fetched 2026-08-23 — links like this can expire, get a fresh one from
   the FAQ page if this doesn't work).
2. Both of you join with your own accounts — the brief's eligibility notes
   say both members register.
3. Ask the two open questions from `expert_dossier.md`'s GAPs / H-U/H-A
   hypotheses while you're in there, early:
   - Does publishing no-letter renders of an eligible scroll violate
     anything? (Non-disclosure clause is scoped to "discovery" per D-09, but
     nothing states outright that a no-letter render is fine to publish.)
   - Does a PR auto-closed by the 14-day inactivity rule still count for the
     monthly Progress Prize?
4. Note the exact channel and date conventions you see in `#general` — you
   need this context for step 4 below.

## 4. Fetch bruniss's PHerc0826 umbilicus and verify it

Per `expert_dossier.md` D-30/D-31: the PHerc0826 umbilicus was posted by
someone the community repo's own metadata identifies as "sean (bruniss)," in
`#general` on **2026-08-08**, as three file attachments (one per scroll:
PHerc0125, PHerc0211, PHerc0826). That identification is the community
repo's own claim, not something we've independently confirmed by seeing the
actual Discord post — worth a glance at who really posted it once you're in
the channel.

**Option A — use the community repo's own fetch tool** (recommended, it
verifies the hash for you):

```bash
git clone https://github.com/AlexeyDrobkovStrikesBack/herculaneum-umbilici.git
cd herculaneum-umbilici
# Download the PHerc0826 attachment from Discord #general (2026-08-08) to
# some local directory first, named PHerc0826_umbilicus.json, then:
python3 scripts/fetch_sean.py --from /path/to/downloaded/files
```

This checks all three of sean's files (not just PHerc0826) against the
hashes in `qc/sean_reference.json`, and on success writes the verified copy
to `ref_sean/PHerc0826_umbilicus.json` (and the other two, if present)
inside the `herculaneum-umbilici` checkout. On a mismatch it writes
`PHerc0826_umbilicus.json.mismatch` instead of installing it — read that
file yourself if it happens, don't just retry blindly.

**Option B — verify by hand**, if you'd rather not clone another repo:

```bash
shasum -a 256 /path/to/downloaded/PHerc0826_umbilicus.json
```

Expected output:

```
ddf2ffa2ab91270b4ccc443d22f10587090f1c5b5561d34dfc4c838ed7a451f3  PHerc0826_umbilicus.json
```

(4379 bytes — `ls -l` the file to cross-check the size too, both numbers
should match before you trust the file.) If the hash doesn't match, stop —
don't use the file, and don't assume the mismatch is on your end without
checking whether the Discord attachment itself changed.

**Where to place it for `03_spiral_fit.sh`:** the script's `--dataset`
argument points at the timestamped folder discovered under
`spiral_datasets/PHerc0826/<timestamp>/` (see `01_scroll_selection.md` —
currently `20250821151701` for PHerc0826, but the script discovers this
dynamically rather than hardcoding it, so confirm the actual folder name
after `make fetch-dataset` runs). Place the verified file there as:

```
spiral_datasets/PHerc0826/20250821151701/umbilicus.json
```

**This exact filename and location is inferred, not independently
confirmed for our case** — it matches the pattern dossier D-21 observed for
a different scroll (PHercParis4, which ships `umbilicus.json` directly
alongside its `tracks/` folder), and it's what `tutorial_spiral`'s
`fit_spiral.py` config implies it wants, but nobody on this team has yet
watched `fit_spiral.py` actually find and accept this file. If it doesn't
pick it up, check `fit_spiral.py`'s own `--help` or source for the exact
expected filename before assuming the umbilicus itself is bad.

## 5. Positive control segment (F6)

Recommended: **PHerc0139, segment `w035`**, natively 9.362um — no pooling
step needed to match the `ink_9um` checkpoint (dossier D-24), and the exact
segment `tutorial5` uses as its own worked example for that checkpoint.

Considered and rejected the three detached fragments in the `ink-labels`
dataset (`scrollprize/datasets`, `ink` branch) — none is a native
resolution match: `PHerc0009B` (4.320um), `PHerc0500P2` (2.215um/4.317um),
`PHerc0343P` (2.215um/4.320um). All would need an unverified pooling step,
which seemed like a worse trade-off for a first control run than accepting
scroll-type ground truth (dossier D-38).

**Two things NOT independently confirmed, resolve before trusting this as
the actual control:**
1. HF's `scrollprize/datasets` repo requires authentication this session
   didn't have — whether `w035` specifically carries ink ground-truth
   labels in the `ink-labels` dataset (as opposed to some other PHerc0139
   segment) was not verified. Someone with HF access should check this
   before F6 runs for real.
2. `PHerc0139` is a scroll segment, not a detached fragment. Per the
   `ink-labels` README, scroll ground truth is hand-annotated ink strokes;
   fragment ground truth is aligned to an actual infrared photo of the
   exposed writing, a stronger form of evidence. This pick trades that
   rigor for resolution-native match and a documented working precedent.

If you'd rather have fragment-grade ground truth and are willing to add a
pooling step, `PHerc0009B` is the closest resolution among the three
checked (4.320um → ~9um is roughly 2x downsampling, similar in kind to the
2.4um→9.6um pooling case D-24 already documents as workable, though not
verified for this specific fragment).

`CONTROL_VOLUME_ZARR` for PHerc0139 (from `tutorial5`'s own example):
`s3://vesuvius-challenge-open-data/PHerc0139/volumes/20250728140407-9.362um-1.2m-113keV-masked.zarr/`

**Where to actually download the `w035.tifxyz` segmentation itself was not
found** — `tutorial5` uses it as a pre-existing local path
(`ink-dataset/pherc0139/w035/w035.tifxyz`) without saying where it comes
from, and a guessed `dl.ash2txt.org` path for it 404'd. Check the Data
Browser or ask in Discord for the actual source before this step.

## 6. Order to run the make targets

Run these from the repo root, in order. Each one is a real command against
real data/hardware for the first time — go slowly, read the output, and
fill in the blanks as you go rather than after the fact.

| # | Command | What it does | Wall-clock | Cost |
|---|---|---|---|---|
| 1 | `make setup` | Clones villa, sets up spiral-fitting + vesuvius Python envs via `uv` | ___ | ___ |
| 2 | `make fetch-dataset SCROLL=PHerc0826` | Downloads the ~6.4 GiB spiral tracks dataset via rclone | ___ | ___ |
| — | *(manual: Section 4 above)* | Fetch + verify + place the umbilicus | ___ | ___ |
| — | *(manual: `02c_f3_preflight.md`)* | Write `spiral-scroll.json`, determine `spiral_outward_sense` in VC3D, download `normal_x`/`normal_y` overrides | ___ | n/a |
| 3 | `export VOLUME_ZARR=...` | Set before step 5 — see Section 2 table | n/a | n/a |
| 4 | `make spiral-fit SCROLL=PHerc0826 Z_BEGIN=___ Z_END=___` | Fits the spiral mesh to the chosen Z-window | ___ | ___ |
| 5 | *(manual)* write `segment_flatten_input.json` | Points at the spiral-fit mesh from step 4 — schema not documented upstream, see `04_lasagna_flatten.sh`'s own comment | ___ | n/a |
| 6 | `make flatten SCROLL=PHerc0826` | Flattens the fitted mesh via lasagna | ___ | ___ |
| 7 | `make render SCROLL=PHerc0826` | Renders the flattened surface to a layered zarr (includes the D-19 sanity check) | ___ | ___ |
| 8 | `make infer SCROLL=PHerc0826` | Downloads the ink_9um checkpoint if needed, runs both-direction ink inference | ___ | ___ |
| 9 | Download the `w035` segmentation for PHerc0139, then `export CONTROL_SEGMENT=/path/to/downloaded/w035.tifxyz CONTROL_VOLUME_ZARR=s3://vesuvius-challenge-open-data/PHerc0139/volumes/20250728140407-9.362um-1.2m-113keV-masked.zarr/` | `CONTROL_SEGMENT` must be a local filesystem path to the actual `.tifxyz` segmentation (`07_controls.sh` passes it straight to `vc_render_tifxyz --segmentation`), not just a name — see Section 5 for where to get it and the two unconfirmed caveats on this pick | n/a | n/a |
| 10 | `make controls SCROLL=PHerc0826` | Runs the positive control through the identical pipeline | ___ | ___ |
| | **Total** | | **___** | **___ / $150 cap** |

Steps 4+6+7+8 together are also available as one command,
`make first-render SCROLL=PHerc0826 Z_BEGIN=___ Z_END=___` (E1), once steps
1–3 and the manual step 5 are done — but running them one at a time the
first time through is worth it so you can actually see where any real
failure happens, rather than losing GPU-hours to a chain you can't inspect
mid-run.

Log every real run's timing and cost the same day in `../logs/` (E5) —
that's what backfills this table and the README's own time/cost section
later, and it's the raw material for the honest write-up, not something to
reconstruct from memory afterward.
