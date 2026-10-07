#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
# SPDX-License-Identifier: MPL-2.0
#
# Carry a solved case on to a later end time, from where it stopped, without meshing it again - for a run
# that had not settled. Fed on stdin, like run_case.sh:
#
#   wsl.exe -d Ubuntu -- bash -s -- <case folder as /mnt/c/...> <name> <end time> < sim/bentobox-cfd/continue_case.sh
#
# Needs the case's working copy that run_case.sh left on WSL's disk, ~/bentobox-cfd/<name>, with its
# processor folders: simpleFoam starts from the latest time in them.
set -eo pipefail
export MAMBA_ROOT_PREFIX=${MAMBA_ROOT_PREFIX:-$HOME/.local/share/mamba}
eval "$("$HOME/.local/bin/micromamba" shell hook -s bash)"
micromamba activate of
set -u
SRC=$1
NAME=$2
END=$3
W=$HOME/bentobox-cfd/$NAME
cd "$W"
[ -d processor0 ] || { echo "FAILED: no processor folders in $W - run run_case.sh first"; exit 1; }
NP=$(awk '/^numberOfSubdomains/ {gsub(";", "", $2); print $2}' system/decomposeParDict)
sed -i "s/endTime [0-9]*;/endTime $END;/" system/controlDict
grep -q "endTime $END;" system/controlDict || { echo "FAILED: endTime not set"; exit 1; }
step() {
    local log="log.$1.continue"
    echo "== $* ($(date +%H:%M:%S))"
    if ! "$@" > "$log" 2>&1; then echo "FAILED: $*"; tail -n 25 "$log"; exit 1; fi
}
echo "== simpleFoam on $NP cores, on to $END ($(date +%H:%M:%S))"
if ! mpirun -np "$NP" simpleFoam -parallel >> log.simpleFoam 2>&1; then echo "FAILED: simpleFoam"; tail -n 40 log.simpleFoam; exit 1; fi
grep -E "^Time = " log.simpleFoam | tail -n 1
step reconstructPar -latestTime
rm -rf VTK
step foamToVTK -latestTime -noZero
rm -rf "$SRC/results" && mkdir -p "$SRC/results"
cp -r postProcessing VTK log.* "$SRC/results/"
cp -r "$(ls -d [0-9]* | sort -n | tail -n 1)/uniform" "$SRC/results/uniform" 2>/dev/null || true
sed -i "s/endTime [0-9]*;/endTime $END;/" "$SRC/system/controlDict"
echo "== done ($(date +%H:%M:%S)): results in $SRC/results"
