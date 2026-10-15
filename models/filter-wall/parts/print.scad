// SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
// SPDX-License-Identifier: CC-BY-4.0

// parts/print.scad - EVERY PART AS IT PRINTS, along the wall on the bed's X, up the wall on its Y - a turn, not a
// mirror: a carbon tray on its inner face, the ring on its skin and the cassette on its land, each the face it is
// open away from. The names are draw's and the checks'. Included by filter-wall.scad; not a model on its own.

module piece_drawn(name) {
    if (len([for (p = ring_pieces) if (p[0] == name) p]) > 0) ring_piece(name);
    else if (len([for (p = cassette_pieces) if (p[0] == name) p]) > 0) cassette_piece(name);
    else if (len([for (p = carbon_pieces) if (p[0] == name) p]) > 0) carbon_piece(name);
    else assert(false, str("no such part: ", name));
}

// A carbon tray: (x, y, z) in the wall's frame to (y - y0, z1 - z, x1 - x), its inner face down. The ring and the
// cassette: to (y - y0, z - z0, x - x0), the room's side down. Each a proper rotation, then a shift.
module print_part(name) let(p = piece(name), inner_down = len([for (q = carbon_pieces) if (q[0] == name) q]) > 0)
    if (inner_down) multmatrix([[0, 1, 0, -p[1]], [0, 0, -1, p[4]], [-1, 0, 0, p[6]], [0, 0, 0, 1]]) piece_drawn(name);
    else multmatrix([[0, 1, 0, -p[1]], [0, 0, 1, -p[3]], [1, 0, 0, -p[5]], [0, 0, 0, 1]]) piece_drawn(name);
