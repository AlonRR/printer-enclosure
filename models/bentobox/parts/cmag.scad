// SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
// SPDX-License-Identifier: CC-BY-NC-SA-4.0
// A remix of BentoBox v2.0 by ThrutheFrame (https://www.printables.com/model/272525), CC BY-NC-SA 4.0.

// parts/cmag.scad - THE C-MAG, an option: its values, the tray and the lid cut from one body, and the grills. Included by bentobox.scad; not a model on its own.

// The C-MAG's three trays, standing: each tray's pellets fall onto the grill below them and spread over the
// whole of the C-MAG's inside. Lying open, a tray between two grills is (spacing - grill) long and the
// inside's W - 4 wide; standing, the same pellets cover (W - 4) x (T - 4). The ribs that hold the grills,
// and the corners' fillets, take about 4 % of a tray either way, and cancel to well under 0.1 mm.
cmag_in = [cmag[1] - 4, cmag[2] - 4];                          // W x T inside its walls
cmag_tray = cmag_grills[1] - cmag_grills[0] - cmag_grill_t;    // a tray's length between two grills
cmag_layer = cmag_tray * cmag_fill / cmag_in[1];               // its pellets' depth, standing
cmag_z0 = carbon_floor;                                         // the C-MAG's bottom, on the housing's floor
// Each layer's bottom: the top face of the grill under it, from the C-MAG's bottom.
cmag_layers = [for (i = [0 : 2]) cmag_grills[i] + cmag_grill_t / 2];
// The C-MAG drawn: its walls' thickness; the grills' honeycomb - its webs, its rim, a hole across its corners.
cmag_wall = cmag_round - cmag_fillet;
cmag_web = cmag_mesh[1] * fdm_extrusion_w;
cmag_rim = cmag_mesh[2] * fdm_extrusion_w;
cmag_hole_ac = cmag_mesh[0] / cos(30);

// The C-MAG drawn (Alon, 9 Oct 2026: D142), to its STLs' measurements, in its own frame: L along X, W along Y, T along
// Z, the tray from Z = 0 and the lid on it from cmag_split. The two halves are cut from one body. Its outside is one
// profile across the box, extruded along it, its open ends' edges chamfered; its inside is the polygon of the
// fillets' centres grown by cmag_fillet. Each tray's air is a hull of slices: the rails' drop at each end, sloping out
// to the whole inside. The rails' cores take the inside in by cmag_rail[1], and each slot takes it out to the
// polygon grown with square corners, where the grill's corners go. The text on the lid's top is left off.
function cmag_k() = let(A = cmag_corner[0], B = cmag_corner[1], r = cmag_round, w = cmag[1], t = cmag[2]) [
    [r, A[0]], [A[1], r], [w - B[1], r], [w - r, B[0]],
    [w - r, t - A[0]], [w - A[1], t - r], [B[1], t - r], [r, t - B[0]]];
module cmag_out2d() let(A = cmag_corner[0], B = cmag_corner[1], r = cmag_round, w = cmag[1], t = cmag[2]) hull() {
    for (c = [[r, A[0]], [w - r, B[0]], [w - r, t - A[0]], [r, t - B[0]]]) translate(c) circle(r = r);
    polygon([[A[2], 0], [w - B[2], 0], [w - A[2], t], [B[2], t]]);
}

module cmag_outside() let(c = cmag_end_chamfer, l = cmag[0]) hull() {
    along_x(0, eps) offset(delta = -c) cmag_out2d();
    along_x(c, l - c) cmag_out2d();
    along_x(l - eps, l) offset(delta = -c) cmag_out2d();
}
module cmag_air() let(rw = cmag_rail[0], core = cmag_rail[1] - cmag_fillet, s = [for (g = cmag_grills) [g - cmag_slot / 2, g + cmag_slot / 2]], n = len(s)) {
    for (i = [0 : n - 2]) let(p = s[i][1] + rw, q = s[i + 1][0] - rw) hull() {
        along_x(p, p + eps) offset(delta = cmag_fillet - cmag_rail[2]) polygon(cmag_k());
        along_x(p + 1, q - 1) offset(r = cmag_fillet) polygon(cmag_k());
        along_x(q - eps, q) offset(delta = cmag_fillet - cmag_rail[2]) polygon(cmag_k());
    }
    for (i = [0 : n - 1]) {
        along_x(i == 0 ? -1 : s[i][0] - rw - eps, i == n - 1 ? cmag[0] + 1 : s[i][1] + rw + eps) offset(delta = -core) polygon(cmag_k());
        along_x(s[i][0], s[i][1]) offset(delta = cmag_fillet) polygon(cmag_k());
    }
}
// A magnet's boss, at the corner x = 0, y = 0, from the joint down (or up, for the lid): a D standing out of the wall.
// Its underside's lowest line runs up from the wall at 45 degrees and rounds into the D's front; each slice along
// the wall is half an ellipse, as wide as the D there and cmag_boss_under[1] deep, or less nearer the joint. Lofted
// by hulls of neighbouring slices.
function cmag_boss_zb(t, R, zr) = t <= R / sqrt(2) ? zr - R * sqrt(2) + t : zr - sqrt(max(R * R - t * t, 0));
module cmag_boss(up) let(c = [cmag_boss[0], cmag_boss[1]], r = cmag_boss[2], z0 = cmag_split, w = cmag_wall, R = c[1] - w + r,
    zr = z0 - cmag_boss_under[0], n = 18, ys = concat([w - 1], [for (i = [0 : n]) w + R * i / n]))
    translate([0, 0, z0]) mirror([0, 0, up ? 1 : 0]) translate([0, 0, -z0])
        for (i = [0 : len(ys) - 2]) hull() for (y = [ys[i], ys[i + 1]])
            let(zb = cmag_boss_zb(max(y - w, 0), R, zr), zc = min(zb + cmag_boss_under[1], zr), b = max(zc - zb, 0.01),
                a = y <= c[1] ? r : max(sqrt(max(r * r - pow(y - c[1], 2), 0)), 0.01))
                translate([0, y + eps / 2, 0]) rotate([90, 0, 0]) linear_extrude(eps)
                    hull() { translate([c[0], zc]) scale([a, b]) circle(r = 1, $fn = 48); translate([c[0] - a, zc]) square([2 * a, z0 - zc]); }
module cmag_corners() for (mx = [0, 1], my = [0, 1]) translate([mx * cmag[0], my * cmag[1], 0]) mirror([mx, 0, 0]) mirror([0, my, 0]) children();
// The fill line, on the -Y wall, in the middle of each tray.
module cmag_lines() let(l = cmag_line, w = cmag_wall)
    for (i = [0 : len(cmag_grills) - 2]) translate([(cmag_grills[i] + cmag_grills[i + 1]) / 2, w, w + cmag_fill]) rotate([-90, 0, 0])
        hull() for (s = [[l[0], l[1], 0], [l[0] - 2 * l[2], l[1] - 2 * l[2], l[2] - eps]]) translate([0, 0, s[2]]) linear_extrude(eps)
            hull() for (sx = [-1, 1]) translate([sx * (s[0] - s[1]) / 2, 0]) circle(d = s[1], $fn = 32);
module cmag_body() difference() {
    union() {
        difference() { cmag_outside(); cmag_air(); }
        cmag_corners() { cmag_boss(false); cmag_boss(true); }
        cmag_lines();
    }
    cmag_corners() translate([cmag_boss[0], cmag_boss[1], cmag_split - mag_h]) cylinder(d = mag_d, h = 2 * mag_h);
}
module cmag_tray_drawn() intersection() { cmag_body(); translate([-1, -1, -1]) cube([cmag[0] + 2, cmag[1] + 2, cmag_split + 1]); }
module cmag_lid_drawn() intersection() { cmag_body(); translate([-1, -1, cmag_split]) cube([cmag[0] + 2, cmag[1] + 2, cmag[2]]); }
// A grill, flat: the plate, and a honeycomb of whole holes inside its rim, their flats facing along W.
function cmag_mesh_holes() = honeycomb_centres([cmag_grill[0] - 2 * cmag_rim, cmag_grill[1] - 2 * cmag_rim], cmag_mesh[0], cmag_web);
module cmag_grill2d() difference() {
    rrect_c(cmag_grill[0], cmag_grill[1], cmag_grill[2]);
    for (c = cmag_mesh_holes()) translate(c) rotate(90) circle(d = cmag_hole_ac, $fn = 6);
}
// The four grills in their slots, in the C-MAG's frame.
module cmag_grills_drawn() for (g = cmag_grills) along_x(g - cmag_grill_t / 2, g + cmag_grill_t / 2) translate([cmag[1] / 2, cmag[2] / 2]) cmag_grill2d();
module cmag_drawn() { cmag_tray_drawn(); cmag_lid_drawn(); cmag_grills_drawn(); }
