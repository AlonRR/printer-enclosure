// SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
// SPDX-License-Identifier: CC-BY-SA-4.0
// A remix of LunchBox by GekoPrime (https://www.printables.com/model/468166), CC BY-SA 4.0.

/*
The LunchBox stack, put together from the original STLs and the remix's parts - for pictures, and for the
fit checks that scripts/lunchbox-checks.py renders. Needs the originals in original/.

  view = "stack"      the box as it stands, with the gaskets
  view = "exploded"   the same, pulled apart along Z
  view = "section"    the stack cut open at X = section_x, seen from the side
  view = "insert"     the insert alone, as it sits under the body - the one view that needs no original
  view = "check_..."  one fit check: a solid that must come out EMPTY. Each is an intersection of two
                      parts that should only touch; anything left is two parts in the same place.
*/
include <lunchbox.scad>
use <../../../../scad-tools/lib/axes.scad>
draw_model = false;

view = "stack";
with_insert = true;     /* the stack with the insert between the body and the fan section, or without */
tabbed = true;          /* the originals with their tabs, or as downloaded */
explode = 40;           /* "exploded": the gap between parts */
section_x = -8;         /* "section": where to cut, along X */
show_axes = true;

function stack_z(g, ex) = stack_at(g, ex, with_insert);

// One part of the stack, in its colour - or, for "section", its cut at X = section_x, laid out with the
// box's depth (Y) across and its height (Z) up. The cut's frame is a rotation, not a mirror: (y, z, x).
module piece(c) color(c) if (view == "section")
    projection(cut = true) multmatrix([[0, 1, 0, 0], [0, 0, 1, 0], [1, 0, 0, -section_x]]) children();
    else children();

module stack(g, ex) {
    z = stack_z(g, ex);
    piece("tan") if (tabbed) body_tabbed(); else body_orig();
    piece("steelblue") translate([0, 0, z[2] - body_h]) lid_orig();
    piece("orange") translate([0, 0, z[1]]) if (tabbed) fans_tabbed(); else fans_orig();
    piece("dimgray") translate([0, 0, z[1]]) blank_in_bay();
    if (with_insert) piece("seagreen") translate([0, 0, z[0]]) insert();
    if (g > 0) {
        piece("firebrick") translate([0, 0, body_h + ex / 2]) gasket_lid();
        piece("firebrick") translate([0, 0, -g - ex / 2]) gasket_fans();
        if (with_insert) piece("firebrick") translate([0, 0, z[0] - ins_h - g - ex / 2]) gasket_fans();
    }
}

// The air's way, from the ORIGINAL's measurements only, never the insert's own - a probe built from the
// cavity would move with it, and could not catch the cavity in the wrong place. The body's channel, carried
// down through the insert to its grid: nothing of the insert may stand in it.
module air_probe() translate([-(groove_x0 - 1), cap_y1 + 0.5, -ins_h + grid_t + eps])
    cube([2 * (groove_x0 - 1), groove_y1 - cap_y1 - 1, ins_h - grid_t - 2 * eps]);
// ...and the fan section's plenum, probe_h deep under its rim, where the insert's air goes.
probe_h = 3;
// Parts that meet face to face are checked sep apart along the joint, so that touching leaves nothing at all
// and anything left is a real overlap. Touching faces would leave a slab of no thickness, which the
// Manifold backend's floats turn into a few hundredths of a mm3 - enough to hide a small collision in.
sep = 0.01;
module plenum_probe() translate([-(plenum_hw - 1), fan_slot_y1 + 0.5, -probe_h])
    cube([2 * (plenum_hw - 1), lip_back_y0 - fan_slot_y1 - 1, probe_h - eps]);

if (view == "stack") stack(gasket_t, 0);
else if (view == "exploded") stack(gasket_t, explode);
else if (view == "section") stack(gasket_t, 0);
// The insert seats in the body: its lip in the groove, its top against the island, its tabs under the body's.
else if (view == "check_insert_body") intersection() { if (tabbed) body_tabbed(); else body_orig(); translate([0, 0, -sep]) insert(); }
// The fan section seats in the insert the way it seats in the body, its tabs under the insert's.
else if (view == "check_insert_fans") intersection() { translate([0, 0, -ins_h - sep]) if (tabbed) fans_tabbed(); else fans_orig(); insert(); }
// The blank stands in the middle bay, clear of the walls and the curved plenum floor behind it.
else if (view == "check_blank") intersection() { fans_orig(); blank_in_bay(sep); }
// The gaskets lie flat on a rim, with the lip, or the lid's plug, coming through them.
else if (view == "check_gasket_fans") intersection() { fans_orig(); translate([0, 0, sep]) gasket_fans(); }
else if (view == "check_gasket_insert") intersection() { insert(); translate([0, 0, sep]) gasket_fans(); }
else if (view == "check_gasket_lid") intersection() { lid_orig(); translate([0, 0, body_h - gasket_t - sep]) gasket_lid(); }
// The tabs of the fan joint meet face to face, and nothing else of one part enters the other.
else if (view == "check_tabs_fans") intersection() { body_tabbed(); translate([0, 0, -sep]) fans_tabbed(); }
// The air's way stays open: through the insert, and into the fan section under it.
else if (view == "check_air_insert") intersection() { insert(); air_probe(); }
else if (view == "check_air_plenum") intersection() { fans_orig(); plenum_probe(); }
else if (view == "insert") color("seagreen") insert();
else assert(false, str("unknown view: ", view));

if (show_axes && (view == "stack" || view == "exploded")) axes([-hx - 30, -10, 0], l = 25);
axes_cam = [50, 0, 30];   // the picture's --camera angles, so the arrows' labels face it
if (show_axes && view == "insert") axes([-hx - 25, -5, -ins_h], l = 15, cam = axes_cam);
// The section is flat, so it gets a flat key: across is +y (front to back), up is +z.
if (show_axes && view == "section") color("black") translate([-52, -40]) {
    translate([0, -0.6]) square([16, 1.2]);
    translate([16, 0]) polygon([[0, -2.5], [5, 0], [0, 2.5]]);
    translate([-0.6, 0]) square([1.2, 16]);
    translate([0, 16]) polygon([[-2.5, 0], [2.5, 0], [0, 5]]);
    translate([23, 0]) text("+y back", size = 3.5, valign = "center");
    translate([0, 24]) text("+z up", size = 3.5, halign = "center");
}
