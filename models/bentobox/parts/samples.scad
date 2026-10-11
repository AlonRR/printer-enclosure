// SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
// SPDX-License-Identifier: CC-BY-NC-SA-4.0
// A remix of BentoBox v2.0 by ThrutheFrame (https://www.printables.com/model/272525), CC BY-NC-SA 4.0.

// parts/samples.scad - THE SAMPLES AND THE SAMPLE PLATES: the joint sample and its bead, the bottom sample, the nut coupon, the grommet's coupon. Included by bentobox.scad; not a model on its own.

// ------------------------------------------------------------------ the joint sample (D121)
// See bentobox.params.scad. Everything past sample_l in from the +Y end wall, sliced off the sealed parts.
module _sample_end(z0, z1) translate([-50, seal_y - sample_l, z0]) cube([100, tab_tip - seal_y + sample_l + 5, z1 - z0]);
// The carbon housing's top end, standing on its cut, its collar and nut tabs up; the HEPA holder's bottom end, on
// its floor, its tabs' counterbores up. Both laid out along X, Y from 0.
module sample_low() translate([0, sample_l - seal_y, sample_low_h - sst[3]])
    intersection() { carbon_sealed(); _sample_end(sst[3] - sample_low_h, sst[3] + 5); }
module sample_up() translate([0, sample_l - seal_y, -sst[3]])
    intersection() { hepa_sealed(); _sample_end(sst[3] - 1, sst[3] + sample_up_h); }
// A fan nut's pocket as the base has it, open under it: 3 mm of its way up, the seat, and the roof with the screw's
// hole bridged through it - for a nut pulled in with a M3 x 8 from above.
pull_block = [16, 16];
module sample_pull() let(h = 3 + nut_slot_h + nut_roof) difference() {
    linear_extrude(h) offset(r = 2) square(pull_block - [4, 4], center = true);
    pull_frame([0, 0, 0], 3 + nut_slot_h) pull_pocket(3 + eps);
}
// The nut coupon (T181, T182 - Alon, 9 Oct 2026: a tray nut spun in its slot, and a fan nut fell out of its seat
// even pulled up). One block: along the back, five fan-nut seats, numbered 1 to 5 on the top, as the base's -
// pull a nut up into each with an M3 x 8 from the top, take the screw out, and see which holds it; along the front,
// five tray-nut slots, 6 to 10, open at the front face, a 0.8 mm floor under them as in the base - slide a nut in,
// drive an M3 up from below, and see which keeps it from turning. 5 was the base's seat and 6 its slot until 10 Oct.
// 6 and 7 end square, as the base's did; 8 and 9 end in the nut's own shape, so it sits against four walls, its two
// flats and the two faces behind them (Alon's idea), and stops on the screw's axis; 10 narrows to the screw (Alon's
// trapezoid): free at its mouth, tight on the nut's flats where it stops. The fits are on top of fdm_hole_comp, each
// side, as pull_fit and nut_fit are. Tried 10 Oct 2026 (T189): seat 3 and slot 8 set pull_fit and the slots' ends.
// The fits are literals, the coupon as it was printed and tried, so setting pull_fit and nut_fit does not change it.
coupon_pull = [-0.15, -0.1, -0.05, 0, 0.05];
coupon_slot = [[0.15, "square"], [0, "square"], [0.15, "hex"], [0, "hex"], [-0.1, "taper"]];
coupon_taper = [0.15, 4];              // the tapered slot: its fit at its mouth, and the taper's length
nc_n = 5;
nc_pitch = 14;
nc_y = [7, 22];                        // the slots' axes, from the front face, and the seats'
nc_h = 3 + nut_slot_h + nut_roof;      // the seats' way 3 mm, the seat, the roof: as sample_pull's
function nc_w(f) = nut_af + 2 * (fdm_hole_comp + f);
// The coupon's tapered slot, in a slot's frame (slot_frame): narrowing from coupon_taper's fit at the mouth to f on
// the nut's flats. Its square and nut-shaped ends are scad-tools nuts.scad's.
module tapered_slot(f0, out) let(ac = nut_af / cos(30), w0 = nc_w(f0), w1 = nc_w(coupon_taper[0]), x0 = ac / 4, l = coupon_taper[1]) {
    translate([-(ac / 2 + fdm_hole_comp + f0), -w0 / 2, 0]) cube([ac / 2 + fdm_hole_comp + f0 + x0 + eps, w0, nut_slot_h]);
    hull() {
        translate([x0, -w0 / 2, 0]) cube([eps, w0, nut_slot_h]);
        translate([x0 + l, -w1 / 2, 0]) cube([eps, w1, nut_slot_h]);
    }
    translate([x0 + l, -w1 / 2, 0]) cube([out - x0 - l, w1, nut_slot_h]);
}
module nut_coupon() difference() {
    translate([-nc_pitch / 2, 0, 0]) cube([nc_n * nc_pitch + 2, nc_y[1] + 8, nc_h]);
    for (k = [0 : nc_n - 1]) let(x = k * nc_pitch, f = coupon_slot[k][0], end = coupon_slot[k][1]) {
        pull_frame([x, nc_y[1], 0], 3 + nut_slot_h) pull_pocket(3 + eps, coupon_pull[k]);
        translate([x, nc_y[0], -1]) cylinder(d = hole_d, h = nut_floor + 1 + eps);
        slot_frame([x, nc_y[0], 270, 0], nut_floor) {
            if (end == "square") nut_slot(nut_af, nut_slot_h, nc_y[0] + 1, fdm_hole_comp + f);
            else if (end == "hex") nut_slot_hex_end(nut_af, nut_slot_h, nc_y[0] + 1, fdm_hole_comp + f);
            else tapered_slot(f, nc_y[0] + 1);
            translate([0, 0, nut_slot_h]) rotate(90) bridged_hole(nc_w(f), hole_d, nc_h - nut_floor - nut_slot_h + 1, fdm_layer_h, eps);
        }
        for (j = [0, 1]) translate([x + 4.6, nc_y[j], nc_h - 0.4]) linear_extrude(1)
            text(str(k + 1 + nc_n * (1 - j)), size = 3, halign = "center", valign = "center");
    }
}

module joint_sample() {
    w = bb_w + sample_gap;
    translate([-w / 2, 0, 0]) sample_low();
    translate([w / 2, 0, 0]) sample_up();
    translate([0, -pull_block[1] / 2 - sample_gap, 0]) sample_pull();
}
// The bottom sample (A140): the tray's -Y end, with the USB-C board's pocket and its stop, and the base's floor over
// it, with the tray's nut slots - side by side, as they print.
module _bottom_end(z0, z1) translate([-bb_w, -bb_l / 2 - 1, z0]) cube([2 * bb_w, bottom_sample_l + 1, z1 - z0]);
module bottom_sample() let(w = bb_w + sample_gap) {
    translate([-w / 2, 0, -auto_base_z0]) intersection() { auto_tray(); _bottom_end(auto_base_z0 - 1, tray_top + 1); }
    translate([w / 2, 0, -auto_bay_top]) intersection() { auto_base(); _bottom_end(auto_bay_top - 1, auto_bay_top + bottom_sample_h); }
}
// The bead for that end, in TPU, flat: the ring's run past the slice, open at both ends.
module joint_sample_bead() translate([0, sample_l - seal_y, 0]) intersection() { bead_ring(); _sample_end(-1, 10); }

// ------------------------------------------------------------------ the sample plates (T131)
// All the samples, as they print: ASA - the joint sample, the glue frame's or the clamp's sample, the bottom sample and the grommet's
// coupon; TPU - the joint sample's bead and the grommet. Placed by their footprints, measured from
// their renders; scad-check counts the bodies, so two that touched would show.
module samples_asa() {
    joint_sample();                                     // Y -24 .. 39.5
    translate([0, 20, 0]) if (glue) glue_sample(); else clamp_sample();   // Y 54 .. 70
    bottom_sample();                                    // Y -56.4 .. -38.4
    translate([75, 0, 0]) grommet_coupon();
}
// The second ASA plate (10 Oct 2026): the samples not yet tried - the glue sample (T185) and the nut coupon (T189).
// The rest were tried on 9 Oct (T131); the grommet's coupon from that plate was still as drawn then. Its hole's
// entrance is larger now (T184, 11 Oct 2026), and it prints alone as grommet_coupon.
module samples_asa_2() {
    nut_coupon();                                       // X -7 .. 65, Y 0 .. 30
    translate([29, 2, 0]) glue_sample();                // X 8.75 .. 49.25, Y 36.25 .. 52.25
}
module samples_tpu() {
    joint_sample_bead();                                // Y 0 .. 27.2
    translate([0, -10, 0]) grommet_body();              // Y -14.4 .. -5.6
}
