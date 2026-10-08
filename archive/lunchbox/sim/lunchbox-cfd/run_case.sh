#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
# SPDX-License-Identifier: MPL-2.0
#
# Mesh and solve one LunchBox case in WSL, then copy the results back beside the case. Fed on stdin, so no
# shell between Windows and WSL parses it (cfd.py prints the exact command):
#
#   wsl.exe -d Ubuntu -- bash -s -- <case folder as /mnt/c/...> <name> < archive/lunchbox/sim/lunchbox-cfd/run_case.sh
#
# Runs on WSL's own disk, ~/lunchbox-cfd/<name>: OpenFOAM writes thousands of small files, and /mnt/c is
# slow at that. Needs OpenFOAM v2412 in the micromamba env "of" (README.md, "Setting up").
set -eo pipefail
# micromamba's hook reads variables that may be unset, so -u comes on only after it has run.
export MAMBA_ROOT_PREFIX=${MAMBA_ROOT_PREFIX:-$HOME/.local/share/mamba}
eval "$("$HOME/.local/bin/micromamba" shell hook -s bash)"
micromamba activate of
# conda-forge's OpenFOAM v2412 links every binary with RPATH lib/sys-mpich:lib/dummy, but ships its MPI
# build of libPstream in lib/mpich-*, and no lib/sys-mpich. So a parallel run finds the dummy library and
# every rank stops with "The dummy Pstream library cannot be used in parallel mode". LD_LIBRARY_PATH
# cannot fix it - an RPATH outranks it. Supplying the folder the RPATH names does.
if [ ! -e "$CONDA_PREFIX/lib/sys-mpich" ]; then
    MPI_LIB=$(ls -d "$CONDA_PREFIX"/lib/mpich-* 2>/dev/null | head -n 1)
    [ -n "$MPI_LIB" ] && ln -s "$(basename "$MPI_LIB")" "$CONDA_PREFIX/lib/sys-mpich"
fi
set -u
SRC=$1
NAME=$2
W=$HOME/lunchbox-cfd/$NAME

rm -rf "$W" && mkdir -p "$W" && cp -r "$SRC"/. "$W"/ && cd "$W"
NP=$(awk '/^numberOfSubdomains/ {gsub(";", "", $2); print $2}' system/decomposeParDict)   # the case says how many cores
[ -n "$NP" ] || { echo "FAILED: no numberOfSubdomains in system/decomposeParDict"; exit 1; }
step() {
    local log="log.$1"
    echo "== $* ($(date +%H:%M:%S))"
    if ! "$@" > "$log" 2>&1; then echo "FAILED: $*"; tail -n 25 "$log"; exit 1; fi
}
step blockMesh
step snappyHexMesh -overwrite
step topoSet
step transformPoints -scale 0.001
step checkMesh
grep -E "^ +cells:|Mesh OK|\*\*\*" log.checkMesh || true
for z in hepa carbon sheet fan1 fan2 inlet outlet sheetFace fan1Around fan2Around; do
    grep -E "(cellZone|faceZone)Set $z\b.*now size|$z.*size" log.topoSet | tail -n 1 || true
done
step decomposePar -force
echo "== simpleFoam on $NP cores ($(date +%H:%M:%S))"
if ! mpirun -np "$NP" simpleFoam -parallel > log.simpleFoam 2>&1; then echo "FAILED: simpleFoam"; tail -n 40 log.simpleFoam; exit 1; fi
grep -E "^Time = |SIMPLE solution converged|End" log.simpleFoam | tail -n 3
step reconstructPar -latestTime
step foamToVTK -latestTime -noZero
rm -rf "$SRC/results" && mkdir -p "$SRC/results"
cp -r postProcessing VTK log.* "$SRC/results/"
cp -r "$(ls -d [0-9]* | sort -n | tail -n 1)/uniform" "$SRC/results/uniform" 2>/dev/null || true
echo "== done ($(date +%H:%M:%S)): results in $SRC/results"
