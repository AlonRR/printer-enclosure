// SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
// SPDX-License-Identifier: CC-BY-NC-SA-4.0
// A remix of BentoBox v2.0 by ThrutheFrame (https://www.printables.com/model/272525), CC BY-NC-SA 4.0.

// The BentoBox remix: the section, and the originals placed in the box's frame. Settings in
// bentobox.params.scad; bentobox-section.scad pins the part in its printing pose.
include <bentobox.layout.scad>
use <../../scad-tools/lib/fdm.scad>
use <../../scad-tools/lib/nuts.scad>
use <../../scad-tools/lib/gasket.scad>

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

// A fan screw's post: round its nut's pocket, on a 45-degree cone; cut back clear of the fans' air. Its top stays
// `meet` under the base's.
module fan_post(s) difference() {
    translate([s[0], s[1], 0]) hull() {
        translate([0, 0, post_bot]) cylinder(r = post_r, h = duct_h - meet - post_bot);
        translate([0, 0, post_bot - post_r]) cylinder(r = 0.01, h = 0.01);
    }
    if (post_clear_air) fan_air(duct_h, meet);
}
// A fan nut's pocket's own frame: the screw's axis on Z, a corner along X, and a flat facing s[2], the nearer fan.
module pull_frame(s, z) translate([s[0], s[1], z]) rotate(s[2] - 30) children();
// An insert's hole, filled: the screw's hole and the slot are cut through the fill.
module fan_plug(s) translate([s[0], s[1], duct_h - auto_fan_insert[1] - 0.1])
    cylinder(d = auto_fan_insert[0] + 0.2, h = auto_fan_insert[1] + 0.1 - meet);
module plate_plug(p) translate([p[0], p[1], auto_seat_z + meet])
    cylinder(d = auto_plate_insert[0] + 0.2, h = auto_plate_insert[1] + 0.1 - meet);
// A fan screw's way: its nut's pocket, up from under the post's cone to the roof, and its hole on up through the
// roof to the base's top, bridged (scad-tools fdm.scad): a channel the hole's width from corner to corner, then the
// hole's square, then the round hole.
module fan_screw_cut(s) pull_frame(s, 0) {
    translate([0, 0, pull_bot]) cylinder(r = pull_ac / 2, h = pull_top - pull_bot, $fn = 6);
    translate([0, 0, pull_top]) bridged_hole(pull_ac, hole_d, duct_h - pull_top + 1, fdm_layer_h, eps);
}
// A plate screw's: the pocket its lobe rises into, its hole bridged up through the pocket's roof to its slot, the
// roof over that, and on past its tip.
module plate_screw_cut(s) {
    translate([s[0], s[1], auto_base_z0 - 1]) cylinder(d = pocket_d, h = pocket_top - auto_base_z0 + 1);
    translate([s[0], s[1], pocket_top]) bridged_hole(pocket_d, hole_d, plate_slot_bot - pocket_top + eps, fdm_layer_h, eps);
    slot_frame(s, plate_slot_bot) { slot(); roof_hole(plate_tip_z + 0.5 - plate_slot_top); }
}
module auto_base() difference() {
    union() {
        orig(auto_base_stl);
        for (s = auto_fan_screws) { fan_post(s); fan_plug(s); }
        for (p = auto_plate_inserts) plate_plug(p);
    }
    for (s = auto_fan_screws) fan_screw_cut(s);
    for (s = auto_plate_screws) plate_screw_cut(s);
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
// See bentobox.params.scad. A lower part's top: its tongue cut away `meet` under its face (the STL's float32 face
// is not where the same number computed here is), its magnets' holes filled, a collar round its edge, the bead's
// groove, and four tabs with a nut in each, on cubic brackets. An upper part's bottom: its groove and its magnets'
// holes filled, its edge cut back at 45 degrees to sit in the collar, and four tabs under the screws' heads.
module outline_in(d) offset(delta = -d) rrect(bb_w, bb_l, bb_r);
// One tab's outline from above, at the +X, +Y corner: from the end wall along the parabola, round the screw's
// boss, down the side face's line into the body.
function _tab_pts() = concat(
    [for (i = [0 : 24]) let(x = tab_x0 + (tab_p[0] - tab_x0) * i / 24) [x, tab_ye - tab_dip + tab_c * pow(x - tab_x0, 2)]],
    [for (a = [tab_a0 - 5 : -5 : 0]) tab_sc + tab_boss_r * [cos(a), sin(a)]],
    [[tab_sc[0] + tab_boss_r, tab_ye - bb_r - 1], [tab_x0, tab_ye - bb_r - 1]]);
module tabs2d() for (mx = [0, 1], my = [0, 1]) mirror([mx, 0, 0]) mirror([0, my, 0]) polygon(_tab_pts());
// Under a nut's tab, its bottom at zt: a bracket whose face is a cubic in its height, from bracket_in inside the end
// wall at its foot, crossing the wall's face at a slant, to the tab's tip at 45 degrees. Not below the part's bottom, z0.
module brackets(zt, z0) {
    foot = zt - bracket_h;
    zs = max(foot, z0 + 0.2);
    n = 24;
    face = [for (i = [0 : n]) let(z = zs + (zt - zs) * i / n)
        [tab_ye - bracket_in + (tab_l + bracket_in) * pow((z - foot) / bracket_h, 3), z]];
    // It reaches 1 mm up into the tab, which has the same outline, so no face of it lies a hair from the tab's.
    intersection() {
        translate([0, 0, zs]) linear_extrude(zt - zs + 1) tabs2d();
        for (my = [0, 1]) mirror([0, my, 0]) rotate([90, 0, 90]) translate([0, 0, -bb_w])
            linear_extrude(2 * bb_w) polygon(concat([[tab_ye - 1, zs], [tab_ye - 1, zt + 1], [tab_ye + tab_l + 1, zt + 1]],
                [for (i = [n : -1 : 0]) face[i]]));
    }
}
// The collar on a lower part's top, its face at z: its outside meet in from the outline, its inside at 45 degrees,
// none where the tabs are. Its rounded corners have their own number of facets: with the part's 64, its slant met
// the section's wall at the wall's own corners, and left degenerate slivers there.
module collar(z, $fn = 97) difference() {
    translate([0, 0, z - 0.5]) linear_extrude(collar_h + 0.5) outline_in(meet);
    hull() {
        translate([0, 0, z - 0.5 - eps]) linear_extrude(eps) outline_in(collar_base + 0.5);
        translate([0, 0, z + collar_h]) linear_extrude(eps) outline_in(collar_top);
    }
    translate([0, 0, z - 1]) linear_extrude(collar_h + 2) offset(delta = collar_play) tabs2d();
}
// What an upper part's bottom edge loses, its face at z: everything outside a 45-degree face from chamfer_in in at
// the face to the outline itself; it stops just past the outline, so it meets none of the part's faces.
module chamfer_cut(z, $fn = 97) difference() {
    translate([0, 0, z - 1]) linear_extrude(chamfer_in + 1 + meet) offset(delta = 5) outline_in(0);
    hull() {
        translate([0, 0, z - 1 - eps]) linear_extrude(eps) outline_in(chamfer_in + 1);
        translate([0, 0, z + chamfer_in + meet]) linear_extrude(eps) outline_in(-meet);
    }
}
module seal_groove_cut(z) translate([0, 0, z - seal_groove[1]]) linear_extrude(seal_groove[1] + 1)
    gasket_groove_2d(seal_ring[0], seal_ring[1], seal_groove[0]);
module bead_ring() gasket_ring(seal_ring[0], seal_ring[1], seal_bead);
module magnet_fill(z0, z1) for (sx = [-1, 1], sy = [-1, 1]) translate([sx * mag_xy[0], sy * mag_xy[1], z0]) cylinder(d = mag_d + 0.2, h = z1 - z0);
// A lower part's top. zf: its imported face; z0: its bottom. The new face is zf - meet.
module lower_face(zf, z0) let(z = zf - meet) difference() {
    union() {
        difference() {
            union() {
                children();
                magnet_fill(zf - mag_h - 0.1, zf + 1);
                translate([0, 0, z - tab_lower_t]) linear_extrude(tab_lower_t + 1) tabs2d();
                brackets(z - tab_lower_t + eps, z0);
            }
            translate([0, 0, z]) linear_extrude(10) offset(delta = 20) outline_in(0);
        }
        collar(z);
    }
    seal_groove_cut(z);
    for (s = tab_screws) {
        slot_frame(s, z + seal_slot_bot) { slot(); roof_hole(-(seal_slot_bot + nut_slot_h) + 1); }
        translate([s[0], s[1], z - 9]) cylinder(d = hole_d, h = 9 + seal_slot_bot + eps);
    }
}
// An upper part's bottom, its face at z.
module upper_face(z) difference() {
    union() {
        difference() {
            union() {
                children();
                translate([0, 0, z + meet]) linear_extrude(groove_h + 0.1)
                    difference() { inside_offset(groove_out + 0.1); inside_offset(-0.2); }
                magnet_fill(z + meet, z + mag_h + 0.1);
            }
            chamfer_cut(z);
        }
        translate([0, 0, z + meet]) linear_extrude(tab_upper_t - meet) tabs2d();
    }
    for (s = tab_screws) translate([s[0], s[1], z - 1]) cylinder(d = hole_d, h = tab_upper_t + 2);
}
// The section, sealed: flat underneath, chamfered to sit in the fan section's collar; a collar and the bead's
// groove on top; a pillar at each corner, which the screw from the carbon housing passes through; no magnets. Its
// outside is one hull with the chamfer in it: cut afterwards, the slant met the wall at the corner's first facet.
module section_sealed() difference() {
    union() {
        difference() {
            union() {
                difference() {
                    hull() {
                        linear_extrude(eps) outline_in(chamfer_in);
                        translate([0, 0, chamfer_in]) linear_extrude(sec_h - chamfer_in - bb_chamfer) outline_in(0);
                        translate([0, 0, sec_h - eps]) linear_extrude(eps) outline_in(bb_chamfer);
                    }
                    translate([0, 0, -1]) linear_extrude(sec_h + 2) inside_offset(0);
                }
                grid();
            }
        }
        linear_extrude(sec_h) tabs2d();
        collar(sec_h);
    }
    seal_groove_cut(sec_h);
    for (s = tab_screws) translate([s[0], s[1], -1]) cylinder(d = hole_d, h = sec_h + 2);
}
// The sealed stack's parts in place: the fan section, the carbon housing, the HEPA holder.
sst = stack(true, true);
carbon_dz = sst[2] - (duct_h + fans_h);
hepa_dz = sst[3] - (duct_h + fans_h + carbon_h);
module fans_sealed() lower_face(duct_h + fans_h, duct_h) fan_section();
module carbon_sealed() lower_face(duct_h + fans_h + carbon_h + carbon_dz, sst[2]) upper_face(sst[2]) orig(carbon_stl, carbon_dz);
module hepa_sealed() upper_face(sst[3]) orig(hepa_stl, hepa_dz);
module say_seal_hardware() echo(str("sealed joints: three TPU bead rings, ", seal_bead[0], " mm; four M3 x ", j3_screw,
    " socket head into nuts, HEPA holder to carbon housing; four M3 x ", j12_screw,
    " through the carbon housing's tabs and the section's pillars into the fan section's nuts; eight M3 nuts"));

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
    else if (part == "auto_plate") { translate([0, 0, -auto_base_z0]) auto_plate(); say_auto_hardware(); }
    else assert(false, str("unknown part: ", part));
}
