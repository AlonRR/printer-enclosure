// SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
// SPDX-License-Identifier: CC-BY-NC-SA-4.0
// A remix of BentoBox v2.0 by ThrutheFrame (https://www.printables.com/model/272525), CC BY-NC-SA 4.0.

// parts/cover.scad - THE COVER, with its hemp-leaf window, and where it stands. Included by bentobox.scad; not a model on its own.

// The cover drawn (Alon, 9 Oct 2026: D142), to ThrutheFrame's cover_hemp, its plate's underside on Z = z0, the
// holder's top: the plate, its bottom edge chamfered and its top edge rounded, then chamfered at 45 degrees as it
// prints, top face down; the plug under it; the magnets' holes in the plate's underside; and the window, filled
// with the hemp-leaf pattern.
module cover_plate(z0) let(r = cover_round, c = bb_chamfer, t = z0 + cover_top, zc = t - r * sqrt(2))
    hull() for (s = concat([[z0, c], [z0 + c, 0]], [for (a = [0 : 9 : 45]) [zc + r * sin(a), r - r * cos(a)]], [[t - eps, r]]))
        translate([0, 0, s[0]]) linear_extrude(eps) rrect_c(bb_w - 2 * s[1], bb_l - 2 * s[1], bb_r - s[1]);
// The pattern's holes: scad-tools' hemp-leaf lattice (patterns.scad), each triangle split in three by its spokes,
// each third shrunk by half a bar, over the window.
module hemp_holes2d() hemp_leaf_holes(2 * cover_win, cover_tile, cover_bar);
module cover_drawn(z0) difference() {
    union() {
        cover_plate(z0);
        translate([0, 0, z0 - cover_plug[3]]) linear_extrude(cover_plug[3] + eps) rrect_c(cover_plug[0], cover_plug[1], cover_plug[2]);
    }
    translate([0, 0, z0 - cover_plug[3] - 1]) linear_extrude(cover_plug[3] + cover_top + 2, convexity = 10)
        intersection() { rrect_c(2 * cover_win[0], 2 * cover_win[1], cover_win_r); hemp_holes2d(); }
    for (sx = [-1, 1], sy = [-1, 1]) translate([sx * top_mag_xy[0], sy * top_mag_xy[1], z0 - 1]) cylinder(d = top_mag_d, h = 1 + magnet[1]);
}
// The cover on the sealed stack's HEPA holder.
cover_z0 = sst[3] - meet + hepa_h;
