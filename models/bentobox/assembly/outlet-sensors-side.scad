// SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
// SPDX-License-Identifier: CC-BY-NC-SA-4.0
// A remix of BentoBox v2.0 by ThrutheFrame (https://www.printables.com/model/272525), CC BY-NC-SA 4.0.

// assembly/outlet-sensors-side.scad - THE SPS30 ON THE OUTLET'S FLOOR, SEEN FROM THE SIDE: the base, the fan section
// and the tray cut through the SPS30's middle (Y 25) and seen from -Y, the outlet to the left. Option (a) of D247
// (Alon, 14 Oct 2026) laid it on the floor, but the floor is flat for only 19.8 mm before it turns up into the +X
// wall, and the SPS30 is 40.6 deep. Two ways to lay it there: in a pocket cut into the turn, or on the flat floor,
// standing out past the outlet's face. A drawing to decide from: the mount is not drawn.
// Not included by bentobox.scad: it includes it. Render from this folder:
//
//   openscad -o ../../../docs/diagrams/bentobox/outlet-sensors-side.png --imgsize=2200,2200 \
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
C_CUT = [0.80, 0.15, 0.10];
C_AIR = [0.98, 0.93, 0.80];

face = -bb_w / 2;                           // the outlet's face
turn_x = duct_in[0] - base_turn_r;          // where the floor starts to turn up into the +X wall
fan_z = duct_h + auto_floor_t;              // the fans stand on the fan section's floor
sps_z = [base_floor, base_floor + sps30[2]];
// (1) in a pocket: turned, its 40.69 along X from the outlet's face, its air face to the duct's middle (-Y), from
// Y 4.5 - clear of the wires' tube, 4 in radius round Y 0 - to 45.1, 4.3 short of the end wall
pocket_y = [4.5, 4.5 + sps30[1]];
inside = [face, face + sps30[0]];
inlets = [inside[1] - sps30_air[0], inside[1]];       // its inlets at the back, upstream...
grille = [inside[0], inside[1] - sps30_air[1]];       // ...its outlet grille and its connector at the front
// (2) on the flat floor: its back where the turn starts, the rest standing out past the outlet's face
flat = [turn_x - sps30[1], turn_x];
out = face - flat[0];
cut_y = (pocket_y[0] + pocket_y[1]) / 2;
gap = 130;                                   // between the two views, down the page
hole_x = -18;                               // a wire hole under the connector's end lands in the bay: X -21.4 to 19.4

module cut(y) projection(cut = true) rotate([-90, 0, 0]) translate([0, -y, 0]) children();
module rect(x, z) translate([x[0], z[0]]) square([x[1] - x[0], z[1] - z[0]]);
module others() {
    color(C_BOX) cut(cut_y) fans_whole();
    color(C_TRAY) cut(cut_y) auto_tray();
    color(_d2_ink()) translate([-fan_t, fan_z]) difference() {
        square([2 * fan_t, fan_t]);
        offset(delta = -$lw) square([2 * fan_t, fan_t]);
    }
    color(_d2_ink()) translate([-fan_t + 2, fan_z + fan_t / 2 - 1]) text("the +Y fan, blowing down", size = $txt * 0.8);
}

// ---- (1) in a pocket cut into the turn
others();
color(C_BOX) render() difference() {
    cut(cut_y) auto_base();
    rect(inside, sps_z);
}
color(C_SPS, 0.85) rect(inside, sps_z);
color(C_AIR) {
    translate([inlets[0], sps_z[0] + 2]) square([inlets[1] - inlets[0], sps30[2] - 4]);
    translate([grille[0], sps_z[0] + 2]) square([grille[1] - grille[0], sps30[2] - 4]);
}
color(C_CUT, 0.7) render() intersection() {
    rect(inside, sps_z);
    cut(cut_y) auto_base();
}
color(_d2_ink()) {
    translate([inlets[0] + 1, sps_z[0] + 4.6]) text("inlets", size = $txt * 0.75);
    translate([grille[0] + 1, sps_z[0] + 4.6]) text("outlet grille", size = $txt * 0.75);
}
dashed([hole_x - 3, base_floor], [hole_x + 3, base_floor], dash = 1.0, gap = 0.6, col = C_CUT);
leader([face - 22, auto_base_z0 - 4], [hole_x - 1, base_floor - 0.5], "wire hole to the bay", C_CUT);
leader([duct_in[0] + base_wall + 4, sps_z[1] + 8], [inside[1] - 3, sps_z[0] + 5], "the pocket cuts this from the turn", C_CUT);
dim_h(inside[0], inside[1], sps_z[1] + 5, sps_z[1], str(sps30[0], ", all inside"), C_SPS);
heading("(1) In a pocket cut into the floor's turn: all inside", [face - 24, duct_h + fans_h + 8]);
color(_d2_ink()) translate([face - 24, auto_base_z0 - 14]) {
    text(str("Turned, its ", sps30[0], " along the box, its air face to the duct's middle (-Y, towards you here): Y ", pocket_y[0], " to ", pocket_y[1], "."), size = $txt * 0.8);
    translate([0, -4]) text("Clear of the wires' tube, the fans' posts and the end wall. The pocket takes 2.7 cm3 from the base and holds it.", size = $txt * 0.8);
    translate([0, -8]) text("Its inlets at the back, upstream; its outlet grille and connector at the front, so the air carries its own out.", size = $txt * 0.8);
}

// ---- (2) on the flat floor, standing out past the outlet's face
translate([0, -gap]) {
    others();
    color(C_BOX) cut(cut_y) auto_base();
    color(C_SPS, 0.85) rect(flat, sps_z);
    color([1, 1, 1]) translate([flat[0] + 2, sps_z[0] + 4]) text("SPS30", size = $txt * 0.9, font = "DejaVu Sans:style=Bold");
    dim_h(flat[0], face, sps_z[1] + 4, sps_z[1], str(out, " out"), C_SPS);
    dim_h(flat[0], flat[1], sps_z[1] + 10, sps_z[1], str(sps30[1]), C_SPS);
    dim_v(sps_z[0], sps_z[1], flat[0] - 4, flat[0], str(sps30[2]), C_SPS, right = false);
    dim_h(face, turn_x, auto_base_z0 - 6, base_floor, str("flat floor ", turn_x - face), above = false);
    heading("(2) On the flat floor: out past the outlet's face", [face - 24, duct_h + fans_h + 8]);
    color(_d2_ink()) translate([face - 24, auto_base_z0 - 20]) {
        text(str("The floor is flat for ", turn_x - face, " mm, then turns up into the +X wall on a ", base_turn_r, " mm radius; ", out, " mm of the SPS30 stands out, on a shelf."), size = $txt * 0.8);
        translate([0, -4]) text(str("Either way it blocks ", round(sps30[1] * sps30[2]), " mm2 of the outlet, 14 %, and lies under the +Y fan. Cut at Y ", cut_y, ", seen from -Y."), size = $txt * 0.8);
    }
}

translate([duct_in[0] + 44, auto_base_z0]) {
    axis("X", 0, 10);
    axis("Z", 90, 10);
}
