// SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
// SPDX-License-Identifier: CC-BY-4.0

// parts/cassette.scad - THE FILTER'S FRAME: a pocket open to the chamber, and at its back a land, with a window,
// that the filter seals on. It is the one part whose fit hangs on the filter in hand, so it is apart from the ring
// and cheap to print again once the filter is measured. Four corners, each on the bed, the land down. Included by
// filter-wall.scad; not a model on its own. Drawn where it sits.
//
// WHICH WAY THE AIR PUSHES: the fans draw from under the carbon, so the plenum behind the land is below the
// chamber's pressure, and the air presses the filter onto the land's seal. The filter goes in and out from the
// chamber (Alon, 15 Oct 2026), held at the inner face by retainers that carry no seal. The seal (TPU, D306 b),
// the retainers, and how the corners join and fix into the ring are not drawn yet.

// The land is a plate as large as the row's inside, so the cassette's outline is set; the pocket's walls stand on
// it round the filter, towards the chamber, and move with the filter's measures.
module cassette_whole() {
    difference() {
        translate([x_cass_back, cass_y0, cass_z0]) cube([land_t, cass[0], cass[1]]);
        translate([x_cass_back - e, cass_c[0] - window[0] / 2, cass_c[1] - window[1] / 2])
            cube([land_t + 2 * e, window[0], window[1]]);
    }
    difference() {
        translate([x_cass_back + land_t - e, cass_c[0] - pocket[0] / 2 - wall_t, cass_c[1] - pocket[1] / 2 - wall_t])
            cube([cass_d - land_t + e, pocket[0] + 2 * wall_t, pocket[1] + 2 * wall_t]);
        translate([x_cass_back + land_t - 2 * e, cass_c[0] - pocket[0] / 2, cass_c[1] - pocket[1] / 2])
            cube([cass_d - land_t + 3 * e, pocket[0], pocket[1]]);
    }
}

module cassette_piece(name) let(p = piece(name)) intersection() {
    cassette_whole();
    translate([p[5] - e, p[1], p[3]]) cube([p[6] - p[5] + 2 * e, p[2] - p[1], p[4] - p[3]]);
}
