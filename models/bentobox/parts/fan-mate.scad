// SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
// SPDX-License-Identifier: CC-BY-NC-SA-4.0
// A remix of BentoBox v2.0 by ThrutheFrame (https://www.printables.com/model/272525), CC BY-NC-SA 4.0.

// parts/fan-mate.scad - THE FANS' PLUG MATE - on hold, not to print, until the fan connector it copies is settled (Alon, 11 Oct 2026). Included by bentobox.scad; not a model on its own.

// The fans' plug mate, in its own frame: the pins along X at Y = 0, standing up from Z = 0, the block's underside;
// the plug's text face towards +Y, its ribs towards -Y. Out from the pins' line: the plug's text face, its ribbed
// face, its ribs' tips; the wall's inside, the key's face and its width; the holes as cut; each plug's X and its
// pocket's half-width; the front wall's inside; the block's ends and its back and front faces; where the grip's ribs
// stand along the plug's end faces, at the faces' quarters; and how much of each wire to bare.
fmp_text = fan_plug_d + fan_plug_hole / 2;
fmp_back = fan_plug[1] - fmp_text;
fmp_ribs = fan_plug_ribs[2] - fmp_text;
fm_wall_y = -(fmp_ribs + fan_mate_play);
fm_key_y = -(fmp_back + fan_mate_play);
fm_key_w = fan_plug_ribs[1] - 2 * fan_mate_play;
fm_core_d = fan_wire[0] + 2 * fdm_hole_comp;
fm_ins_d = fan_wire[1] + 2 * fdm_hole_comp;
fm_xs = [for (i = [0 : fan_mate_n - 1]) (i - (fan_mate_n - 1) / 2) * (fan_plug[0] + fan_mate_gap)];
fm_px = fan_plug[0] / 2 + fan_mate_play;
fm_x0 = min(fm_xs) - fm_px - fan_mate_wall[0];
fm_x1 = max(fm_xs) + fm_px + fan_mate_wall[0];
fm_y0 = fm_wall_y - fan_mate_wall[0];
fm_fy = fmp_text + fan_mate_play;
fm_y1 = fm_fy + fan_mate_wall[0] + fan_mate_front;
fm_grip_y = [for (s = [-1, 1]) let(bk = fmp_back - fan_plug_lip[0]) (fmp_text - bk) / 2 + s * (fmp_text + bk) / 4];
// The insulation stops up the slot's roof, where the roof is as narrow as the insulation; the bared length is rounded
// to half a millimetre, so the pin stands a little over fan_mate_pin.
fm_stop = fan_mate_base[0] - fan_mate_base[1] + (fm_ins_d - fan_wire[1]) / 2;
fm_strip = ceil((fan_mate_base[0] - fm_stop + fan_mate_pin) * 2) / 2;
fmp_plug_lip_l = fan_plug_lip[1];   // the plug's lip's length, drawn: its own, so a check's control can move it alone
fmp_plug_a = fan_plug[0];           // the plug's width, drawn, its own for the same reason

// ------------------------------------------------------------------ the fans' plug mate (Alon, 9 Oct 2026)
// See bentobox.params.scad. Drawn in its own frame (bentobox.layout.scad): the pins along X at Y = 0, the block's
// underside at Z = 0, as it prints. Each wire comes up its slot from below, its insulation stopping where the slot
// ends, so it cannot be pulled out upwards; its bared core goes on up its hole and stands as the pin. Under the block
// each wire bends over into a groove to the back edge: once the block is fixed down, that bend stops a pin being
// pushed down.
module fan_mate_key(x) let(h = fan_mate_base[0], wh = fan_mate_wall[1] - 0.5, d = fm_key_y - fm_wall_y, e = 0.3)
    // its top chamfered at 45 degrees, a lead-in between the ribs, 0.5 mm under the wall's top. It starts e inside
    // the wall, so the chamfer crosses the wall's face: an edge lying in that face leaves sliver facets
    translate([x - fm_key_w / 2, fm_wall_y - e, h - 0.01]) hull() {
        cube([fm_key_w, d + e, wh - d - e + 0.01]);
        cube([fm_key_w, 0.01, wh + 0.01]);
    }
// The grip, as the fan connector's male has it (Alon, 10 Oct 2026: "no spring, friction fit"): round ribs up the
// walls at each plug's ends, from the floor, each standing g into the plug's end face. In plan each is an arc of a
// circle fan_mate_grip[1] across, its ends 0.05 mm short of the wall's face, then straight on into the wall: so its
// outline crosses the face part way along an edge - a corner in the face leaves zero-area facets. Each rib's top leans
// back into the wall at 30 degrees from upright, a lead-in for the plug's edge, and ends inside the wall 0.2 mm under
// its top. Drawn with the wall's face at x = 0, the pocket towards -x.
module fan_mate_grips(g = fan_mate_grip[0])
    let(h = fan_mate_base[0], r = fan_mate_grip[1] / 2, k = fan_mate_play + g, t = h + fan_mate_wall[1] - 0.2,
        lead = (k + 0.1) * sqrt(3), a = acos((r - k + 0.05) / r), ye = r * sin(a),
        plan = [for (i = [0 : 12]) let(u = 180 - a + 2 * a * i / 12) [r - k + r * cos(u), r * sin(u)], [0.3, -ye], [0.3, ye]])
        for (x = fm_xs, s = [-1, 1], y = fm_grip_y) translate([x + s * fm_px, y, 0]) mirror([s < 0 ? 1 : 0, 0, 0]) hull() {
            translate([0, 0, h - 0.01]) linear_extrude(t - lead - h + 0.01) polygon(plan);
            translate([k + 0.1, 0, t - 0.01]) linear_extrude(0.01) polygon(plan);
        }
// The air over the block, in plan: each plug's pocket, and everything in front of the front walls.
module fan_mate_air_2d() {
    for (x = fm_xs) translate([x - fm_px, fm_wall_y]) square([2 * fm_px, fm_fy - fm_wall_y]);
    translate([fm_x0 - 1, fm_fy + fan_mate_wall[0]]) square([fm_x1 - fm_x0 + 2, fan_mate_front + 1]);
}
// The block and its walls - the back one, one at each end, one between the plugs and one in front of each plug's text
// face (Alon, 9 Oct 2026) - are one prism of the whole outline with what is air cut out of it: boxes sharing faces
// would meet in lines of T-junctions. Joined at the corners, the walls stiffen one another, and the grip holds the
// plugs. The mate first had a spring front wall, freed by slits, and a clip on each key over the plug's lip, as the
// fan connector's male did: printed and tried on the male, the front wall as the spring was too weak to press, and
// on the back one the clip snapped off (10 Oct 2026). The groove is a little wider than the slot, so its sides are
// not tangent to the slot's round ends. The slot's roof slopes up at 45 degrees to a ridge between its end pins, so
// no core's hole starts in a bridged layer: on the fan connector's male, a flat roof printed each hole's rim over air
// and closed it (T188, 10 Oct 2026). The roof also leads each core into its hole.
module fan_mate(with_grip = true) let(h = fan_mate_base[0], c = fan_mate_base[1], wh = fan_mate_wall[1], s = 2 * fan_pitch + fm_ins_d + 0.4)
    difference() {
        union() {
            difference() {
                translate([fm_x0, fm_y0, 0]) cube([fm_x1 - fm_x0, fm_y1 - fm_y0, h + wh]);
                translate([0, 0, h]) linear_extrude(wh + 1) fan_mate_air_2d();
            }
            for (x = fm_xs) fan_mate_key(x);
            if (with_grip) fan_mate_grips();
        }
        for (x = fm_xs) {
            for (k = [-1 : 1]) translate([x + k * fan_pitch, 0, h - c - 0.01]) cylinder(d = fm_core_d, h = c + 1, $fn = 16);
            hull() for (k = [-1, 1]) translate([x + k * fan_pitch, 0, 0]) {
                translate([0, 0, -1]) cylinder(d = fm_ins_d, h = h - c + 1, $fn = 24);
                translate([0, 0, h - c]) cylinder(d1 = fm_ins_d, d2 = 0, h = fm_ins_d / 2, $fn = 24);
            }
            translate([x - s / 2, fm_y0 - 1, -1]) cube([s, 1 - fm_y0, fm_ins_d + 1]);
            // the red pin's mark, on the block in front of the front wall: the plug's moulded pin-1 arrow lands over it
            translate([x - fan_pitch, fm_y1 - fan_mate_front / 2, h - 0.4]) linear_extrude(1)
                text("+", size = 1.8, halign = "center", valign = "center");
        }
    }

// The wires' bared cores, standing as the pins: from where the insulation stops to the pins' tips.
module fan_mate_pins() for (x = fm_xs, k = [-1 : 1])
    translate([x + k * fan_pitch, 0, fm_stop]) cylinder(d = fan_wire[0], h = fm_strip, $fn = 16);
