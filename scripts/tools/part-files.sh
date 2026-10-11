#!/usr/bin/env sh
# SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
# SPDX-License-Identifier: MPL-2.0
# The part files scad-tools' scad-check.sh and printables.py take - one short file per printed part, which includes
# the BentoBox remix's model and sets what to draw - written into models/bentobox/.check/, which git ignores
# (scad-tools docs/project-layout.md). bentobox-print.sh runs it; run it yourself before printables.py. Add a line
# here for a new part in models/bentobox/parts/print.scad. The fans' plug mate has none: it is on hold, not to print.
#
#   sh scripts/tools/part-files.sh
set -eu
cd "$(dirname "$0")/../.." || exit 1
dir=models/bentobox/.check
mkdir -p "$dir"
part() {  # the part file's name, after bentobox-, then each setting past draw
    name=$1
    shift
    draw=$(printf '%s' "$name" | tr '-' '_')
    {
        printf '%s\n' "// SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz" "// SPDX-License-Identifier: CC-BY-NC-SA-4.0" \
            "// A remix of BentoBox v2.0 by ThrutheFrame (https://www.printables.com/model/272525), CC BY-NC-SA 4.0." "" \
            "// Written by scripts/tools/part-files.sh: the BentoBox remix's $name, as it prints." \
            "include <../bentobox.scad>" "draw = \"$draw\";"
        for s in "$@"; do printf '%s;\n' "$s"; done
    } > "$dir/bentobox-$name.scad"
}
for p in section auto-base auto-fans auto-tray carbon hepa cover cmag-tray cmag-lid cmag-grills bead-ring \
         glue-frame glue-sample grommet grommet-coupon joint-sample joint-sample-bead bottom-sample nut-coupon \
         samples-asa samples-asa-2 samples-tpu; do
    part "$p"
done
# The paper's clamp, shelved for the glue frame (T131, 9 Oct 2026), kept buildable.
for p in clamp-lower clamp-upper clamp-sample; do
    part "$p" 'hepa_frame = "clamp"'
done
echo "wrote $(ls "$dir"/*.scad | wc -l | tr -d ' ') part files in $dir"
