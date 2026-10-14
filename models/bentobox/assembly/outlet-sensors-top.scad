// SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
// SPDX-License-Identifier: CC-BY-NC-SA-4.0
// A remix of BentoBox v2.0 by ThrutheFrame (https://www.printables.com/model/272525), CC BY-NC-SA 4.0.

// assembly/outlet-sensors-top.scad - THE SPS30 IN ITS POCKET, FROM ABOVE: the base cut through the SPS30's middle, its
// pocket and the end wall's slot as the model cuts them (parts/bottom.scad); the tray's stop in front of it, and the
// tray's groove for its lead, under the base, dashed; the fans' openings above and the bay below in outline. Which way
// its openings and its connector face, where its plug and lead go, and what holds it (D252, D255, Alon, 14 Oct 2026).
// Its rules are Sensirion's, as the air-quality monitor's docs/design.md lists them: the two inlets and the outlet
// grille on one 40.69 x 12.2 face, the connector on the face opposite, near the outlet end.
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
C_TRAY = [0.30, 0.30, 0.30];
C_SPS = [0.85, 0.45, 0.10];
C_IN = [0.10, 0.45, 0.75];
C_OUT = [0.80, 0.15, 0.10];
C_PLUG = [0.95, 0.80, 0.55];
C_FAINT = [0.45, 0.45, 0.45];

face = -bb_w / 2;                           // the outlet's face
body = [sps30_x[0] - sps30_nub, sps30_x[1] + sps30_nub];   // the SPS30 with its nubs, along X
inlets = [sps30_x[1] - sps30_air[0], sps30_x[1] - sps30_open[0]];   // at the back, upstream...
grille = [sps30_x[0] + sps30_open[1], sps30_x[1] - sps30_air[1]];   // ...the grille at the front, by the outlet
groove_y = [bay_size[1] / 2 - 4, sps30_slot_y];
lead_x = (sps30_wires_x[0] + sps30_wires_x[1]) / 2;
cut_z = base_floor + sps30[2] / 2;

module rect(x, y) translate([x[0], y[0]]) square([x[1] - x[0], y[1] - y[0]]);
module outline(col) color(col) render() difference() {
    children();
    offset(delta = -$lw) children();
}
module dashed_box(x, y, col) {
    dashed([x[0], y[0]], [x[1], y[0]], col = col);
    dashed([x[1], y[0]], [x[1], y[1]], col = col);
    dashed([x[1], y[1]], [x[0], y[1]], col = col);
    dashed([x[0], y[1]], [x[0], y[0]], col = col);
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

// ---- its plug, in the end wall's slot; the lead down the slot and along the tray's groove into the bay
color(C_PLUG) rect(sps30_plug_x, [sps30_yy[1], sps30_yy[1] + sps30_plug_out + sps30_lead_bend]);
dashed_box(leads_groove_x, groove_y, C_OUT);
color(_d2_ink()) hull() for (y = [groove_y[0] + 1, sps30_yy[1] + sps30_plug_out + sps30_lead_bend - sps30_wire / 2]) translate([lead_x, y]) circle(r = 0.35, $fn = 12);
arrow_at([lead_x, groove_y[0] + 0.6], 270);
leader([bb_w / 2 + 6, sps30_slot_y + 4], [sps30_plug_x[1] + 0.6, sps30_yy[1] + sps30_lead_bend / 2], "its plug, flush, the leads bent down in the end wall's slot - open to the outlet", C_OUT);
leader([bb_w / 2 + 6, groove_y[0] + 2], [leads_groove_x[1] + 0.4, groove_y[0] + 6], "its lead, down the slot and along the tray's groove into the bay", C_OUT);

// ---- the tray's stop, up through the floor's notch, in front of it
color(C_TRAY) rect([face + sps30_stop_in, face + sps30_stop_in + sps30_stop[0]], sps30_stop_y);
leader([face - 22, sps30_stop_y[0] - 6], [face + 0.4, (sps30_stop_y[0] + sps30_stop_y[1]) / 2], "the tray's stop: holds it in", C_TRAY);

// ---- dimensions and labels
dim_h(face, body[0], sps30_yy[0] - 20, sps30_yy[0], str(sps30_in, " in"), C_SPS, above = false);
dim_v(sps30_yy[1], sps30_slot_y, face - 4, face, str(sps30_slot_y - sps30_yy[1], " slot"), C_OUT, right = false);
leader([auto_conduit[0] + 14, auto_conduit[1] - 10], [auto_conduit[0] + 1, auto_conduit[1] - 2], "the fans' wires' tube", C_FAINT);
color(_d2_ink()) translate([face - 4, -bb_l / 2 + 6]) rotate(90) text("outlet: the air leaves here", size = $txt * 0.8);
heading("The SPS30 in its pocket, from above", [face - 14, bb_l / 2 + 8]);
color(_d2_ink()) translate([face - 14, -bb_l / 2 - 12]) {
    text("Its two inlets and its outlet grille are on one face, the edge facing the duct's middle (-Y): in at the back, out", size = $txt * 0.8);
    translate([0, -4]) text(str("at the front, and the duct's air carries that out of the outlet. In front of them the floor's turn is cut back ", sps30_air_room, " mm."), size = $txt * 0.8);
    translate([0, -8]) text(str("Its connector face is ", round(10 * (duct_in[1] - sps30_yy[1])) / 10, " mm off the +Y end wall, two beads clear of the tray's nut slots there; the plug"), size = $txt * 0.8);
    translate([0, -12]) text(str("sits flush, its leads bent down in a slot ", sps30_slot_y - sps30_yy[1], " mm out from that face, open to the outlet, so it"), size = $txt * 0.8);
    translate([0, -16]) text(str("slides in with its lead on, and the lead goes down the slot and along the tray's groove into the bay. Its front is ", sps30_in, " mm"), size = $txt * 0.8);
    translate([0, -20]) text("inside the outlet's face; the tray's stop, up through a notch in the floor's front edge, holds it in.", size = $txt * 0.8);
}

translate([bb_w / 2 + 10, -bb_l / 2]) {
    axis("X", 0, 10);
    axis("Y", 90, 10);
}
