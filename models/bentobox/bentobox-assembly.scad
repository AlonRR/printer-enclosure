// SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
// SPDX-License-Identifier: CC-BY-NC-SA-4.0
// A remix of BentoBox v2.0 by ThrutheFrame (https://www.printables.com/model/272525), CC BY-NC-SA 4.0.

/*
The BentoBox stack, put together from the original STLs and the remix's section - for pictures, and for the
fit checks that scripts/bentobox-checks.py renders. Needs the originals in original/.

  view = "stack"      the box as it stands, with the section
  view = "exploded"   the same, pulled apart along Z
  view = "cut"        the stack cut open at X = cut_x, seen from the side
  view = "section"    the section alone, as it prints - the one view that needs no original
  view = "frame"      the frame for your own HEPA paper, pulled apart: the ring, the paper, the two caps
  view = "cap"        one cap, as it prints
  view = "paper_cut"  flat, across the folds: the ring's middle with the paper, beside a cap's face with it
  view = "bottom"     the Auto's bottom pulled apart: the plate, the base with its nuts in their pockets and
                      slots, the fan section, and the screws
  view = "joints"     the sealed joints pulled apart: the fan section, the section, the carbon housing and the
                      HEPA holder, a bead ring over each lower part's groove, and the screws
  view = "check_..."  one fit check: a solid that must come out EMPTY. Each is an intersection of two
                      parts that should only touch; anything left is two parts in the same place.
*/
include <bentobox.scad>
use <../../scad-tools/lib/axes.scad>
draw_model = false;

view = "stack";
with_section = true;
explode = 30;           /* "exploded": the gap between parts */
cut_x = 0;              /* "cut": where to cut, along X */
show_axes = true;

// One part of the stack, in its colour - or, for "cut", its cut at X = cut_x, laid out with the box's
// length (Y) across and its height (Z) up. The cut's frame is a rotation, not a mirror: (y, z, x).
module piece(c) color(c) if (view == "cut")
    projection(cut = true) multmatrix([[0, 1, 0, 0], [0, 0, 1, 0], [1, 0, 0, -cut_x]]) children();
    else children();

module stack(ex) if (sealed) stack_sealed(ex); else stack_magnets(ex);
module stack_magnets(ex) {
    st = stack(with_section);
    dz = st[2] - st[1];
    if (bottom == "auto") {
        piece("dimgray") translate([0, 0, -ex]) auto_plate();
        piece("dimgray") auto_base();
    }
    else piece("dimgray") orig(duct_stl);
    piece("steelblue") translate([0, 0, ex]) fan_section();
    if (with_section) piece("seagreen") translate([0, 0, st[1] + 2 * ex]) section();
    piece("tan") translate([0, 0, 3 * ex]) orig(carbon_stl, dz);
    piece("sienna") translate([0, 0, 3 * ex]) cmag_standing(st[2] + cmag_z0);
    piece("lightsteelblue") translate([0, 0, 4 * ex]) orig(hepa_stl, dz);
    piece("darkslategray") translate([0, 0, 5 * ex]) orig(cover_stl, dz);
}

// The sealed stack: each sealed part in its place, a bead ring in each lower part's groove, the screws.
module stack_sealed(ex) {
    assert(with_section, "the sealed stack is built for the section: without it, the carbon housing's screws have no fan section's nuts to reach");
    if (bottom == "auto") {
        piece("dimgray") translate([0, 0, -ex]) auto_plate();
        piece("dimgray") auto_base();
    }
    else piece("dimgray") orig(duct_stl);
    piece("steelblue") translate([0, 0, ex]) fans_sealed();
    piece("seagreen") translate([0, 0, sst[1] + 2 * ex]) section();
    piece("tan") translate([0, 0, 3 * ex]) carbon_sealed();
    piece("sienna") translate([0, 0, 3 * ex]) cmag_standing(sst[2] - meet + cmag_z0);
    piece("lightsteelblue") translate([0, 0, 4 * ex]) hepa_sealed();
    piece("darkslategray") translate([0, 0, 4 * ex]) orig(cover_stl, hepa_dz);
}
// Where the sealed joints' parts are, and what goes in them. A lower part's face, sealed: J1 the fan section's
// top, J2 the section's, J3 the carbon housing's.
seal_faces = [sst[1], sst[2], sst[3]];
module seal_beads(lift = 0) for (z = seal_faces) translate([0, 0, z - seal_groove[1] + lift]) bead_ring();
module seal_screws() translate([screw_shift[0], screw_shift[1], 0]) for (s = tab_screws) {
    for (j = [[sst[3], j3_screw], [sst[2], j12_screw]]) translate([s[0], s[1], j[0] + tab_upper_t]) {
        translate([0, 0, -j[1]]) cylinder(d = screw_d, h = j[1]);
        cylinder(d = plate_head[0], h = plate_head[1]);
    }
}
module seal_nuts(way = 0) for (s = tab_screws, z = [sst[1], sst[3]])
    hull() for (x = [0, way]) translate([x * cos(s[2]), x * sin(s[2]), 0]) nut_at(s, z + seal_slot_bot);
// Over each screw's head, from its tab's top - the head is sunk in it - as far up as the screw is long and 10 mm
// more: the room to put it in and turn it.
module seal_access() for (s = tab_screws, j = [[sst[3], j3_screw], [sst[2], j12_screw]])
    translate([s[0], s[1], j[0] + tab_upper_h]) cylinder(d = plate_head[0] + 1, h = j[1] + 10);
module seal_parts() { fans_sealed(); translate([0, 0, sst[1]]) section(); carbon_sealed(); hepa_sealed(); }
module joints_exploded(ex) {
    color("steelblue") fans_sealed();
    color("seagreen") translate([0, 0, sst[1] + ex]) section();
    color("tan") translate([0, 0, 2 * ex]) carbon_sealed();
    color("lightsteelblue") translate([0, 0, 3 * ex]) hepa_sealed();
    color("orange") for (i = [0 : 2]) translate([0, 0, seal_faces[i] - seal_groove[1] + (i + 0.5) * ex]) bead_ring();
    color("silver") for (s = tab_screws) {
        translate([s[0], s[1], sst[3] + tab_upper_t + 3.5 * ex]) { translate([0, 0, -j3_screw]) cylinder(d = screw_d, h = j3_screw); cylinder(d = plate_head[0], h = plate_head[1]); }
        translate([s[0], s[1], sst[2] + tab_upper_t + 2.5 * ex]) { translate([0, 0, -j12_screw]) cylinder(d = screw_d, h = j12_screw); cylinder(d = plate_head[0], h = plate_head[1]); }
    }
}

// Parts that meet face to face are checked sep apart along the joint, so that touching leaves nothing at all
// and anything left is a real overlap. Touching faces would leave a slab of no thickness, which the
// Manifold backend's floats turn into a few hundredths of a mm3 - enough to hide a small collision in.
sep = 0.01;
st = stack(true);
// A magnet in each of the section's holes, standing into the original's hole across the joint: if the two
// holes line up, it touches neither part. Built from the section's own holes - the original's stay put.
module magnets_across(z) for (sx = [-1, 1], sy = [-1, 1])
    translate([sx * mag_xy[0], sy * mag_xy[1], z - mag_h + 0.1]) cylinder(d = 4, h = 2 * mag_h - 0.2);
// The air's way through the section, from the ORIGINAL's measurements only: the carbon housing's two floor
// openings, carried down through the plenum and the sheet's space to the grid. Nothing of the section may
// stand in it.
module air_probe() for (sy = [-1, 1])
    translate([-floor_open[0], sy > 0 ? floor_open[1] : -floor_open[2], grid_t + eps])
        cube([2 * floor_open[0], floor_open[2] - floor_open[1], sec_h - grid_t - 2 * eps]);
floor_open = [18, 2, 48];   /* MEASURED: the carbon housing's floor openings, X +/-18, Y 2 to 48 each side */
// The Auto's bottom: the plate's nuts in their slots, centred in height, and the fans' pulled up against their
// pockets' roofs, sep under them; each nut's way in - slid out through its slot's mouth, or down its pocket and
// out under its post; the screws, head to tip; the wires' way down. Built from the screws' places, not the slots':
// a control moves them (screw_shift, wire_shift) and leaves the holes where they are.
nut_way = 10;           /* How far each nut is slid out of its slot or pocket, to show the way in is open. */
screw_shift = [0, 0];   /* Controls only: the screws moved off their holes. */
wire_shift = 0;         /* Controls only: the wires' probe moved off the tube, along X. */
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
    for (s = auto_plate_screws) hull() for (x = [0, way]) translate([x * cos(s[2]), x * sin(s[2]), 0]) nut_at(s, plate_slot_bot);
}
module auto_screws() translate([screw_shift[0], screw_shift[1], 0]) {
    for (s = auto_fan_screws) translate([s[0], s[1], fan_tip_z]) cylinder(d = screw_d, h = fan_screw);
    for (s = auto_plate_screws) translate([s[0], s[1], plate_head_z]) {
        cylinder(d = screw_d, h = plate_screw);
        translate([0, 0, -plate_head[1]]) cylinder(d = plate_head[0], h = plate_head[1]);
    }
}
module wire_probe() translate([auto_conduit[0] + wire_shift, auto_conduit[1], auto_conduit_z[0] - 2])
    cylinder(d = wire_d, h = auto_conduit_z[1] - auto_conduit_z[0] + 3);
// The bottom pulled apart along Z, the nuts and screws drawn in their places.
module bottom_exploded(ex) {
    color("dimgray") translate([0, 0, -ex]) auto_plate();
    color("lightslategray") auto_base();
    color("gold") auto_nuts();
    color("silver") { auto_screws(); }
    color("steelblue", 0.85) translate([0, 0, ex]) if (sealed) fans_sealed(); else auto_fans();
}

// The HEPA holder's ledge, with the section in the stack: where the frame's ring stands.
ledge_z = st[3] + hepa_ledge;
// The ledge's opening, from the original's measurement, carried up through the ring's height: the air's way
// down, which the ring must leave open.
module opening_probe() translate([0, 0, -1]) linear_extrude(ring_h + 2) rrect(hepa_open[0], hepa_open[1], hepa_open_r);
// The frame pulled apart: the paper lifted out of the ring, the caps drawn back off its ends.
module frame_exploded(ex) {
    color("orange") hepa_ring();
    color("ivory") paper_pack(ring_h + ex);
    color("dimgray") for (a = [0, 180]) rotate([0, 0, a]) translate([0, ex, ring_h + ex]) caps_in_place_one();
}
module caps_in_place_one() translate([0, ring_in[1] / 2, 0]) rotate([90, 0, 0]) hepa_cap();
// Across the folds, flat: on the left the ring's middle - its long walls, the strips on their feet, the
// paper with a flap in each slot; on the right a cap's face, its wedges and teeth round the paper's end.
module paper_cut() {
    gap = ring_out[0] / 2 + 4;
    translate([-gap, 0]) {
        color("orange") {
            for (m = [0, 1]) mirror([m, 0]) translate([-ring_out[0] / 2, 0]) square([ring_wall, ring_h]);
            if (paper_flaps) strips_2d();
        }
        color("black") paper_2d();
    }
    translate([gap, 0]) {
        color("silver") wedges_2d();
        color("black") paper_2d();
    }
}

if (view == "stack") stack(0);
else if (view == "exploded") stack(explode);
else if (view == "cut") stack(0);
else if (view == "section") color("seagreen") section();
// The section seats in the carbon housing: its tongue in the housing's groove, its magnets under the housing's.
else if (view == "check_section_carbon") intersection() { section(); translate([0, 0, sec_h + sep - st[2]]) orig(carbon_stl, st[2] - st[1]); }
// The fan case seats in the section the way it seats in the housing.
else if (view == "check_section_fans") intersection() { translate([0, 0, st[1] + sep]) section(); fan_section(); }
// Each magnet's hole in the section lines up with its partner's in the original.
else if (view == "check_magnets_top") intersection() {
    union() { section(); translate([0, 0, sec_h + sep - st[2]]) orig(carbon_stl, st[2] - st[1]); }
    magnets_across(sec_h);
}
else if (view == "check_magnets_bottom") intersection() {
    union() { translate([0, 0, st[1] + sep]) section(); fan_section(); }
    translate([0, 0, st[1]]) magnets_across(0);
}
// The air from the housing's openings reaches the whole sheet.
else if (view == "check_air") intersection() { section(); air_probe(); }
// The Auto's bottom. The fan section stands on the base, and the plate is pulled up into its recess.
else if (view == "check_auto_fans_base") intersection() { translate([0, 0, sep]) auto_fans(); auto_base(); }
else if (view == "check_auto_plate") intersection() { translate([0, 0, -sep]) auto_plate(); auto_base(); }
// Each nut fits its slot, and slides in from outside.
else if (view == "check_auto_nuts") intersection() { auto_base(); auto_nuts(); }
else if (view == "check_auto_nut_ways") intersection() { auto_base(); auto_nuts(nut_way); }
// Each screw passes the fan section's floor, the base and the plate to its nut, and its tip has room.
else if (view == "check_auto_screws") intersection() { union() { auto_base(); auto_fans(); auto_plate(); } auto_screws(); }
// The wires pass the floor's hole and the tube to the bay.
else if (view == "check_auto_wires") intersection() { union() { auto_base(); auto_fans(); } wire_probe(); }
// Nothing of the base stands under the fans' openings in the floor, its new posts included.
else if (view == "check_auto_air") intersection() { auto_base(); fan_air(8); }
else if (view == "bottom") bottom_exploded(explode);
else if (view == "joints") joints_exploded(explode);
// The sealed joints: each upper part on its lower one - flat on the land, its chamfer in the collar, tab on tab.
else if (view == "check_seal_j1") intersection() { fans_sealed(); translate([0, 0, sst[1] + sep]) section(); }
else if (view == "check_seal_j2") intersection() { translate([0, 0, sst[1]]) section(); translate([0, 0, sep]) carbon_sealed(); }
else if (view == "check_seal_j3") intersection() { carbon_sealed(); translate([0, 0, sep]) hepa_sealed(); }
// Each bead lies in its groove, clear of its walls and floor: against its own lower part only, since it stands
// proud into the part above by design - the squeeze.
else if (view == "check_seal_beads") union() {
    intersection() { fans_sealed(); translate([0, 0, seal_faces[0] - seal_groove[1] + sep]) bead_ring(); }
    intersection() { translate([0, 0, sst[1]]) section(); translate([0, 0, seal_faces[1] - seal_groove[1] + sep]) bead_ring(); }
    intersection() { carbon_sealed(); translate([0, 0, seal_faces[2] - seal_groove[1] + sep]) bead_ring(); }
}
// The screws, head to tip, through the tabs, the section's pillars and the nuts' slots.
else if (view == "check_seal_screws") intersection() { seal_parts(); seal_screws(); }
// The nuts in their slots, and their way in from the tabs' ends.
else if (view == "check_seal_nuts") intersection() { seal_parts(); seal_nuts(); }
else if (view == "check_seal_nut_ways") intersection() { seal_parts(); seal_nuts(nut_way); }
// Room over each head to put the screw in and turn it: nothing of the stack above it.
else if (view == "check_seal_access") intersection() { seal_parts(); seal_access(); }
else if (view == "frame") frame_exploded(explode);
else if (view == "cap") color("dimgray") hepa_cap();
else if (view == "paper_cut") paper_cut();
// The ring stands in the HEPA holder's pocket, on its ledge.
else if (view == "check_ring_holder") intersection() { translate([0, 0, ledge_z + sep]) hepa_ring(); orig(hepa_stl, st[2] - st[1]); }
// The ring's walls stand on the ledge, clear of its opening. The strips reach over it on purpose.
else if (view == "check_ring_opening") intersection() { hepa_ring_walls(); opening_probe(); }
// The caps' wedges and teeth stand in the paper's channels without cutting into it: the paper is drawn from
// its own values, the wedges and teeth from their arithmetic, and they are held sep inside their outline.
else if (view == "check_wedges_paper") intersection() { paper_pack(); caps_in_place(0, true, sep); }
// The ring's walls and strips clear the paper: each flap in its slot, each strip under the first pleat.
else if (view == "check_ring_paper") intersection() { paper_pack(); hepa_ring(); }
// The caps' teeth, cut back, clear the strips where both stand in the channel beside a flap.
else if (view == "check_caps_strips") intersection() { caps_in_place(); hepa_ring_strips(); }
else assert(false, str("unknown view: ", view));

if (show_axes && (view == "stack" || view == "exploded")) axes([-bb_w / 2 - 40, -bb_l / 2, 0], l = 25);
axes_cam = [55, 0, 30];   // the picture's --camera angles, so the arrows' labels face it
if (show_axes && view == "section") axes([-bb_w / 2 - 20, -bb_l / 2, 0], l = 15, cam = axes_cam);
if (show_axes && view == "frame") axes([-ring_out[0] / 2 - 25, -ring_out[1] / 2 - explode, 0], l = 15, cam = axes_cam);
if (show_axes && view == "joints") axes([bb_w / 2 + 20, bb_l / 2, sst[0] + 30], l = 20, cam = axes_cam);
if (show_axes && view == "bottom") axes([bb_w / 2 + 15, bb_l / 2, 0], l = 20, cam = axes_cam);
if (show_axes && view == "cap") axes([-ring_in[0] / 2 - 15, -5, 0], l = 8, cam = axes_cam);
// A flat view gets a flat key: an arrow across, labelled with the box's axis it shows, and +z up.
module flat_key(across) color("black") {
    translate([0, -0.6]) square([16, 1.2]);
    translate([16, 0]) polygon([[0, -2.5], [5, 0], [0, 2.5]]);
    translate([-0.6, 0]) square([1.2, 16]);
    translate([0, 16]) polygon([[-2.5, 0], [2.5, 0], [0, 5]]);
    translate([23, 0]) text(across, size = 3.5, valign = "center");
    translate([0, 24]) text("+z up", size = 3.5, halign = "center");
}
// The cut's across is +y, along the box; the paper's cut's is +x, across it.
if (show_axes && view == "cut") translate([-bb_l / 2 - 30, 10]) flat_key("+y");
if (show_axes && view == "paper_cut") translate([-ring_out[0] - 4 - 22, 2]) scale(0.5) flat_key("+x");
