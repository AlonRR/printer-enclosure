#!/usr/bin/env sh
# SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
# SPDX-License-Identifier: MPL-2.0
# Every part the BentoBox remix prints - and the sample plates - rendered, checked and sliced by scad-tools'
# scad-check.sh, each STL and its G-code collected in models/bentobox/print/, not left beside the sources.
#
#   sh scripts/bentobox-print.sh               every part
#   sh scripts/bentobox-print.sh samples-asa samples-tpu
#
# A part is its file's name without "bentobox-" and ".scad". OPENSCAD should name the nightly, as for the checks.
# Exit status: 0 every part built and sliced clean; 1 one would not build; 2 one built with warnings to read.
set -u
cd "$(dirname "$0")/.." || exit 1
OUT=models/bentobox/print
PROFILE="0.2mm QUALITY @MK3 - no skirt, no brim, no crossing perimeter"
ASA="Inslogic ASA"
TPU="Inslogic TPU 95A"
mkdir -p "$OUT"

# Each part: its name, how many separate bodies its plate holds, and its filament.
PARTS_LIST="section 1 ASA
auto-base 1 ASA
auto-tray 1 ASA
auto-fans 1 ASA
carbon 1 ASA
hepa 1 ASA
cover 1 ASA
clamp-lower 1 ASA
clamp-upper 1 ASA
bead-ring 1 TPU
grommet 1 TPU
fan-mate 1 ASA
joint-sample 3 ASA
joint-sample-bead 1 TPU
clamp-sample 2 ASA
bottom-sample 2 ASA
samples-asa 8 ASA
samples-tpu 2 TPU"

worst=0
summary=""
build() {
    name=$1 bodies=$2 material=$3
    case $material in ASA) fil=$ASA ;; *) fil=$TPU ;; esac
    src=models/bentobox/bentobox-$name.scad
    [ -f "$src" ] || { echo "no such part: $name ($src)"; worst=1; return; }
    log=$OUT/bentobox-$name.log
    PARTS=$bodies sh scad-tools/scripts/scad-check.sh "$src" "$PROFILE" "$fil" > "$log" 2>&1
    status=$?
    for ext in stl gcode; do
        [ -f "${src%.scad}.$ext" ] && mv -f "${src%.scad}.$ext" "$OUT/"
    done
    line=$(grep -E "printing time|filament used \[g\]" "$log" | sed 's/.*= //' | tr '\n' ' ')
    case $status in
        0) summary="$summary
  ok        $name  $line" ;;
        2) summary="$summary
  WARNINGS  $name  $line (read $log)"; [ $worst -eq 0 ] && worst=2 ;;
        *) summary="$summary
  FAILED    $name  (read $log)"; worst=1 ;;
    esac
}

if [ $# -eq 0 ]; then
    echo "$PARTS_LIST" | while read -r name bodies material; do echo "$name $bodies $material"; done > "$OUT/.list"
else
    : > "$OUT/.list"
    for want in "$@"; do
        found=$(echo "$PARTS_LIST" | while read -r name bodies material; do [ "$name" = "$want" ] && echo "$name $bodies $material"; done)
        if [ -n "$found" ]; then echo "$found" >> "$OUT/.list"; else echo "not a part: $want"; worst=1; fi
    done
fi
while read -r name bodies material; do
    echo "building $name"
    build "$name" "$bodies" "$material"
done < "$OUT/.list"
rm -f "$OUT/.list"
echo "$summary"
echo "in $OUT/"
exit $worst
