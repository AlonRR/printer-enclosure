// SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
// SPDX-License-Identifier: CC-BY-NC-SA-4.0
// A remix of BentoBox v2.0 by ThrutheFrame (https://www.printables.com/model/272525), CC BY-NC-SA 4.0.

// parts/print.scad - EVERY PRINTED PART AS IT PRINTS: print_part(name), whose names are draw's, and the part files'
// that scripts/tools/part-files.sh writes in .check/ for scad-tools' scad-check.sh and printables.py. Included by
// bentobox.scad; not a model on its own.

printed = ["section", "glue_frame", "glue_sample", "clamp_lower", "clamp_upper", "clamp_sample", "auto_base", "auto_tray", "auto_fans", "carbon", "hepa", "cover", "cmag_tray", "cmag_lid", "cmag_grills", "bead_ring", "joint_sample", "joint_sample_bead", "grommet", "grommet_coupon", "fan_mate", "bottom_sample", "nut_coupon", "samples_asa", "samples_asa_2", "samples_tpu"];
module print_part(name) {
    if (name == "section") section();
    // The clamp's two frames as they print: the lower standing, the upper on its band; and its sample.
    else if (name == "glue_frame") { assert(glue, "the glue frame's part: hepa_frame = \"glue\""); glue_frame(); say_paper_cut(); }
    else if (name == "glue_sample") { assert(glue, "the glue frame's part: hepa_frame = \"glue\""); glue_sample(); say_paper_cut(); }
    else if (name == "clamp_lower") { assert(!glue, "the clamp's parts: hepa_frame = \"clamp\""); clamp_low(); say_paper_cut(); }
    else if (name == "clamp_upper") { assert(!glue, "the clamp's parts: hepa_frame = \"clamp\""); translate([0, 0, cas_h]) mirror([0, 0, 1]) clamp_up(); say_paper_cut(); }
    else if (name == "clamp_sample") { assert(!glue, "the clamp's parts: hepa_frame = \"clamp\""); clamp_sample(); say_paper_cut(); }
    // The Auto's parts as they print, standing: the base on its floor, the tray on its own.
    else if (name == "auto_base") { translate([0, 0, -auto_bay_top]) auto_base(); say_auto_hardware(); say_sps30(); }
    else if (name == "auto_tray") { translate([0, 0, -auto_base_z0]) auto_tray(); say_auto_hardware(); say_usb(); }
    else if (name == "auto_fans") translate([0, 0, -duct_h]) if (sealed) fans_sealed(); else auto_fans();
    // The sealed stack's remixed originals and the bead ring, as they print: standing, the ring flat.
    else if (name == "carbon") { translate([0, 0, -sst[2]]) carbon_sealed(); say_seal_hardware(); }
    else if (name == "hepa") { translate([0, 0, -sst[3]]) hepa_sealed(); say_seal_hardware(); }
    else if (name == "cover") translate([0, 0, cover_top]) mirror([0, 0, 1]) cover_drawn(0);
    else if (name == "cmag_tray") cmag_tray_drawn();
    else if (name == "cmag_lid") translate([0, 0, cmag[2]]) mirror([0, 0, 1]) cmag_lid_drawn();
    else if (name == "cmag_grills") { for (i = [0 : 3]) translate([0, i * (cmag_grill[1] + 5), 0]) linear_extrude(cmag_grill_t, convexity = 10) cmag_grill2d(); say_cmag(); }
    else if (name == "bead_ring") bead_ring();
    // The joint sample's ASA plate, and its TPU bead.
    else if (name == "joint_sample") { joint_sample(); say_sample_hardware(); }
    else if (name == "joint_sample_bead") joint_sample_bead();
    // The wires' grommet, in TPU, on its foot; the bottom sample; and every sample on its plate.
    else if (name == "grommet") grommet_body();
    // The floor's hole on a 3 mm coupon, in ASA, to try the grommet in (T184).
    else if (name == "grommet_coupon") grommet_coupon();
    // The fans' plug mate, in ASA, on its underside.
    else if (name == "fan_mate") { fan_mate(); say_fan_mate(); }
    else if (name == "bottom_sample") { bottom_sample(); say_auto_hardware(); say_usb(); }
    else if (name == "nut_coupon") { nut_coupon(); say_nut_coupon(); }
    else if (name == "samples_asa") { samples_asa(); say_sample_hardware(); say_auto_hardware(); }
    else if (name == "samples_asa_2") { assert(glue, "the glue sample's plate: hepa_frame = \"glue\""); samples_asa_2(); say_nut_coupon(); say_paper_cut(); }
    else if (name == "samples_tpu") samples_tpu();
}
