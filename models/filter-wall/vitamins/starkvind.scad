// SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
// SPDX-License-Identifier: CC-BY-4.0

// vitamins/starkvind.scad - THE FILTER: IKEA's STARKVIND particle filter (Alon, 15 Oct 2026: D303 a). Included by
// filter-wall.scad; not a model on its own. Drawn at its own origin: its long side along X, its short side along Y,
// its thickness along Z, the face taking the dirty air at Z = 0.
//
// IKEA lists it at 37 x 29 x 4 cm - whole centimetres - with a PET frame and non-woven polypropylene media, and
// says nothing of the frame's rim, which face takes the air, or how it seats (ikea.com, read 15 Oct 2026; its grade,
// EPA12, comes from other IKEA pages). Every number below waits for one in hand.

/* [Hidden] */
starkvind = [370, 290, 40]; /* Long, short, thick. <<CONFIRM>> IKEA's 37 x 29 x 4 cm, rounded to the centimetre. */
starkvind_rim = 12;         /* Its frame's rim on the face, each side, before the media starts. <<CONFIRM>> not listed. */
starkvind_upstream = "Z0";  /* Which face takes the dirty air. <<CONFIRM>> not listed: look for an arrow on its frame. */

module starkvind_filter() {
    l = starkvind[0]; w = starkvind[1]; t = starkvind[2]; r = starkvind_rim;
    color("white") difference() {
        cube([l, w, t]);
        translate([r, r, -1]) cube([l - 2 * r, w - 2 * r, t + 2]);
    }
    color([1, 0.95, 0.7]) translate([r, r, 1]) difference() {        // the pleated media, as a slab with grooves
        cube([l - 2 * r, w - 2 * r, t - 2]);
        for (x = [6 : 12 : l - 2 * r - 6]) translate([x, -1, -1]) cube([1, w - 2 * r + 2, 3]);
    }
}
