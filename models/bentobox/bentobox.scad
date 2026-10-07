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

if (draw_model) {
    if (part == "section") section();
    else assert(false, str("unknown part: ", part));
}
