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
module long_teeth_2d() if (flaps) { tooth_2d(1); tooth_2d(fold_last - 1); }
module half_wedge_2d() let(t = paper_depth + clamp_fold_gap + eps) polygon([[-cas[0] / 2 - 1, half_wedge_z0],
    [flap_out_x(half_wedge_z0), half_wedge_z0], [flap_out_x(t), t], [-cas[0] / 2 - 1, t]]);
module half_wedges_2d() if (flaps) for (m = [0, 1]) mirror([m, 0]) half_wedge_2d();
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
        flaps && (i == 0 || i == fold_last)
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

// ------------------------------------------------------------------ the glue frame for your own HEPA paper (T131)
// Alon, 9 Oct 2026: "make a hot glue version for the hepa". One ASA frame, the clamp's outline: walls glue_lip over
// the paper's top folds, a rim round its bottom on the ledge, open over the ledge's opening. The paper stands on the
// rim, its long edges cut on a top fold against the side walls, its cut ends against the end walls. The glue goes in
// from the top, the dirty side, and that is the only side that needs it: in the end of every channel open at the
// top, at both ends, as the clamp's wedges were, and in a bead across each end and along each long side where the
// top fold meets the wall. The channels open at the bottom end over the rim, which closes them. No fins: every wall
// is solid, two lines or more, the corners at least 1.1 mm. Short fins on the rim at each end (Alon, 9 Oct 2026)
// space the folds as the paper goes in: one up into each channel open at the bottom, glue_jig[1] clear of the
// paper, glue_jig[0] tall - from 1.4 mm wide at the rim to 1 at the top. They stop 0.3 mm short of the rim's
// inner edge, so no face of theirs lies in the rim's.
module jig_fin_2d(i) let(x = fold_x(i), ta = tan(pleat_alpha), w0 = pack_pitch / 2 + (1 + paper_t / 2) * ta - jig_c,
                         w1 = pack_pitch / 2 - (glue_jig[0] - paper_t / 2) * ta - jig_c)
    polygon([[x - w0, -1], [x + w0, -1], [x + w1, glue_jig[0]], [x - w1, glue_jig[0]]]);
module jig_fins_2d() for (i = [1 : fold_last - 1]) if (fold_top(i)) jig_fin_2d(i);
module glue_frame() union() {
    difference() {
        linear_extrude(gf_h) cas2d();
        translate([-gf_in[0], -gf_in[1], clamp_rim]) cube([2 * gf_in[0], 2 * gf_in[1], gf_h]);
        translate([-gf_rim[0] / 2, -gf_rim[1] / 2, -1]) cube([gf_rim[0], gf_rim[1], clamp_rim + 2]);
    }
    both_ends() run_y(gf_rim[1] / 2 + 0.3, gf_in[1] + 0.5) jig_fins_2d();
}
// Its sample: one end, glue_sample_l in from it, as it prints - to glue an offcut in before the whole frame.
glue_sample_l = 16;
module glue_sample() intersection() {
    glue_frame();
    translate([-50, cas[1] / 2 - glue_sample_l, -1]) cube([100, glue_sample_l + 1, gf_h + 2]);
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
module cmag_standing(z0) cmag_stood(z0) for (f = cmag_stls) import(f, convexity = 10);
// A C-MAG, from its own frame to standing on end in the housing, its bottom at z0.
module cmag_stood(z0) translate([cmag[2] / 2, -cmag[1] / 2, z0]) rotate([0, -90, 0]) children();

// ------------------------------------------------------------------ the bottom
// The base and its tray are the remix's own, drawn to the Auto's measurements (bentobox.params.scad); the fan
// section is Strangwooduk's (scripts/bentobox-auto-stl.py writes it from the STEP, with the base and plate this
// remix measured), moved into this frame. The base stands on the tray, the tray on Z = auto_base_z0, and the
// base's top is at duct_h, where the duct's is.
auto_fans_stl  = str(orig_dir, "bentobox-auto-fans.stl");
module auto_fans() orig(auto_fans_stl, auto_fans_dz);
// The fan section the stack stands on, whichever bottom it has, as it comes - its tongue and magnets on top, for the
// original joints' checks.
module fan_section() if (bottom == "auto") auto_fans(); else orig(fans_stl);
// The Auto's fan section drawn (Alon, 9 Oct 2026: "rebuild all the parts that are not currently scad"), to its STL's
// measurements: the box's outline and inside, its top edge chamfered bb_chamfer outside; the floor auto_floor_t,
// with each fan's opening and its two screws' holes. Its top is the sealed joint's (sealed_part cuts it there), and
// the wires' hole is the grommet's (fans_sealed cuts it).
module fans_drawn() let(z0 = duct_h, z1 = duct_h + fans_h, c = bb_chamfer) difference() {
    hull() {
        translate([0, 0, z0]) linear_extrude(z1 - z0 - c) rrect(bb_w, bb_l, bb_r);
        translate([0, 0, z1 - eps]) linear_extrude(eps) rrect(bb_w - 2 * c, bb_l - 2 * c, bb_r - c);
    }
    translate([0, 0, z0 + auto_floor_t]) linear_extrude(z1 - z0) inside_offset(0);
    for (y = fan_ys) translate([0, y, z0 - 1]) cylinder(d = auto_fan_air, h = auto_floor_t + 2, $fn = 96);
    for (s = auto_fan_screws) translate([s[0], s[1], z0 - 1]) cylinder(d = auto_fan_hole, h = auto_floor_t + 2);
}
// The fan section as it prints: drawn and sealed, with the bottom; the Auto's own, with the bambu bottom unsealed.
module fans_printed() if (sealed && bottom == "auto") fans_sealed(); else fan_section();

// A slot's own frame: X out towards its mouth, the screw's axis at the origin, Z = 0 at z.
module slot_frame(s, z) translate([s[0], s[1], z]) rotate(s[2]) children();
// A nut's slot (scad-tools nuts.scad), from behind the axis out through its mouth, `out` past the axis, its back end
// the nut's own shape (T189, 10 Oct 2026: on the coupon only those ends held the nut still and kept it in)...
module slot(out = nut_slot_out) nut_slot_hex_end(nut_af, nut_slot_h, out, fdm_hole_comp + nut_fit);
// ...and the screw's hole on up through its roof, l long, as a bridged hole (scad-tools fdm.scad): a channel as
// wide as the hole across the slot, so the first layer is two bridges from side to side; the hole, square, so the
// second is two bridges along the slot over the channel; then the round hole.
module roof_hole(l) translate([0, 0, nut_slot_h]) rotate(90) bridged_hole(nut_slot_w, hole_d, l, fdm_layer_h, eps);
// The fan section's floor openings, carried down into the base: the fans' air.
module fan_air(h, grow = 0) for (y = fan_ys) translate([0, y, duct_h - h]) cylinder(d = auto_fan_air + 2 * grow, h = h + 1);

// A fan screw's post (seamless, Alon 8 Oct): big enough for the nut, and cut back clear of the fans' air (Alon,
// 9 Oct). Its frame: the screw's axis at the origin, X out of the post's wall into the room.
module post_frame(s) translate([s[0], s[1], 0]) rotate(s[3]) children();
// From above: round at its end, its sides running into the wall on fillets; cut back clear of the fans' air, the
// corners there rounded. The fillets are tangent to a line post_blend inside the wall's face, so the two cross at a
// slant; the strip they come off runs 3 mm into the wall.
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
// A fan screw's way: its nut's pocket (scad-tools nuts.scad), up from its mouth under the post to the seat, the
// seat a nut's height under the roof, and the screw's hole on up through the roof to the base's top, bridged
// (scad-tools fdm.scad): a channel the hole's width from corner to corner, then the hole's square, then the round hole.
module pull_pocket(way, f = pull_fit) {
    pull_nut_pocket(nut_af, nut_slot_h, way, fdm_hole_comp + f, fdm_hole_comp + pull_way_fit, eps);
    bridged_hole((nut_af + 2 * (fdm_hole_comp + f)) / cos(30), hole_d, duct_h - pull_top + 1, fdm_layer_h, eps);
}
module fan_screw_cut(s) pull_frame(s, pull_top) pull_pocket(pull_seat - pull_bot);
// A tray screw's way in the base: its hole up from the base's bottom face through the floor to its slot, the slot
// out through the end face, and the hole on up through the slot's roof, bridged, to past its tip.
module tray_slot_cut(s) {
    translate([s[0], s[1], auto_bay_top - 1]) cylinder(d = hole_d, h = tray_slot_bot - auto_bay_top + 1 + eps);
    slot_frame(s, tray_slot_bot) { slot(s[3]); roof_hole(tray_tip_z + 0.5 - tray_slot_top); }
}
// The duct's air: its floor flat from the outlet, then turning up into the +X wall on base_turn_r, tangent to both,
// between the end walls; every edge where these meet rounded by base_fillet. It is a convex core, base_fillet in
// from the air's faces, grown by a ball; the core runs on past the outlet and over the top, so only the inside's
// edges come out round. OpenSCAD's ball has no corner at its poles or on its equator - its rings sit half a step
// off them - so it is scaled until those reach base_fillet: then the flat faces are where they are set.
module duct_core() let(r = base_turn_r - base_fillet, x1 = duct_in[0] - base_fillet, z1 = base_floor + base_fillet)
    rotate([90, 0, 0]) linear_extrude(2 * (duct_in[1] - base_fillet), center = true)
        polygon(concat([[-bb_w, z1]], [for (a = [-90 : 3 : 0]) turn_c + r * [cos(a), sin(a)]], [[x1, duct_h + 20], [-bb_w, duct_h + 20]]));
module duct_air() minkowski() { duct_core(); sphere(r = base_fillet / cos(180 / 32), $fn = 32); }
// The outlet's rim rounded by base_lip_r: a cutter - a square corner less its quarter circle - run along the floor's
// edge, round the fillets into the end walls, and up the end walls' tips. It starts 0.3 mm out in the air, so it
// crosses the duct's faces rather than lying on them.
module lip2d() difference() { translate([-0.3, -0.3]) square(base_lip_r + 0.3); translate([base_lip_r, base_lip_r]) circle(r = base_lip_r, $fn = 32); }
module outlet_lip() let(x0 = -bb_w / 2, y1 = duct_in[1] - base_fillet, z1 = base_floor + base_fillet) {
    translate([x0, 0, base_floor]) rotate([90, 0, 0]) linear_extrude(2 * y1 + 0.02, center = true) mirror([0, 1]) lip2d();
    for (sy = [-1, 1]) {
        translate([x0, sy * y1, z1]) rotate([0, 90, 0]) rotate_extrude(angle = sy * 90, $fn = 64) translate([base_fillet, 0]) lip2d();
        translate([x0, sy * duct_in[1], z1 - 0.01]) linear_extrude(duct_h - z1 + 1) mirror([0, sy < 0 ? 1 : 0]) lip2d();
    }
}
// The wires' tube, from above: round on the hole's axis, standing against the +X wall on fillets into it, as the
// posts do - tangent to a line post_blend inside the wall's face.
module conduit2d() let(r = conduit_wall[0], f = conduit_wall[1]) offset(r = -f) offset(delta = f) {
    translate([auto_conduit[0], auto_conduit[1]]) circle(r = r);
    translate([duct_in[0] + post_blend, auto_conduit[1] - r - f - 0.5]) square([3 - post_blend, 2 * (r + f + 0.5)]);
}
// The base: the duct's walls and floor over the bay's roof, the tube and the posts; the outlet's rim rounded; the
// wires' hole down the tube to the bay, the fans' nut pockets, and the tray's screws' slots.
module auto_base() difference() {
    intersection() {
        union() {
            difference() {
                translate([0, 0, auto_bay_top]) linear_extrude(duct_h - auto_bay_top) rrect(bb_w, bb_l, bb_r);
                duct_air();
            }
            translate([0, 0, auto_bay_top]) linear_extrude(duct_h - auto_bay_top) conduit2d();
            for (s = auto_fan_screws) fan_post(s);
        }
        below(duct_h);
    }
    outlet_lip();
    translate([auto_conduit[0], auto_conduit[1], auto_bay_top - 1]) cylinder(d = auto_conduit[2], h = duct_h - auto_bay_top + 2);
    for (s = auto_fan_screws) fan_screw_cut(s);
    for (s = tray_screws) tray_slot_cut(s);
}

// ------------------------------------------------------------------ the bay's tray (Alon, 8-9 Oct 2026)
// The bottom under the bay's roof, a part of its own: the floor, the walls round the bay, the ends' blocks, the
// magnets' holes, and the USB-C board's pocket in the -Y end. It prints on its floor, open at the top.
module tray_outline() rrect(bb_w, bb_l, bb_r);
module bay2d() translate([bay_x, 0]) rrect(bay_size[0], bay_size[1], bay_size[2]);
// The USB-C board's pocket: the notch the socket goes through, round at its ends and open over its top; the board's
// pocket behind the wall in front of it, from its floor on up, open to the bay - its far edge stops short of it.
module usb_notch2d() hull() {
    for (s = [-1, 1]) translate([usb_x + s * (usb_notch_w / 2 - usb_notch_r), usb_axis_z]) circle(r = usb_notch_r, $fn = 32);
    translate([usb_x - usb_notch_w / 2, usb_axis_z]) square([usb_notch_w, tray_top + 1 - usb_axis_z]);
}
module usb_pocket() {
    translate([0, usb_pcb_y0 + 1, 0]) rotate([90, 0, 0]) linear_extrude(usb_pcb_y0 + 1 + bb_l / 2 + 1) usb_notch2d();
    translate([usb_x - usb_pocket[0] / 2, usb_pocket[1], usb_pcb_z]) cube([usb_pocket[0], -bay_size[1] / 2 + 1 - usb_pocket[1], tray_top + 1 - usb_pcb_z]);
}
// The stop behind the board, on the bay's floor, between the board's pads: up to the board's top and a little more.
module usb_stop_block() translate([usb_x - usb_stop[0] / 2, usb_pcb_y1 + usb_c, auto_seat_z - eps])
    cube([usb_stop[0], usb_stop[1], usb_pcb_z + usb_board[2] + 0.5 - auto_seat_z + eps]);
// A tray screw's way in the tray: its head's counterbore up from the bottom face, and its hole bridged up through
// the counterbore's roof and on through the tray.
module tray_screw_cut(s) translate([s[0], s[1], 0]) {
    translate([0, 0, auto_base_z0 - 1]) cylinder(d = m3_cb[0], h = m3_cb[1] + 1);
    translate([0, 0, tray_head_z]) bridged_hole(m3_cb[0], hole_d, tray_top - tray_head_z + 1, fdm_layer_h, eps);
}
module auto_tray() union() {
    difference() {
        translate([0, 0, auto_base_z0]) linear_extrude(tray_top - auto_base_z0) tray_outline();
        translate([0, 0, auto_seat_z]) linear_extrude(tray_top - auto_seat_z + 1) bay2d();
        usb_pocket();
        for (m = auto_magnets, sy = [-1, 1]) translate([m[0], sy * m[1], auto_base_z0 - 1]) cylinder(d = auto_magnet[0], h = auto_magnet[1] + 1);
        for (s = tray_screws) tray_screw_cut(s);
    }
    usb_stop_block();
}
module say_usb() echo(str("usb-c: the socket's face flush with the -Y end face, its axis at X ", usb_x, ", Z ", usb_axis_z,
    " (", usb_axis_z - auto_base_z0, " over the bottom face); the board on a floor ", usb_pcb_z - auto_base_z0, " over the bottom face"));
module say_auto_hardware() echo(str("auto: eight M3 nuts, the fans' four pulled up into pockets, the tray's four in slots; the fans' four screws M3 x ",
    fan_screw, " socket head, through the fans; the tray's four M3 x ", tray_screw, " socket head, sunk ", head_sink,
    " mm into its bottom face"));

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
            for (s = joint_screws(st)) {
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
// The sealed stack's parts in place: the fan section, the carbon housing, the HEPA holder. Each part's body stands
// `meet` lower than its joint's face, whose cut takes that much off its floor.
sst = stack(true, true);
module fans_sealed() difference() {
    sealed_part(undef, sst[1], duct_h, duct_h + fans_h) if (bottom == "auto") fans_drawn(); else fan_section();
    translate([grommet_x, auto_conduit[1], duct_h]) grommet_hole();
}
// The carbon housing drawn (Alon, 9 Oct 2026), to its STL's measurements, from Z = z0, housing_h tall: the outline,
// its edges chamfered; the inside over the floor, its edge on the floor chamfered; and through the floor, for the bed
// a honeycomb across the whole inside (D146), for the C-MAG the original's two openings, chamfered underneath, and a
// fill mark on each inside wall for the bed. Its two faces are the sealed joints' (sealed_part cuts them). The
// original's text on its -X face is left off.
module carbon_open2d() let(o = carbon_open) hull() {
    translate([0, o[2] - o[0]]) circle(r = o[0], $fn = 96);
    translate([o[0] - o[3], o[1] + o[3]]) circle(r = o[3], $fn = 32);
    intersection() { translate([0, o[1] + o[0]]) circle(r = o[0], $fn = 96); translate([-o[0], o[1]]) square(o[0]); }
}
// The floor's honeycomb: whole holes inside the inside's outline, bed_mesh[2] in, its rounded corners included.
function in_rrect(c, size, r, margin) = let(dx = max(abs(c[0]) - (size[0] / 2 - r), 0), dy = max(abs(c[1]) - (size[1] / 2 - r), 0))
    norm([dx, dy]) <= r - margin + 1e-9;
function bed_holes() = let(size = [in_w - 2 * bed_mesh[2], in_l - 2 * bed_mesh[2]], r = max(in_r - bed_mesh[2], 0.01))
    [for (c = mesh_holes(size, bed_mesh[0], bed_web)) if (in_rrect(c, size, r, bed_hole_ac / 2)) c];
module bed_holes2d() for (c = bed_holes()) translate(c) rotate(90) circle(d = bed_hole_ac, $fn = 6);
// A fill mark at the origin, on a wall in the XZ plane, standing out towards +Y: a slot's shape, its edges at 45
// degrees; it starts 0.05 inside the wall, so it joins it. One in the middle of each inside wall, at the bed's top.
module bed_mark1() let(l = bed_mark, k = bed_mark[2] + 0.05) translate([0, -0.05, 0]) rotate([-90, 0, 0])
    hull() for (s = [[l[0], l[1], 0], [l[0] - 2 * k, l[1] - 2 * k, k - eps]]) translate([0, 0, s[2]]) linear_extrude(eps)
        hull() for (sx = [-1, 1]) translate([sx * (s[0] - s[1]) / 2, 0]) circle(d = s[1], $fn = 32);
module bed_marks(z0) let(z = z0 + carbon_floor + bed_depth)
    for (w = [[0, -in_l / 2, 0], [0, in_l / 2, 180], [in_w / 2, 0, 90], [-in_w / 2, 0, -90]])
        translate([w[0], w[1], z]) rotate(w[2]) bed_mark1();
// Its outside runs 1 mm past both ends: each end is a sealed joint, which cuts it there, and the outline's own
// chamfers, left inside the cut, crossed the joint's outline under the collar and made slivers.
module carbon_drawn(z0) let(c = carbon_chamfer, f = carbon_floor, h = housing_h) union() {
    difference() {
        translate([0, 0, z0 - 1]) outline_solid(h + 2);
        hull() {
            translate([0, 0, z0 + f]) linear_extrude(eps) inside_offset(-c);
            translate([0, 0, z0 + f + c]) linear_extrude(h) inside_offset(0);
        }
        if (carbon == "bed") translate([0, 0, z0 - 2]) linear_extrude(f + 3, convexity = 10) bed_holes2d();
        else for (r = [0, 180]) rotate(r) {
            hull() {
                translate([0, 0, z0 - 1]) linear_extrude(1 + eps) offset(delta = c) carbon_open2d();
                translate([0, 0, z0 + c]) linear_extrude(eps) carbon_open2d();
            }
            translate([0, 0, z0 + c]) linear_extrude(f) carbon_open2d();
        }
    }
    if (carbon == "bed") bed_marks(z0);
}
module carbon_sealed() sealed_part(sst[2], sst[3], sst[2] - meet, sst[2] - meet + housing_h, "corners", top_tabs) carbon_drawn(sst[2] - meet);
// The HEPA holder drawn (Alon, 9 Oct 2026), to its STL's measurements, from Z = z0: the outline, its top edge
// chamfered; the pocket - the whole inside - over the ledge; the ledge's opening; and the magnets' holes in its top,
// where the original cover sits on it. Drawn as the cut-out original was, the pocket and the opening `meet` past its
// faces and the ledge `meet` under: the clamp is sized to that. Its bottom is the sealed joint's (sealed_part). The
// outside is the sealed joint's own outline, its chamfer made from the same points: a chamfer from the box's rounded
// rectangle crossed that outline's prism at the corners a hair off, and made slivers.
module hepa_drawn(z0) let(c = bb_chamfer, t = z0 + hepa_h) difference() {
    hull() {
        translate([0, 0, z0 - 1]) linear_extrude(hepa_h + 1 - c) polygon(outline_pts());
        translate([0, 0, t - eps]) linear_extrude(eps) offset(delta = -c) polygon(outline_pts());
    }
    translate([0, 0, z0 + ledge_top]) linear_extrude(hepa_h) inside_offset(hepa_in_grow);
    translate([0, 0, z0 - 1]) linear_extrude(hepa_ledge + 2) offset(delta = meet) rrect(open_wl[0], open_wl[1], hepa_open_r);
    magnet_holes(z0 + hepa_h, false);
}
module hepa_sealed() sealed_part(sst[3], undef, sst[3] - meet, sst[3] - meet + hepa_h, top_tabs) hepa_drawn(sst[3] - meet);
// The cover drawn (Alon, 9 Oct 2026: D142), to ThrutheFrame's cover_hemp, its plate's underside on Z = z0, the
// holder's top: the plate, its bottom edge chamfered and its top edge rounded, then chamfered at 45 degrees as it
// prints, top face down; the plug under it; the magnets' holes in the plate's underside; and the window, filled
// with the hemp-leaf pattern.
module cover_plate(z0) let(r = cover_round, c = bb_chamfer, t = z0 + cover_top, zc = t - r * sqrt(2))
    hull() for (s = concat([[z0, c], [z0 + c, 0]], [for (a = [0 : 9 : 45]) [zc + r * sin(a), r - r * cos(a)]], [[t - eps, r]]))
        translate([0, 0, s[0]]) linear_extrude(eps) rrect(bb_w - 2 * s[1], bb_l - 2 * s[1], bb_r - s[1]);
// The pattern's holes: each triangle of the lattice split in three by its spokes, each third shrunk by half a bar.
// Its corners stand in rows cover_tile * sqrt(3) / 2 apart in Y, every other row moved half a side along X.
function hemp_corner(k, j) = [(j + (k % 2 == 0 ? 0 : 0.5)) * cover_tile, k * cover_tile * sqrt(3) / 2];
module hemp_holes2d() let(a = cover_tile, h = a * sqrt(3) / 2, n = ceil(cover_win[0] / a) + 1, m = ceil(cover_win[1] / h) + 1)
    for (k = [-m : m - 1], j = [-n : n], up = [0, 1])
        let(p = hemp_corner(up == 1 ? k : k + 1, j), q = p + [a, 0], o = (p + q) / 2 + [0, up == 1 ? h : -h], c = (p + q + o) / 3)
            for (e = [[p, q], [q, o], [o, p]]) offset(delta = -cover_bar / 2) polygon([c, e[0], e[1]]);
module cover_drawn(z0) difference() {
    union() {
        cover_plate(z0);
        translate([0, 0, z0 - cover_plug[3]]) linear_extrude(cover_plug[3] + eps) rrect(cover_plug[0], cover_plug[1], cover_plug[2]);
    }
    translate([0, 0, z0 - cover_plug[3] - 1]) linear_extrude(cover_plug[3] + cover_top + 2, convexity = 10)
        intersection() { rrect(2 * cover_win[0], 2 * cover_win[1], cover_win_r); hemp_holes2d(); }
    for (sx = [-1, 1], sy = [-1, 1]) translate([sx * mag_xy[0], sy * mag_xy[1], z0 - 1]) cylinder(d = mag_d, h = 1 + mag_h);
}
// The cover on the sealed stack's HEPA holder.
cover_z0 = sst[3] - meet + hepa_h;

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
// A profile drawn across the box (Y, Z), extruded along it from x0 to x1.
module along_x(x0, x1) translate([x0, 0, 0]) rotate([90, 0, 90]) linear_extrude(x1 - x0, convexity = 10) children();
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
// A honeycomb of whole hexagonal holes inside the rectangle `size`, centred: holes `hole` across their flats, `web`
// between every two neighbours, their flats facing along X. Rows run along X, an even number of them across Y, which
// fits the most whole holes into a grill. (scad-tools lib/patterns.scad has it as honeycomb_centres; this copy stays
// until the scad-tools pin moves past it.)
function mesh_holes(size, hole, web) = let(p = hole + web, dy = p * sqrt(3) / 2, R = hole / sqrt(3),
    hx = size[0] / 2, hy = size[1] / 2, m = ceil(hy / dy) + 1, k = ceil(hx / p) + 2)
    [for (i = [-m : m], j = [-k : k]) let(c = [(j + (i % 2 == 0 ? 0 : 0.5)) * p, (i + 0.5) * dy])
        if (abs(c[0]) + hole / 2 <= hx + 1e-9 && abs(c[1]) + R <= hy + 1e-9) c];
// A grill, flat: the plate, and a honeycomb of whole holes inside its rim, their flats facing along W.
function cmag_mesh_holes() = mesh_holes([cmag_grill[0] - 2 * cmag_rim, cmag_grill[1] - 2 * cmag_rim], cmag_mesh[0], cmag_web);
module cmag_grill2d() difference() {
    rrect(cmag_grill[0], cmag_grill[1], cmag_grill[2]);
    for (c = cmag_mesh_holes()) translate(c) rotate(90) circle(d = cmag_hole_ac, $fn = 6);
}
// The four grills in their slots, in the C-MAG's frame.
module cmag_grills_drawn() for (g = cmag_grills) along_x(g - cmag_grill_t / 2, g + cmag_grill_t / 2) translate([cmag[1] / 2, cmag[2] / 2]) cmag_grill2d();
module cmag_drawn() { cmag_tray_drawn(); cmag_lid_drawn(); cmag_grills_drawn(); }
module say_cmag() let(n = len(cmag_mesh_holes()), open = n * 3 * sqrt(3) / 8 * pow(cmag_hole_ac, 2))
    echo(str("C-MAG grills: ", n, " holes each, ", cmag_mesh[0], " mm across their flats, ", cmag_hole_ac, " across their corners, ",
        "for ", cmag_pellet, " mm pellets; ", round(open), " mm2 open, ", round(100 * open / (cmag_grill[0] * cmag_grill[1])), " % of a grill"));
function _count(n) = n == 1 ? "one" : n == 2 ? "two" : n == 4 ? "four" : n == 6 ? "six" : n == 8 ? "eight" : str(n);
module say_seal_hardware() echo(str("sealed joints: three TPU bead rings, ", seal_bead[0], " mm; ", _count(len(top_screws)),
    " M3 x ", j3_screw, " socket head into nuts, HEPA holder to carbon housing; four M3 x ", j12_screw,
    " through the carbon housing's tabs and the section's pillars into the fan section's nuts; ",
    _count(len(tab_screws) + len(top_screws)), " M3 nuts; every head sunk in its tab, turned with a 2.5 mm hex screwdriver"));

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
// The nut coupon (T181, T182 - Alon, 9 Oct 2026: a tray nut spun in its slot, and a fan nut fell out of its seat
// even pulled up). One block: along the back, five fan-nut seats, numbered 1 to 5 on the top, as the base's -
// pull a nut up into each with an M3 x 8 from the top, take the screw out, and see which holds it; along the front,
// five tray-nut slots, 6 to 10, open at the front face, a 0.8 mm floor under them as in the base - slide a nut in,
// drive an M3 up from below, and see which keeps it from turning. 5 is today's seat and 6 today's slot. 6 and 7 end
// square, as the base's do; 8 and 9 end in the nut's own shape, so it sits against four walls, its two flats and the
// two faces behind them (Alon's idea), and stops on the screw's axis; 10 narrows to the screw (Alon's trapezoid):
// free at its mouth, tight on the nut's flats where it stops. The fits are on top of fdm_hole_comp, each side, as
// pull_fit and nut_fit are. Tried 10 Oct 2026 (T189): seat 3 and slot 8 set pull_fit and the slots' ends. The fits
// are literals, the coupon as it was printed and tried, so setting pull_fit and nut_fit does not change it.
coupon_pull = [-0.15, -0.1, -0.05, 0, 0.05];
coupon_slot = [[0.15, "square"], [0, "square"], [0.15, "hex"], [0, "hex"], [-0.1, "taper"]];
coupon_taper = [0.15, 4];              // the tapered slot: its fit at its mouth, and the taper's length
nc_n = 5;
nc_pitch = 14;
nc_y = [7, 22];                        // the slots' axes, from the front face, and the seats'
nc_h = 3 + nut_slot_h + nut_roof;      // the seats' way 3 mm, the seat, the roof: as sample_pull's
function nc_w(f) = nut_af + 2 * (fdm_hole_comp + f);
// The coupon's tapered slot, in a slot's frame (slot_frame): narrowing from coupon_taper's fit at the mouth to f on
// the nut's flats. Its square and nut-shaped ends are scad-tools nuts.scad's.
module tapered_slot(f0, out) let(ac = nut_af / cos(30), w0 = nc_w(f0), w1 = nc_w(coupon_taper[0]), x0 = ac / 4, l = coupon_taper[1]) {
    translate([-(ac / 2 + fdm_hole_comp + f0), -w0 / 2, 0]) cube([ac / 2 + fdm_hole_comp + f0 + x0 + eps, w0, nut_slot_h]);
    hull() {
        translate([x0, -w0 / 2, 0]) cube([eps, w0, nut_slot_h]);
        translate([x0 + l, -w1 / 2, 0]) cube([eps, w1, nut_slot_h]);
    }
    translate([x0 + l, -w1 / 2, 0]) cube([out - x0 - l, w1, nut_slot_h]);
}
module nut_coupon() difference() {
    translate([-nc_pitch / 2, 0, 0]) cube([nc_n * nc_pitch + 2, nc_y[1] + 8, nc_h]);
    for (k = [0 : nc_n - 1]) let(x = k * nc_pitch, f = coupon_slot[k][0], end = coupon_slot[k][1]) {
        pull_frame([x, nc_y[1], 0], 3 + nut_slot_h) pull_pocket(3 + eps, coupon_pull[k]);
        translate([x, nc_y[0], -1]) cylinder(d = hole_d, h = nut_floor + 1 + eps);
        slot_frame([x, nc_y[0], 270, 0], nut_floor) {
            if (end == "square") nut_slot(nut_af, nut_slot_h, nc_y[0] + 1, fdm_hole_comp + f);
            else if (end == "hex") nut_slot_hex_end(nut_af, nut_slot_h, nc_y[0] + 1, fdm_hole_comp + f);
            else tapered_slot(f, nc_y[0] + 1);
            translate([0, 0, nut_slot_h]) rotate(90) bridged_hole(nc_w(f), hole_d, nc_h - nut_floor - nut_slot_h + 1, fdm_layer_h, eps);
        }
        for (j = [0, 1]) translate([x + 4.6, nc_y[j], nc_h - 0.4]) linear_extrude(1)
            text(str(k + 1 + nc_n * (1 - j)), size = 3, halign = "center", valign = "center");
    }
}
module say_nut_coupon() echo(str("nut coupon, as cut across the flats: seats 1-", nc_n, " ", [for (f = coupon_pull) nc_w(f)],
    " (pull_fit ", coupon_pull, "); slots ", nc_n + 1, "-", 2 * nc_n, " ", [for (c = coupon_slot) [nc_w(c[0]), c[1]]],
    " (the taper from ", nc_w(coupon_taper[0]), " at its mouth)"));
module joint_sample() {
    w = bb_w + sample_gap;
    translate([-w / 2, 0, 0]) sample_low();
    translate([w / 2, 0, 0]) sample_up();
    translate([0, -pull_block[1] / 2 - sample_gap, 0]) sample_pull();
}
// The bottom sample (A140): the tray's -Y end, with the USB-C board's pocket and its stop, and the base's floor over
// it, with the tray's nut slots - side by side, as they print.
module _bottom_end(z0, z1) translate([-bb_w, -bb_l / 2 - 1, z0]) cube([2 * bb_w, bottom_sample_l + 1, z1 - z0]);
module bottom_sample() let(w = bb_w + sample_gap) {
    translate([-w / 2, 0, -auto_base_z0]) intersection() { auto_tray(); _bottom_end(auto_base_z0 - 1, tray_top + 1); }
    translate([w / 2, 0, -auto_bay_top]) intersection() { auto_base(); _bottom_end(auto_bay_top - 1, auto_bay_top + bottom_sample_h); }
}
// The bead for that end, in TPU, flat: the ring's run past the slice, open at both ends.
module joint_sample_bead() translate([0, sample_l - seal_y, 0]) intersection() { bead_ring(); _sample_end(-1, 10); }
// ------------------------------------------------------------------ the wires' grommet (D117)
// See bentobox.params.scad. Drawn on its axis, Z = 0 at the floor's underside. The floor's hole: opened out to the
// grommet, a groove round it at mid-height with 45-degree sides, and a chamfer at its top for the lip.
module grommet_hole() let(r = grommet_hole_r, g = grommet_groove, c = grommet_chamfer, h = auto_floor_t, m = grommet_mid)
    rotate_extrude($fn = 64) polygon([[0, -1], [r, -1], [r, m - g], [r + g, m], [r, m + g], [r, h - c], [r + c + 1, h + 1], [0, h + 1]]);
// The grommet, one piece (Alon, 9 Oct 2026): a ring through the floor, the lip round it at mid-height, a small
// chamfer at its foot, and a thin skin across the leads' hole there - with grommet_skin 0, an open hole. It prints
// as drawn, on its foot. The skin is a disc of its own, reaching halfway into the ring: a profile with points on the
// axis would leave a sliver facet round each of them. In the skin, a hole for each lead (Alon, 9 Oct 2026), out by
// the ring; each runs on up the ring's inside as a groove, so its lead goes straight up.
module grommet_body() let(r = grommet_r, i = grommet_in_r, l = grommet_lip, h = auto_floor_t, m = grommet_mid, s = grommet_skin * fdm_layer_h)
    difference() {
        union() {
            rotate_extrude($fn = 64) polygon([[i, 0], [r - 0.3, 0], [r, 0.3], [r, m - l], [r + l, m], [r, m + l], [r, h], [i, h]]);
            if (s > 0) cylinder(r = (i + r - 0.3) / 2, h = s, $fn = 64);
        }
        if (s > 0) for (k = [0 : grommet_leads[0] - 1]) rotate(k * 360 / grommet_leads[0])
            translate([grommet_lead_r, 0, -1]) cylinder(d = grommet_lead_d, h = h + 2, $fn = 32);
    }
// The floor's hole on a coupon of the floor, to try the grommet in before the fan section: 3 mm, in ASA.
module grommet_coupon() difference() {
    translate([-10, -10, 0]) cube([20, 20, auto_floor_t]);
    grommet_hole();
}

// ------------------------------------------------------------------ the fans' plug mate (Alon, 9 Oct 2026)
// See bentobox.params.scad. Drawn in its own frame (bentobox.layout.scad): the pins along X at Y = 0, the block's
// underside at Z = 0, as it prints. Each wire comes up its slot from below, its insulation stopping where the slot
// ends, so it cannot be pulled out upwards; its bared core goes on up its hole and stands as the pin. Under the block
// each wire bends over into a groove to the back edge: once the block is fixed down, that bend stops a pin being
// pushed down.
module fan_mate_key(x) let(h = fan_mate_base[0], wh = fan_mate_wall[1] - 0.5, d = fm_key_y - fm_wall_y, e = 0.3)
    // its top chamfered at 45 degrees, a lead-in between the ribs, 0.5 mm under the wall's top. It starts e inside
    // the wall, so the chamfer crosses the wall's face: an edge lying in that face leaves sliver facets
    translate([x - fm_key_w / 2, fm_wall_y - e, h - 0.01]) hull() {
        cube([fm_key_w, d + e, wh - d - e + 0.01]);
        cube([fm_key_w, 0.01, wh + 0.01]);
    }
// The clip (D174): a ridge across each key's face that the plug's lip rides over going on - a 30-degree lead-in
// above - and clicks under, its 45-degree underside pressing on the lip's top edge. It starts inside the key and is
// 0.2 mm narrower each side, so none of its faces lies in one of the key's.
module fan_mate_clip(x, cl = fan_mate_clip) let(e = 0.3, w = fm_key_w - 0.4, cy = fm_clip_y(cl), cz = fm_clip_z(cl), r = cy - fm_key_y + e)
    translate([x - w / 2, 0, 0]) rotate([90, 0, 90]) linear_extrude(w)
        polygon([[fm_key_y - e, cz - r], [cy, cz], [fm_key_y - e, cz + r * sqrt(3)]]);
// The air round each plug's front wall, in plan: over the block, the plug's pocket, the slits at the front wall's
// ends and everything in front of it; in the block, the slits round it, behind, at its ends and in front.
module fan_mate_air_2d() let(f = fan_mate_spring[0], g = fan_mate_slit[0]) {
    for (x = fm_xs) {
        translate([x - fm_px, fm_wall_y]) square([2 * fm_px, fm_fy - fm_wall_y]);
        for (s = [-1, 1]) translate([s > 0 ? x + fm_px - g : x - fm_px, fm_fy - 0.01]) square([g, f + 0.02]);
    }
    translate([fm_x0 - 1, fm_fy + f]) square([fm_x1 - fm_x0 + 2, fm_y1 - fm_fy - f + 1]);
}
module fan_mate_slits_2d() let(f = fan_mate_spring[0], g = fan_mate_slit[0]) for (x = fm_xs) difference() {
    translate([x - fm_px, fm_fy - g]) square([2 * fm_px, f + 2 * g]);
    translate([x - fm_px + g, fm_fy]) square([2 * (fm_px - g), f]);
}
// The block and its walls - the back one, one at each end, one between the plugs and one in front of each plug's text
// face (Alon, 9 Oct 2026) - are one prism of the whole outline with what is air cut out of it: boxes sharing faces
// would meet in lines of T-junctions. Each front wall is a spring: slits round it, down into the block to
// fan_mate_slit[1] over its underside, free it from the block and the walls beside it, so it gives when the plug's lip
// rides over the clip. The groove is a little wider than the slot, so its sides are not tangent to the slot's round
// ends.
module fan_mate(with_clip = true, cl = fan_mate_clip) let(h = fan_mate_base[0], c = fan_mate_base[1], wh = fan_mate_wall[1], s = 2 * fan_pitch + fm_ins_d + 0.4)
    difference() {
        union() {
            difference() {
                translate([fm_x0, fm_y0, 0]) cube([fm_x1 - fm_x0, fm_y1 - fm_y0, h + wh]);
                translate([0, 0, h]) linear_extrude(wh + 1) fan_mate_air_2d();
                translate([0, 0, fan_mate_slit[1]]) linear_extrude(h - fan_mate_slit[1] + 1) fan_mate_slits_2d();
            }
            for (x = fm_xs) fan_mate_key(x);
            if (with_clip) for (x = fm_xs) fan_mate_clip(x, cl);
        }
        for (x = fm_xs) {
            for (k = [-1 : 1]) translate([x + k * fan_pitch, 0, h - c - 0.01]) cylinder(d = fm_core_d, h = c + 1, $fn = 16);
            translate([x, 0, -1]) linear_extrude(h - c + 1)
                hull() for (k = [-1, 1]) translate([k * fan_pitch, 0]) circle(d = fm_ins_d, $fn = 24);
            translate([x - s / 2, fm_y0 - 1, -1]) cube([s, 1 - fm_y0, fm_ins_d + 1]);
            // the red pin's mark, on the block in front of the front wall: the plug's moulded pin-1 arrow lands over it
            translate([x - fan_pitch, fm_y1 - fan_mate_front / 2, h - 0.4]) linear_extrude(1)
                text("+", size = 1.8, halign = "center", valign = "center");
        }
    }
// The fan's plug as measured, to check the mate against and to draw, never printed: its body, the lip across its
// open end between the ribs, the two ribs on the face opposite the text, and a hole over each pin at the plug's own
// pitch. Seated on the block, at plug x.
module fan_plug_model(x) let(a = fan_plug[0], b = fan_plug[1], c = fan_plug[2], rw = fan_plug_ribs[0], rg = fan_plug_ribs[1],
                             o = fan_plug_hole, l = fan_plug_lip, bk = fmp_back - fan_plug_lip[0])
    translate([x, 0, fan_mate_base[0]]) difference() {
        union() {
            translate([-a / 2, -bk, 0]) cube([a, b - l[0], c]);
            translate([-rg / 2 - 0.01, -fmp_back, 0]) cube([rg + 0.02, l[0] + 0.01, fmp_plug_lip_l]);
            for (s = [-1, 1]) translate([s * (rg + rw) / 2 - rw / 2, -fmp_ribs, 0]) cube([rw, fmp_ribs - bk + 0.01, c]);
        }
        for (k = [-1 : 1]) translate([k * fan_plug_pitch - o / 2, -o / 2, -1]) cube([o, o, fan_mate_pin + 1]);
    }
// The wires' bared cores, standing as the pins: from where the insulation stops to the pins' tips.
module fan_mate_pins() for (x = fm_xs, k = [-1 : 1])
    translate([x + k * fan_pitch, 0, fan_mate_base[0] - fan_mate_base[1]]) cylinder(d = fan_wire[0], h = fm_strip, $fn = 16);
module say_fan_mate() echo(str("fan plug mate: ", fan_mate_n, fan_mate_n == 1 ? " plug" : " plugs", "; bare each wire ",
    fm_strip, " mm, push it up from below until its insulation stops, and bend it over into the groove underneath"));

// ------------------------------------------------------------------ the sample plates (T131)
// All the samples, as they print: ASA - the joint sample, the glue frame's or the clamp's sample, the bottom sample and the grommet's
// coupon; TPU - the joint sample's bead and the grommet. Placed by their footprints, measured from
// their renders; scad-check counts the bodies, so two that touched would show.
module samples_asa() {
    joint_sample();                                     // Y -24 .. 39.5
    translate([0, 20, 0]) if (glue) glue_sample(); else clamp_sample();   // Y 54 .. 70
    bottom_sample();                                    // Y -56.4 .. -38.4
    translate([75, 0, 0]) grommet_coupon();
}
// The second ASA plate (10 Oct 2026): the samples not yet tried - the glue sample (T185) and the nut coupon (T189).
// The rest were tried on 9 Oct (T131), and the grommet's coupon from that plate is still as drawn.
module samples_asa_2() {
    nut_coupon();                                       // X -7 .. 65, Y 0 .. 30
    translate([29, 2, 0]) glue_sample();                // X 8.75 .. 49.25, Y 36.25 .. 52.25
}
module samples_tpu() {
    joint_sample_bead();                                // Y 0 .. 27.2
    translate([0, -10, 0]) grommet_body();              // Y -14.4 .. -5.6
}
module say_sample_hardware() let(n = _count(len(top_screws) / 2)) echo(str("joint sample: ", n, " M3 x ", j3_screw,
    " socket head and ", n, len(top_screws) == 2 ? " M3 nut" : " M3 nuts", " for the joint, one M3 nut and an M3 x 8 for the pocket's seat"));

// How to cut the paper for the clamp, from the values above: what the build page quotes. Only the length is
// measured; across the folds the piece is counted, since the clamp sets its width.
module say_paper_cut() if (glue) echo(str("paper: cut a piece ", round(pack_l * 10) / 10, " mm long along the folds and ", pack_n,
    " pleats across, both long edges on a top fold (about ", round(pack_n * paper_pitch * 10) / 10, " mm as folded; the frame takes ",
    round(2 * pack_edge * 10) / 10, " mm, ", round(pack_pitch * 100) / 100, " mm a pleat). Glue it in from the top: fill the end of",
    " every channel open at the top, at both ends, and run a bead across each end and along each long side's top fold"));
else echo(str("paper: cut a piece ", round(pack_l * 10) / 10, " mm long along the folds and ", pack_n,
    flaps ? " pleats across and a half pleat more each side, both long edges on a bottom fold"
                : " pleats across, both long edges on a top fold",
    " (about ", round((pack_n + pack_halves) * paper_pitch * 10) / 10, " mm as folded; the clamp spreads it to ",
    round(2 * pack_edge * 10) / 10, " mm, ", round(pack_pitch * 100) / 100, " mm a pleat). The clamp's slot is ",
    clamp_slot, " mm; its four screws M2 x ", clamp_screw, " socket head, into M2 nuts pulled into the lower frame"));

if (draw_model) {
    if (part == "section") section();
    // The clamp's two frames as they print: the lower standing, the upper on its band; and its sample.
    else if (part == "glue_frame") { assert(glue, "the glue frame's part: hepa_frame = \"glue\""); glue_frame(); say_paper_cut(); }
    else if (part == "glue_sample") { assert(glue, "the glue frame's part: hepa_frame = \"glue\""); glue_sample(); say_paper_cut(); }
    else if (part == "clamp_lower") { assert(!glue, "the clamp's parts: hepa_frame = \"clamp\""); clamp_low(); say_paper_cut(); }
    else if (part == "clamp_upper") { assert(!glue, "the clamp's parts: hepa_frame = \"clamp\""); translate([0, 0, cas_h]) mirror([0, 0, 1]) clamp_up(); say_paper_cut(); }
    else if (part == "clamp_sample") { assert(!glue, "the clamp's parts: hepa_frame = \"clamp\""); clamp_sample(); say_paper_cut(); }
    // The Auto's parts as they print, standing: the base on its floor, the tray on its own.
    else if (part == "auto_base") { translate([0, 0, -auto_bay_top]) auto_base(); say_auto_hardware(); }
    else if (part == "auto_tray") { translate([0, 0, -auto_base_z0]) auto_tray(); say_auto_hardware(); say_usb(); }
    else if (part == "auto_fans") translate([0, 0, -duct_h]) if (sealed) fans_sealed(); else auto_fans();
    // The sealed stack's remixed originals and the bead ring, as they print: standing, the ring flat.
    else if (part == "carbon") { translate([0, 0, -sst[2]]) carbon_sealed(); say_seal_hardware(); }
    else if (part == "hepa") { translate([0, 0, -sst[3]]) hepa_sealed(); say_seal_hardware(); }
    else if (part == "cover") translate([0, 0, cover_top]) mirror([0, 0, 1]) cover_drawn(0);
    else if (part == "cmag_tray") cmag_tray_drawn();
    else if (part == "cmag_lid") translate([0, 0, cmag[2]]) mirror([0, 0, 1]) cmag_lid_drawn();
    else if (part == "cmag_grills") { for (i = [0 : 3]) translate([0, i * (cmag_grill[1] + 5), 0]) linear_extrude(cmag_grill_t, convexity = 10) cmag_grill2d(); say_cmag(); }
    else if (part == "bead_ring") bead_ring();
    // The joint sample's ASA plate, and its TPU bead.
    else if (part == "joint_sample") { joint_sample(); say_sample_hardware(); }
    else if (part == "joint_sample_bead") joint_sample_bead();
    // The wires' grommet, in TPU, on its foot; the bottom sample; and every sample on its plate.
    else if (part == "grommet") grommet_body();
    // The fans' plug mate, in ASA, on its underside.
    else if (part == "fan_mate") { fan_mate(); say_fan_mate(); }
    else if (part == "bottom_sample") { bottom_sample(); say_auto_hardware(); say_usb(); }
    else if (part == "nut_coupon") { nut_coupon(); say_nut_coupon(); }
    else if (part == "samples_asa") { samples_asa(); say_sample_hardware(); say_auto_hardware(); }
    else if (part == "samples_asa_2") { assert(glue, "the glue sample's plate: hepa_frame = \"glue\""); samples_asa_2(); say_nut_coupon(); say_paper_cut(); }
    else if (part == "samples_tpu") samples_tpu();
    else assert(false, str("unknown part: ", part));
}
