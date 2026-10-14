// SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
// SPDX-License-Identifier: CC-BY-NC-SA-4.0
// A remix of BentoBox v2.0 by ThrutheFrame (https://www.printables.com/model/272525), CC BY-NC-SA 4.0.

// assembly/outlet-sensors-top.scad - THE SPS30 IN ITS POCKET, FROM ABOVE: the base cut through the SPS30's middle,
// with the pocket and the plug's room taken out, the fans' openings above and the bay below drawn in outline. Which
// way its openings and its connector face, and where its lead goes (D252 (a), Alon, 14 Oct 2026). Its rules are
// Sensirion's, as the air-quality monitor's docs/design.md lists them: the two inlets and the outlet grille on one
// 40.6 x 12.2 face, the connector on the face opposite, near the outlet end. A drawing to decide from: the pocket
// is not in the model yet.
// Not included by bentobox.scad: it includes it. Render from this folder:
//
//   openscad -o ../../../docs/diagrams/bentobox/outlet-sensors-top.png --imgsize=2200,2600 \
//     --camera=0,0,0,0,0,0,250 --viewall --autocenter --projection=ortho outlet-sensors-top.scad

include <../bentobox.scad>
use <../../../scad-tools/lib/draw2d.scad>
draw = "none";

$txt = 2.2;
$lw = 0.18;
$ah = 1.4;
C_BOX = [0.55, 0.66, 0.82];
C_SPS = [0.85, 0.45, 0.10];
C_IN = [0.10, 0.45, 0.75];
C_OUT = [0.80, 0.15, 0.10];
C_PLUG = [0.95, 0.80, 0.55];
C_FAINT = [0.45, 0.45, 0.45];

sps_fit = 0.2;                              // round the SPS30: the air-quality monitor's, tested
cable_room = 10;                            // in front of its connector face, for the plugged lead (the monitor's)
conn = [2.0, 10.5];                         // the plug, along the connector face from the outlet end (the monitor's)
face = -bb_w / 2;                           // the outlet's face
sps_x = [face - 2.2, face - 2.2 + sps30[0]];   // 2.2 out past the face, so its back clears the wires' tube
sps_y = [-1.5, -1.5 + sps30[1]];            // its air face at the low end, to the duct's middle; its connector face at the high end
inlets = [sps_x[1] - sps30_air[0], sps_x[1]];  // at the back, upstream
grille = [sps_x[0], sps_x[1] - sps30_air[1]];  // at the front, by the outlet
plug = [sps_x[0] + conn[0], sps_x[0] + conn[1]];
hole = [-17, 39.5, 3];                      // the lead's hole down into the bay: X, Y, d
cut_z = base_floor + sps30[2] / 2;

module rect(x, y) translate([x[0], y[0]]) square([x[1] - x[0], y[1] - y[0]]);
module outline(col) color(col) render() difference() {
    children();
    offset(delta = -$lw) children();
}

// ---- the base, cut through the SPS30's middle, without the pocket and the plug's room
color(C_BOX) render() difference() {
    projection(cut = true) translate([0, 0, -cut_z]) auto_base();
    offset(delta = sps_fit) rect(sps_x, sps_y);
    rect(plug, [sps_y[1] + sps_fit, sps_y[1] + sps_fit + cable_room]);
}
// the fans' openings above, and the bay below
for (y = fan_ys) outline(C_FAINT) translate([0, y]) circle(d = auto_fan_air, $fn = 96);
leader([bb_w / 2 + 6, fan_ys[0] - 2], [17.4, fan_ys[0] - 6.3], "a fan's opening, above", C_FAINT);
outline(C_FAINT) bay2d();
color(C_FAINT) translate([-18, -38]) text("the bay, below: the ESP32", size = $txt * 0.8);

// ---- the SPS30 from above, its label face up: the label face's edge is one of its inlets
color(C_SPS, 0.85) rect(sps_x, sps_y);
color([1, 1, 1]) {
    translate([sps_x[0] + 4, sps_y[0] + 22]) text("SPS30, label up", size = $txt * 0.9, font = "DejaVu Sans:style=Bold");
    translate([sps_x[0] + 4, sps_y[0] + 17]) text("its air face along the bottom edge", size = $txt * 0.75);
}
// its air face: the inlets and the outlet grille, both on the edge that faces the duct's middle (-Y)
color(C_IN) rect(inlets, [sps_y[0], sps_y[0] + 1.6]);
color(C_OUT) rect(grille, [sps_y[0], sps_y[0] + 1.6]);
for (x = [inlets[0] + 4, inlets[1] - 4]) {
    color(C_IN) translate([x - $lw / 2, sps_y[0] - 9]) square([$lw, 7]);
    arrow_at([x, sps_y[0] - 1.6], 90, C_IN);
}
for (x = [grille[0] + 4, (grille[0] + grille[1]) / 2, grille[1] - 4]) {
    color(C_OUT) translate([x - $lw / 2, sps_y[0] - 9.6]) square([$lw, 7.6]);
    arrow_at([x, sps_y[0] - 10], 270, C_OUT);
}
color(C_IN) translate([inlets[0] + 1, sps_y[0] - 14]) text("in: 2 inlets", size = $txt * 0.8, font = "DejaVu Sans:style=Bold");
color(C_OUT) translate([grille[0], sps_y[0] - 14]) text("out: the grille", size = $txt * 0.8, font = "DejaVu Sans:style=Bold");

// the duct's own air, from the fans to the outlet: it carries the grille's air away from the inlets
for (y = [-24, -34]) {
    color(_d2_ink()) translate([-10, y - $lw / 2]) square([24, $lw]);
    arrow_at([-11, y], 180);
}
color(_d2_ink()) translate([-10, -30.4]) text("the duct's air, to the outlet", size = $txt * 0.75);

// ---- the connector, on the face opposite the openings, near the outlet end, and its lead to the bay
color(C_PLUG) rect(plug, [sps_y[1] + sps_fit, sps_y[1] + sps_fit + cable_room]);
color(_d2_ink()) {
    translate([plug[0] + 0.6, sps_y[1] + 4]) text("plug", size = $txt * 0.75);
    hull() for (p = [[plug[0] + 5, sps_y[1] + 6.5], [hole[0], sps_y[1] + 6.5]]) translate(p) circle(r = 0.35, $fn = 12);
    hull() for (p = [[hole[0], sps_y[1] + 6.5], [hole[0], hole[1]]]) translate(p) circle(r = 0.35, $fn = 12);
}
outline(C_OUT) translate([hole[0], hole[1]]) circle(d = hole[2], $fn = 32);
leader([hole[0] + 18, hole[1] + 6], [hole[0] + 1.6, hole[1]], "the lead, down a hole into the bay", C_OUT);

// ---- dimensions and labels
dim_h(sps_x[0], face, sps_y[1] + 15, sps_y[1], "2.2 out", C_SPS);
dim_v(sps_y[1] + sps_fit, sps_y[1] + sps_fit + cable_room, plug[0] - 4, plug[0], str(cable_room), C_SPS, right = false);
leader([auto_conduit[0] + 14, auto_conduit[1] - 10], [auto_conduit[0] + 1, auto_conduit[1] - 2], "the fans' wires' tube", C_FAINT);
color(_d2_ink()) translate([face - 4, -bb_l / 2 + 6]) rotate(90) text("outlet: the air leaves here", size = $txt * 0.8);
heading("The SPS30 in its pocket, from above", [face - 14, bb_l / 2 + 8]);
color(_d2_ink()) translate([face - 14, -bb_l / 2 - 12]) {
    text("Its two inlets and its outlet grille are on one face, the edge facing the duct's middle (-Y). It draws air in at", size = $txt * 0.8);
    translate([0, -4]) text("the inlets, at the back, and blows it out of the grille, at the front; the duct's air then carries that out of the", size = $txt * 0.8);
    translate([0, -8]) text("outlet, away from the inlets. Its connector is on the opposite face, near the outlet end: the plugged lead needs", size = $txt * 0.8);
    translate([0, -12]) text("about 10 mm there, so the SPS30 sits towards the middle, 2.2 mm out past the outlet's face to clear the tube.", size = $txt * 0.8);
}

translate([bb_w / 2 + 10, -bb_l / 2]) {
    axis("X", 0, 10);
    axis("Y", 90, 10);
}
