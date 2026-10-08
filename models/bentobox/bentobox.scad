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

// ------------------------------------------------------------------ the clamp for your own HEPA paper (D127)
// See bentobox.params.scad. The cassette in its own frame: X across, Y along the folds, Z up from its bottom face,
// as it stands on the ledge. The lower frame prints as it stands; the upper one upside down, its band on the bed.
module cas2d() offset(delta = -clamp_play) inside_offset(meet);
// Across the folds - X, and up over the pack's bottom face - what fills the paper's channels. A tooth under every
// top fold, from the lower frame's rim up; a wedge over every bottom fold between the edges, from the upper
// frame's band down; outside each flap, a half wedge from the band down to where it is two beads thick.
module tooth_2d(i) let(x = fold_x(i), g = clamp_fold_gap * tan(pleat_alpha))
    polygon([[x - tooth_w / 2 - g, -clamp_fold_gap - eps], [x + tooth_w / 2 + g, -clamp_fold_gap - eps], [x, tooth_z1]]);
module teeth_2d() for (i = [0 : fold_last]) if (fold_top(i)) tooth_2d(i);
module long_teeth_2d() if (paper_flaps) { tooth_2d(1); tooth_2d(fold_last - 1); }
module half_wedge_2d() let(t = paper_depth + clamp_fold_gap + eps) polygon([[-cas[0] / 2 - 1, half_wedge_z0],
    [flap_out_x(half_wedge_z0), half_wedge_z0], [flap_out_x(t), t], [-cas[0] / 2 - 1, t]]);
module half_wedges_2d() if (paper_flaps) for (m = [0, 1]) mirror([m, 0]) half_wedge_2d();
module wedges_2d() {
    for (i = [1 : fold_last - 1]) if (!fold_top(i)) let(x = fold_x(i), g = clamp_fold_gap * tan(pleat_alpha), t = paper_depth + clamp_fold_gap + eps)
        polygon([[x - wedge_w / 2 - g, t], [x + wedge_w / 2 + g, t], [x, wedge_z0]]);
    half_wedges_2d();
}
// A profile across the folds, run along Y from y0 to y1, its heights over the pack's bottom face.
module run_y(y0, y1) translate([0, y1, pack_z]) rotate([90, 0, 0]) linear_extrude(y1 - y0) children();
// The same, from y0 to y_low under the end blocks' split and to y_high over it: what belongs to one frame stops
// clamp_fold_gap short of the other's end block, and runs on into its own.
module run_split(y0, y_low, y_high) {
    intersection() { run_y(y0, y_low) children(); below(clamp_split); }
    intersection() { run_y(y0, y_high) children(); above(clamp_split); }
}
module both_ends() for (s = [0, 1]) mirror([0, s, 0]) children();
module clamp_screws_at() for (sx = [-1, 1], sy = [-1, 1]) translate([sx * clamp_screw_x, sy * clamp_screw_y, 0]) children();
// The lower frame: a rim round its bottom, under the ends' combs and along the long sides out of the long teeth;
// the end blocks' lower halves; the teeth at each end, and the long teeth beside the flaps. Each end block has a
// pull nut's seat for each screw, its way open underneath.
module clamp_low() let(g = clamp_fold_gap, w = clamp_wedge_l) difference() {
    intersection() {
        union() {
            linear_extrude(clamp_rim) difference() { cas2d(); square([-2 * rim_in, 2 * (comb_y - w)], center = true); }
            linear_extrude(clamp_split) difference() { cas2d(); square([100, 2 * comb_y], center = true); }
            both_ends() run_split(comb_y - w, comb_y + 1, comb_y - g) teeth_2d();
            intersection() { run_y(-comb_y - 1, comb_y + 1) long_teeth_2d(); below(clamp_split); }
            intersection() { run_y(-comb_y + g, comb_y - g) long_teeth_2d(); above(clamp_split); }
        }
        linear_extrude(cas_h) cas2d();
    }
    clamp_screws_at() translate([0, 0, clamp_nut_top]) {
        pull_nut_pocket(small_nut[0], small_nut_slot_h, clamp_way, fdm_hole_comp + pull_fit, fdm_hole_comp + pull_way_fit, eps);
        bridged_hole(small_seat_af / cos(30), small_hole_d, clamp_split - clamp_nut_top + 1, fdm_layer_h, eps);
    }
}
// The upper frame: a band round its top, over the ends' combs and along the long sides out to the first top
// fold; the end blocks' upper halves; the wedges at each end, and the half wedges outside the flaps. Each end
// block has each screw's hole, and a counterbore its head sinks in - bridged, since the frame prints upside down.
module clamp_up() let(g = clamp_fold_gap, w = clamp_wedge_l) difference() {
    intersection() {
        union() {
            translate([0, 0, band_z]) linear_extrude(clamp_band) difference() { cas2d(); square([-2 * fold_x(1), 2 * (comb_y - w)], center = true); }
            translate([0, 0, clamp_split]) linear_extrude(cas_h - clamp_split) difference() { cas2d(); square([100, 2 * comb_y], center = true); }
            both_ends() run_split(comb_y - w, comb_y - g, comb_y + 1) wedges_2d();
            intersection() { run_y(-comb_y + g, comb_y - g) half_wedges_2d(); below(clamp_split); }
            intersection() { run_y(-comb_y - 1, comb_y + 1) half_wedges_2d(); above(clamp_split); }
        }
        linear_extrude(cas_h) cas2d();
    }
    clamp_screws_at() {
        translate([0, 0, clamp_split - 1]) cylinder(d = small_hole_d, h = cas_h - clamp_split + 2);
        translate([0, 0, clamp_head_z]) {
            cylinder(d = small_cb[0], h = small_cb[1] + 1);
            mirror([0, 0, 1]) bridged_hole(small_cb[0], small_hole_d, 1, fdm_layer_h, eps);
        }
    }
}
module clamp_cassette() { clamp_low(); clamp_up(); }
// The paper, for pictures and for checking the frames against it - drawn from the paper's own values, not from
// their arithmetic: each flank a strip t thick, round at the folds, between fold lines paper_t / 2 inside the
// pack's faces. With flaps, each flap's cut end stands on the lower frame's rim.
module paper_2d(t = paper_t) {
    pts = [for (i = [0 : fold_last])
        paper_flaps && (i == 0 || i == fold_last)
            ? [fold_x(i) + (i == 0 ? 1 : -1) * (flap_foot_z - paper_t / 2) * tan(pleat_alpha), flap_foot_z]
            : [fold_x(i), fold_top(i) ? paper_depth - paper_t / 2 : paper_t / 2]];
    for (k = [0 : len(pts) - 2]) hull() {
        translate(pts[k]) circle(d = t, $fn = 16);
        translate(pts[k + 1]) circle(d = t, $fn = 16);
    }
}
module paper_pack(t = paper_t, z = 0) translate([0, 0, z]) run_y(-pack_l / 2, pack_l / 2) paper_2d(t);
// The two frames as they print, side by side: the lower standing, the upper turned over onto its band.
module clamp_frames_printing() {
    translate([-cas[0] / 2 - 3, 0, 0]) clamp_low();
    translate([cas[0] / 2 + 3, 0, cas_h]) mirror([0, 0, 1]) clamp_up();
}
// The clamp's sample (D130): one end of both frames, clamp_sample_l of each in from the end, as they print.
clamp_sample_l = 16;
module _clamp_end() translate([-50, cas[1] / 2 - clamp_sample_l, -1]) cube([100, clamp_sample_l + 1, cas_h + 2]);
module clamp_sample() {
    translate([-cas[0] / 2 - 3, 0, 0]) intersection() { clamp_low(); _clamp_end(); }
    translate([cas[0] / 2 + 3, 0, cas_h]) mirror([0, 0, 1]) intersection() { clamp_up(); _clamp_end(); }
}

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
// The HEPA holder, moved up by dz. With hepa_full its pocket is cut out to the box's whole inside, `meet` past its
// walls' faces, from `meet` under its ledge up through its top; and its ledge's opening to hepa_ledge_w inside
// that, `meet` past the original's sides. The original's ends were solid funnels round an 80 mm cartridge.
module hepa_body(dz = 0) let(f = duct_h + fans_h + carbon_h + dz) difference() {
    orig(hepa_stl, dz);
    if (hepa_full) {
        translate([0, 0, f + ledge_top]) linear_extrude(hepa_h) inside_offset(meet);
        translate([0, 0, f - 1]) linear_extrude(hepa_ledge + 2) offset(delta = meet) rrect(open_wl[0], open_wl[1], hepa_open_r);
    }
}
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
module hepa_sealed() sealed_part(sst[3], undef, sst[3] - meet, sst[3] - meet + hepa_h) hepa_body(hepa_dz);
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

// How to cut the paper for the clamp, from the values above: what the build page quotes. Only the length is
// measured; across the folds the piece is counted, since the clamp sets its width.
module say_paper_cut() echo(str("paper: cut a piece ", round(pack_l * 10) / 10, " mm long along the folds and ", pack_n,
    paper_flaps ? " pleats across and a half pleat more each side, both long edges on a bottom fold"
                : " pleats across, both long edges on a top fold",
    " (about ", round((pack_n + pack_halves) * paper_pitch * 10) / 10, " mm as folded; the clamp spreads it to ",
    round(2 * pack_edge * 10) / 10, " mm, ", round(pack_pitch * 100) / 100, " mm a pleat). The clamp's slot is ",
    clamp_slot, " mm; its four screws M2 x ", clamp_screw, " socket head, into M2 nuts pulled into the lower frame"));

if (draw_model) {
    if (part == "section") section();
    // The clamp's two frames as they print: the lower standing, the upper on its band; and its sample.
    else if (part == "clamp_lower") { clamp_low(); say_paper_cut(); }
    else if (part == "clamp_upper") { translate([0, 0, cas_h]) mirror([0, 0, 1]) clamp_up(); say_paper_cut(); }
    else if (part == "clamp_sample") { clamp_sample(); say_paper_cut(); }
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
