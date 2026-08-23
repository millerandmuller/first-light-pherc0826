# F2 — provision the box, fetch tools and data

This step needs your RunPod account and payment — it is not something an agent
does on your behalf. What follows is the grounded checklist; fill in the
TODOs from the actual console/CLI as you go, then this file becomes the real
runbook entry (E3 wants a time/cost line per step).

## 1. Provision (manual, RunPod console)
- Secure Cloud, A6000 48GB, + 200GB network volume (per project_brief.md
  Section 6 / DECISION_LOG.md 2026-08-23 "GPU rental research" entry — network
  volumes persist independently of the pod, matching a stop/resume usage
  pattern; community-tier pods can't attach one).
- Region: EU if available (project_brief.md 0. AI Runtime Profile).
- Budget discipline: cap is 150 USD total. Log every hour/dollar here as you
  go — this feeds E3's time/cost table directly.
- TODO: record actual $/hr once provisioned (brief estimate: ~$0.53/hr GPU +
  ~$0.07/GB/mo volume, per the DECISION_LOG GPU-rental entry — verify against
  the live RunPod price at provisioning time, prices drift).

## 2. Clone and pin villa
```bash
git clone https://github.com/ScrollPrize/villa.git
cd villa
git rev-parse HEAD   # record this — "pinned versions" is a Success Criterion
```
TODO: decide whether to pin to a specific tag/commit or track main; either
way, record the exact commit hash used for the submission run (Success
Criteria: "pinned versions").

## 3. Python environment (vesuvius / ink-detection extras)
Confirmed working command sequence (scrollprize.substack.com/p/from-ct-scan-to-ancient-text-a-first,
fetched 2026-08-23):
```bash
cd villa/vesuvius
uv sync --extra models
uv run --extra models python -c "import torch; print(torch.__version__, '| cuda:', torch.cuda.is_available())"
```
Requires Python >= 3.14 for the spiral fitter (D-22, expert_dossier.md) — `uv`
resolves this from the lockfile; commit the lockfile per project_brief.md
Section 6 ("committed lockfiles", D-22).
Note (D-18): the `models` extra pulls `cucim-cu13`, which only has Linux
wheels — this is fine on the rented Linux box, but don't try to `uv sync` this
locally on macOS to test.

## 4. VC3D
```bash
docker pull ghcr.io/scrollprize/villa/volume-cartographer:stable
```
TODO: exact run invocation (volume mounts, X11/VNC for the GUI if needed for
the manual mesh-inspection step in F3) — not covered by the source workflow
post, which describes VC3D as a GUI app opened locally. Confirm whether a
headless/remote-display setup is needed for a rented box, or whether mesh
inspection can be done by syncing `.tifxyz` output back to a local machine
with VC3D installed instead.

## 5. Ink checkpoint
```bash
uvx --from huggingface_hub hf download scrollprize/ink_9um \
  hybrid_3d2d-seed42/step-075000.pth \
  --local-dir checkpoints/ink_9um
```
(D-24: models expect ~9um isotropic surface volumes — matches our scroll pick,
see 00_scroll_selection.md for the per-scroll voxel size check.)

## 6. Scroll data (S3 streaming)
`s3://vesuvius-challenge-open-data/`, anonymous access — VC3D, the `vesuvius`
library, and lasagna stream directly, no local copy of the raw CT volume
needed (DECISION_LOG.md 2026-08-23 "Disk-footprint research" entry). Verify
streaming works from the rented box before relying on it (network egress from
RunPod to S3 was not measured — GAP in expert_dossier.md).

## 7. Spiral tracks + umbilicus for the chosen scroll
See `00_scroll_selection.md` — do not download the ~9 GiB tracks file until
the scroll pick is confirmed there.

## Sync policy
"Outputs synced after every step" (F2 requirement) — TODO: pick a mechanism
(rclone to the network volume, or push intermediates straight to a private S3
prefix / local machine) and record it here before F3 starts, so a pod restart
doesn't lose work.
