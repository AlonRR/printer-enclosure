// SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
// SPDX-License-Identifier: CC-BY-SA-4.0
// A remix of LunchBox by GekoPrime (https://www.printables.com/model/468166), CC BY-SA 4.0.

/*
The LunchBox stack as the air sees it, for the airflow simulation in sim/lunchbox-cfd/. The box's frame, mm.
Needs the originals in original/.

  view = "solid"    every solid as one body: the stack with its gaskets, the HEPA frame in its holder, the
                    fans' frames and hubs, the blank. The carbon bed's perforated walls are left out - the
                    simulation takes the whole bed, walls and all, as one porous zone.
  view = "numbers"  nothing drawn: echoes `cfd = [[name, value], ...]`, every zone and plane the case is
                    built from, so the case and this model cannot disagree.
*/
include <lunchbox.scad>
draw_model = false;

view = "solid";
with_insert = true;
hepa_top_sealed = true;   /* the 2.6 mm slot over the HEPA frame closed, as by a strip on its top; false: open, as built */

g = gasket_t;
st = stack_at(g, 0, with_insert);           // the insert's top, the fan section's rim, the lid's underside
fans_rim = st[1];
floor_z = fans_rim - fans_h;
top_z = st[2] + lid_t;

// The fans: 40 x 40 x 20 (Delta EFB0412VHD). Bore and hub are ESTIMATED - typical of a 4020 fan, not measured.
fan_size = 40;
fan_depth = 20;
fan_bore = 38.5;
fan_hub = 21;
fan_xs = [-(fan_slot_hw - bay_w / 2), fan_slot_hw - bay_w / 2];    // the two outer bays
fan_y1 = fan_slot_y1;                       // their own thrust pushes them back against the slot's step
fan_y0 = fan_y1 - fan_depth;
fan_zc = fans_rim - fan_slot_h + fan_size / 2;

// The HEPA frame (furnace_filter.stl, 109.4 x 19 x 73.4) in its holder: on the gasket, pushed back by the
// air against the carbon bed's front wall. Its STL is in its own frame; these move it into the box's.
hepa_frame = [109.4, 19, 73.4];
hepa_y0 = hepa_y1 - hepa_frame[1];
hepa_stl_x = [-30.564, 78.836];                                        // its STL's x range (stl-inspect bounds)
hepa_from_stl = [-(hepa_stl_x[0] + hepa_stl_x[1]) / 2, hepa_y0, 117.244];   // centred in x, front face, bottom on z = 0
hepa_in = [-52.7, 52.7, hepa_y0, hepa_y1, 2.0, 71.4];                  // inside the frame: the paper
// The holder's ceiling - the funnel's underside - is flat at Z = 76.0 from the grid to the carbon bed
// (MEASURED: cuts at x = -30, 0 and 30, 7 Oct 2026). The frame is 73.4 tall, so 2.6 mm of slot runs over it
// the whole width: a way round the paper into the carbon, with almost no resistance.
hepa_ceiling = 76.0;

// The carbon bed's perforated walls: cut out from the cap's top to where the walls turn solid.
bars_cut = [-(hx - lb_wall), hx - lb_wall, hepa_y1 - 0.1, cap_y1 + 0.1, 4.0, 75.9];
carbon = [-(hx - lb_wall), hx - lb_wall, hepa_y1, cap_y1, 4.0, body_h - 4];

sheet_z0 = st[0] - ins_h + grid_t;
sheet = [-cav_hw, cav_hw, cav_y0, cav_y1, sheet_z0, sheet_z0 + sheet_t];

module box6(b) translate([b[0], b[2], b[4]]) cube([b[1] - b[0], b[3] - b[2], b[5] - b[4]]);
module fan_frame(x) translate([x, 0, fan_zc]) {
    difference() {
        translate([-fan_size / 2, fan_y0, -fan_size / 2]) cube([fan_size, fan_depth, fan_size]);
        translate([0, fan_y0 - 1, 0]) rotate([-90, 0, 0]) cylinder(d = fan_bore, h = fan_depth + 2);
    }
    translate([0, fan_y0, 0]) rotate([-90, 0, 0]) cylinder(d = fan_hub, h = fan_depth);
}

module solid() {
    difference() { body_orig(); box6(bars_cut); }
    translate([0, 0, g]) lid_orig();
    translate([0, 0, body_h]) gasket_lid();
    translate(hepa_from_stl) import("original/furnace_filter.stl", convexity = 10);
    if (hepa_top_sealed)
        translate([-hepa_frame[0] / 2, hepa_y0, hepa_frame[2] - eps])
            cube([hepa_frame[0], hepa_frame[1], hepa_ceiling - hepa_frame[2] + 2 * eps]);
    translate([0, 0, -g]) gasket_fans();
    if (with_insert) {
        translate([0, 0, st[0]]) insert();
        translate([0, 0, st[0] - ins_h - g]) gasket_fans();
    }
    translate([0, 0, fans_rim]) { fans_orig(); blank_in_bay(); }
    for (x = fan_xs) fan_frame(x);
    // The lid's two screws fill its holes; left open, the holes would let air round the HEPA paper.
    for (y = lid_screw_ys) translate([0, y, top_z - lid_screw_l]) cylinder(d = 3.2, h = lid_screw_l);
}

if (view == "solid") solid();
else if (view == "numbers") echo(cfd = [
    ["with_insert", with_insert], ["hepa_top_sealed", hepa_top_sealed], ["hepa_ceiling", hepa_ceiling],
    ["box", [-hx, hx, 0, lb_d, floor_z, top_z]],
    ["floor_z", floor_z], ["fans_rim", fans_rim], ["body_top", body_h],
    ["hepa", hepa_in], ["carbon", carbon], ["sheet", with_insert ? sheet : []],
    ["fans", [for (x = fan_xs) [x, fan_zc]]], ["fan_y", [fan_y0, fan_y1]],
    ["fan_r", fan_bore / 2], ["fan_depth", fan_depth],
    ["inlet", [-hx, hx, 0, body_h]], ["outlet", [-hx, hx, floor_z, fans_rim]],
    ["channel", [-(hx - lb_wall), hx - lb_wall, cap_y1, lb_d - lb_wall]],
]);
else assert(false, str("unknown view: ", view));
