// SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
// SPDX-License-Identifier: CC-BY-4.0

// assembly/wall.scad - THE WALL ASSEMBLED, in the Lack, and exploded: every part where it sits, the filter in its
// pocket, the carbon, the floss, the fans and the sensors as placeholders, and the xyz arrows every figure carries.
// Included by filter-wall.scad; not a model on its own.

module filter_home() translate([filter_x, cass_c[0] - starkvind[0] / 2, cass_c[1] - starkvind[1] / 2])
    rotate([90, 0, 90]) mirror([0, 0, 1]) starkvind_filter();   // long side along Y, upstream face at filter_x

module carbon_contents() {
    for (h = [[0, split_y], [split_y, open_l]]) let(y0 = h[0] + wall_t, y1 = h[1] - wall_t) {
        color([0.2, 0.2, 0.2]) translate([x_out + wall_t, y0, bed_bot]) cube([depth - wall_t - face_t, y1 - y0, bed_depth]);
        color([0.93, 0.93, 0.93]) translate([x_out + wall_t, y0, floss_bot]) cube([depth - wall_t - face_t, y1 - y0, floss_t]);
    }
    for (y = fans_at) translate([(x_out + x_in) / 2, y, fan_bot]) delta_fan();
    translate([x_in - face_t - sps30[2], split_y + wall_t + 20, wall_t + 2]) rotate([0, 90, 0]) translate([-sps30[0], 0, 0]) sps30_sensor();
    translate([x_in - face_t - sgp41[2], split_y + wall_t + 70, wall_t + 2]) sgp41_sensor();
}

module wall_colour(name) color(
    len([for (p = cassette_pieces) if (p[0] == name) p]) > 0 ? [0.95, 0.55, 0.25]
    : len([for (p = carbon_pieces) if (p[0] == name) p]) > 0 ? [0.55, 0.62, 0.7] : [0.75, 0.8, 0.86]) piece_drawn(name);

// Exploded: each piece away from the wall's middle along the wall and up it, the ring and the carbon trays out
// into the room, the cassette and the filter in towards the chamber.
function explode_of(name) = let(p = piece(name), yc = (p[1] + p[2]) / 2, zc = (p[3] + p[4]) / 2,
        out = len([for (q = cassette_pieces) if (q[0] == name) q]) > 0 ? 2 * explode
            : len([for (q = carbon_pieces) if (q[0] == name) q]) > 0 ? 0 : -explode)
    [out, sign(yc - open_l / 2) * explode / 2, (zc < z_row ? -explode : sign(zc - z_ring_split) * explode / 2)];

module wall_assembled(spread = 0) {
    for (n = printed) translate(spread * explode_of(n)) wall_colour(n);
    translate(spread * [3 * explode, 0, 0]) filter_home();
    translate(spread * [0, 0, -explode]) carbon_contents();
}

// cam: the figure's --camera angles, so the arrows' labels face it.
// outside: the arrows on the room's side, where a view from there sees them.
module wall_figure(spread = 0, cam = [0, 0, 0], outside = false) {
    if (spread == 0) lack_context(reach = 160);
    wall_assembled(spread);
    axes([outside ? x_out - 110 : x_in + 40, -lack_leg - 90, 0], l = 110, cam = cam);
}
