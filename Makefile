# First Light — Vesuvius Challenge Progress Prize pipeline
# Single entry point. Every target shells out to the maintainers' own tools
# (villa/spiral-fitting, villa/lasagna, VC3D, villa/vesuvius) — nothing here
# reimplements their logic. Commands are sourced from:
#   - https://scrollprize.org/tutorial_spiral      (spiral fit)
#   - https://scrollprize.org/tutorial5            (render + inference flag reference)
#   - https://scrollprize.substack.com/p/from-ct-scan-to-ancient-text-a-first  (full workflow order)
#
# NOT YET RUN. Every target here is untested against the real GPU box and real
# scroll data — verify each one manually before trusting its output, and update
# this comment (and DECISION_LOG.md) once a target has actually completed.

SHELL := /bin/bash
.DEFAULT_GOAL := help

# --- Required per-run config (no defaults — fail loudly if unset) ---
# SCROLL:   e.g. PHerc0125  (must match a folder under spiral_datasets/)
# Z_BEGIN, Z_END: slice window in full-resolution voxels (tutorial recommends
#   a ~1,000-slice band for the first run: https://scrollprize.org/tutorial_spiral)
SCROLL ?=
Z_BEGIN ?=
Z_END ?=
RUN_TAG ?= window1

DATASET_DIR := spiral_datasets/$(SCROLL)
OUT_DIR := runbook/out/$(SCROLL)/$(RUN_TAG)
CHECKPOINT := checkpoints/ink_9um/hybrid_3d2d-seed42/step-075000.pth

.PHONY: help setup fetch-dataset spiral-fit flatten render infer controls first-render clean-check

help:
	@echo "Targets: setup fetch-dataset spiral-fit flatten render infer controls first-render"
	@echo "Required vars: SCROLL Z_BEGIN Z_END   (e.g. make first-render SCROLL=PHerc0125 Z_BEGIN=10000 Z_END=11000)"

setup:
	bash runbook/02_env_setup.sh

fetch-dataset:
	@test -n "$(SCROLL)" || (echo "SCROLL is required" && exit 1)
	rclone copy :http: ./spiral_datasets/$(SCROLL) \
		--http-url https://dl.ash2txt.org/datasets/spiral_datasets/$(SCROLL)/ \
		--transfers 32 -P

spiral-fit:
	@test -n "$(SCROLL)" || (echo "SCROLL is required" && exit 1)
	@test -n "$(Z_BEGIN)" || (echo "Z_BEGIN is required" && exit 1)
	@test -n "$(Z_END)" || (echo "Z_END is required" && exit 1)
	SCROLL=$(SCROLL) Z_BEGIN=$(Z_BEGIN) Z_END=$(Z_END) RUN_TAG=$(RUN_TAG) \
		bash runbook/03_spiral_fit.sh

flatten:
	@test -n "$(SCROLL)" || (echo "SCROLL is required" && exit 1)
	SCROLL=$(SCROLL) RUN_TAG=$(RUN_TAG) bash runbook/04_lasagna_flatten.sh

render:
	@test -n "$(SCROLL)" || (echo "SCROLL is required" && exit 1)
	SCROLL=$(SCROLL) RUN_TAG=$(RUN_TAG) bash runbook/05_render_tifxyz.sh

infer:
	@test -n "$(SCROLL)" || (echo "SCROLL is required" && exit 1)
	SCROLL=$(SCROLL) RUN_TAG=$(RUN_TAG) CHECKPOINT=$(CHECKPOINT) bash runbook/06_ink_inference.sh

controls:
	@test -n "$(SCROLL)" || (echo "SCROLL is required" && exit 1)
	SCROLL=$(SCROLL) CHECKPOINT=$(CHECKPOINT) bash runbook/07_controls.sh

# E1 — one command runs F3-F5 end to end from the pinned config.
first-render: spiral-fit flatten render infer
	@echo "first-render complete for $(SCROLL) $(RUN_TAG) — check $(OUT_DIR)"
