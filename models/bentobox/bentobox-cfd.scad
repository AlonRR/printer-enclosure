// SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
// SPDX-License-Identifier: CC-BY-NC-SA-4.0
// A remix of BentoBox v2.0 by ThrutheFrame (https://www.printables.com/model/272525), CC BY-NC-SA 4.0.

/*
The BentoBox stack as the air sees it, for the airflow simulation in sim/bentobox-cfd/. The box's frame, mm.
Needs the originals in original/.

  view = "solid"    every solid as one body: the duct, the fan case with the fans' frames and hubs, the
                    section if with_section, the carbon housing with the C-MAG standing in it, the HEPA
                    holder, the cover's frame.
  view = "numbers"  nothing drawn: echoes `cfd = [[name, value], ...]`, every zone and plane the case is
                    built from, so the case and this model cannot disagree.

What is left out or closed, and why:
- The C-MAG's grills: the slicer makes them a honeycomb of a solid plate, mostly open. Left out.
- The cover's pattern: bars 1.2 to 2.4 mm wide, thinner than a cell. Left out; the window is open. The
  hemp pattern is 60 % open, the Voronoi 74 % (cut at mid-thickness), and at well under 1 m/s either costs
  well under 1 Pa.
- The C-MAG's 0.4 mm clearance in its housing: closed. Its walls stand on the housing's floor all round the
  floor's two openings, so air down that clearance meets the floor; a cell is five times wider than it.
- The HEPA cartridge: its pack fills the pocket above the ledge as one porous zone. The ledge under its
  edges leaves 78 x 36.8 mm open below it, and the pleats let no air sideways.
*/
include <bentobox.scad>
draw_model = false;

view = "solid";
with_section = true;

st = stack(with_section);
fans_z = st[0]; sec_z = st[1]; carbon_z = st[2]; hepa_z = st[3]; top_z = st[4];

// The fans: 40 x 40 x 20 (Delta EFB0412VHD), standing on the fan case's floor, blowing down. Bore and hub
// are ESTIMATED - typical of a 4020 fan, not measured.
fan_size = 40;
fan_depth = 20;
fan_bore = 38.5;
fan_hub = 21;
fan_z0 = fans_z + fans_floor;

module box6(b) translate([b[0], b[2], b[4]]) cube([b[1] - b[0], b[3] - b[2], b[5] - b[4]]);
module fan_frame(y) translate([0, y, fan_z0]) {
    difference() {
        translate([-fan_size / 2, -fan_size / 2, 0]) cube([fan_size, fan_size, fan_depth]);
        translate([0, 0, -1]) cylinder(d = fan_bore, h = fan_depth + 2);
    }
    cylinder(d = fan_hub, h = fan_depth);
}

cm_x = cmag_in[1] / 2;     // the C-MAG's inside, standing: X +/-18...
cm_y = cmag_in[0] / 2;     // ...Y +/-48
cmag_bottom = carbon_z + cmag_z0;
carbon_layers = [for (b = cmag_layers) [-cm_x, cm_x, -cm_y, cm_y, cmag_bottom + b, cmag_bottom + b + cmag_layer]];

hepa_zone = [-in_w / 2, in_w / 2, -(hepa_cart[0] + 2) / 2, (hepa_cart[0] + 2) / 2,
             hepa_z + hepa_ledge, hepa_z + hepa_ledge + hepa_cart[2]];
sheet_zone = [-in_w / 2, in_w / 2, -in_l / 2, in_l / 2, sec_z + grid_t, sec_z + grid_t + sheet_t];

module solid() {
    orig(duct_stl);
    orig(fans_stl);
    for (y = fan_ys) fan_frame(y);
    if (with_section) translate([0, 0, sec_z]) section();
    dz = carbon_z - sec_z;
    orig(carbon_stl, dz);
    cmag_standing(cmag_bottom);
    // The clearance round the C-MAG, closed: from the housing's inside to the C-MAG's.
    translate([0, 0, cmag_bottom]) linear_extrude(cmag[0])
        difference() { inside_offset(eps); square([2 * cm_x, 2 * cm_y], center = true); }
    orig(hepa_stl, dz);
    difference() {
        orig(cover_stl, dz);
        translate([-cover_win[0], -cover_win[1], hepa_z]) cube([2 * cover_win[0], 2 * cover_win[1], 100]);
    }
}

if (view == "solid") solid();
else if (view == "numbers") echo(cfd = [
    ["with_section", with_section],
    ["box", [-bb_w / 2, bb_w / 2, -bb_l / 2, bb_l / 2, 0, top_z]],
    ["fans_z", fans_z], ["sec_z", sec_z], ["carbon_z", carbon_z], ["hepa_z", hepa_z], ["top_z", top_z],
    ["hepa", hepa_zone], ["hepa_face", [-18.4, 18.4, -39, 39]],
    ["carbon", carbon_layers], ["carbon_layer", cmag_layer], ["cmag_in", [2 * cm_x, 2 * cm_y]],
    ["sheet", with_section ? sheet_zone : []],
    ["fans", [for (y = fan_ys) [0, y]]], ["fan_z", [fan_z0, fan_z0 + fan_depth]],
    ["fan_r", fan_bore / 2], ["fan_depth", fan_depth],
    ["inlet", [-cover_win[0], cover_win[0], -cover_win[1], cover_win[1], top_z - 2.2]],
    ["outlet", [-bb_w / 2, duct_out[0], duct_out[1], duct_out[2], duct_out[3]]],
    ["below_hepa", hepa_z + hepa_ledge / 2], ["carbon_floor", carbon_z + carbon_floor / 2],
    ["fan_floor", fans_z + fans_floor / 2],
]);
else if (view != "none") assert(false, str("unknown view: ", view));   // "none": for a file that includes this one
