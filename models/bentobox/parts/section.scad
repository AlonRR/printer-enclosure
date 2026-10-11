// SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
// SPDX-License-Identifier: CC-BY-NC-SA-4.0
// A remix of BentoBox v2.0 by ThrutheFrame (https://www.printables.com/model/272525), CC BY-NC-SA 4.0.

// parts/section.scad - THE SECTION: its grid, the original joint's version, and the sealed one. Included by bentobox.scad; not a model on its own.

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
