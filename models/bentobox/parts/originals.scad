// SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
// SPDX-License-Identifier: CC-BY-NC-SA-4.0
// A remix of BentoBox v2.0 by ThrutheFrame (https://www.printables.com/model/272525), CC BY-NC-SA 4.0.

// parts/originals.scad - THE ORIGINALS, ThrutheFrame's and the Auto's STLs, in the box's frame: never printed - the stack as it comes (sealed = false), the checks of the original joints, and the airflow simulation. They are in original/, which the README there says how to fill. Included by bentobox.scad; not a model on its own.

// ------------------------------------------------------------------ the originals, in the box's frame
orig_dir = "../original/";    // from parts/, where import() reads it: an import is read from the file it is written in
duct_stl   = str(orig_dir, "fan duct BambuLab 20231017.stl");
fans_stl   = str(orig_dir, "fan case v1_28.stl");
carbon_stl = str(orig_dir, "carbon.stl");
hepa_stl   = str(orig_dir, "hepa.stl");
cover_stl  = str(orig_dir, "cover_hemp.stl");
cmag_stls  = [str(orig_dir, "CMag Case 01 v5.stl"), str(orig_dir, "CMag Case 02 v5.stl")];

// An original, moved up by dz: the parts above the section stand sec_h higher with it.
module orig(file, dz = 0) translate([0, 0, dz] - stl_origin) import(file, convexity = 10);
// The HEPA holder, moved up by dz. With hepa_full its pocket is cut out to the box's whole inside, `meet` past its
// walls' faces, from `meet` under its ledge up through its top; and its ledge's opening to hepa_ledge_w inside
// that, `meet` past the original's sides. The original's ends were solid funnels round an 80 mm cartridge.
module hepa_body(dz = 0) let(f = duct_h + fans_h + carbon_h + dz) difference() {
    orig(hepa_stl, dz);
    if (hepa_full) {
        translate([0, 0, f + ledge_top]) linear_extrude(hepa_h) inside_offset(meet);
        translate([0, 0, f - 1]) linear_extrude(hepa_ledge + 2) offset(delta = meet) rrect_c(open_wl[0], open_wl[1], hepa_open_r);
    }
}
// The C-MAG, from its own frame (L along X, W along Y, T along Z) to standing on end in the housing.
module cmag_standing(z0) cmag_stood(z0) for (f = cmag_stls) import(f, convexity = 10);
// A C-MAG, from its own frame to standing on end in the housing, its bottom at z0.
module cmag_stood(z0) translate([cmag[2] / 2, -cmag[1] / 2, z0]) rotate([0, -90, 0]) children();

auto_fans_stl  = str(orig_dir, "bentobox-auto-fans.stl");
module auto_fans() orig(auto_fans_stl, auto_fans_dz);
// The fan section the stack stands on, whichever bottom it has, as it comes - its tongue and magnets on top, for the
// original joints' checks.
module fan_section() if (bottom == "auto") auto_fans(); else orig(fans_stl);
