// SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
// SPDX-License-Identifier: CC-BY-4.0

// parts/carbon.scad - THE CARBON ROW: two trays, front and back, each its own airway - the port in its top from the
// filter row's plenum, then the carbon, its dust floss, a Delta, and the clean air's plenum with the outlet in the
// inner face. Each on the bed, its inner face down. Included by filter-wall.scad; not a model on its own. Drawn
// where it sits.
//
// Not drawn yet: the carbon's mesh floor, the floss's frame, the fans' plate, the sensors' mounts, the louvre's
// slats, the hatch on the room's side, and the purge - a servo's damper and the 100 mm collar - in the back tray's.

module carbon_piece(name) let(p = piece(name), y0 = p[1], y1 = p[2]) difference() {
    translate([x_out, y0, 0]) cube([depth, y1 - y0, z_row]);
    translate([x_out - e, y0 + wall_t, wall_t]) cube([depth - face_t + e, y1 - y0 - 2 * wall_t, z_row - 2 * wall_t]);
    // the port, from the filter row's plenum
    translate([x_out + wall_t, y0 + wall_t, z_row - wall_t - e]) cube([plenum_d, y1 - y0 - 2 * wall_t, wall_t + 2 * e]);
    // the clean air's outlet, low in the inner face
    translate([x_in - face_t - e, (y0 + y1) / 2 - louvre[0] / 2, wall_t + louvre_z]) cube([face_t + 2 * e, louvre[0], louvre[1]]);
}
