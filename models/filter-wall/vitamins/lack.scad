// SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
// SPDX-License-Identifier: CC-BY-4.0

// vitamins/lack.scad - THE ENCLOSURE the wall stands in: a Lack's legs, its floor and its roof. Included by
// filter-wall.scad; not a model on its own. Drawn where it stands, in the wall's frame: Y along the wall from the
// front leg's inner face, Z up from the floor, X across, 0 at the Lack's edge and + into the chamber.

/* [Hidden] */
lack_w = 550;       /* The Lack's top, square. The Lack's, as IKEA sells it; not measured. */
lack_leg = 50;      /* Its legs, square. The Lack's; not measured. */
lack_top_t = 50;    /* Its top's thickness. MEASURED 15 Oct 2026: 50.07 by caliper (T286). */
lack_chamber = 460; /* The chamber, floor to roof: 40 cm under the top and 6 more. Alon, 9 Oct 2026 (Q157). */

// reach: how far into the chamber the floor and the roof are drawn, so a figure is not all Lack.
module lack_context(alpha = 0.35, reach = lack_w) {
    color([0.85, 0.76, 0.6, alpha]) {
        for (y = [-lack_leg, lack_w - 2 * lack_leg]) translate([0, y, 0]) cube([lack_leg, lack_leg, lack_chamber]);
        translate([0, -lack_leg, -lack_top_t]) cube([reach, lack_w, lack_top_t]);
        translate([0, -lack_leg, lack_chamber]) cube([reach, lack_w, lack_top_t]);
    }
}
