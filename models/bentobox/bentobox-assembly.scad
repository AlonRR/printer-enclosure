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

module stack(ex) {
    st = stack(with_section);
    dz = st[2] - st[1];
    piece("dimgray") orig(duct_stl);
    piece("steelblue") translate([0, 0, ex]) orig(fans_stl);
    if (with_section) piece("seagreen") translate([0, 0, st[1] + 2 * ex]) section();
    piece("tan") translate([0, 0, 3 * ex]) orig(carbon_stl, dz);
    piece("sienna") translate([0, 0, 3 * ex]) cmag_standing(st[2] + cmag_z0);
    piece("lightsteelblue") translate([0, 0, 4 * ex]) orig(hepa_stl, dz);
    piece("darkslategray") translate([0, 0, 5 * ex]) orig(cover_stl, dz);
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

if (view == "stack") stack(0);
else if (view == "exploded") stack(explode);
else if (view == "cut") stack(0);
else if (view == "section") color("seagreen") section();
// The section seats in the carbon housing: its tongue in the housing's groove, its magnets under the housing's.
else if (view == "check_section_carbon") intersection() { section(); translate([0, 0, sec_h + sep - st[2]]) orig(carbon_stl, st[2] - st[1]); }
// The fan case seats in the section the way it seats in the housing.
else if (view == "check_section_fans") intersection() { translate([0, 0, st[1] + sep]) section(); orig(fans_stl); }
// Each magnet's hole in the section lines up with its partner's in the original.
else if (view == "check_magnets_top") intersection() {
    union() { section(); translate([0, 0, sec_h + sep - st[2]]) orig(carbon_stl, st[2] - st[1]); }
    magnets_across(sec_h);
}
else if (view == "check_magnets_bottom") intersection() {
    union() { translate([0, 0, st[1] + sep]) section(); orig(fans_stl); }
    translate([0, 0, st[1]]) magnets_across(0);
}
// The air from the housing's openings reaches the whole sheet.
else if (view == "check_air") intersection() { section(); air_probe(); }
else if (view == "frame") frame_exploded(explode);
else if (view == "cap") color("dimgray") hepa_cap();
// The ring stands in the HEPA holder's pocket, on its ledge.
else if (view == "check_ring_holder") intersection() { translate([0, 0, ledge_z + sep]) hepa_ring(); orig(hepa_stl, st[2] - st[1]); }
// The ring leaves the ledge's opening clear.
else if (view == "check_ring_opening") intersection() { hepa_ring(); opening_probe(); }
// The caps' wedges and teeth stand in the paper's channels without cutting into it: the paper is drawn from
// its own values, the wedges and teeth from their arithmetic, and they are held sep inside their outline.
else if (view == "check_wedges_paper") intersection() { paper_pack(); caps_in_place(0, true, sep); }
else assert(false, str("unknown view: ", view));

if (show_axes && (view == "stack" || view == "exploded")) axes([-bb_w / 2 - 30, -bb_l / 2, 0], l = 25);
axes_cam = [55, 0, 30];   // the picture's --camera angles, so the arrows' labels face it
if (show_axes && view == "section") axes([-bb_w / 2 - 20, -bb_l / 2, 0], l = 15, cam = axes_cam);
if (show_axes && view == "frame") axes([-ring_out[0] / 2 - 25, -ring_out[1] / 2 - explode, 0], l = 15, cam = axes_cam);
if (show_axes && view == "cap") axes([-ring_in[0] / 2 - 15, -5, 0], l = 8, cam = axes_cam);
// The cut is flat, so it gets a flat key: across is +y (along the box), up is +z.
if (show_axes && view == "cut") color("black") translate([-bb_l / 2 - 30, 10]) {
    translate([0, -0.6]) square([16, 1.2]);
    translate([16, 0]) polygon([[0, -2.5], [5, 0], [0, 2.5]]);
    translate([-0.6, 0]) square([1.2, 16]);
    translate([0, 16]) polygon([[-2.5, 0], [2.5, 0], [0, 5]]);
    translate([23, 0]) text("+y", size = 3.5, valign = "center");
    translate([0, 24]) text("+z up", size = 3.5, halign = "center");
}
