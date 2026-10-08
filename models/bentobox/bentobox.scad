// SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
// SPDX-License-Identifier: CC-BY-NC-SA-4.0
// A remix of BentoBox v2.0 by ThrutheFrame (https://www.printables.com/model/272525), CC BY-NC-SA 4.0.

// The BentoBox remix: the section, and the originals placed in the box's frame. Settings in
// bentobox.params.scad; bentobox-section.scad pins the part in its printing pose.
include <bentobox.layout.scad>
use <../../scad-tools/lib/fdm.scad>
use <../../scad-tools/lib/nuts.scad>
use <../../scad-tools/lib/gasket.scad>
use <../../scad-tools/lib/shapes.scad>

draw_model = true;   // a file that includes this one for its values sets it false after the include

$fn = 64;

// ------------------------------------------------------------------ outlines
module rrect(w, l, r) {
    offset(r = r) square([w - 2 * r, l - 2 * r], center = true);
}
// The inside's outline grown by d: a tongue or groove face d outside it, or inside for d < 0.
module inside_offset(d) rrect(in_w + 2 * d, in_l + 2 * d, max(in_r + d, 0.01));

module outline_solid(h) {
    // The outside, with its 0.4 mm chamfers at the bottom and top edges.
    hull() {
        translate([0, 0, 0]) linear_extrude(eps) rrect(bb_w - 2 * bb_chamfer, bb_l - 2 * bb_chamfer, bb_r - bb_chamfer);
        translate([0, 0, bb_chamfer]) linear_extrude(h - 2 * bb_chamfer) rrect(bb_w, bb_l, bb_r);
        translate([0, 0, h - eps]) linear_extrude(eps) rrect(bb_w - 2 * bb_chamfer, bb_l - 2 * bb_chamfer, bb_r - bb_chamfer);
    }
}

// ------------------------------------------------------------------ the joint, copied from the originals
// The tongue: a sloped ring standing on a top face, its inner face the inside's outline.
module tongue() {
    difference() {
        hull() {
            linear_extrude(eps) inside_offset(tongue_base);
            translate([0, 0, tongue_h - eps]) linear_extrude(eps) inside_offset(tongue_top);
        }
        translate([0, 0, -1]) linear_extrude(tongue_h + 2) inside_offset(0);
    }
}
// The groove, as the space it cuts out of a bottom face: straight for groove_flat, then sloping inwards.
module groove_cut() {
    difference() {
        union() {
            translate([0, 0, -1]) linear_extrude(1 + groove_flat) inside_offset(groove_out);
            hull() {
                translate([0, 0, groove_flat - eps]) linear_extrude(eps) inside_offset(groove_out);
                translate([0, 0, groove_h - eps]) linear_extrude(eps) inside_offset(groove_out_top);
            }
        }
        translate([0, 0, -2]) linear_extrude(groove_h + 3) inside_offset(groove_in);
    }
}
module magnet_holes(z, up) {
    for (sx = [-1, 1], sy = [-1, 1])
        translate([sx * mag_xy[0], sy * mag_xy[1], up ? z : z - mag_h]) cylinder(d = mag_d, h = mag_h + eps);
}

// ------------------------------------------------------------------ the section
// Bottom face on Z = 0, as it prints. The grid and its ledge at the bottom roof the groove; the sheet lies
// on the grid; the plenum above lets the air from the housing's two openings spread over the whole sheet.
module grid() {
    linear_extrude(grid_t) {
        difference() { inside_offset(0); inside_offset(-ledge_w); }
        intersection() {
            inside_offset(-ledge_w + eps);
            union() {
                n = floor((in_l / 2) / grid_pitch);
                for (i = [-n : n]) translate([-in_w / 2, i * grid_pitch - rib_w / 2]) square([in_w, rib_w]);
                for (x = [-1, 1] * in_w / 6) translate([x - rib_w / 2, -in_l / 2]) square([rib_w, in_l]);
            }
        }
    }
}
module section() if (sealed) section_sealed(); else section_magnets();
module section_magnets() {
    // The groove is cut after the grid is in: its inner face is 0.1 mm inside the inside's outline, in the
    // grid's ledge, and a ledge added afterwards would fill that back and stand against the tongue.
    difference() {
        union() {
            difference() {
                outline_solid(sec_h);
                translate([0, 0, -1]) linear_extrude(sec_h + 2) inside_offset(0);
            }
            grid();
        }
        groove_cut();
        magnet_holes(0, true);
        magnet_holes(sec_h, false);
    }
    translate([0, 0, sec_h - eps]) tongue();
}

// ------------------------------------------------------------------ the frame for your own HEPA paper
// The ring: its bottom face on Z = 0, as it stands on the ledge and as it prints. It has no floor: the
// paper's long edges rest on the ledge or in the strips' slots, its ends on the caps' teeth, and the ledge's
// opening stays open but for the strips.
module hepa_ring_walls() {
    difference() {
        translate([-ring_out[0] / 2, -ring_out[1] / 2, 0]) cube([ring_out[0], ring_out[1], ring_h]);
        translate([-ring_in[0] / 2, -ring_in[1] / 2, -1]) cube([ring_in[0], ring_in[1], ring_h + 2]);
    }
}
// With flaps, the strips on the long walls' feet, seen along the folds: X across, the second axis up. Each is
// a floor from the wall to the strip, under the slot, and the strip itself, parallel to the flap.
module strips_2d() for (m = [0, 1]) mirror([m, 0]) polygon([
    [-ring_in[0] / 2 - eps, 0], [strip_x(0) + strip_w / cos(pleat_alpha), 0],
    [strip_x(ring_strip_h) + strip_w / cos(pleat_alpha), ring_strip_h], [strip_x(ring_strip_h), ring_strip_h],
    [strip_x(strip_floor), strip_floor], [-ring_in[0] / 2 - eps, strip_floor]]);
// The strips run between the caps' plates, 0.1 mm short of each.
module hepa_ring_strips() if (paper_flaps) rotate([90, 0, 0]) linear_extrude(pack_l - 0.2, center = true) strips_2d();
module hepa_ring() {
    hepa_ring_walls();
    hepa_ring_strips();
}
// One end's wedges and teeth, in a plane across the folds: X across, the second axis up the pack from its
// bottom face (bentobox.layout.scad says how their shapes follow from the paper's). A wedge fills each
// channel open at the top, over every bottom fold between the edges. A tooth fills each channel open at the
// bottom, under every top fold; without flaps the two at the edges, beside the ring's walls, are halves.
// With flaps, a half wedge fills the sliver between each flap and its wall, and the teeth beside the flaps
// are cut back clear of the strips.
module wedges_2d(shrink = 0) offset(delta = -shrink) difference() {
    union() {
        for (i = [1 : fold_last - 1]) if (!fold_top(i))
            polygon([[fold_x(i) - wedge_w / 2, ring_h], [fold_x(i) + wedge_w / 2, ring_h], [fold_x(i), wedge_z0]]);
        // Every half stops eps inside the plate's sides: flush with them, the union leaves broken faces there.
        if (paper_flaps) for (m = [0, 1]) mirror([m, 0]) polygon([
            [-ring_in[0] / 2 - cap_squeeze + eps, ring_h], [-ring_in[0] / 2 + half_wedge_w, ring_h],
            [-ring_in[0] / 2, half_wedge_z0], [-ring_in[0] / 2 - cap_squeeze + eps, half_wedge_z0]]);
        if (cap_teeth_below) intersection() {
            translate([-ring_in[0] / 2 - cap_squeeze + eps, 0]) square([ring_in[0] + 2 * (cap_squeeze - eps), ring_h]);
            for (i = [0 : fold_last]) if (fold_top(i))
                polygon([[fold_x(i) - tooth_w / 2, 0], [fold_x(i) + tooth_w / 2, 0], [fold_x(i), tooth_z1]]);
        }
    }
    if (paper_flaps) offset(delta = strip_notch) strips_2d();
}
// A cap, as it prints: its plate on the bed, X across, Y up the pack, the wedges and teeth standing up out of it.
module hepa_cap(wedges_only = false, shrink = 0) {
    w = ring_in[0] + 2 * cap_squeeze;
    if (!wedges_only) translate([-w / 2, 0, 0]) cube([w, ring_h, cap_plate]);
    translate([0, 0, cap_plate - eps]) linear_extrude(cap_wedge_l + eps) wedges_2d(shrink);
}
// Both caps in the ring, its bottom at z: each plate's back against an end wall, the wedges reaching in.
module caps_in_place(z = 0, wedges_only = false, shrink = 0)
    for (a = [0, 180]) rotate([0, 0, a]) translate([0, ring_in[1] / 2, z]) rotate([90, 0, 0]) hepa_cap(wedges_only, shrink);
// The paper, for pictures and for checking the wedges and the strips against it - drawn from the paper's
// own values, not from their arithmetic: each flank a strip paper_t thick, round at the folds, between fold
// lines paper_t / 2 inside the pack's faces. With flaps, each flap's cut end stands on its slot's floor.
flap_z = strip_floor + paper_t;   // a flap's cut end, its middle
module paper_2d() {
    pts = [for (i = [0 : fold_last])
        paper_flaps && (i == 0 || i == fold_last)
            ? [fold_x(i) + (i == 0 ? 1 : -1) * (flap_z - paper_t / 2) * tan(pleat_alpha), flap_z]
            : [fold_x(i), fold_top(i) ? ring_h - paper_t / 2 : paper_t / 2]];
    for (k = [0 : len(pts) - 2]) hull() {
        translate(pts[k]) circle(d = paper_t, $fn = 16);
        translate(pts[k + 1]) circle(d = paper_t, $fn = 16);
    }
}
module paper_pack(z = 0) translate([0, 0, z]) rotate([90, 0, 0]) linear_extrude(pack_l, center = true) paper_2d();

// ------------------------------------------------------------------ the originals, in the box's frame
orig_dir = "original/";
duct_stl   = str(orig_dir, "fan duct BambuLab 20231017.stl");
fans_stl   = str(orig_dir, "fan case v1_28.stl");
carbon_stl = str(orig_dir, "carbon.stl");
hepa_stl   = str(orig_dir, "hepa.stl");
cover_stl  = str(orig_dir, "cover_hemp.stl");
cmag_stls  = [str(orig_dir, "CMag Case 01 v5.stl"), str(orig_dir, "CMag Case 02 v5.stl")];

// An original, moved up by dz: the parts above the section stand sec_h higher with it.
module orig(file, dz = 0) translate([0, 0, dz] - stl_origin) import(file, convexity = 10);
// The C-MAG, from its own frame (L along X, W along Y, T along Z) to standing on end in the housing.
module cmag_standing(z0) translate([cmag[2] / 2, -cmag[1] / 2, z0]) rotate([0, -90, 0])
    for (f = cmag_stls) import(f, convexity = 10);

// ------------------------------------------------------------------ the Auto's bottom
// Strangwooduk's base, fan section and plate (scripts/bentobox-auto-stl.py writes them from the STEP), moved
// into this frame. The base stands on Z = auto_base_z0, its top at duct_h, where the duct's is.
auto_base_stl  = str(orig_dir, "bentobox-auto-base.stl");
auto_fans_stl  = str(orig_dir, "bentobox-auto-fans.stl");
auto_plate_stl = str(orig_dir, "bentobox-auto-plate.stl");
module auto_fans() orig(auto_fans_stl, auto_fans_dz);
// The fan section the stack stands on, whichever bottom it has.
module fan_section() if (bottom == "auto") auto_fans(); else orig(fans_stl);

// A slot's own frame: X out towards its mouth, the screw's axis at the origin, Z = 0 at z.
module slot_frame(s, z) translate([s[0], s[1], z]) rotate(s[2]) children();
// A nut's slot (scad-tools nuts.scad), from behind the axis out through its mouth, nut_slot_out past the axis...
module slot() nut_slot(nut_af, nut_slot_h, nut_slot_out, fdm_hole_comp + nut_fit);
// ...and the screw's hole on up through its roof, l long, as a bridged hole (scad-tools fdm.scad): a channel as
// wide as the hole across the slot, so the first layer is two bridges from side to side; the hole, square, so the
// second is two bridges along the slot over the channel; then the round hole.
module roof_hole(l) translate([0, 0, nut_slot_h]) rotate(90) bridged_hole(nut_slot_w, hole_d, l, fdm_layer_h, eps);
// The fan section's floor openings, carried down into the base: the fans' air.
module fan_air(h, grow = 0) for (y = fan_ys) translate([0, y, duct_h - h]) cylinder(d = auto_fan_air + 2 * grow, h = h + 1);

// A fan screw's post (seamless, Alon 8 Oct): the Auto's lug under its insert, made big enough for the nut, and
// holding the lug inside it. Its frame: the screw's axis at the origin, X out of the post's wall into the room.
module post_frame(s) translate([s[0], s[1], 0]) rotate(s[3]) children();
// From above: round at its end, its sides running into the wall on fillets; cut back clear of the fans' air, the
// corners there rounded. The fillets are tangent to a line post_blend inside the wall's face, so the two cross at a
// slant; the strip they come off runs 3 mm into the wall, inside the original.
module post2d(s) offset(r = 1) offset(delta = -1) difference() {
    offset(r = -post_fillet) offset(delta = post_fillet) post_frame(s) {
        circle(r = post_r);
        translate([-auto_post_wall - 3, -post_r]) square([auto_post_wall + 3, 2 * post_r]);
        translate([-auto_post_wall - 3, -post_r - post_fillet - 0.5]) square([3 - post_blend, 2 * (post_r + post_fillet + 0.5)]);
    }
    if (post_clear_air) for (y = fan_ys) translate([0, y]) circle(d = auto_fan_air + 2 * meet);
}
// From the side, out of the wall (X) and up (Y): the post's underside - straight down, then a round into 45
// degrees, which meets the wall's face at post_foot.
function _post_profile() = let(P = post_reach, R = post_round, c = [P - R, post_round_z])
    concat([[-5, post_foot - 5]], [for (a = [-45 : 5 : 0]) c + R * [cos(a), sin(a)]], [[P + 1, post_round_z], [P + 1, duct_h + 1], [-5, duct_h + 1]]);
module fan_post(s) intersection() {
    translate([0, 0, post_foot - 6]) linear_extrude(duct_h - post_foot + 7) post2d(s);
    post_frame(s) rotate([90, 0, 0]) linear_extrude(2 * (post_r + post_fillet + 2), center = true)
        polygon([for (q = _post_profile()) [q[0] - auto_post_wall, q[1]]]);
}
// A fan nut's pocket's own frame: the screw's axis on Z, a corner along X, and a flat facing s[2].
module pull_frame(s, z) translate([s[0], s[1], z]) rotate(s[2] - 30) children();
// An insert's hole, filled: the screw's hole and the slot are cut through the fill.
module fan_plug(s) translate([s[0], s[1], duct_h - auto_fan_insert[1] - 0.1])
    cylinder(d = auto_fan_insert[0] + 0.2, h = auto_fan_insert[1] + 0.1 - meet);
module plate_plug(p) translate([p[0], p[1], auto_seat_z + meet])
    cylinder(d = auto_plate_insert[0] + 0.2, h = auto_plate_insert[1] + 0.1 - meet);
// A fan screw's way: its nut's pocket (scad-tools nuts.scad), up from its mouth under the post to the seat, the
// seat a nut's height under the roof, and the screw's hole on up through the roof to the base's top, bridged
// (scad-tools fdm.scad): a channel the hole's width from corner to corner, then the hole's square, then the round hole.
module pull_pocket(way) {
    pull_nut_pocket(nut_af, nut_slot_h, way, fdm_hole_comp + pull_fit, fdm_hole_comp + pull_way_fit, eps);
    bridged_hole(pull_ac, hole_d, duct_h - pull_top + 1, fdm_layer_h, eps);
}
module fan_screw_cut(s) pull_frame(s, pull_top) pull_pocket(pull_seat - pull_bot);
// A plate screw's: the pocket its lobe rises into, its hole bridged up through the pocket's roof to its slot, the
// roof over that, and on past its tip.
module plate_screw_cut(s) {
    translate([s[0], s[1], auto_base_z0 - 1]) cylinder(d = pocket_d, h = pocket_top - auto_base_z0 + 1);
    translate([s[0], s[1], pocket_top]) bridged_hole(pocket_d, hole_d, plate_slot_bot - pocket_top + eps, fdm_layer_h, eps);
    slot_frame(s, plate_slot_bot) { slot(); roof_hole(plate_tip_z + 0.5 - plate_slot_top); }
}
// The base, its top cut `meet` under the original's, so the posts' tops are its own: the fan section stands that
// much lower on it.
module auto_base() intersection() {
    difference() {
        union() {
            orig(auto_base_stl);
            for (s = auto_fan_screws) { fan_post(s); fan_plug(s); }
            for (p = auto_plate_inserts) plate_plug(p);
        }
        for (s = auto_fan_screws) fan_screw_cut(s);
        for (s = auto_plate_screws) plate_screw_cut(s);
    }
    below(duct_h - meet);
}
// The plate: the Auto's outline, its countersunk holes filled, as thick as its recess is deep, so it is flush with
// the base's bottom face; a lobe on it for each screw, a counterbore up into the lobe for the screw's head, and the
// screw's hole bridged up through the counterbore's roof.
module plate_outline() union() {
    projection() orig(auto_plate_stl, auto_plate_dz);
    for (p = auto_plate_inserts) translate(p) circle(d = 7);
}
module auto_plate() difference() {
    union() {
        translate([0, 0, auto_base_z0]) linear_extrude(plate_t) plate_outline();
        for (s = auto_plate_screws) translate([s[0], s[1], auto_base_z0]) cylinder(d = lobe_d, h = lobe_top - auto_base_z0);
    }
    for (s = auto_plate_screws) translate([s[0], s[1], 0]) {
        translate([0, 0, auto_base_z0 - 1]) cylinder(d = plate_cb[0], h = plate_cb[1] + 1);
        translate([0, 0, plate_head_z]) bridged_hole(plate_cb[0], hole_d, lobe_top - plate_head_z + 1, fdm_layer_h, eps);
    }
}
module say_auto_hardware() echo(str("auto: six M3 nuts, the fans' four pulled up into pockets; the fans' four screws M3 x ", fan_screw,
    " socket head, through the fans; the plate's two M3 x ", plate_screw, " socket head, sunk ", head_sink,
    " mm into the bottom face"));

// ------------------------------------------------------------------ the sealed joints
// See bentobox.params.scad. Each sealed part is cut to one outline, drawn here: the originals' outside is cut `meet`
// inside their own faces (an STL's float32 face is not where the same number computed here is, and faces a hair
// apart make slivers), and the tabs, the brackets and the section's pillars belong to that same outline, so their
// faces run on from the walls' with no seam. Where a part meets a sealed joint it is cut there too: a lower part's
// top, an upper part's floor. A lower part's top: its magnets' holes filled, a collar round its edge, the bead's
// groove, and a nut in each tab, on a bracket. An upper part's floor: its groove and magnets' holes filled, its edge
// cut back at 45 degrees to sit in the collar, and each screw's head sunk in its tab.
module outline_in(d) offset(delta = -d) rrect(bb_w, bb_l, bb_r);
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
function plan_pts() = _round(_tab_pts());
// Each tab's zone: the tabs' material comes in only there.
module tab_zone2d() for (mx = [0, 1], my = [0, 1]) mirror([mx, 0, 0]) mirror([0, my, 0])
    translate([tab_x0, tab_zone_y]) square([seal_x + 20 - tab_x0, tab_tip + 20 - tab_zone_y]);
// Material for the tabs: the outline grown by g, so the cut to the outline sets every face; in the tabs' zones only.
module tab_stuff2d(g) intersection() { offset(delta = g) polygon(plan_pts()); tab_zone2d(); }
// Everything below z, or above it, with its face exactly at z.
module below(z) translate([-100, -100, z]) mirror([0, 0, 1]) cube([200, 200, 400]);
module above(z) translate([-100, -100, z]) cube([200, 200, 400]);

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
// The four brackets: g = 0, the shape; g > 0, the material for it, grown and in the tabs' zones only.
module brackets(zt, z0, g = 0) intersection() {
    for (mx = [0, 1], my = [0, 1]) mirror([mx, 0, 0]) mirror([0, my, 0]) bracket_block(zt, z0, g);
    translate([0, 0, z0 - 1]) linear_extrude(zt - z0 + 3) if (g > 0) tab_stuff2d(g); else polygon(plan_pts());
}
// Inside a 45-degree face over the outline with its tabs: at z, the outline inset by d, and 1 mm less inset for
// every 1 mm up, for rise (scad-tools shapes.scad, slant). It is exact where the outline turns no tighter than d -
// here nowhere: the tabs' bosses are tab_boss_r round, and the corners are the tabs'.
module slant_in(z, d, rise) translate([0, 0, z]) slant(d, rise, 23, eps) polygon(plan_pts());
// The collar on a lower part's top, its face at z: round the whole outline, tabs and all; its outside the outline's,
// its inside at 45 degrees, collar_base in at its foot.
module collar(z) difference() {
    translate([0, 0, z - 0.5]) linear_extrude(collar_h + 0.5) polygon(plan_pts());
    slant_in(z - 0.5 - eps, collar_base + 0.5 + eps, collar_base + 0.5 - collar_top + 2 * eps);
}
// What an upper part's bottom edge loses, its face at z, round the whole outline, tabs and all: everything outside a
// 45-degree face from chamfer_in in at the face to just past the outline.
module chamfer_cut(z) difference() {
    translate([0, 0, z - 1]) linear_extrude(chamfer_in + 1 + meet) offset(delta = 5) polygon(plan_pts());
    slant_in(z - 1 - eps, chamfer_in + 1 + eps, chamfer_in + 1 + 2 * meet);
}
module seal_groove_cut(z) translate([0, 0, z - seal_groove[1]]) linear_extrude(seal_groove[1] + 1)
    gasket_groove_2d(seal_ring[0], seal_ring[1], seal_groove[0]);
module bead_ring() gasket_ring(seal_ring[0], seal_ring[1], seal_bead);
module magnet_fill(z0, z1) for (sx = [-1, 1], sy = [-1, 1]) translate([sx * mag_xy[0], sy * mag_xy[1], z0]) cylinder(d = mag_d + 0.2, h = z1 - z0);
// The material grown past the outline for the tabs, g: a hair, so that the cut to the outline sets every face.
tab_g = 0.02;
// A sealed original, its STL the child. zb: its floor's cut, at the joint under it (an upper part's), or undef;
// zt: its top's cut, at the joint over it (a lower part's), or undef. z0, z1: its STL's bottom and top faces.
module sealed_part(zb, zt, z0, z1) {
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
                        translate([0, 0, zb - 1]) linear_extrude(1 + tab_upper_h + tab_g) tab_stuff2d(tab_g);
                    }
                    if (low) {
                        magnet_fill(zt + meet - mag_h - 0.1, zt + 1);
                        translate([0, 0, ztab]) linear_extrude(tab_lower_t + 1) tab_stuff2d(tab_g);
                        brackets(ztab, zbr, tab_g);
                    }
                }
                // The shape: the outline, the tabs, the brackets, cut at the joints' faces.
                intersection() {
                    union() {
                        translate([0, 0, z0 - 1]) linear_extrude(z1 - z0 + 2) polygon(outline_pts());
                        if (up) translate([0, 0, zb - 1]) linear_extrude(1 + tab_upper_h) polygon(plan_pts());
                        if (low) {
                            translate([0, 0, ztab]) linear_extrude(tab_lower_t + 1) polygon(plan_pts());
                            brackets(ztab, zbr);
                        }
                    }
                    if (up) above(zb);
                    if (low) below(zt);
                }
            }
            if (low) collar(zt);
        }
        if (up) {
            chamfer_cut(zb);
            for (s = tab_screws) translate([s[0], s[1], zb - 1]) {
                cylinder(d = hole_d, h = tab_upper_h + 2);
                translate([0, 0, 1 + tab_upper_t]) cylinder(d = plate_cb[0], h = tab_upper_h);
            }
        }
        if (low) {
            seal_groove_cut(zt);
            for (s = tab_screws) {
                slot_frame(s, zt + seal_slot_bot) { slot(); roof_hole(-(seal_slot_bot + nut_slot_h) + 1); }
                translate([s[0], s[1], zt - 9]) cylinder(d = hole_d, h = 9 + seal_slot_bot + eps);
            }
        }
    }
}
// The section, sealed: the outline with its tabs, the inside cut out, the grid; its edge chamfered underneath to sit
// in the fan section's collar, a collar and the bead's groove on top. Its tabs are pillars, which the screws from
// the carbon housing pass through; no magnets.
module section_sealed() difference() {
    union() {
        intersection() {
            union() {
                difference() {
                    linear_extrude(sec_h + 1) polygon(plan_pts());
                    translate([0, 0, -1]) linear_extrude(sec_h + 3) inside_offset(0);
                }
                grid();
            }
            below(sec_h);
        }
        collar(sec_h);
    }
    chamfer_cut(0);
    seal_groove_cut(sec_h);
    for (s = tab_screws) translate([s[0], s[1], -1]) cylinder(d = hole_d, h = sec_h + 2);
}
// The sealed stack's parts in place: the fan section, the carbon housing, the HEPA holder. Each original stands
// `meet` lower than its joint's face, whose cut takes that much off its floor.
sst = stack(true, true);
carbon_dz = sst[2] - meet - (duct_h + fans_h);
hepa_dz = sst[3] - meet - (duct_h + fans_h + carbon_h);
module fans_sealed() sealed_part(undef, sst[1], duct_h, duct_h + fans_h) fan_section();
module carbon_sealed() sealed_part(sst[2], sst[3], sst[2] - meet, sst[2] - meet + carbon_h) orig(carbon_stl, carbon_dz);
module hepa_sealed() sealed_part(sst[3], undef, sst[3] - meet, sst[3] - meet + hepa_h) orig(hepa_stl, hepa_dz);
module say_seal_hardware() echo(str("sealed joints: three TPU bead rings, ", seal_bead[0], " mm; four M3 x ", j3_screw,
    " socket head into nuts, HEPA holder to carbon housing; four M3 x ", j12_screw,
    " through the carbon housing's tabs and the section's pillars into the fan section's nuts; eight M3 nuts; every head sunk in its tab"));

// ------------------------------------------------------------------ the joint sample (D121)
// See bentobox.params.scad. Everything past sample_l in from the +Y end wall, sliced off the sealed parts.
module _sample_end(z0, z1) translate([-50, seal_y - sample_l, z0]) cube([100, tab_tip - seal_y + sample_l + 5, z1 - z0]);
// The carbon housing's top end, standing on its cut, its collar and nut tabs up; the HEPA holder's bottom end, on
// its floor, its tabs' counterbores up. Both laid out along X, Y from 0.
module sample_low() translate([0, sample_l - seal_y, sample_low_h - sst[3]])
    intersection() { carbon_sealed(); _sample_end(sst[3] - sample_low_h, sst[3] + 5); }
module sample_up() translate([0, sample_l - seal_y, -sst[3]])
    intersection() { hepa_sealed(); _sample_end(sst[3] - 1, sst[3] + sample_up_h); }
// A fan nut's pocket as the base has it, open under it: 3 mm of its way up, the seat, and the roof with the screw's
// hole bridged through it - for a nut pulled in with a M3 x 8 from above.
pull_block = [16, 16];
module sample_pull() let(h = 3 + nut_slot_h + nut_roof) difference() {
    linear_extrude(h) offset(r = 2) square(pull_block - [4, 4], center = true);
    pull_frame([0, 0, 0], 3 + nut_slot_h) pull_pocket(3 + eps);
}
module joint_sample() {
    w = bb_w + sample_gap;
    translate([-w / 2, 0, 0]) sample_low();
    translate([w / 2, 0, 0]) sample_up();
    translate([0, -pull_block[1] / 2 - sample_gap, 0]) sample_pull();
}
// The bead for that end, in TPU, flat: the ring's run past the slice, open at both ends.
module joint_sample_bead() translate([0, sample_l - seal_y, 0]) intersection() { bead_ring(); _sample_end(-1, 10); }
module say_sample_hardware() echo(str("joint sample: two M3 x ", j3_screw, " socket head and two M3 nuts for the joint, one M3 nut and an M3 x 8 for the pocket's seat"));

// How to cut the paper for the frame, from the values above: what the build page quotes. Only the length is
// measured; across the folds the piece is counted, since the ring sets its width.
module say_paper_cut() echo(str("paper: cut a piece ", round(pack_l * 10) / 10, " mm long along the folds and ", pack_n,
    paper_flaps ? " pleats across and a half pleat more each side, both long edges on a bottom fold"
                : " pleats across, both long edges on a top fold",
    " (about ", round((pack_n + pack_halves) * paper_pitch * 10) / 10, " mm as folded; the ring spreads it to ",
    round(2 * pack_edge * 10) / 10, " mm, ", round(pack_pitch * 100) / 100, " mm a pleat). The caps' wedges are ", round(wedge_w * 100) / 100,
    " mm wide, their points ", round(wedge_z0 * 10) / 10, " mm above the bottom face",
    cap_teeth_below ? "; the teeth from below the same" : "", "; the slots ", round(slot_w * 100) / 100, " mm"));

if (draw_model) {
    if (part == "section") section();
    else if (part == "hepa_ring") { hepa_ring(); say_paper_cut(); }
    else if (part == "hepa_cap") { hepa_cap(); say_paper_cut(); }
    // The Auto's parts as they print: the base and the fan section standing, the plate on its outer face.
    else if (part == "auto_base") { translate([0, 0, -auto_base_z0]) auto_base(); say_auto_hardware(); }
    else if (part == "auto_fans") translate([0, 0, -duct_h]) if (sealed) fans_sealed(); else auto_fans();
    // The sealed stack's remixed originals and the bead ring, as they print: standing, the ring flat.
    else if (part == "carbon") { translate([0, 0, -sst[2]]) carbon_sealed(); say_seal_hardware(); }
    else if (part == "hepa") { translate([0, 0, -sst[3]]) hepa_sealed(); say_seal_hardware(); }
    else if (part == "bead_ring") bead_ring();
    // The joint sample's ASA plate, and its TPU bead.
    else if (part == "joint_sample") { joint_sample(); say_sample_hardware(); }
    else if (part == "joint_sample_bead") joint_sample_bead();
    else if (part == "auto_plate") { translate([0, 0, -auto_base_z0]) auto_plate(); say_auto_hardware(); }
    else assert(false, str("unknown part: ", part));
}
