// SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
// SPDX-License-Identifier: CC-BY-4.0

// parts/ring.scad - THE FILTER ROW'S FRAME: a ring as deep as the wall - its top under the roof, its bottom on the
// carbon row, its ends at the legs - and a flange at the inner face between each end and the cassette. Four
// corners, each on the bed. Included by filter-wall.scad; not a model on its own. Drawn where it sits.
//
// Open towards the room: the hatch that closes it, and through which the filter changes, is not drawn yet. Its
// bottom is open over the plenum behind the cassette: the port the air takes down into the carbon row.

module ring_whole() {
    H = lack_chamber;
    difference() {
        translate([x_out, 0, z_row]) cube([depth, open_l, filter_row_h]);
        translate([x_out - e, wall_t, z_row + wall_t]) cube([depth + 2 * e, open_l - 2 * wall_t, filter_row_h - 2 * wall_t]);
        // the port: the bottom wall over the plenum
        translate([x_out + wall_t, wall_t, z_row - e]) cube([plenum_d, open_l - 2 * wall_t, wall_t + 2 * e]);
    }
    // the end flanges, in the inner face between the ends and the cassette
    for (y = [[wall_t, cass_y0], [cass_y0 + cass[0], open_l - wall_t]])
        translate([x_in - face_t, y[0] - e, z_row + wall_t - e]) cube([face_t, y[1] - y[0] + 2 * e, filter_row_h - 2 * wall_t + 2 * e]);
}

module ring_piece(name) let(p = piece(name)) intersection() {
    ring_whole();
    translate([p[5] - e, p[1], p[3]]) cube([p[6] - p[5] + 2 * e, p[2] - p[1], p[4] - p[3]]);
}
