// SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
// SPDX-License-Identifier: CC-BY-SA-4.0
// A remix of LunchBox by GekoPrime (https://www.printables.com/model/468166), CC BY-SA 4.0.

/*
The LunchBox remix's parts, drawn from lunchbox.layout.scad. Set `part` in lunchbox.params.scad to view
one, or render a part's own file (lunchbox-insert.scad, ...) - those pin `part`, so a check cannot measure
whichever part happens to be on screen.

Every part is drawn in the box's frame (see lunchbox.params.scad) and moved to its printing pose only at the
end, in the part list at the bottom: the body and the fan section print standing as they stand in use, the
insert too, and the blank on its face. The lid is printed as the original.
*/
include <lunchbox.layout.scad>

$fn = 48;

// =================================================================== outlines
module rounded_rect(x0, y0, x1, y1, r) translate([x0 + r, y0 + r]) offset(r = r) square([x1 - x0 - 2 * r, y1 - y0 - 2 * r]);
module outline2d() rounded_rect(-hx, 0, hx, lb_d, lb_r);
module inside2d() translate([-(hx - lb_wall), lb_wall]) square([2 * (hx - lb_wall), lb_d - 2 * lb_wall]);
module gasket_hole2d(y0 = gasket_y0) translate([-gasket_hx, y0]) square([2 * gasket_hx, gasket_y1 - y0]);

// The fan section's lip: a U along both ends and the back, its outer back corners rounded.
module lip2d() difference() {
    intersection() {
        rounded_rect(-lip_x1, fan_slot_y1 - 10, lip_x1, lip_back_y1, lip_t_back);
        translate([-hx, fan_slot_y1]) square([lb_l, lb_d]);
    }
    translate([-lip_x0, fan_slot_y1 - 1]) square([2 * lip_x0, lip_back_y0 - fan_slot_y1 + 1]);
}

// The body's groove, where the fan section's lip runs: inside the wall, round the island.
module groove2d() intersection() {
    difference() {
        inside2d();
        translate([-groove_x0, groove_y0]) square([2 * groove_x0, groove_y1 - groove_y0]);
    }
    translate([-hx, ins_groove_from]) square([lb_l, lb_d]);
}

// =================================================================== tabs
// A tab on the end wall at side s (+1 or -1), Y y, from z0 up by h. `under` adds the 45-degree support
// under it, for a tab whose underside faces the bed's way while printing.
module tab_block(s, y, z0, h, under = false) mirror([s < 0 ? 1 : 0, 0, 0]) {
    translate([hx - 0.5, y - tab_w / 2, z0]) cube([tab_l + 0.5, tab_w, h]);
    if (under) translate([0, y + tab_w / 2, 0]) rotate([90, 0, 0]) linear_extrude(tab_w)
        polygon([[hx - 0.5, z0 + eps], [hx + tab_l, z0 + eps], [hx - 0.5, z0 - chamfer_h - 0.5]]);
}
module tab_hole(s, y, z0, h) translate([s * tab_x, y, z0]) cylinder(d = hole_d, h = h);
// The nut's pocket, open to the tab's end so the nut slides in flat, its flats facing along Y.
module nut_slot(s, y, zc) mirror([s < 0 ? 1 : 0, 0, 0]) translate([tab_x, y, zc - nut_slot_h / 2]) {
    rotate(30) cylinder(r = nut_ac / 2 + fdm_hole_comp + nut_fit, h = nut_slot_h, $fn = 6);
    translate([0, -nut_slot_w / 2, 0]) cube([tab_l, nut_slot_w, nut_slot_h]);
}

// =================================================================== the originals
module original(file, tf) translate(tf[1]) rotate(tf[0]) import(file, convexity = 10);
module body_orig() original(body_stl, body_from_stl);
module lid_orig() original(lid_stl, body_from_stl);
module fans_orig() original(fans_stl, fans_from_stl);

// The body's tabs are at its bottom only, on the bed in print: the lid is held by its own two screws.
module body_tabbed() {
    body_orig();
    difference() {
        for (s = [-1, 1], y = tab_ys) tab_block(s, y, 0, tab_t);
        for (s = [-1, 1], y = tab_ys) tab_hole(s, y, -1, tab_t + 2);
    }
}
module fans_tabbed() {
    fans_orig();
    difference() {
        for (s = [-1, 1], y = tab_ys) tab_block(s, y, fans_tab_z0, tab_t, under = true);
        for (s = [-1, 1], y = tab_ys) {
            tab_hole(s, y, fans_tab_z0 - chamfer_h - 1, tab_t + chamfer_h + 2);
            nut_slot(s, y, fans_tab_z0 + tab_t / 2);
        }
    }
}

// =================================================================== the insert
// In the box's frame it takes the fan section's place: its top face at Z = 0, under the body.
module insert() {
    difference() {
        union() {
            translate([0, 0, -ins_h]) linear_extrude(ins_h) outline2d();
            translate([0, 0, -eps]) linear_extrude(groove_h + eps) lip2d();
            if (insert_tabs) for (s = [-1, 1], y = tab_ys) tab_block(s, y, -ins_h, ins_h);
        }
        translate([-cav_hw, cav_y0, -ins_h - 1]) cube([2 * cav_hw, cav_y1 - cav_y0, ins_h + 2]);
        translate([0, 0, -ins_h - 1]) linear_extrude(groove_h + 1) groove2d();
        if (insert_tabs) for (s = [-1, 1], y = tab_ys) tab_hole(s, y, -ins_h - 1, ins_h + 2);
    }
    // The grid the sheet lies on, and the ledge round it that the ribs end on.
    translate([0, 0, -ins_h]) linear_extrude(grid_t) intersection() {
        translate([-cav_hw - eps, cav_y0 - eps]) square([2 * cav_hw + 2 * eps, cav_y1 - cav_y0 + 2 * eps]);
        union() {
            difference() {
                translate([-cav_hw - 1, cav_y0 - 1]) square([2 * cav_hw + 2, cav_y1 - cav_y0 + 2]);
                translate([-cav_hw + ledge_w, cav_y0 + ledge_w]) square([2 * (cav_hw - ledge_w), cav_y1 - cav_y0 - 2 * ledge_w]);
            }
            for (x = rib_xs) translate([x - rib_w / 2, cav_y0 - 1]) square([rib_w, cav_y1 - cav_y0 + 2]);
            for (y = rib_ys) translate([-cav_hw - 1, y - rib_w / 2]) square([2 * cav_hw + 2, rib_w]);
        }
    }
}

// =================================================================== the gaskets
module ears2d() for (s = [-1, 1], y = tab_ys) mirror([s < 0 ? 1 : 0, 0])
    translate([hx - 1, y - tab_w / 2]) square([tab_l + 1, tab_w]);
module ear_holes2d() for (s = [-1, 1], y = tab_ys) translate([s * tab_x, y]) circle(d = hole_d);
// The lid's: a ring on the body's top rim, round the lid's plug, clamped by the lid's own two screws.
module gasket_lid() linear_extrude(gasket_t) difference() {
    outline2d();
    gasket_hole2d();
}
// The fans': solid under the HEPA paper and over the fans - the paper's bottom edge sits on it, and nothing
// reaches the fans but through the carbon - and open behind, round the lip, where the air goes down.
module gasket_fans() linear_extrude(gasket_t) difference() {
    union() { outline2d(); ears2d(); }
    gasket_hole2d(gasket_open_y0);
    ear_holes2d();
}

// =================================================================== the blank
// A cup lying on its face: the face closes the middle bay's front, the walls keep it square in the bay.
// Drawn as it prints, face down; blank_in_bay() stands it in the box's frame.
module blank() difference() {
    translate([-blank_w / 2, 0, 0]) cube([blank_w, blank_h, blank_d]);
    translate([-blank_w / 2 + blank_wall, blank_wall, blank_face])
        cube([blank_w - 2 * blank_wall, blank_h - 2 * blank_wall, blank_d]);
}
module blank_in_bay(dz = 0) translate([0, lb_wall + blank_fit, dz - fan_slot_h + blank_h]) rotate([-90, 0, 0]) blank();

// =================================================================== echoes
module report() {
    echo(str("insert       : ", ins_h, " mm tall (grid ", grid_t, ", sheet ", sheet_t, ", plenum ", plenum_h, "), tabs ", insert_tabs));
    echo(str("filter sheet : cut ", sheet_cut[0], " x ", sheet_cut[1], " mm; ", round(sheet_area / 100), " cm2, against the channel's ",
             round(chan_area / 100), " cm2"));
    echo(str("screws       : fan joint M3 x ", screw_fans, ", or M3 x ", screw_ins, " through the insert - 4, each with an M3 nut;",
             " the lid its own 2, M3 x ", lid_screw_l));
    echo(str("gaskets      : ", gasket_t, " mm TPU"));
    echo(str("blank        : ", blank_w, " x ", blank_h, " x ", blank_d, " mm, for the middle bay"));
    for (w = warns) echo(str("WARNING: ", w));
    echo(len(warns) == 0 ? "warnings     : none" : str("warnings     : ", len(warns)));
}

// =================================================================== the part list, each in its printing pose
draw_model = true;   // set false after including this file, to use its values without drawing a part
if (draw_model) {
    report();
    if (part == "insert") translate([0, 0, ins_h]) insert();
    else if (part == "gasket-lid") gasket_lid();
    else if (part == "gasket-fans") gasket_fans();
    else if (part == "blank") blank();
    else if (part == "body") body_tabbed();
    else if (part == "fans") translate([0, 0, fans_h]) fans_tabbed();
    else assert(false, str("unknown part: ", part));
}
