// SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
// SPDX-License-Identifier: CC-BY-NC-SA-4.0
// A remix of BentoBox v2.0 by ThrutheFrame (https://www.printables.com/model/272525), CC BY-NC-SA 4.0.

// assembly/outlet-sensors-top.scad - THE SPS30 IN ITS POCKET, FROM ABOVE: the base cut through the SPS30's middle,
// its pocket, the plug's room and the lead's slot as the model cuts them (parts/bottom.scad), the fans' openings above
// and the bay below in outline. Which way its openings and its connector face, and where its lead goes (D252, Alon,
// 14 Oct 2026). Its rules are Sensirion's, as the air-quality monitor's docs/design.md lists them: the two inlets and
// the outlet grille on one 40.69 x 12.2 face, the connector on the face opposite, near the outlet end.
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

face = -bb_w / 2;                           // the outlet's face
body = [sps30_x[0] - sps30_nub, sps30_x[1] + sps30_nub];   // the SPS30 with its nubs, along X
inlets = [sps30_x[1] - sps30_air[0], sps30_x[1] - sps30_open[0]];   // at the back, upstream...
grille = [sps30_x[0] + sps30_open[1], sps30_x[1] - sps30_air[1]];   // ...the grille at the front, by the outlet
room = [sps30_yy[1] + sps30_fit, duct_in[1]];                       // the plug's room, to the end wall
cut_z = base_floor + sps30[2] / 2;

module rect(x, y) translate([x[0], y[0]]) square([x[1] - x[0], y[1] - y[0]]);
module outline(col) color(col) render() difference() {
    children();
    offset(delta = -$lw) children();
}

// ---- the base, cut through the SPS30's middle; the fans' openings above, and the bay below
color(C_BOX) projection(cut = true) translate([0, 0, -cut_z]) auto_base();
for (y = fan_ys) outline(C_FAINT) translate([0, y]) circle(d = auto_fan_air, $fn = 96);
leader([bb_w / 2 + 6, fan_ys[0] - 2], [17.4, fan_ys[0] - 6.3], "a fan's opening, above", C_FAINT);
outline(C_FAINT) bay2d();
color(C_FAINT) translate([-18, -38]) text("the bay, below: the ESP32", size = $txt * 0.8);

// ---- the SPS30 from above, its label face up: the label face's edge is one of its inlets
color(C_SPS, 0.85) rect(body, sps30_yy);
color([1, 1, 1]) {
    translate([body[0] + 4, sps30_yy[0] + 22]) text("SPS30, label up", size = $txt * 0.9, font = "DejaVu Sans:style=Bold");
    translate([body[0] + 4, sps30_yy[0] + 17]) text("its air face along the bottom edge", size = $txt * 0.75);
}
// its air face: the inlets and the outlet grille, both on the edge that faces the duct's middle (-Y)
color(C_IN) rect(inlets, [sps30_yy[0], sps30_yy[0] + 1.6]);
color(C_OUT) rect(grille, [sps30_yy[0], sps30_yy[0] + 1.6]);
for (x = [inlets[0] + 3, inlets[1] - 3]) {
    color(C_IN) translate([x - $lw / 2, sps30_yy[0] - 9]) square([$lw, 7]);
    arrow_at([x, sps30_yy[0] - 1.6], 90, C_IN);
}
for (x = [grille[0] + 4, (grille[0] + grille[1]) / 2, grille[1] - 4]) {
    color(C_OUT) translate([x - $lw / 2, sps30_yy[0] - 9.6]) square([$lw, 7.6]);
    arrow_at([x, sps30_yy[0] - 10], 270, C_OUT);
}
color(C_IN) translate([inlets[0] + 1, sps30_yy[0] - 14]) text("in: 2 inlets", size = $txt * 0.8, font = "DejaVu Sans:style=Bold");
color(C_OUT) translate([grille[0], sps30_yy[0] - 14]) text("out: the grille", size = $txt * 0.8, font = "DejaVu Sans:style=Bold");

// the duct's own air, from the fans to the outlet: it carries the grille's air away from the inlets
for (y = [-24, -34]) {
    color(_d2_ink()) translate([-10, y - $lw / 2]) square([24, $lw]);
    arrow_at([-11, y], 180);
}
color(_d2_ink()) translate([-10, -30.4]) text("the duct's air, to the outlet", size = $txt * 0.75);

// ---- the connector, on the face opposite the openings, near the outlet end, and its lead down its slot to the bay
color(C_PLUG) rect(sps30_plug_x, [room[0], room[0] + sps30_lead_room]);
color(_d2_ink()) {
    translate([sps30_plug_x[0] + 0.6, sps30_yy[1] + 4]) text("plug", size = $txt * 0.75);
    hull() for (p = [[sps30_plug_x[0] + 5, sps30_yy[1] + 6.5], [sps30_lead[0], sps30_yy[1] + 6.5]]) translate(p) circle(r = 0.35, $fn = 12);
    hull() for (p = [[sps30_lead[0], sps30_yy[1] + 6.5], [sps30_lead[0], sps30_lead_y]]) translate(p) circle(r = 0.35, $fn = 12);
}
outline(C_OUT) hull() for (x = [sps30_lead[0], sps30_lead[1]]) translate([x, sps30_lead_y]) circle(d = sps30_lead[2], $fn = 32);
leader([sps30_lead[1] + 14, sps30_lead_y + 8], [sps30_lead[1] + 1.4, sps30_lead_y + 1], "the lead, down its slot into the bay", C_OUT);

// ---- dimensions and labels
dim_h(body[0], face, sps30_yy[1] + 15, sps30_yy[1], str(sps30_out, " out"), C_SPS);
dim_v(room[0], room[1], sps30_plug_x[0] - 4, sps30_plug_x[0], str(sps30_room), C_SPS, right = false);
leader([auto_conduit[0] + 14, auto_conduit[1] - 10], [auto_conduit[0] + 1, auto_conduit[1] - 2], "the fans' wires' tube", C_FAINT);
color(_d2_ink()) translate([face - 4, -bb_l / 2 + 6]) rotate(90) text("outlet: the air leaves here", size = $txt * 0.8);
heading("The SPS30 in its pocket, from above", [face - 14, bb_l / 2 + 8]);
color(_d2_ink()) translate([face - 14, -bb_l / 2 - 12]) {
    text("Its two inlets and its outlet grille are on one face, the edge facing the duct's middle (-Y). It draws air in at", size = $txt * 0.8);
    translate([0, -4]) text("the inlets, at the back, and blows it out of the grille, at the front; the duct's air then carries that out of the", size = $txt * 0.8);
    translate([0, -8]) text(str("outlet, away from the inlets. In front of them the floor's turn is cut back ", sps30_air_room, " mm, so they face open air."), size = $txt * 0.8);
    translate([0, -12]) text(str("Its connector is on the opposite face, near the outlet end: the plugged lead wants ", sps30_lead_room, " mm there, so it sits towards"), size = $txt * 0.8);
    translate([0, -16]) text(str("the middle, its front ", sps30_out, " mm out past the outlet's face, so its back clears the wires' tube."), size = $txt * 0.8);
}

translate([bb_w / 2 + 10, -bb_l / 2]) {
    axis("X", 0, 10);
    axis("Y", 90, 10);
}
