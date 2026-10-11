// SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
// SPDX-License-Identifier: CC-BY-NC-SA-4.0
// A remix of BentoBox v2.0 by ThrutheFrame (https://www.printables.com/model/272525), CC BY-NC-SA 4.0.

// parts/paper-frame.scad - THE FRAME FOR YOUR OWN HEPA PAPER: the glue frame, and the shelved clamp - their values, then their geometry. Included by bentobox.scad; not a model on its own.

// The frame for your own HEPA paper. The ring stands on the HEPA holder's ledge, in its pocket; the paper
// fills it with its folds along Y, and a cap closes each end. Across, the piece holds a whole number of
// pleats: as many as come nearest filling the ring, stretched or squeezed to fill it, as a pleated pack
// will - and the caps' wedges and teeth are spaced to match. Its long edges are cut on a top fold, which
// rests against the ring's wall; or, with paper_flaps, on a bottom fold, so each side keeps half a pleat more
// as a flap whose cut end stands in a slot at the wall's foot.

// The clamp (D127): a cassette, its outline the pocket's, clamp_play in; X across, Y along the folds, Z from its
// bottom face, which stands on the ledge. The paper's bottom face clamp_fold_gap over the lower frame's rim, its
// top as deep again, and the upper frame's band clamp_fold_gap over that.
// The glue frame (hepa_frame = "glue") has the same outline: the paper stands on its rim, its long edges cut on a top
// fold against the side walls, its cut ends against the end walls with clamp_fold_gap for the glue.
cas = [in_w + 2 * meet - 2 * clamp_play, pocket_l + 2 * meet - 2 * clamp_play];
glue = hepa_frame == "glue";
flaps = paper_flaps && !glue;
pack_z = glue ? clamp_rim : clamp_rim + clamp_fold_gap;
pack_top = pack_z + paper_depth;
band_z = pack_top + clamp_fold_gap;
cas_h = band_z + clamp_band;
comb_y = cas[1] / 2 - clamp_blk;                     // each end block's inner face; the combs reach in from it
slot_w = clamp_slot;                                 // the slot the paper sits in, pinched
pack_edge = glue ? cas[0] / 2 - glue_wall[0] - paper_t / 2   // the paper's middle at its long edges, +/- X
          : flaps ? cas[0] / 2 - slot_w / 2 : cas[0] / 2;
pack_halves = flaps ? 1 : 0;                         // the flaps: a half pleat each side
pack_n = max(1, round(2 * pack_edge / paper_pitch) - pack_halves);   // full pleats across
pack_pitch = 2 * pack_edge / (pack_n + pack_halves);
pack_l = glue ? cas[1] - 2 * (glue_wall[1] + clamp_fold_gap)   // the piece's length, along the folds, clear of
             : 2 * (comb_y - clamp_fold_gap);                 // the end walls or the end blocks
// The ledge's opening, cut out with the pocket: hepa_ledge_w inside the walls across, and along to the combs.
open_wl = hepa_full ? [in_w - 2 * hepa_ledge_w, 2 * comb_y] : hepa_open;
// The glue frame: its inside, half across and half along; its rim's opening, the ledge's; and its height.
gf_in = [cas[0] / 2 - glue_wall[0], cas[1] / 2 - glue_wall[1]];
gf_rim = open_wl;
gf_h = pack_top + glue_lip;
// The folds across the piece, from one long edge to the other: the i-th is at fold_x(i), a top fold or a
// bottom one. With flaps, the first and the last are the flaps' cut ends.
fold_last = 2 * (pack_n + pack_halves);
function fold_x(i) = -pack_edge + i * pack_pitch / 2;
function fold_top(i) = (i % 2 == 0) != flaps;
// Seen along the folds, the paper's middle runs from a top fold paper_t / 2 under the pack's top face to a
// bottom fold paper_t / 2 over its bottom, leaning pleat_alpha from upright. Screwed together, the frames leave
// it a slot slot_w wide, centred on that middle, so the side of a wedge or a tooth is the middle moved
// slot_w / (2 cos(alpha)) sideways. A wedge, in a channel open at the top, is wedge_w wide at the top face
// and comes to a point slot_w / (2 sin(alpha)) above the bottom fold's middle - in a narrow pleat,
// millimetres, not the slot's width. A tooth, in a channel open at the bottom, is the same shape upside down.
// Heights here are over the pack's bottom face.
pleat_alpha = atan((pack_pitch / 2) / (paper_depth - paper_t));
// The glue frame's fins: a side's offset across from the paper's middle, and a fin's width at its top.
jig_c = (paper_t / 2 + glue_jig[1]) / cos(pleat_alpha);
jig_top_w = 2 * (pack_pitch / 2 - (glue_jig[0] - paper_t / 2) * tan(pleat_alpha) - jig_c);
wedge_w = 2 * ((paper_depth - paper_t / 2) * tan(pleat_alpha) - slot_w / (2 * cos(pleat_alpha)));   // at the top face
wedge_z0 = paper_t / 2 + slot_w / (2 * sin(pleat_alpha));    // its point
tooth_w = wedge_w;                                           // at the bottom face
tooth_z1 = paper_depth - paper_t / 2 - slot_w / (2 * sin(pleat_alpha));   // its point
// A flap's middle, on the line of a full pleat's wall, and its outer face: its cut end stands on the lower
// frame's rim. Outside it, the upper frame's half wedge runs down from the band to where it is two beads thick;
// inside it, the lower frame's tooth under the first top fold runs the whole length.
flap_foot_z = clamp_rim + paper_t / 2 - pack_z;              // over the pack's bottom face: a little under it
function flap_mid_x(z) = fold_x(0) + (z - paper_t / 2) * tan(pleat_alpha);
flap_off = slot_w / (2 * cos(pleat_alpha));           // the slot's half, across, at a flap
function flap_out_x(z) = flap_mid_x(z) - flap_off;
half_wedge_z0 = paper_t / 2 + (2 * bead + flap_off - slot_w / 2) / tan(pleat_alpha);
// The lower frame's rim along the long sides: from the side to the long tooth's inner flank, at the rim's top.
rim_in = fold_x(1) + tooth_w / 2 + clamp_fold_gap * tan(pleat_alpha);

// The clamp's screws, M2, two at each end, from the upper end block's top into a nut pulled up into a seat in the
// lower one, as the fans' are (scad-tools nuts.scad, pull_nut_pocket); its way open under the block. The halves
// meet at clamp_split; each head sinks in a counterbore. The nut's flats face along the pleats.
small_hole_d = 2 * (small_screw[0] / 2 + fdm_hole_comp);
small_nut_slot_h = up_to_layer(small_nut[1] + 2 * nut_fit);
small_seat_af = small_nut[0] + 2 * (fdm_hole_comp + pull_fit);
small_way_af = small_nut[0] + 2 * (fdm_hole_comp + pull_way_fit);
small_nut_wall = (clamp_blk - small_way_af) / 2;
small_cb = [small_screw[1] + 2 * fdm_hole_comp + head_room, small_screw[2] + head_sink];   // a head's counterbore
clamp_split = up_to_layer(cas_h / 2);
clamp_nut_top = clamp_split - small_nut_roof;           // the seat's roof: the nut pulled up against it
clamp_head_z = cas_h - small_cb[1];                     // where a head bears
clamp_screw = [for (l = small_screw_lengths) if (l >= clamp_head_z - clamp_nut_top + small_nut[1] + screw_tip - 1e-9) l][0];
clamp_screw_y = comb_y + clamp_blk / 2;
clamp_way = clamp_nut_top - small_nut_slot_h + 1;      // each nut's way, down from its seat out through the bottom

// ------------------------------------------------------------------ the clamp for your own HEPA paper (D127)
// See bentobox.params.scad. The cassette in its own frame: X across, Y along the folds, Z up from its bottom face,
// as it stands on the ledge. The lower frame prints as it stands; the upper one upside down, its band on the bed.
module cas2d() offset(delta = -clamp_play) inside_offset(meet);
// Across the folds - X, and up over the pack's bottom face - what fills the paper's channels. A tooth under every
// top fold, from the lower frame's rim up; a wedge over every bottom fold between the edges, from the upper
// frame's band down; outside each flap, a half wedge from the band down to where it is two beads thick.
module tooth_2d(i) let(x = fold_x(i), g = clamp_fold_gap * tan(pleat_alpha))
    polygon([[x - tooth_w / 2 - g, -clamp_fold_gap - eps], [x + tooth_w / 2 + g, -clamp_fold_gap - eps], [x, tooth_z1]]);
module teeth_2d() for (i = [0 : fold_last]) if (fold_top(i)) tooth_2d(i);
module long_teeth_2d() if (flaps) { tooth_2d(1); tooth_2d(fold_last - 1); }
module half_wedge_2d() let(t = paper_depth + clamp_fold_gap + eps) polygon([[-cas[0] / 2 - 1, half_wedge_z0],
    [flap_out_x(half_wedge_z0), half_wedge_z0], [flap_out_x(t), t], [-cas[0] / 2 - 1, t]]);
module half_wedges_2d() if (flaps) for (m = [0, 1]) mirror([m, 0]) half_wedge_2d();
module wedges_2d() {
    for (i = [1 : fold_last - 1]) if (!fold_top(i)) let(x = fold_x(i), g = clamp_fold_gap * tan(pleat_alpha), t = paper_depth + clamp_fold_gap + eps)
        polygon([[x - wedge_w / 2 - g, t], [x + wedge_w / 2 + g, t], [x, wedge_z0]]);
    half_wedges_2d();
}
// A profile across the folds, run along Y from y0 to y1, its heights over the pack's bottom face.
module run_y(y0, y1) translate([0, y1, pack_z]) rotate([90, 0, 0]) linear_extrude(y1 - y0) children();
// The same, from y0 to y_low under the end blocks' split and to y_high over it: what belongs to one frame stops
// clamp_fold_gap short of the other's end block, and runs on into its own.
module run_split(y0, y_low, y_high) {
    intersection() { run_y(y0, y_low) children(); below(clamp_split); }
    intersection() { run_y(y0, y_high) children(); above(clamp_split); }
}
module both_ends() for (s = [0, 1]) mirror([0, s, 0]) children();
module clamp_screws_at() for (sx = [-1, 1], sy = [-1, 1]) translate([sx * clamp_screw_x, sy * clamp_screw_y, 0]) children();
// The lower frame: a rim round its bottom, under the ends' combs and along the long sides out of the long teeth;
// the end blocks' lower halves; the teeth at each end, and the long teeth beside the flaps. Each end block has a
// pull nut's seat for each screw, its way open underneath.
module clamp_low() let(g = clamp_fold_gap, w = clamp_wedge_l) difference() {
    intersection() {
        union() {
            linear_extrude(clamp_rim) difference() { cas2d(); square([-2 * rim_in, 2 * (comb_y - w)], center = true); }
            linear_extrude(clamp_split) difference() { cas2d(); square([100, 2 * comb_y], center = true); }
            both_ends() run_split(comb_y - w, comb_y + 1, comb_y - g) teeth_2d();
            intersection() { run_y(-comb_y - 1, comb_y + 1) long_teeth_2d(); below(clamp_split); }
            intersection() { run_y(-comb_y + g, comb_y - g) long_teeth_2d(); above(clamp_split); }
        }
        linear_extrude(cas_h) cas2d();
    }
    clamp_screws_at() translate([0, 0, clamp_nut_top]) {
        pull_nut_pocket(small_nut[0], small_nut_slot_h, clamp_way, fdm_hole_comp + pull_fit, fdm_hole_comp + pull_way_fit, eps);
        bridged_hole(small_seat_af / cos(30), small_hole_d, clamp_split - clamp_nut_top + 1, fdm_layer_h, eps);
    }
}
// The upper frame: a band round its top, over the ends' combs and along the long sides out to the first top
// fold; the end blocks' upper halves; the wedges at each end, and the half wedges outside the flaps. Each end
// block has each screw's hole, and a counterbore its head sinks in - bridged, since the frame prints upside down.
module clamp_up() let(g = clamp_fold_gap, w = clamp_wedge_l) difference() {
    intersection() {
        union() {
            translate([0, 0, band_z]) linear_extrude(clamp_band) difference() { cas2d(); square([-2 * fold_x(1), 2 * (comb_y - w)], center = true); }
            translate([0, 0, clamp_split]) linear_extrude(cas_h - clamp_split) difference() { cas2d(); square([100, 2 * comb_y], center = true); }
            both_ends() run_split(comb_y - w, comb_y - g, comb_y + 1) wedges_2d();
            intersection() { run_y(-comb_y + g, comb_y - g) half_wedges_2d(); below(clamp_split); }
            intersection() { run_y(-comb_y - 1, comb_y + 1) half_wedges_2d(); above(clamp_split); }
        }
        linear_extrude(cas_h) cas2d();
    }
    clamp_screws_at() {
        translate([0, 0, clamp_split - 1]) cylinder(d = small_hole_d, h = cas_h - clamp_split + 2);
        translate([0, 0, clamp_head_z]) {
            cylinder(d = small_cb[0], h = small_cb[1] + 1);
            mirror([0, 0, 1]) bridged_hole(small_cb[0], small_hole_d, 1, fdm_layer_h, eps);
        }
    }
}
module clamp_cassette() { clamp_low(); clamp_up(); }
// The paper, for pictures and for checking the frames against it - drawn from the paper's own values, not from
// their arithmetic: each flank a strip t thick, round at the folds, between fold lines paper_t / 2 inside the
// pack's faces. With flaps, each flap's cut end stands on the lower frame's rim.
module paper_2d(t = paper_t) {
    pts = [for (i = [0 : fold_last])
        flaps && (i == 0 || i == fold_last)
            ? [fold_x(i) + (i == 0 ? 1 : -1) * (flap_foot_z - paper_t / 2) * tan(pleat_alpha), flap_foot_z]
            : [fold_x(i), fold_top(i) ? paper_depth - paper_t / 2 : paper_t / 2]];
    for (k = [0 : len(pts) - 2]) hull() {
        translate(pts[k]) circle(d = t, $fn = 16);
        translate(pts[k + 1]) circle(d = t, $fn = 16);
    }
}
module paper_pack(t = paper_t, z = 0) translate([0, 0, z]) run_y(-pack_l / 2, pack_l / 2) paper_2d(t);
// The two frames as they print, side by side: the lower standing, the upper turned over onto its band.
module clamp_frames_printing() {
    translate([-cas[0] / 2 - 3, 0, 0]) clamp_low();
    translate([cas[0] / 2 + 3, 0, cas_h]) mirror([0, 0, 1]) clamp_up();
}
// The clamp's sample (D130): one end of both frames, clamp_sample_l of each in from the end, as they print.
clamp_sample_l = 16;
module _clamp_end() translate([-50, cas[1] / 2 - clamp_sample_l, -1]) cube([100, clamp_sample_l + 1, cas_h + 2]);
module clamp_sample() {
    translate([-cas[0] / 2 - 3, 0, 0]) intersection() { clamp_low(); _clamp_end(); }
    translate([cas[0] / 2 + 3, 0, cas_h]) mirror([0, 0, 1]) intersection() { clamp_up(); _clamp_end(); }
}

// ------------------------------------------------------------------ the glue frame for your own HEPA paper (T131)
// Alon, 9 Oct 2026: "make a hot glue version for the hepa". One ASA frame, the clamp's outline: walls glue_lip over
// the paper's top folds, a rim round its bottom on the ledge, open over the ledge's opening. The paper stands on the
// rim, its long edges cut on a top fold against the side walls, its cut ends against the end walls. The glue goes in
// from the top, the dirty side, and that is the only side that needs it: in the end of every channel open at the
// top, at both ends, as the clamp's wedges were, and in a bead across each end and along each long side where the
// top fold meets the wall. The channels open at the bottom end over the rim, which closes them. No fins: every wall
// is solid, two lines or more, the corners at least 1.1 mm. Short fins on the rim at each end (Alon, 9 Oct 2026)
// space the folds as the paper goes in: one up into each channel open at the bottom, glue_jig[1] clear of the
// paper, glue_jig[0] tall - from 1.4 mm wide at the rim to 1 at the top. They stop 0.3 mm short of the rim's
// inner edge, so no face of theirs lies in the rim's.
module jig_fin_2d(i) let(x = fold_x(i), ta = tan(pleat_alpha), w0 = pack_pitch / 2 + (1 + paper_t / 2) * ta - jig_c,
                         w1 = pack_pitch / 2 - (glue_jig[0] - paper_t / 2) * ta - jig_c)
    polygon([[x - w0, -1], [x + w0, -1], [x + w1, glue_jig[0]], [x - w1, glue_jig[0]]]);
module jig_fins_2d() for (i = [1 : fold_last - 1]) if (fold_top(i)) jig_fin_2d(i);
module glue_frame() union() {
    difference() {
        linear_extrude(gf_h) cas2d();
        translate([-gf_in[0], -gf_in[1], clamp_rim]) cube([2 * gf_in[0], 2 * gf_in[1], gf_h]);
        translate([-gf_rim[0] / 2, -gf_rim[1] / 2, -1]) cube([gf_rim[0], gf_rim[1], clamp_rim + 2]);
    }
    both_ends() run_y(gf_rim[1] / 2 + 0.3, gf_in[1] + 0.5) jig_fins_2d();
}
// Its sample: one end, glue_sample_l in from it, as it prints - to glue an offcut in before the whole frame.
glue_sample_l = 16;
module glue_sample() intersection() {
    glue_frame();
    translate([-50, cas[1] / 2 - glue_sample_l, -1]) cube([100, glue_sample_l + 1, gf_h + 2]);
}
