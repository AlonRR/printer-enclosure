// SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
// SPDX-License-Identifier: CC-BY-NC-SA-4.0
// A remix of BentoBox v2.0 by ThrutheFrame (https://www.printables.com/model/272525), CC BY-NC-SA 4.0.

// The BentoBox remix: the section, and the originals placed in the box's frame. Settings in
// bentobox.params.scad; bentobox-section.scad pins the part in its printing pose.
include <bentobox.layout.scad>

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
module section() {
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
    else assert(false, str("unknown part: ", part));
}
