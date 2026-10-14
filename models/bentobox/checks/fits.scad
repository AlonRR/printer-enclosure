// SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
// SPDX-License-Identifier: CC-BY-NC-SA-4.0
// A remix of BentoBox v2.0 by ThrutheFrame (https://www.printables.com/model/272525), CC BY-NC-SA 4.0.

// checks/fits.scad - WHAT THE FIT CHECKS READ (scripts/checks/bentobox-checks.py): the screws, nuts, beads, probes and drivers set in the parts, and the checks' own numbers. Their views are the entry's draw menu. Included by bentobox.scad; not a model on its own.

module seal_screws() translate([screw_shift[0], screw_shift[1], 0]) for (s = seal_screw_list)
    translate([s[0], s[1], s[3] + tab_upper_t]) {
        translate([0, 0, -s[4]]) cylinder(d = screw_d, h = s[4]);
        cylinder(d = m3_head[0], h = m3_head[1]);
    }
// Each joint's nut, pulled up into its seat in the lower part's tab; with way, drawn on down its pocket, through the
// tab and way down past it - a bracket's height takes it out of the bracket.
module seal_nuts(way = 0) for (n = concat([for (s = tab_screws) [s, sst[1]]], [for (s = top_screws) [s, sst[3]]]))
    let(s = n[0], z = n[1] + seal_slot_bot + nut_slot_h - sep - nut_h)
        hull() for (zz = way == 0 ? [z] : [z, n[1] - tab_lower_t - way]) pull_frame(s, zz) hex_nut(nut_af, nut_h);
// The hex screwdriver on a screw's head, from its tab's top - the head is sunk in it: its blade, then its handle.
module hex_driver(s) translate([s[0], s[1], s[3] + tab_upper_h]) {
    cylinder(d = driver[0], h = driver[1]);
    translate([0, 0, driver[1]]) cylinder(d = driver[2], h = 100);
}

// Parts that meet face to face are checked sep apart along the joint, so that touching leaves nothing at all
// and anything left is a real overlap. Touching faces would leave a slab of no thickness, which the
// Manifold backend's floats turn into a few hundredths of a mm3 - enough to hide a small collision in.
sep = 0.01;

// A magnet in each of the tray's holes, standing into the lid's across the joint, in the C-MAG's frame.
module cmag_magnets_across() cmag_corners() translate([cmag_boss[0], cmag_boss[1], cmag_split - mag_h + 0.1]) cylinder(d = 4, h = 2 * mag_h - 0.2);
// A magnet in each of the section's holes, standing into the original's hole across the joint: if the two
// holes line up, it touches neither part. Built from the section's own holes - the original's stay put.
// With xy, d and h given, the cover's joint's magnets.
module magnets_across(z, xy = mag_xy, d = 4, h = mag_h) for (sx = [-1, 1], sy = [-1, 1])
    translate([sx * xy[0], sy * xy[1], z - h + 0.1]) cylinder(d = d, h = 2 * h - 0.2);
// The air's way through the section, from numbers kept apart from the ones that draw it: where the carbon housing's
// floor lets the air down, carried down through the plenum and the sheet's space to the grid. Nothing of the section
// may stand in it. With the C-MAG, the original's two floor openings; with the bed, the floor's honeycomb, which
// spans the whole inside but for bed_mesh[2] round its edge.
module air_probe() if (carbon == "bed") translate([-floor_mesh[0], -floor_mesh[1], grid_t + eps])
        cube([2 * floor_mesh[0], 2 * floor_mesh[1], sec_h - grid_t - 2 * eps]);
    else for (sy = [-1, 1])
        translate([-floor_open[0], sy > 0 ? floor_open[1] : -floor_open[2], grid_t + eps])
            cube([2 * floor_open[0], floor_open[2] - floor_open[1], sec_h - grid_t - 2 * eps]);
floor_open = [18, 2, 48];   /* MEASURED: the carbon housing's floor openings, X +/-18, Y 2 to 48 each side: kept apart from carbon_open, which draws them, so the check reads the original's measurement */
floor_mesh = [18.4, 48.4];  /* The bed's floor honeycomb's reach, X and Y +/-: in_w / 2 and in_l / 2 less bed_mesh[2], written out so a control that narrows the inside cannot move it */
// The Auto's bottom: the tray's nuts in their slots, centred in height, and the fans' pulled up against their
// pockets' roofs, sep under them; each nut's way in - slid out through its slot's mouth, or down its pocket and
// out under its post; the screws, head to tip; the wires' way down. Built from the screws' places, not the slots':
// a control moves them (screw_shift, wire_shift) and leaves the holes where they are.
nut_way = 10;           /* How far each nut is slid out of its slot or pocket, to show the way in is open. */

wire_d = 4.5;           /* The wires that must pass the floor's hole and the tube: the two fans' six leads, about 4 mm
                           bundled. A 5 mm rod would graze the tube's exit, which turns 1.2 mm towards -X into the bay. */
module nut_at(s, z) slot_frame(s, z + (nut_slot_h - nut_h) / 2) hex_nut(nut_af, nut_h);
module auto_nuts(way = 0) {
    // A fan nut, pulled up into its seat; its way in: down its pocket to the mouth, and out under the post into the room.
    for (s = auto_fan_screws) if (way == 0) pull_frame(s, pull_top - sep - nut_h) hex_nut(nut_af, nut_h);
        else {
            hull() for (z = [pull_top - sep - nut_h, pull_bot + sep]) pull_frame(s, z) hex_nut(nut_af, nut_h);
            hull() for (x = [0, way]) translate([x * cos(s[3]), x * sin(s[3]), 0]) pull_frame(s, pull_bot + sep) hex_nut(nut_af, nut_h);
        }
    // A tray nut on its screw's axis; its way in: along its slot and out through the end face.
    for (s = tray_screws) hull() for (x = [0, way == 0 ? 0 : s[3] + 1]) translate([x * cos(s[2]), x * sin(s[2]), 0]) nut_at(s, tray_slot_bot);
}
module auto_screws() translate([screw_shift[0], screw_shift[1], 0]) {
    for (s = auto_fan_screws) translate([s[0], s[1], fan_tip_z]) cylinder(d = screw_d, h = fan_screw);
    for (s = tray_screws) translate([s[0], s[1], tray_head_z]) {
        cylinder(d = screw_d, h = tray_screw);
        translate([0, 0, -m3_head[1]]) cylinder(d = m3_head[0], h = m3_head[1]);
    }
}
// Round each tray screw's slot, two beads every way, and round its hole on to past the screw's tip: all inside the
// original's end wall, nothing of it open to the duct. Grown by spheres, so a corner keeps two beads, not more.
module tray_slot_walls() let(g = 2 * bead, f = fdm_hole_comp + nut_fit, ac = nut_af / cos(30)) for (s = tray_screws)
    slot_frame(s, tray_slot_bot) {
        hull() for (x = [-(ac / 2 + f), s[3]], y = [-1, 1] * (nut_af / 2 + f), z = [0, nut_slot_h]) translate([x, y, z]) sphere(r = g, $fn = 12);
        hull() for (z = [0, tray_room_z - tray_slot_bot]) translate([0, 0, z]) sphere(r = hole_d / 2 + g, $fn = 16);
    }
// The base's air: the duct and the SPS30's pocket, inside the outline - a millimetre in, clear of the slots' mouths in
// the end faces.
module base_air() intersection() {
    union() { duct_air(); sps30_cut(); }
    translate([0, 0, auto_bay_top]) linear_extrude(duct_h - auto_bay_top) offset(delta = -1) tray_outline();
}

module wire_probe() translate([auto_conduit[0] + wire_shift, auto_conduit[1], auto_conduit_z[0] - 2])
    cylinder(d = wire_d, h = auto_conduit_z[1] - auto_conduit_z[0] + 3);

// The outlet's SPS30 (D252). Its plug's room, from the sensor's own values, in front of its connector face; the open
// air its openings want, in front of them along the air face, from the checks' own number; its lead, a bundle from
// over the floor down its slot into the bay; and its way in, slid in from out past the outlet's face.
sps30_air_need = 10;    /* Open air in front of the SPS30's openings: kept apart from sps30_air_room, which cuts it, so a control can cut less. */
sps30_lead_d = 3;       /* The SPS30's five leads, side by side: its slot must pass a rod this thick along it. */
module sps30_plug_probe() translate(sps30_shift + [sps30_plug_x[0], sps30_yy[1] + sep, base_floor + sep])
    cube([sps30_plug[1] - sps30_plug[0], sps30_lead_room, sps30[2]]);
module sps30_air_probe() translate(sps30_shift + [sps30_x[0] + sps30_open[1], sps30_yy[0] - sps30_air_need, base_floor + sep])
    cube([sps30[0] - sps30_open[0] - sps30_open[1], sps30_air_need - sep, sps30[2]]);
module sps30_lead_probe() hull() for (x = [sps30_lead[0], sps30_lead[1]])
    translate([x, sps30_lead_y, auto_seat_z + 1]) cylinder(d = sps30_lead_d, h = base_floor + 1 - auto_seat_z, $fn = 16);
module sps30_way() hull() for (x = [0, -50]) translate([x, 0, 0]) sps30_model();

// The air's way down under the paper, from the paper's own folds: between the combs, and between the second
// bottom folds from the edges, inside the long teeth's channels. The lower frame must leave it open; its rim
// and its end blocks stand round it, on the ledge.
module opening_probe() translate([fold_x(2) + sep, -(comb_y - clamp_wedge_l) + sep, -1])
    cube([fold_x(fold_last - 2) - fold_x(2) - 2 * sep, 2 * (comb_y - clamp_wedge_l - sep), pack_z]);
// The clamp's screws, head to tip, and its nuts pulled up into their seats - or slid down out of them.
module clamp_screws() translate([screw_shift[0], screw_shift[1], 0]) clamp_screws_at() {
    translate([0, 0, clamp_head_z - clamp_screw]) cylinder(d = small_screw[0], h = clamp_screw);
    translate([0, 0, clamp_head_z]) cylinder(d = small_screw[1], h = small_screw[2]);
}
module clamp_nuts(way = 0) clamp_screws_at() hull() for (z = [0, way])
    translate([0, 0, clamp_nut_top - sep - small_nut[1] - z]) hex_nut(small_nut[0], small_nut[1]);

// The ledge's opening, from the holder's own values, under the glue frame's rim: the rim must leave it open.
module glue_opening_probe() translate([-open_wl[0] / 2 + sep, -open_wl[1] / 2 + sep, -1]) cube([open_wl[0] - 2 * sep, open_wl[1] - 2 * sep, clamp_rim + 1 - sep]);
