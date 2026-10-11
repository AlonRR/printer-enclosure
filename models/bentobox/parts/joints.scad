// SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
// SPDX-License-Identifier: CC-BY-NC-SA-4.0
// A remix of BentoBox v2.0 by ThrutheFrame (https://www.printables.com/model/272525), CC BY-NC-SA 4.0.

// parts/joints.scad - THE SEALED JOINTS: the outline with its tabs, the brackets, the collar, the chamfer, the bead's groove and ring, the magnets' holes filled; and sealed_part(), which cuts a part to them. Included by bentobox.scad; not a model on its own.

// ------------------------------------------------------------------ the sealed joints
// See bentobox.params.scad. Each sealed part is cut to one outline, drawn here: the originals' outside is cut `meet`
// inside their own faces (an STL's float32 face is not where the same number computed here is, and faces a hair
// apart make slivers), and the tabs, the brackets and the section's pillars belong to that same outline, so their
// faces run on from the walls' with no seam. Where a part meets a sealed joint it is cut there too: a lower part's
// top, an upper part's floor. A lower part's top: its magnets' holes filled, a collar round its edge, the bead's
// groove, and a nut in each tab, on a bracket. An upper part's floor: its groove and magnets' holes filled, its edge
// cut back at 45 degrees to sit in the collar, and each screw's head sunk in its tab.
module outline_in(d) offset(delta = -d) rrect_c(bb_w, bb_l, bb_r);
// The outline from above, as points, anticlockwise: the side faces at +-seal_x, the end walls at +-seal_y. Each is
// built from its +X +Y corner by exact reflections, and every point where a curve meets a straight face is written
// with that face's own number, so the two outlines below share their faces exactly.
function _mx(ps) = [for (p = ps) [-p[0], p[1]]];
function _my(ps) = [for (p = ps) [p[0], -p[1]]];
function _rev(ps) = [for (i = [len(ps) - 1 : -1 : 0]) ps[i]];
function _round(c) = concat(c, _rev(_mx(c)), _mx(_my(c)), _rev(_my(c)));
// The plain outline, its corners round.
function _corner_pts() = concat([[seal_x, seal_yc]],
    [for (i = [1 : 15]) [seal_xc, seal_yc] + seal_r * [cos(90 * i / 16), sin(90 * i / 16)]], [[seal_xc, seal_y]]);
function outline_pts() = _round(_corner_pts());
// With the tabs: up the side face onto the screw's boss, round it to tab_a0, and down the parabola into the end wall.
function _tab_pts() = concat([[seal_x, tab_sc[1]]],
    [for (a = [5 : 5 : tab_a0 - 1]) tab_sc + tab_boss_r * [cos(a), sin(a)]],
    [for (i = [0 : 24]) let(x = tab_p[0] - (tab_p[0] - tab_x0) * i / 24) [x, seal_y + tab_c * pow(x - tab_x0, 2)]]);
// With a tab in the middle of each end wall instead (style "middle", the top joint's - D147): round the corner,
// along the end wall to the parabola's foot, up it onto the boss, and round the boss to just short of the middle, so
// that its mirror image repeats no point.
function _mid_pts() = let(xb = tab_sc[0] - tab_p[0], xf = tab_mx0) concat(_corner_pts(),
    [for (i = [0 : 24]) let(x = xf - (xf - xb) * i / 24) [x, seal_y + tab_c * pow(x - xf, 2)]],
    [for (a = [35 : 5 : 85]) [0, tab_sc[1]] + tab_boss_r * [cos(a), sin(a)]]);
// A joint's outline with its tabs: "corners", or "middle".
function plan_pts(style = "corners") = style == "middle" ? _round(_mid_pts()) : _round(_tab_pts());
// Each tab's zone: the tabs' material comes in only there.
module tab_zone2d(style = "corners") if (style == "middle") for (my = [0, 1]) mirror([0, my, 0])
        translate([-tab_mx0, tab_zone_y]) square([2 * tab_mx0, tab_tip + 20 - tab_zone_y]);
    else for (mx = [0, 1], my = [0, 1]) mirror([mx, 0, 0]) mirror([0, my, 0])
        translate([tab_x0, tab_zone_y]) square([seal_x + 20 - tab_x0, tab_tip + 20 - tab_zone_y]);
// The outline in a tabs' band, where the part's own outline prism already stands: with corner tabs the whole outline;
// with middle tabs only the tabs' zones - the whole outline there would lay the plain corners' round over the
// part's own, face on face, and leave slivers along each of its points.
module tab_band2d(style) if (style == "middle") intersection() { polygon(plan_pts(style)); tab_zone2d(style); }
    else polygon(plan_pts(style));
// Material for the tabs: the outline grown by g, so the cut to the outline sets every face; in the tabs' zones only.
module tab_stuff2d(g, style = "corners") intersection() { offset(delta = g) polygon(plan_pts(style)); tab_zone2d(style); }

// Under a nut's tab, its bottom at zt: a bracket whose face is y = F(x, z), 45 degrees at the tab, tangent to the wall
// at its foot. Along the end wall F is a cubic in the height, from tab_blend inside the wall out past the tab's tip.
// In the rounded corner it starts tab_blend inside the round and, between tab_corner_t, fills the corner out to the
// end wall's line, smoothly - so the side face runs on into the bracket's side.
function _corner_y(x) = x <= seal_xc ? bracket_y0
    : x <= seal_xc + seal_r - tab_blend ? seal_yc + sqrt(max(0, pow(seal_r - tab_blend, 2) - pow(x - seal_xc, 2)))
    : tab_zone_y + 0.5;
function _smooth(u) = let(v = min(1, max(0, u))) v * v * (3 - 2 * v);
function bracket_f(x, z, zt) = let(t = min(1, max(0, (z - zt) / bracket_h + 1)), y0 = _corner_y(x))
    y0 + (bracket_y0 - y0) * _smooth((t - tab_corner_t[0]) / (tab_corner_t[1] - tab_corner_t[0])) + bracket_l * pow(t, 3);
// The solid behind that face at the +X +Y corner, grown by g: X from before the parabola's start to past the side
// face, Y from inside the wall out to the face, Z from z0 to 1 mm up into the tab. The columns in the corner follow
// its round; one beyond the side face, where the corner has ended, starts the face back inside the side wall.
module bracket_block(zt, z0, g) {
    xs = concat([tab_x0 - 1], [for (i = [0 : 16]) seal_xc + (seal_r - tab_blend) * sin(90 * i / 16)], [seal_x + 1]);
    zs = concat([for (j = [0 : 36]) z0 + (zt - z0) * j / 36], [zt + 1]);
    nx = len(xs);
    nz = len(zs);
    pts = concat([for (x = xs, z = zs) [x, bracket_f(x, z, zt) + g, z]], [for (x = xs, z = zs) [x, tab_zone_y - 0.5, z]]);
    b = nx * nz;   // the back's points follow the face's
    polyhedron(pts, concat(
        [for (i = [0 : nx - 2], j = [0 : nz - 2]) each [
            [i * nz + j, (i + 1) * nz + j, (i + 1) * nz + j + 1], [i * nz + j, (i + 1) * nz + j + 1, i * nz + j + 1],
            [b + i * nz + j, b + (i + 1) * nz + j + 1, b + (i + 1) * nz + j], [b + i * nz + j, b + i * nz + j + 1, b + (i + 1) * nz + j + 1]]],
        [concat([for (j = [0 : nz - 1]) j], [for (j = [nz - 1 : -1 : 0]) b + j])],
        [concat([for (j = [0 : nz - 1]) b + (nx - 1) * nz + j], [for (j = [nz - 1 : -1 : 0]) (nx - 1) * nz + j])],
        [concat([for (i = [0 : nx - 1]) b + i * nz], [for (i = [nx - 1 : -1 : 0]) i * nz])],
        [concat([for (i = [0 : nx - 1]) i * nz + nz - 1], [for (i = [nx - 1 : -1 : 0]) b + i * nz + nz - 1])]));
}
// Under a tab in the middle of the end wall, nothing turns a corner: the bracket's face is the same cubic all along X,
// a profile across the wall extruded along it.
module bracket_mid(zt, z0, g) let(zs = [for (j = [0 : 36]) z0 + (zt - z0) * j / 36], x = tab_mx0 + 1)
    for (my = [0, 1]) mirror([0, my, 0]) along_x(-x, x) polygon(concat([[tab_zone_y - 0.5, z0]],
        [for (z = zs) [bracket_f(0, z, zt) + g, z]], [[bracket_f(0, zt, zt) + g, zt + 1], [tab_zone_y - 0.5, zt + 1]]));
// The brackets: g = 0, the shape; g > 0, the material for it, grown and in the tabs' zones only.
module brackets(zt, z0, g = 0, style = "corners") intersection() {
    if (style == "middle") bracket_mid(zt, z0, g);
    else for (mx = [0, 1], my = [0, 1]) mirror([mx, 0, 0]) mirror([0, my, 0]) bracket_block(zt, z0, g);
    translate([0, 0, z0 - 1]) linear_extrude(zt - z0 + 3) if (g > 0) tab_stuff2d(g, style); else polygon(plan_pts(style));
}
// Inside a 45-degree face over the outline with its tabs: at z, the outline inset by d, and 1 mm less inset for
// every 1 mm up, for rise (scad-tools shapes.scad, slant). It is exact where the outline turns no tighter than d -
// here nowhere: the tabs' bosses are tab_boss_r round, and the corners are the tabs'.
module slant_in(z, d, rise, style = "corners") translate([0, 0, z]) slant(d, rise, 23, eps) polygon(plan_pts(style));
// The collar on a lower part's top, its face at z: round the whole outline, tabs and all; its outside the outline's,
// its inside at 45 degrees, collar_base in at its foot.
module collar(z, style = "corners") difference() {
    translate([0, 0, z - 0.5]) linear_extrude(collar_h + 0.5) polygon(plan_pts(style));
    slant_in(z - 0.5 - eps, collar_base + 0.5 + eps, collar_base + 0.5 - collar_top + 2 * eps, style);
}
// What an upper part's bottom edge loses, its face at z, round the whole outline, tabs and all: everything outside a
// 45-degree face from chamfer_in in at the face to just past the outline.
module chamfer_cut(z, style = "corners") difference() {
    translate([0, 0, z - 1]) linear_extrude(chamfer_in + 1 + meet) offset(delta = 5) polygon(plan_pts(style));
    slant_in(z - 1 - eps, chamfer_in + 1 + eps, chamfer_in + 1 + 2 * meet, style);
}
module seal_groove_cut(z) translate([0, 0, z - seal_groove[1]]) linear_extrude(seal_groove[1] + 1)
    gasket_groove_2d(seal_ring[0], seal_ring[1], seal_groove[0]);
module bead_ring() gasket_ring(seal_ring[0], seal_ring[1], seal_bead);
module magnet_fill(z0, z1) for (sx = [-1, 1], sy = [-1, 1]) translate([sx * mag_xy[0], sy * mag_xy[1], z0]) cylinder(d = mag_d + 0.2, h = z1 - z0);
// The material grown past the outline for the tabs, g: a hair, so that the cut to the outline sets every face.
tab_g = 0.02;
// A sealed original, its STL the child. zb: its floor's cut, at the joint under it (an upper part's), or undef;
// zt: its top's cut, at the joint over it (a lower part's), or undef. z0, z1: its STL's bottom and top faces. sb, st:
// the tabs at its bottom's joint and at its top's, "corners" or "middle".
module sealed_part(zb, zt, z0, z1, sb = "corners", st = "corners") {
    up = !is_undef(zb);
    low = !is_undef(zt);
    ztab = low ? zt - tab_lower_t : undef;                                // a nut's tab's bottom
    zbr = low ? max(ztab - bracket_h, z0 + bb_chamfer + 0.1) : undef;     // its bracket's foot, over any bottom chamfer
    difference() {
        union() {
            intersection() {
                union() {
                    children();
                    if (up) {
                        translate([0, 0, zb - 1]) linear_extrude(1 - meet + groove_h + 0.1)
                            difference() { inside_offset(groove_out + 0.1); inside_offset(-0.2); }
                        magnet_fill(zb - 1, zb - meet + mag_h + 0.1);
                        translate([0, 0, zb - 1]) linear_extrude(1 + tab_upper_h + tab_g) tab_stuff2d(tab_g, sb);
                    }
                    if (low) {
                        magnet_fill(zt + meet - mag_h - 0.1, zt + 1);
                        translate([0, 0, ztab]) linear_extrude(tab_lower_t + 1) tab_stuff2d(tab_g, st);
                        brackets(ztab, zbr, tab_g, st);
                    }
                }
                // The shape: the outline, the tabs, the brackets, cut at the joints' faces.
                intersection() {
                    union() {
                        // With middle tabs on top, the collar's corners are the outline's own round, point for
                        // point: the outline's prism stops where the collar starts, so its faces meet the collar's at
                        // the same points rather than running past them and leaving a sliver at each.
                        if (low && st == "middle") {
                            translate([0, 0, z0 - 1]) linear_extrude(zt - 0.5 - z0 + 1) polygon(outline_pts());
                            translate([0, 0, zt - 0.5]) linear_extrude(z1 - zt + 1.5) polygon(outline_pts());
                        } else translate([0, 0, z0 - 1]) linear_extrude(z1 - z0 + 2) polygon(outline_pts());
                        if (up) translate([0, 0, zb - 1]) linear_extrude(1 + tab_upper_h) tab_band2d(sb);
                        if (low) {
                            translate([0, 0, ztab]) linear_extrude(tab_lower_t + 1) tab_band2d(st);
                            brackets(ztab, zbr, 0, st);
                        }
                    }
                    if (up) above(zb);
                    if (low) below(zt);
                }
            }
            if (low) collar(zt, st);
        }
        if (up) {
            chamfer_cut(zb, sb);
            for (s = joint_screws(sb)) translate([s[0], s[1], zb - 1]) {
                cylinder(d = hole_d, h = tab_upper_h + 2);
                translate([0, 0, 1 + tab_upper_t]) cylinder(d = m3_cb[0], h = tab_upper_h);
            }
        }
        if (low) {
            seal_groove_cut(zt);
            // Each nut's pull pocket, a flat towards the wall, its roof's hole up to the joint's face.
            for (s = joint_screws(st)) pull_frame(s, zt + seal_slot_bot + nut_slot_h)
                pull_pocket(seal_way, pull_fit, -(seal_slot_bot + nut_slot_h) + 1);
        }
    }
}
