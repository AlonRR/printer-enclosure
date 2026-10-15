// SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
// SPDX-License-Identifier: CC-BY-4.0

// vitamins/fans.scad - THE FANS: Delta EFB0412VHD, 40 x 40 x 20, two now and places for four (D300 a). Included by
// filter-wall.scad; not a model on its own. Drawn at its own origin: centred on X and Y, its intake at Z = 0.

/* [Hidden] */
delta = [40, 40, 20];   /* Square, and deep. As the BentoBox remix's vitamins/fans.scad has it, and Delta's sheet. */
delta_pitch = 32;       /* Between its screw holes. <<CONFIRM>> the usual 40 mm frame's; not measured here. */
delta_hole = 3.4;       /* Its screw holes. <<CONFIRM>> as the BentoBox's fan floor clears them. */

module delta_fan() color([0.15, 0.15, 0.15]) difference() {
    translate([-delta[0] / 2, -delta[1] / 2, 0]) cube(delta);
    translate([0, 0, -1]) cylinder(d = delta[0] - 3, h = delta[2] + 2, $fn = 48);
    for (sx = [-1, 1], sy = [-1, 1]) translate([sx * delta_pitch / 2, sy * delta_pitch / 2, -1])
        cylinder(d = delta_hole, h = delta[2] + 2, $fn = 16);
}
