#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
# SPDX-License-Identifier: MPL-2.0
#
# Run every pleat case (pleat.py cases) in WSL, side by side, and copy each one's results back beside it. Fed on
# stdin, so no shell between Windows and WSL parses it (pleat.py prints the exact command):
#
#   wsl.exe -d Ubuntu -- bash -s -- <the cases folder as /mnt/c/...> [ranks] < sim/bentobox-cfd/run_pleats.sh
#
# Each case is a few tens of thousands of cells and runs on one core; `ranks` of them run at once (14). Runs on
# WSL's own disk, ~/bentobox-cfd/<the cases folder's name>. Needs OpenFOAM v2412 in the micromamba env "of" (README.md).
set -eo pipefail
export MAMBA_ROOT_PREFIX=${MAMBA_ROOT_PREFIX:-$HOME/.local/share/mamba}
eval "$("$HOME/.local/bin/micromamba" shell hook -s bash)"
micromamba activate of
set -u
SRC=$1
RANKS=${2:-14}
# A folder of its own per set of cases (pleats, pleats-mesh), so two sets can run at once without one wiping the other.
W=$HOME/bentobox-cfd/$(basename "$SRC")
rm -rf "$W" && mkdir -p "$W" && cp -r "$SRC"/. "$W"/ && cd "$W"

one() {
    local c=$1
    cd "$W/$c" || return 0
    local s
    for s in blockMesh topoSet simpleFoam; do
        if ! "$s" > "log.$s" 2>&1; then echo "FAILED $c $s"; break; fi
    done
    rm -rf "$SRC/$c/results" && mkdir -p "$SRC/$c/results"
    cp -r postProcessing log.* "$SRC/$c/results/" 2>/dev/null || true
    echo "done $c $(grep -c '^Time = ' log.simpleFoam 2>/dev/null || echo 0) iterations"
}
export -f one
export W SRC
echo "== $(wc -l < list.txt) cases, $RANKS at a time ($(date +%H:%M:%S))"
xargs -P "$RANKS" -I{} bash -c 'one "$1"' _ {} < list.txt
echo "== all done ($(date +%H:%M:%S))"
