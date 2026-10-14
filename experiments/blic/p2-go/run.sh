#!/usr/bin/env bash
# experiments/blic/p2-go/run.sh — build and start prototype 2.
#
#   ./run.sh              build and run the console
#   ./run.sh --capture 'j,enter,peer:0'   build and render plain-text frames
#
# Needs a Go toolchain on PATH. See REPORT.md for what that costs.
set -euo pipefail
cd "$(dirname "$0")"
command -v go >/dev/null || { echo "run.sh: no go toolchain on PATH. REPORT.md §3 says what that means." >&2; exit 1; }
go build -o ./blic . && exec ./blic "$@"
