// SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
// SPDX-License-Identifier: CC-BY-NC-SA-4.0
// A remix of BentoBox v2.0 by ThrutheFrame (https://www.printables.com/model/272525), CC BY-NC-SA 4.0.

// lib/helpers.scad - THE MODULES AND FUNCTIONS MORE THAN ONE PART USES: the outlines, the originals' joint, the nuts' frames and pockets, half-spaces, a profile run along X. They set no values and draw nothing alone. Included by bentobox.scad; not a model on its own.

// ------------------------------------------------------------------ outlines
// A rounded rectangle centred on the origin (shapes.scad's rrect starts at its corner).
module rrect_c(w, l, r) {
    offset(r = r) square([w - 2 * r, l - 2 * r], center = true);
}
// The inside's outline grown by d: a tongue or groove face d outside it, or inside for d < 0.
module inside_offset(d) rrect_c(in_w + 2 * d, in_l + 2 * d, max(in_r + d, 0.01));

module outline_solid(h) {
    // The outside, with its 0.4 mm chamfers at the bottom and top edges.
    hull() {
        translate([0, 0, 0]) linear_extrude(eps) rrect_c(bb_w - 2 * bb_chamfer, bb_l - 2 * bb_chamfer, bb_r - bb_chamfer);
        translate([0, 0, bb_chamfer]) linear_extrude(h - 2 * bb_chamfer) rrect_c(bb_w, bb_l, bb_r);
        translate([0, 0, h - eps]) linear_extrude(eps) rrect_c(bb_w - 2 * bb_chamfer, bb_l - 2 * bb_chamfer, bb_r - bb_chamfer);
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
// The magnets' holes at a joint's face z, up into the part over it or down into the part under it: the originals', or
// with xy and d given, the cover's joint's.
module magnet_holes(z, up, xy = mag_xy, d = mag_d, h = mag_h) {
    for (sx = [-1, 1], sy = [-1, 1])
        translate([sx * xy[0], sy * xy[1], up ? z : z - h]) cylinder(d = d, h = h + eps);
}

// A slot's own frame: X out towards its mouth, the screw's axis at the origin, Z = 0 at z.
module slot_frame(s, z) translate([s[0], s[1], z]) rotate(s[2]) children();

// A fan nut's pocket's own frame: the screw's axis on Z, a corner along X, and a flat facing s[2].
module pull_frame(s, z) translate([s[0], s[1], z]) rotate(s[2] - 30) children();
// A pull nut's way: its pocket (scad-tools nuts.scad), up from its mouth to the seat, the seat a nut's height under
// the roof, and the screw's hole on up through the roof, roof long, bridged (scad-tools fdm.scad): a channel the
// hole's width from corner to corner, then the hole's square, then the round hole. A fan screw's roof by default.
module pull_pocket(way, f = pull_fit, roof = nut_roof + 1) {
    pull_nut_pocket(nut_af, nut_slot_h, way, fdm_hole_comp + f, fdm_hole_comp + pull_way_fit, eps);
    bridged_hole((nut_af + 2 * (fdm_hole_comp + f)) / cos(30), hole_d, roof, fdm_layer_h, eps);
}

// Everything below z, or above it, with its face exactly at z.
module below(z) translate([-100, -100, z]) mirror([0, 0, 1]) cube([200, 200, 400]);
module above(z) translate([-100, -100, z]) cube([200, 200, 400]);

// A profile drawn across the box (Y, Z), extruded along it from x0 to x1.
module along_x(x0, x1) translate([x0, 0, 0]) rotate([90, 0, 90]) linear_extrude(x1 - x0, convexity = 10) children();
