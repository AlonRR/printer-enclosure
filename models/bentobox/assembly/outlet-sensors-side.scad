// SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
// SPDX-License-Identifier: CC-BY-NC-SA-4.0
// A remix of BentoBox v2.0 by ThrutheFrame (https://www.printables.com/model/272525), CC BY-NC-SA 4.0.

// assembly/outlet-sensors-side.scad - THE SPS30 IN ITS POCKET, SEEN FROM THE SIDE: the base, the fan section and the
// tray cut through the SPS30's middle and seen from -Y, the outlet to the left, the pocket as the model cuts it
// (parts/bottom.scad, D252, Alon, 14 Oct 2026). The floor is flat for only 19.8 mm before it turns up into the +X wall,
// and the SPS30 is 40.6 deep: the pocket cuts the turn back to the floor; dashed, the turn as it was.
// Not included by bentobox.scad: it includes it. Render from this folder:
//
//   openscad -o ../../../docs/diagrams/bentobox/outlet-sensors-side.png --imgsize=2200,1650 \
//     --camera=0,0,0,0,0,0,250 --viewall --autocenter --projection=ortho outlet-sensors-side.scad

include <../bentobox.scad>
use <../../../scad-tools/lib/draw2d.scad>
draw = "none";

$txt = 2.2;
$lw = 0.18;
$ah = 1.4;
C_BOX = [0.55, 0.66, 0.82];
C_TRAY = [0.72, 0.78, 0.86];
C_SPS = [0.85, 0.45, 0.10];
C_AIR = [0.98, 0.93, 0.80];
C_TURN = [0.80, 0.15, 0.10];

face = -bb_w / 2;                           // the outlet's face
turn_x = duct_in[0] - base_turn_r;          // where the floor starts to turn up into the +X wall
fan_z = duct_h + auto_floor_t;              // the fans stand on the fan section's floor
cut_y = (sps30_yy[0] + sps30_yy[1]) / 2;
body = [sps30_x[0] - sps30_nub, sps30_x[1] + sps30_nub];
sps_z = [base_floor, sps30_top];
inlets = [sps30_x[1] - sps30_air[0], sps30_x[1] - sps30_open[0]];
grille = [sps30_x[0] + sps30_open[1], sps30_x[1] - sps30_air[1]];
turn = [for (a = [-90 : 3 : 0]) [turn_x, base_floor + base_turn_r] + base_turn_r * [cos(a), sin(a)]];   // the turn as it was

module cut(y) projection(cut = true) rotate([-90, 0, 0]) translate([0, -y, 0]) children();
module rect(x, z) translate([x[0], z[0]]) square([x[1] - x[0], z[1] - z[0]]);

// ---- the parts, cut through the SPS30's middle
color(C_BOX) cut(cut_y) auto_base();
color(C_BOX) cut(cut_y) fans_whole();
color(C_TRAY) cut(cut_y) auto_tray();
color(_d2_ink()) translate([-fan_t, fan_z]) difference() {
    square([2 * fan_t, fan_t]);
    offset(delta = -$lw) square([2 * fan_t, fan_t]);
}
color(_d2_ink()) translate([-fan_t + 2, fan_z + fan_t / 2 - 1]) text("the +Y fan, blowing down", size = $txt * 0.8);

// ---- the SPS30 in its pocket: its air face towards you, its inlets at the back and its grille at the front; over it,
// dashed, the turn as it was
color(C_SPS, 0.85) rect(body, sps_z);
color(C_AIR) {
    translate([inlets[0], sps_z[0] + 2]) square([inlets[1] - inlets[0], sps30[2] - 4]);
    translate([grille[0], sps_z[0] + 2]) square([grille[1] - grille[0], sps30[2] - 4]);
}
translate([0, 0, 1]) for (i = [0 : len(turn) - 2]) if (turn[i + 1][1] <= sps30_top + sps30_fit + 3) dashed(turn[i], turn[i + 1], col = C_TURN);
color(_d2_ink()) {
    translate([inlets[0] + 1, sps_z[0] + 4.6]) text("inlets", size = $txt * 0.75);
    translate([grille[0] + 1, sps_z[0] + 4.6]) text("outlet grille", size = $txt * 0.75);
}

// ---- dimensions
dim_h(face, body[0], sps_z[1] + 4, sps_z[1], str(sps30_in, " in"), C_SPS);
dim_h(body[0], body[1], sps_z[1] + 10, sps_z[1], str(body[1] - body[0], " with its nubs"), C_SPS);
dim_h(face, turn_x, auto_base_z0 - 6, base_floor, str("flat floor ", turn_x - face), above = false);
leader([duct_in[0] + base_wall + 4, sps_z[1] + 6], [turn_x + 9, base_floor + 2.4], "the turn as it was, cut back to the floor", C_TURN);
leader([face - 16, base_floor + sps30_stop[2] + 8], [face + sps30_stop[0] / 2, base_floor + sps30_stop[2] - 1], "the tray's stop", _d2_ink());

// ---- what it says
color(_d2_ink()) translate([face - 6, auto_base_z0 - 20]) {
    text(str("The floor is flat for ", turn_x - face, " mm in from the outlet's face, then turns up into the +X wall on a ", base_turn_r, " mm radius."), size = $txt * 0.8);
    translate([0, -4]) text(str("The SPS30 is ", sps30[1], " deep: the pocket cuts the turn back to the floor, and its front stands ", sps30_in, " mm inside the face,"), size = $txt * 0.8);
    translate([0, -8]) text("behind the tray's stop, which comes up through a notch in the floor's front edge.", size = $txt * 0.8);
    translate([0, -12]) text(str("Its air face, towards you here, faces the duct's middle (-Y). Cut at Y ", round(10 * cut_y) / 10, ", seen from -Y."), size = $txt * 0.8);
}
heading("The SPS30 in its pocket, from the side", [face - 6, duct_h + fans_h + 8]);

translate([duct_in[0] + 44, auto_base_z0]) {
    axis("X", 0, 10);
    axis("Z", 90, 10);
}
