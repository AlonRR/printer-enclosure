// SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
// SPDX-License-Identifier: CC-BY-NC-SA-4.0
// A remix of BentoBox v2.0 by ThrutheFrame (https://www.printables.com/model/272525), CC BY-NC-SA 4.0.

// assembly/outlet-sensors-wall.scad - WHERE THE SGP41 COULD GO: the +Y end wall seen from inside the duct (from -Y), the
// outlet to the left. The base cut just inside the wall's face, so the wall shows solid and the SPS30's slot shows cut;
// in front of the wall, the fan screw's post on it and the SPS30, in outline; behind the cut, the tray screws' holes,
// dashed. The SGP41 (Q248, Alon, 14 Oct 2026: beside the SPS30, its leads down the same slot) in a recess in the wall
// above the SPS30, clear of the post, its sensor facing the duct, its leads along a short groove into the slot. A
// drawing to decide from: nothing of the SGP41 is in the model.
// Not included by bentobox.scad: it includes it. Render from this folder:
//
//   openscad -o ../../../docs/diagrams/bentobox/outlet-sensors-wall.png --imgsize=2200,1650 \
//     --camera=0,0,0,0,0,0,250 --viewall --autocenter --projection=ortho outlet-sensors-wall.scad

include <../bentobox.scad>
use <../../../scad-tools/lib/draw2d.scad>
draw = "none";

$txt = 2.2;
$lw = 0.18;
$ah = 1.4;
C_BOX = [0.55, 0.66, 0.82];
C_POST = [0.40, 0.48, 0.62];
C_SPS = [0.85, 0.45, 0.10];
C_SGP = [0.15, 0.55, 0.30];
C_CUT = [0.80, 0.15, 0.10];

face = -bb_w / 2;
wall_y = duct_in[1];
post = [for (s = auto_fan_screws) if (s[1] > 0 && abs(s[1]) > 40) s][0];   // the fan screw's post on the +Y end wall
// The SGP41, its long side along X, pins towards the outlet: seen from its sensor side, the sensor at its far end's
// bottom and its hole at the far end's top (the air-quality monitor's gy_hole_right). Behind the post, over the SPS30.
sgp_x = [-8.5, -8.5 + sgp41[0]];
sgp_z = [sps30_top + sps30_fit + 0.2, sps30_top + sps30_fit + 0.2 + sgp41[1]];
hole = [sgp_x[1] - (1.32 + sgp41_hole / 2), sgp_z[1] - (1.25 + sgp41_hole / 2)];
sensor = [sgp_x[1] - 3, sgp_z[0] + 2.5];
lead_groove = [[sps30_plug_x[1], sgp_x[0] + 0.5], [sgp_z[0], sgp_z[0] + 2.2]];   // its leads, into the SPS30's slot

module rect(x, z) translate([x[0], z[0]]) square([x[1] - x[0], z[1] - z[0]]);
module cut(y) projection(cut = true) rotate([-90, 0, 0]) translate([0, -y, 0]) children();
module outline(col) color(col) render() difference() {
    children();
    offset(delta = -$lw) children();
}
module dashed_box(x, z, col) {
    dashed([x[0], z[0]], [x[1], z[0]], col = col);
    dashed([x[1], z[0]], [x[1], z[1]], col = col);
    dashed([x[1], z[1]], [x[0], z[1]], col = col);
    dashed([x[0], z[1]], [x[0], z[0]], col = col);
}

// ---- the end wall, cut 0.3 mm inside its face; the fan section over it
color(C_BOX) cut(wall_y + 0.3) auto_base();
color(C_BOX) cut(wall_y + 0.3) fans_whole();
// the fan screw's post, standing out of the wall in front of the cut
color(C_POST, 0.8) projection() rotate([-90, 0, 0]) fan_post(post);
// the tray screws' holes, behind the cut, up to where the longest screw's tip may reach
for (s = tray_screws) if (s[1] > 0) dashed_box([s[0] - hole_d / 2, s[0] + hole_d / 2], [auto_bay_top, tray_room_z], _d2_ink());
// the SPS30, in front of the wall
outline(C_SPS) rect([sps30_x[0] - sps30_nub, sps30_x[1] + sps30_nub], [base_floor, sps30_top]);
color(C_SPS) translate([sps30_x[0] + 14, base_floor + 4.5]) text("SPS30, in front", size = $txt * 0.85);

// ---- the SGP41, in a recess in the wall, its sensor facing you; its leads along a groove into the SPS30's slot
color(C_SGP, 0.85) rect(sgp_x, sgp_z);
color([1, 1, 1]) {
    translate(sensor) square(2.4, center = true);
    translate(hole) circle(d = sgp41_hole, $fn = 24);
}
color(C_CUT, 0.6) rect(lead_groove[0], lead_groove[1]);
for (i = [0 : 3]) color(_d2_ink()) translate([sgp_x[0] + 0.9, sgp_z[0] + 1.6 + i * 2.54]) circle(d = 0.9, $fn = 12);

// ---- labels
leader([sgp_x[1] + 14, sgp_z[1] + 8], [sgp_x[1] - 2, sgp_z[1] - 1], "SGP41, in a recess, flush with the wall", C_SGP);
leader([sgp_x[1] + 14, sgp_z[0] - 4], [sensor[0] + 1.4, sensor[1]], "its sensor, facing the duct", C_SGP);
leader([sgp_x[1] + 14, sgp_z[1] + 3], [hole[0] + 1.6, hole[1]], "its hole: an M2.5 into the wall", C_SGP);
leader([sgp_x[0] - 22, sgp_z[0] + 14], [sgp_x[0] + 0.9, sgp_z[0] + 6], "its four pins, towards the outlet", _d2_ink());
leader([face - 16, sgp_z[0] + 3], [lead_groove[0][0] + 1, lead_groove[1][0] + 1], "its leads: a groove into the SPS30's slot", C_CUT);
leader([face - 16, base_floor - 3], [sps30_plug_x[0] + 2, base_floor + 6], "the SPS30's slot, open to the outlet", C_CUT);
leader([post[0] - 18, duct_h - 2], [post[0], post_foot + 6], "the fan screw's post, in front", C_POST);
leader([tray_screws_x[1][0] + 10, auto_bay_top - 6], [tray_screws_x[1][0], auto_bay_top + 4], "the tray's screws, behind", _d2_ink());
color(_d2_ink()) translate([face - 4, base_floor + 14]) rotate(90) text("outlet", size = $txt * 0.8);
heading("Where the SGP41 could go: the +Y end wall, from inside the duct", [face - 16, duct_h + fans_h + 8]);
color(_d2_ink()) translate([face - 16, auto_base_z0 - 16]) {
    text("Over the SPS30 and behind the fan screw's post, the SGP41 lies in a recess in the end wall, its sensor flush with the wall's face,", size = $txt * 0.8);
    translate([0, -4]) text("in the air the +Y fan blows down to the outlet. Its pins face the outlet; its four leads run along a short groove into the SPS30's", size = $txt * 0.8);
    translate([0, -8]) text("slot, and down it and the tray's groove into the bay with the SPS30's. In front of the post the post would sit over its sensor and screw.", size = $txt * 0.8);
}

translate([bb_w / 2 + 12, auto_base_z0]) {
    axis("X", 0, 10);
    axis("Z", 90, 10);
}
