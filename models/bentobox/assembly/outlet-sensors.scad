// SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
// SPDX-License-Identifier: CC-BY-NC-SA-4.0
// A remix of BentoBox v2.0 by ThrutheFrame (https://www.printables.com/model/272525), CC BY-NC-SA 4.0.

// assembly/outlet-sensors.scad - WHERE THE OUTLET'S SENSORS COULD GO: the base's outlet seen from in front (from -X),
// drawn from the model's own values, with the SPS30 in each place it could sit and the SGP41 on an end wall. A
// drawing to decide from (D247, 12 Oct 2026): the mount is not drawn. Seen from in front, +Y is to the LEFT.
// Not included by bentobox.scad: it includes it. Render from this folder:
//
//   openscad -o ../../../docs/diagrams/bentobox/outlet-sensors.png --imgsize=2200,1650 \
//     --camera=0,0,0,0,0,0,250 --viewall --autocenter --projection=ortho outlet-sensors.scad

include <../bentobox.scad>
use <../../../scad-tools/lib/draw2d.scad>
draw = "none";

$txt = 2.2;
$lw = 0.18;
$ah = 1.4;
C_BOX = [0.55, 0.66, 0.82];
C_GAP = [1.0, 1.0, 0.94];
C_SPS = [0.85, 0.45, 0.10];
C_SGP = [0.15, 0.55, 0.30];
C_ASK = [0.80, 0.15, 0.10];

function u(y) = -y;                         // seen from in front, +Y is to the left
end_in = bb_l / 2 - base_wall;              // the end walls' inside faces: the outlet's sides
base_top = duct_h;                          // the fan section's floor: the outlet's top
gap = [2 * end_in, base_top - base_floor];  // the opening, Y and Z
sps_z = [base_floor, base_floor + sps30[2]];
a_y = [end_in - base_fillet, end_in - base_fillet - sps30[0]];   // (a): on the floor, clear of the corner's fillet
b_y = [bb_l / 2, bb_l / 2 + sps30[2]];      // (b): standing against the +Y end, outside
blocked = sps30[0] * sps30[2];
open_area = gap[0] * gap[1] - (4 - PI) * base_fillet * base_fillet / 2;   // less the two fillets at the floor
sgp_z = [base_floor + base_fillet + 4, base_floor + base_fillet + 4 + sgp41[1]];
hole_y = bay_size[1] / 2 - 3;               // a wire hole must land in the bay below: inside its +-41.4

module opening() hull() {
    for (s = [-1, 1]) translate([s * (end_in - base_fillet), base_floor + base_fillet]) circle(r = base_fillet, $fn = 48);
    translate([-end_in, base_floor + base_fillet]) square([2 * end_in, base_top - base_floor - base_fillet]);
}

// ---- the base and the fan section, from in front
color(C_BOX) difference() {
    translate([-bb_l / 2, auto_base_z0]) square([bb_l, base_top + fans_h - auto_base_z0]);
    opening();
}
color(C_GAP) opening();
color(_d2_ink()) for (z = [auto_bay_top, base_top]) translate([-bb_l / 2, z - $lw / 2]) square([bb_l, $lw]);
color(_d2_ink()) {
    translate([-bb_l / 2 + 2, auto_bay_top - 4.5]) text("tray: the bay, under the duct's floor", size = $txt * 0.75);
    translate([-bb_l / 2 + 2, base_top + 3]) text("fan section: the fans blow down into the base", size = $txt * 0.75);
    translate([-end_in + 3, base_top - 5.5]) text("the outlet: the air leaves towards you", size = $txt * 0.75);
}

// ---- (a) the SPS30 lying on the floor at the +Y end, its air face towards the fans
color(C_SPS) translate([u(a_y[0]), sps_z[0]]) square([u(a_y[1]) - u(a_y[0]), sps30[2]]);
color([1, 1, 1]) translate([u(a_y[0]) + 2, sps_z[0] + 3.6]) text("(a) SPS30", size = $txt * 0.9, font = "DejaVu Sans:style=Bold");

// ---- (b) the SPS30 standing against the +Y end wall, outside, its air face at the outlet's edge
color(C_SPS, 0.75) translate([u(b_y[1]), auto_base_z0]) square([sps30[2], sps30[1]]);
color([1, 1, 1]) translate([u(b_y[1]) + sps30[2] / 2 + $txt * 0.35, auto_base_z0 + 12]) rotate(90) text("(b) SPS30", size = $txt * 0.9, font = "DejaVu Sans:style=Bold");

// ---- the SGP41 on the -Y end wall, inside, its sensor facing across the stream
color(C_SGP) translate([u(-end_in) - sgp41[2], sgp_z[0]]) square([sgp41[2], sgp41[1]]);

// ---- the wire hole: through the duct's floor, into the bay, at the -Y end
dashed([u(-hole_y) - 3, base_floor], [u(-hole_y) + 3, base_floor], dash = 1.0, gap = 0.6, col = C_ASK);

// ---- dimensions
dim_h(u(end_in), u(-end_in), base_floor - 9, base_floor, str("the outlet ", gap[0], " wide"), above = false);
dim_v(base_floor, base_top, bb_l / 2 + 22, end_in, str(gap[1], " tall"));
dim_h(u(a_y[0]), u(a_y[1]), sps_z[1] + 3, sps_z[1], str(sps30[0]), C_SPS);
dim_v(sps_z[0], sps_z[1], u(a_y[1]) + 3, u(a_y[1]), str(sps30[2]), C_SPS);
dim_v(auto_base_z0, auto_base_z0 + sps30[1], u(b_y[1]) - 4, u(b_y[1]), str(sps30[1]), C_SPS, right = false);
dim_h(u(b_y[1]), u(b_y[0]), auto_base_z0 + sps30[1] + 3, auto_base_z0 + sps30[1], str(sps30[2]), C_SPS);

leader([u(-end_in) + 12, sgp_z[0] - 12], [u(-end_in) - sgp41[2] / 2, sgp_z[0] + 1], "SGP41, on the -Y end wall", C_SGP);
leader([u(-hole_y) - 20, base_floor - 22], [u(-hole_y), base_floor - 0.5], str("wire hole into the bay: |Y| under ", bay_size[1] / 2), C_ASK);

// ---- what each costs
color(_d2_ink()) translate([-bb_l / 2 - 16, -30]) {
    text(str("(a) inside, on the floor: it blocks ", round(blocked), " mm2, ", round(100 * blocked / open_area), " % of the outlet; it reads the air after the carbon, undiluted"), size = $txt * 0.8);
    translate([0, -4]) text("(b) outside, against the end wall: it blocks nothing; it reads the edge of the outlet's air, mixed with the room's; the box is 12.2 mm longer there", size = $txt * 0.8);
    translate([0, -8]) text("The SPS30 cannot stand in the outlet: its 40.6 mm face is taller than the 36 mm opening. Under the outlet there is 12.5 mm, under the air, not in it.", size = $txt * 0.8);
    translate([0, -12]) text("Nor between the fans: the space there is 20 x 40.8 x 31.6 mm (14 Oct). Its 5 V comes from the ESP32's step-down in the bay (D249).", size = $txt * 0.8);
    translate([0, -16]) text("(a), Alon, 14 Oct (D247). But the floor is flat for only 19.8 of its 40.6 depth: outlet-sensors-side.png has how it can lie there (D252).", size = $txt * 0.8);
    translate([0, -20]) text("Not settled: how it lies (D252), and which end (Q248).", size = $txt * 0.8, font = "DejaVu Sans:style=Bold");
}
heading("The outlet's sensors: where they could go - from in front (-X)", [-bb_l / 2 - 16, base_top + fans_h + 8]);

translate([bb_l / 2 + 30, auto_base_z0 - 26]) {
    axis("", 180, 10);
    axis("Z", 90, 10);
    color(_d2_ink()) translate([-10 - 2.5 - $txt * 0.8, -$txt * 0.4]) text("Y", size = $txt, font = "DejaVu Sans:style=Bold");
}
