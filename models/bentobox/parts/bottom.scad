// SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
// SPDX-License-Identifier: CC-BY-NC-SA-4.0
// A remix of BentoBox v2.0 by ThrutheFrame (https://www.printables.com/model/272525), CC BY-NC-SA 4.0.

// parts/bottom.scad - THE BOTTOM, after the BentoBox Auto: the base, the bay's tray with the USB-C board's pocket, and the fan section, drawn and sealed. Included by bentobox.scad; not a model on its own.

// ------------------------------------------------------------------ the bottom
// The base and its tray are the remix's own, drawn to the Auto's measurements (bentobox.params.scad); the fan
// section is Strangwooduk's (scripts/tools/bentobox-auto-stl.py writes it from the STEP, with the base and plate this
// remix measured), moved into this frame. The base stands on the tray, the tray on Z = auto_base_z0, and the
// base's top is at duct_h, where the duct's is.

// The USB-C board in its pocket: its front edge against the wall in front of it, as thick as the socket stands past
// it, so the socket's face is the end face; the socket's top usb_play under the base.
usb_c = fdm_hole_comp + usb_play;
usb_pcb_y0 = -bb_l / 2 + usb_socket[2];
usb_pcb_y1 = -bb_l / 2 + usb_board[0];
usb_top = auto_bay_top - usb_play;
usb_axis_z = usb_top - usb_socket[1] / 2;
usb_pcb_z = usb_top - usb_socket[1] - usb_board[2];
usb_notch_w = usb_socket[0] + 2 * usb_c;               // the notch the socket goes through, across...
usb_notch_r = usb_socket[1] / 2 + usb_c;               // ...and the radius of its round ends
usb_pocket = [usb_board[1] + 2 * usb_c, usb_pcb_y0];  // the board's pocket: across, and its front

auto_magnet = [magnet[0] + 0.2, magnet[1] + 0.2];      // the tray's magnets' holes, d and depth

// The Auto's fan section drawn (Alon, 9 Oct 2026: "rebuild all the parts that are not currently scad"), to its STL's
// measurements: the box's outline and inside, its top edge chamfered bb_chamfer outside; the floor auto_floor_t,
// with each fan's opening and its two screws' holes. Its top is the sealed joint's (sealed_part cuts it there), and
// the wires' hole is the grommet's (fans_sealed cuts it).
module fans_drawn() let(z0 = duct_h, z1 = duct_h + fans_h, c = bb_chamfer) difference() {
    hull() {
        translate([0, 0, z0]) linear_extrude(z1 - z0 - c) rrect_c(bb_w, bb_l, bb_r);
        translate([0, 0, z1 - eps]) linear_extrude(eps) rrect_c(bb_w - 2 * c, bb_l - 2 * c, bb_r - c);
    }
    translate([0, 0, z0 + auto_floor_t]) linear_extrude(z1 - z0) inside_offset(0);
    for (y = fan_ys) translate([0, y, z0 - 1]) cylinder(d = auto_fan_air, h = auto_floor_t + 2, $fn = 96);
    for (s = auto_fan_screws) translate([s[0], s[1], z0 - 1]) cylinder(d = auto_fan_hole, h = auto_floor_t + 2);
}
// The fan section as it prints: drawn and sealed, with the bottom; the Auto's own, with the bambu bottom unsealed.
module fans_printed() if (sealed && bottom == "auto") fans_sealed(); else fan_section();

// A nut's slot (scad-tools nuts.scad), from behind the axis out through its mouth, `out` past the axis, its back end
// the nut's own shape (T189, 10 Oct 2026: on the coupon only those ends held the nut still and kept it in)...
module slot(out) nut_slot_hex_end(nut_af, nut_slot_h, out, fdm_hole_comp + nut_fit);
// ...and the screw's hole on up through its roof, l long, as a bridged hole (scad-tools fdm.scad): a channel as
// wide as the hole across the slot, so the first layer is two bridges from side to side; the hole, square, so the
// second is two bridges along the slot over the channel; then the round hole.
module roof_hole(l) translate([0, 0, nut_slot_h]) rotate(90) bridged_hole(nut_slot_w, hole_d, l, fdm_layer_h, eps);
// The fan section's floor openings, carried down into the base: the fans' air.
module fan_air(h, grow = 0) for (y = fan_ys) translate([0, y, duct_h - h]) cylinder(d = auto_fan_air + 2 * grow, h = h + 1);

// A fan screw's post (seamless, Alon 8 Oct): big enough for the nut, and cut back clear of the fans' air (Alon,
// 9 Oct). Its frame: the screw's axis at the origin, X out of the post's wall into the room.
module post_frame(s) translate([s[0], s[1], 0]) rotate(s[3]) children();
// From above: round at its end, its sides running into the wall on fillets; cut back clear of the fans' air, the
// corners there rounded. The fillets are tangent to a line post_blend inside the wall's face, so the two cross at a
// slant; the strip they come off runs 3 mm into the wall.
module post2d(s) offset(r = 1) offset(delta = -1) difference() {
    offset(r = -post_fillet) offset(delta = post_fillet) post_frame(s) {
        circle(r = post_r);
        translate([-auto_post_wall - 3, -post_r]) square([auto_post_wall + 3, 2 * post_r]);
        translate([-auto_post_wall - 3, -post_r - post_fillet - 0.5]) square([3 - post_blend, 2 * (post_r + post_fillet + 0.5)]);
    }
    if (post_clear_air) for (y = fan_ys) translate([0, y]) circle(d = auto_fan_air + 2 * meet);
}
// From the side, out of the wall (X) and up (Y): the post's underside - straight down, then a round into 45
// degrees, which meets the wall's face at post_foot.
function _post_profile() = let(P = post_reach, R = post_round, c = [P - R, post_round_z])
    concat([[-5, post_foot - 5]], [for (a = [-45 : 5 : 0]) c + R * [cos(a), sin(a)]], [[P + 1, post_round_z], [P + 1, duct_h + 1], [-5, duct_h + 1]]);
module fan_post(s) intersection() {
    translate([0, 0, post_foot - 6]) linear_extrude(duct_h - post_foot + 7) post2d(s);
    post_frame(s) rotate([90, 0, 0]) linear_extrude(2 * (post_r + post_fillet + 2), center = true)
        polygon([for (q = _post_profile()) [q[0] - auto_post_wall, q[1]]]);
}

module fan_screw_cut(s) pull_frame(s, pull_top) pull_pocket(pull_seat - pull_bot);
// A tray screw's way in the base: its hole up from the base's bottom face through the floor to its slot, the slot
// out through the end face, and the hole on up through the slot's roof, bridged, to past the tip of the longest
// screw it takes (D213).
module tray_slot_cut(s) {
    translate([s[0], s[1], auto_bay_top - 1]) cylinder(d = hole_d, h = tray_slot_bot - auto_bay_top + 1 + eps);
    slot_frame(s, tray_slot_bot) { slot(s[3]); roof_hole(tray_room_z - tray_slot_top); }
}
// The duct's air: its floor flat from the outlet, then turning up into the +X wall on base_turn_r, tangent to both,
// between the end walls; every edge where these meet rounded by base_fillet. It is a convex core, base_fillet in
// from the air's faces, grown by a ball; the core runs on past the outlet and over the top, so only the inside's
// edges come out round. OpenSCAD's ball has no corner at its poles or on its equator - its rings sit half a step
// off them - so it is scaled until those reach base_fillet: then the flat faces are where they are set.
module duct_core() let(r = base_turn_r - base_fillet, x1 = duct_in[0] - base_fillet, z1 = base_floor + base_fillet)
    rotate([90, 0, 0]) linear_extrude(2 * (duct_in[1] - base_fillet), center = true)
        polygon(concat([[-bb_w, z1]], [for (a = [-90 : 3 : 0]) turn_c + r * [cos(a), sin(a)]], [[x1, duct_h + 20], [-bb_w, duct_h + 20]]));
module duct_air() minkowski() { duct_core(); sphere(r = base_fillet / cos(180 / 32), $fn = 32); }
// The outlet's rim rounded by base_lip_r: a cutter - a square corner less its quarter circle - run along the floor's
// edge, round the fillets into the end walls, and up the end walls' tips. It starts 0.3 mm out in the air, so it
// crosses the duct's faces rather than lying on them.
module lip2d() difference() { translate([-0.3, -0.3]) square(base_lip_r + 0.3); translate([base_lip_r, base_lip_r]) circle(r = base_lip_r, $fn = 32); }
module outlet_lip() let(x0 = -bb_w / 2, y1 = duct_in[1] - base_fillet, z1 = base_floor + base_fillet) {
    translate([x0, 0, base_floor]) rotate([90, 0, 0]) linear_extrude(2 * y1 + 0.02, center = true) mirror([0, 1]) lip2d();
    for (sy = [-1, 1]) {
        translate([x0, sy * y1, z1]) rotate([0, 90, 0]) rotate_extrude(angle = sy * 90, $fn = 64) translate([base_fillet, 0]) lip2d();
        translate([x0, sy * duct_in[1], z1 - 0.01]) linear_extrude(duct_h - z1 + 1) mirror([0, sy < 0 ? 1 : 0]) lip2d();
    }
}
// The wires' tube, from above: round on the hole's axis, standing against the +X wall on fillets into it, as the
// posts do - tangent to a line post_blend inside the wall's face.
module conduit2d() let(r = conduit_wall[0], f = conduit_wall[1]) offset(r = -f) offset(delta = f) {
    translate([auto_conduit[0], auto_conduit[1]]) circle(r = r);
    translate([duct_in[0] + post_blend, auto_conduit[1] - r - f - 0.5]) square([3 - post_blend, 2 * (r + f + 0.5)]);
}
// The base: the duct's walls and floor over the bay's roof, the tube and the posts; the outlet's rim rounded; the
// wires' hole down the tube to the bay, the fans' nut pockets, and the tray's screws' slots.
module auto_base() difference() {
    intersection() {
        union() {
            difference() {
                translate([0, 0, auto_bay_top]) linear_extrude(duct_h - auto_bay_top) rrect_c(bb_w, bb_l, bb_r);
                duct_air();
            }
            translate([0, 0, auto_bay_top]) linear_extrude(duct_h - auto_bay_top) conduit2d();
            for (s = auto_fan_screws) fan_post(s);
        }
        below(duct_h);
    }
    outlet_lip();
    translate([auto_conduit[0], auto_conduit[1], auto_bay_top - 1]) cylinder(d = auto_conduit[2], h = duct_h - auto_bay_top + 2);
    for (s = auto_fan_screws) fan_screw_cut(s);
    for (s = tray_screws) tray_slot_cut(s);
}

// ------------------------------------------------------------------ the bay's tray (Alon, 8-9 Oct 2026)
// The bottom under the bay's roof, a part of its own: the floor, the walls round the bay, the ends' blocks, the
// magnets' holes, and the USB-C board's pocket in the -Y end. It prints on its floor, open at the top.
module tray_outline() rrect_c(bb_w, bb_l, bb_r);
module bay2d() translate([bay_x, 0]) rrect_c(bay_size[0], bay_size[1], bay_size[2]);
// The USB-C board's pocket: the notch the socket goes through, round at its ends and open over its top; the board's
// pocket behind the wall in front of it, from its floor on up, open to the bay - its far edge stops short of it.
module usb_notch2d() hull() {
    for (s = [-1, 1]) translate([usb_x + s * (usb_notch_w / 2 - usb_notch_r), usb_axis_z]) circle(r = usb_notch_r, $fn = 32);
    translate([usb_x - usb_notch_w / 2, usb_axis_z]) square([usb_notch_w, tray_top + 1 - usb_axis_z]);
}
module usb_pocket() {
    translate([0, usb_pcb_y0 + 1, 0]) rotate([90, 0, 0]) linear_extrude(usb_pcb_y0 + 1 + bb_l / 2 + 1) usb_notch2d();
    translate([usb_x - usb_pocket[0] / 2, usb_pocket[1], usb_pcb_z]) cube([usb_pocket[0], -bay_size[1] / 2 + 1 - usb_pocket[1], tray_top + 1 - usb_pcb_z]);
}
// The stop behind the board, on the bay's floor, between the board's pads: up to the board's top and a little more.
module usb_stop_block() translate([usb_x - usb_stop[0] / 2, usb_pcb_y1 + usb_c, auto_seat_z - eps])
    cube([usb_stop[0], usb_stop[1], usb_pcb_z + usb_board[2] + 0.5 - auto_seat_z + eps]);
// A tray screw's way in the tray: its head's counterbore up from the bottom face, and its hole bridged up through
// the counterbore's roof and on through the tray.
module tray_screw_cut(s) translate([s[0], s[1], 0]) {
    translate([0, 0, auto_base_z0 - 1]) cylinder(d = m3_cb[0], h = m3_cb[1] + 1);
    translate([0, 0, tray_head_z]) bridged_hole(m3_cb[0], hole_d, tray_top - tray_head_z + 1, fdm_layer_h, eps);
}
module auto_tray() union() {
    difference() {
        translate([0, 0, auto_base_z0]) linear_extrude(tray_top - auto_base_z0) tray_outline();
        translate([0, 0, auto_seat_z]) linear_extrude(tray_top - auto_seat_z + 1) bay2d();
        usb_pocket();
        for (m = auto_magnets, sy = [-1, 1]) translate([m[0], sy * m[1], auto_base_z0 - 1]) cylinder(d = auto_magnet[0], h = auto_magnet[1] + 1);
        for (s = tray_screws) tray_screw_cut(s);
    }
    usb_stop_block();
}

module fans_sealed() difference() {
    sealed_part(undef, sst[1], duct_h, duct_h + fans_h) if (bottom == "auto") fans_drawn(); else fan_section();
    translate([grommet_x, auto_conduit[1], duct_h]) grommet_hole();
}
