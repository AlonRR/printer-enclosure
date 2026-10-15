// SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
// SPDX-License-Identifier: CC-BY-4.0

// filter-wall.layout.scad - THE VALUES MORE THAN ONE PART READS, derived from the settings and the bought parts'
// numbers; it draws nothing. Included by filter-wall.scad after the vitamins; not a model on its own.
//
// THE WALL'S FRAME, which every part is drawn in where it sits: Y along the wall from the front leg's inner face to
// the back leg's, Z up from the floor, X across - 0 at the Lack's edge, + into the chamber. The inner face is at
// x_in, the outer at x_out.

/* [Hidden] */
e = 0.01;
wall_t = wall_perims * fdm_extrusion_w;     // a wall: whole perimeters
face_t = face_layers * fdm_layer_h;         // a face: whole layers
land_t = land_layers * fdm_layer_h;
plate_t = plate_layers * fdm_layer_h;

open_l = lack_w - 2 * lack_leg;             // the wall's length, between the legs
x_in = in_depth;
x_out = -proud;
depth = in_depth + proud;

// The filter's thin frame - the cassette - and the row round it. The rows and the cassette's outside are set; the
// pocket follows the filter, and the cassette's walls take up the difference.
pocket = [starkvind[0] + 2 * clearance, starkvind[1] + 2 * clearance];
cass = [cass_l, filter_row_h - 2 * wall_t];
cass_wall = (cass - pocket) / 2;           // the cassette's walls round the pocket, along and up
cass_d = cass_depth;
retain = cass_d - land_t - seal_t * (1 - seal_squeeze) - starkvind[2];  // behind the filter, for its retainers
window = [starkvind[0] - 2 * starkvind_rim, starkvind[1] - 2 * starkvind_rim];
carbon_row_h = lack_chamber - filter_row_h;
z_row = carbon_row_h;                       // where the rows meet
cass_y0 = (open_l - cass[0]) / 2;
cass_z0 = z_row + wall_t;
cass_c = [cass_y0 + cass[0] / 2, cass_z0 + cass[1] / 2];   // where the cassette's corners meet
x_cass_back = x_in - cass_d;
plenum_d = x_cass_back - (x_out + wall_t);  // behind the cassette, the filter row's plenum
z_ring_split = z_row + filter_row_h / 2;
filter_x = x_in - land_t - seal_t * (1 - seal_squeeze);    // the filter's upstream face, pressed on the seal

// The carbon row's stack, from its top wall down.
bed_top = z_row - wall_t - head_room;
bed_bot = bed_top - bed_depth;
floss_bot = bed_bot - floss_t;
fan_top = floss_bot - fan_gap;
fan_bot = fan_top - delta[2];
plate_bot = fan_bot - plate_t;
plenum_h = plate_bot - wall_t;              // the clean air's plenum, over the row's floor

// THE PRINTED PIECES: each one's name and its box in the wall's frame [y0, y1, z0, z1, x0, x1]. print_part() and
// the checks read these; parts/ draws them.
ring_pieces = [
    ["ring_front_low", 0, split_y, z_row, z_ring_split, x_out, x_in],
    ["ring_back_low", split_y, open_l, z_row, z_ring_split, x_out, x_in],
    ["ring_front_high", 0, split_y, z_ring_split, lack_chamber, x_out, x_in],
    ["ring_back_high", split_y, open_l, z_ring_split, lack_chamber, x_out, x_in],
];
cassette_pieces = [
    ["cassette_front_low", cass_y0, cass_c[0], cass_z0, cass_c[1], x_cass_back, x_in],
    ["cassette_back_low", cass_c[0], cass_y0 + cass[0], cass_z0, cass_c[1], x_cass_back, x_in],
    ["cassette_front_high", cass_y0, cass_c[0], cass_c[1], cass_z0 + cass[1], x_cass_back, x_in],
    ["cassette_back_high", cass_c[0], cass_y0 + cass[0], cass_c[1], cass_z0 + cass[1], x_cass_back, x_in],
];
carbon_pieces = [
    ["carbon_front", 0, split_y, 0, z_row, x_out, x_in],
    ["carbon_back", split_y, open_l, 0, z_row, x_out, x_in],
];
pieces = concat(ring_pieces, cassette_pieces, carbon_pieces);
printed = [for (p = pieces) p[0]];

function piece(name) = [for (p = pieces) if (p[0] == name) p][0];
// A piece as it prints: its inner face on the bed, along the wall on the bed's X, up the wall on its Y.
function print_size(p) = [p[2] - p[1], p[4] - p[3], p[6] - p[5]];
