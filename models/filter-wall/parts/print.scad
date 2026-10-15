// SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
// SPDX-License-Identifier: CC-BY-4.0

// parts/print.scad - EVERY PART AS IT PRINTS: its inner face on the bed, along the wall on the bed's X, up the wall
// on its Y - a turn, not a mirror. The names are draw's and the checks'. Included by filter-wall.scad; not a model on
// its own.

module piece_drawn(name) {
    if (len([for (p = ring_pieces) if (p[0] == name) p]) > 0) ring_piece(name);
    else if (len([for (p = cassette_pieces) if (p[0] == name) p]) > 0) cassette_piece(name);
    else if (len([for (p = carbon_pieces) if (p[0] == name) p]) > 0) carbon_piece(name);
    else assert(false, str("no such part: ", name));
}

// (x, y, z) in the wall's frame to (y - y0, z1 - z, x1 - x) on the bed: a proper rotation, then a shift.
module print_part(name) let(p = piece(name))
    multmatrix([[0, 1, 0, -p[1]], [0, 0, -1, p[4]], [-1, 0, 0, p[6]], [0, 0, 0, 1]]) piece_drawn(name);
