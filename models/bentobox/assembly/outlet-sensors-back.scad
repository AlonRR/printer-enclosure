// SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
// SPDX-License-Identifier: CC-BY-NC-SA-4.0
// A remix of BentoBox v2.0 by ThrutheFrame (https://www.printables.com/model/272525), CC BY-NC-SA 4.0.

// assembly/outlet-sensors-back.scad - THE SPS30 STANDING AGAINST THE BACK WALL, OPENINGS DOWN: Sensirion's best
// orientation, asked about by Alon (14 Oct 2026). The base, the fan section, a fan and the tray cut through where it
// would stand (Y -25, clear of the SPS30's pocket at the +Y end) and seen from -Y, the outlet to the left; in red,
// what it would run into. Not built: it is why the SPS30 lies in its pocket (D252).
// Not included by bentobox.scad: it includes it. Render from this folder:
//
//   openscad -o ../../../docs/diagrams/bentobox/outlet-sensors-back.png --imgsize=2200,2200 \
//     --camera=0,0,0,0,0,0,250 --viewall --autocenter --projection=ortho outlet-sensors-back.scad

include <../bentobox.scad>
use <../../../scad-tools/lib/draw2d.scad>
draw = "none";

$txt = 2.2;
$lw = 0.18;
$ah = 1.4;
C_BOX = [0.55, 0.66, 0.82];
C_TRAY = [0.72, 0.78, 0.86];
C_SPS = [0.85, 0.45, 0.10];
C_CUT = [0.80, 0.15, 0.10];
C_AIR = [0.98, 0.93, 0.80];

cut_y = -25;
air_gap = 3;                                // open air under its openings
fan_z = duct_h + auto_floor_t;
back = duct_in[0];                          // the back wall's inside face
sps_x = [back - sps30[2], back];            // standing against it, 12.2 thick
sps_z = [base_floor + air_gap, base_floor + air_gap + sps30[1]];   // its openings down, air_gap over the floor
fan = [[-fan_t, fan_t], [fan_z, fan_z + fan_t]];

module cut(y) projection(cut = true) rotate([-90, 0, 0]) translate([0, -y, 0]) children();
module rect(x, z) translate([x[0], z[0]]) square([x[1] - x[0], z[1] - z[0]]);
module solids() {
    cut(cut_y) auto_base();
    cut(cut_y) fans_whole();
    rect(fan[0], fan[1]);
}

// ---- the parts
color(C_BOX) render() difference() {
    union() {
        cut(cut_y) auto_base();
        cut(cut_y) fans_whole();
    }
    rect(sps_x, [sps_z[0] - air_gap, sps_z[1]]);
}
color(C_TRAY) cut(cut_y) auto_tray();
color(_d2_ink()) translate([fan[0][0], fan[1][0]]) difference() {
    square([2 * fan_t, fan_t]);
    offset(delta = -$lw) square([2 * fan_t, fan_t]);
}
color(_d2_ink()) translate([-fan_t + 2, fan_z + fan_t / 2 - 1]) text("the -Y fan", size = $txt * 0.8);

// ---- the SPS30 standing against the back wall, its openings down, and what it runs into
color(C_SPS, 0.85) rect(sps_x, sps_z);
color(C_AIR) rect(sps_x, [sps_z[0], sps_z[0] + 1.4]);
color(C_CUT, 0.75) render() intersection() {
    rect(sps_x, [sps_z[0] - air_gap, sps_z[1]]);
    solids();
}
color([1, 1, 1]) translate([sps_x[0] + sps30[2] / 2 + $txt * 0.35, sps_z[0] + 12]) rotate(90)
    text("SPS30, upright", size = $txt * 0.9, font = "DejaVu Sans:style=Bold");

// ---- dimensions
dim_v(base_floor, duct_h, -bb_w / 2 - 6, -bb_w / 2, str("the duct ", duct_h - base_floor, " tall"), right = false);
dim_v(sps_z[0] - air_gap, sps_z[1], back + base_wall + 6, back, str(sps30[1], " + ", air_gap, " of air under it"), C_SPS);
leader([-bb_w / 2 - 8, sps_z[0] - 14], [sps_x[0] + 2, sps_z[0] + 0.7], "its openings, facing down", C_SPS);
leader([back + base_wall + 8, sps_z[1] + 10], [sps_x[0] + 5, sps_z[1] - 3], "into the fan section and the fan", C_CUT);
leader([back + base_wall + 8, base_floor - 6], [sps_x[0] + 4, base_floor + 4], "into the floor's curve", C_CUT);

// ---- what it says
color(_d2_ink()) translate([-bb_w / 2 - 20, auto_base_z0 - 14]) {
    text(str("Upright, the SPS30 is ", sps30[1], " tall, and its openings need open air under them; the duct is ", duct_h - base_floor, " tall, floor to fan section."), size = $txt * 0.8);
    translate([0, -4]) text(str("At the back the floor curves up on a ", base_turn_r, " mm radius and meets the wall at Z ", base_floor + base_turn_r, ": the wall is flat for only its top ", duct_h - base_floor - base_turn_r, " mm."), size = $txt * 0.8);
    translate([0, -8]) text("Above it the fans fill the fan section to the wall. Sunk instead into the curve and the bay, its openings would face", size = $txt * 0.8);
    translate([0, -12]) text("down into the bottom of that slot - still air, or the bay's - not the filtered air leaving the box.", size = $txt * 0.8);
}
heading(str("The SPS30 against the back wall, openings down - cut at Y ", cut_y, ", seen from -Y"), [-bb_w / 2 - 20, duct_h + fans_h + 8]);

translate([back + base_wall + 40, auto_base_z0]) {
    axis("X", 0, 10);
    axis("Z", 90, 10);
}
