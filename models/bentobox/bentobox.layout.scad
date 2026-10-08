// SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
// SPDX-License-Identifier: CC-BY-NC-SA-4.0
// A remix of BentoBox v2.0 by ThrutheFrame (https://www.printables.com/model/272525), CC BY-NC-SA 4.0.

// What follows from bentobox.params.scad: the section's heights, where every part of the stack stands, and
// the rules as asserts (impossible) and warnings (builds, but compromised).
include <bentobox.params.scad>

eps = 0.01;
bead = fdm_extrusion_w;
perim3 = 3 * fdm_extrusion_w;

// The section, face to face: the grid, the sheet, the air above it. Its tongue stands above that.
sec_h = grid_t + sheet_t + plenum_h;
ledge_w = ledge_beads * bead;
rib_w = grid_beads * bead;

// The stack, bottom up: the Z of each part's bottom face, with the section or without. Sealed, an original is cut
// `meet` inside its own face at each sealed joint (bentobox.scad, sealed joints) - a lower part's top down, an upper
// part's floor up - and everything over the cut stands that much lower; the section's own faces are exact. The
// airflow simulation asks for the originals' stack.
function stack(with_section, seal = false) = let(
    drop = seal ? meet : 0,
    fans_z = duct_h,
    sec_z = fans_z + fans_h - drop,
    carbon_z = sec_z + (with_section ? sec_h : 0),
    hepa_z = carbon_z + carbon_h - 2 * drop
) [fans_z, sec_z, carbon_z, hepa_z, hepa_z + hepa_h - drop + cover_top];
// [fan case, section, carbon housing, HEPA holder, the cover's top]

// The C-MAG's three trays, standing: each tray's pellets fall onto the grill below them and spread over the
// whole of the C-MAG's inside. Lying open, a tray between two grills is (spacing - grill) long and the
// inside's W - 4 wide; standing, the same pellets cover (W - 4) x (T - 4). The ribs that hold the grills,
// and the corners' fillets, take about 4 % of a tray either way, and cancel to well under 0.1 mm.
cmag_in = [cmag[1] - 4, cmag[2] - 4];                          // W x T inside its walls
cmag_tray = cmag_grills[1] - cmag_grills[0] - cmag_grill_t;    // a tray's length between two grills
cmag_layer = cmag_tray * cmag_fill / cmag_in[1];               // its pellets' depth, standing
cmag_z0 = carbon_floor;                                         // the C-MAG's bottom, on the housing's floor
// Each layer's bottom: the top face of the grill under it, from the C-MAG's bottom.
cmag_layers = [for (i = [0 : 2]) cmag_grills[i] + cmag_grill_t / 2];

// The frame for your own HEPA paper. The ring stands on the HEPA holder's ledge, in its pocket; the paper
// fills it with its folds along Y, and a cap closes each end. Across, the piece holds a whole number of
// pleats: as many as come nearest filling the ring, stretched or squeezed to fill it, as a pleated pack
// will - and the caps' wedges and teeth are spaced to match. Its long edges are cut on a top fold, which
// rests against the ring's wall; or, with paper_flaps, on a bottom fold, so each side keeps half a pleat more
// as a flap whose cut end stands in a slot at the wall's foot.
ring_wall = ring_beads * bead;
// The HEPA holder's pocket and its ledge's opening: the original's, or cut out to the whole inside (hepa_full),
// its ledge then cut `meet` under the original's.
pocket_l = hepa_full ? in_l : hepa_pocket_l;
ledge_top = hepa_ledge - (hepa_full ? meet : 0);             // over the original's floor
// The ring's square corners stand ring_play clear of the pocket's corners, which are round once it is cut out.
pocket_r = in_r + meet;
ring_out = let(x = in_w / 2 - ring_play, c = [in_w / 2 + meet - pocket_r, in_l / 2 + meet - pocket_r])
    [2 * x, hepa_full ? 2 * (c[1] + sqrt(pow(pocket_r - ring_play, 2) - pow(x - c[0], 2))) : pocket_l - 2 * ring_play];   // X, Y
ring_in = ring_out - 2 * [ring_wall, ring_wall];
// The ledge's opening, cut out with the pocket: hepa_ledge_w inside the walls across, and along to 0.2 inside
// the ring, which stands on the ledge at its ends.
open_wl = hepa_full ? [in_w - 2 * hepa_ledge_w, ring_in[1] - 0.4] : hepa_open;
ring_h = paper_depth;
slot_w = cap_teeth_below || paper_flaps ? paper_t + slot_play : paper_t;   // a slot the paper sits in
pack_edge = paper_flaps ? ring_in[0] / 2 - slot_w / 2 : ring_in[0] / 2;   // the paper's middle at its long edges, +/- X
pack_halves = paper_flaps ? 1 : 0;                   // the flaps: a half pleat each side
pack_n = max(1, round(2 * pack_edge / paper_pitch) - pack_halves);   // full pleats across
pack_pitch = 2 * pack_edge / (pack_n + pack_halves);
pack_l = ring_in[1] - 2 * cap_plate;                 // the piece's length, along the folds
// The folds across the piece, from one long edge to the other: the i-th is at fold_x(i), a top fold or a
// bottom one. With flaps, the first and the last are the flaps' cut ends, at the walls' feet.
fold_last = 2 * (pack_n + pack_halves);
function fold_x(i) = -pack_edge + i * pack_pitch / 2;
function fold_top(i) = (i % 2 == 0) != paper_flaps;
// Seen along the folds, the paper's middle runs from a top fold paper_t / 2 under the pack's top face to a
// bottom fold paper_t / 2 over its bottom, leaning pleat_alpha from upright. The paper sits in a slot
// slot_w wide, centred on that middle, so the side of a wedge or a tooth is the middle moved
// slot_w / (2 cos(alpha)) sideways. A wedge, in a channel open at the top, is wedge_w wide at the top face
// and comes to a point slot_w / (2 sin(alpha)) above the bottom fold's middle - in a narrow pleat,
// millimetres, not the slot's width. A tooth, in a channel open at the bottom, is the same shape upside down.
pleat_alpha = atan((pack_pitch / 2) / (paper_depth - paper_t));
wedge_w = 2 * ((paper_depth - paper_t / 2) * tan(pleat_alpha) - slot_w / (2 * cos(pleat_alpha)));   // at the top face
wedge_z0 = paper_t / 2 + slot_w / (2 * sin(pleat_alpha));    // its point, above the pack's bottom face
tooth_w = 2 * ((paper_depth - paper_t / 2) * tan(pleat_alpha) - slot_w / (2 * cos(pleat_alpha)));   // at the bottom face
tooth_z1 = paper_depth - paper_t / 2 - slot_w / (2 * sin(pleat_alpha));   // its point, above the pack's bottom face
// With flaps: the strip on the left wall's foot, seen along the folds. A floor two layers thick closes the
// slot's bottom, and the flap's cut end stands on it; the strip's face is the slot's clean side, parallel to
// the flap. strip_x(z) is that face, ring_strip_beads further in the strip's other side. The caps' teeth are
// cut back strip_notch clear of it, at the ends, where both stand in the same channel.
strip_floor = 2 * fdm_layer_h;
strip_w = ring_strip_beads * bead;
function strip_x(z) = -pack_edge + (z - paper_t / 2) * tan(pleat_alpha) + slot_w / (2 * cos(pleat_alpha));
strip_notch = slot_play / 2;
// The dirty sliver between each flap and its wall, which the caps close with a half wedge: wide at the top,
// coming to nothing near the bottom, where the flap meets the wall.
half_wedge_w = strip_x(ring_h) - slot_w / cos(pleat_alpha) + ring_in[0] / 2;   // at the top face
half_wedge_z0 = paper_t / 2 + slot_w * (1 / cos(pleat_alpha) - 1) / (2 * tan(pleat_alpha));   // where it meets the wall

// The Auto's bottom, its heat-set inserts made nuts. A plate screw's nut lies flat in a slot that opens one way,
// its flats against the slot's sides; its back corner stops against the slot's closed end with the nut on the
// screw's axis. The screw comes up through the plate into it and pulls it down onto the slot's floor. A fan
// screw's nut is a pull nut (D123, D124): it goes up a hex pocket under its post, on the screw's axis and open
// downwards, into a tight seat under the roof, which the screw, down through the fan, the fan section's floor and the
// base's top, pulls it into. Each screw is the shortest of screw_lengths that stands screw_tip out.
function up_to_layer(z) = ceil(z / fdm_layer_h - 1e-9) * fdm_layer_h;
function screw_for(need) = [for (l = screw_lengths) if (l >= need - 1e-9) l][0];
hole_d = 2 * (screw_d / 2 + fdm_hole_comp);
nut_ac = nut_af / cos(30);
nut_slot_w = nut_af + 2 * (fdm_hole_comp + nut_fit);
nut_slot_h = up_to_layer(nut_h + 2 * nut_fit);
pull_af = nut_af + 2 * (fdm_hole_comp + pull_fit);    // a fan nut's seat, across its flats: tight
pull_ac = pull_af / cos(30);
pull_top = duct_h - nut_roof;                          // ...its roof, which the nut is pulled up against
pull_seat = pull_top - nut_slot_h;                     // ...and its bottom; under it, the pocket runs on, a little looser
pull_way_ac = (nut_af + 2 * (fdm_hole_comp + pull_way_fit)) / cos(30);
post_r = pull_way_ac / 2 + post_beads * bead;          // the post round the pocket
post_reach = auto_post_wall + post_r;                  // how far it stands out of its wall
pull_bot = post_foot + pull_rise;                      // the pocket's mouth, where the nut slides in under the post
// The post's underside, out from its wall, at height z: straight down, then a round into 45 degrees to the foot.
post_round_z = post_reach - post_round + post_foot + post_round * sqrt(2);   // the round's centre, and its top
fan_head_z = duct_h + auto_floor_t + fan_t;            // a fan screw's head, on the fan's top flange
fan_screw = screw_for(fan_t + auto_floor_t + nut_roof + nut_h + screw_tip);
fan_tip_z = fan_head_z - fan_screw;
// A plate screw comes up through a counterbore in the plate, its head head_sink inside the base's bottom face, the
// counterbore in a lobe that rises into a pocket in the base; its nut's slot is over the pocket.
plate_t = auto_seat_z - auto_base_z0;                  // the plate: it fills its recess
plate_cb = [plate_head[0] + 2 * fdm_hole_comp + head_room, plate_head[1] + head_sink];   // a head's counterbore, d and depth
plate_head_z = auto_base_z0 + plate_cb[1];             // where a head bears, up in its lobe
lobe_d = plate_cb[0] + 2 * perim3;
lobe_top = plate_head_z + lobe_cap;
pocket_d = lobe_d + 2 * lobe_play;
pocket_top = lobe_top + lobe_play;
plate_slot_bot = pocket_top + nut_floor;
plate_slot_top = plate_slot_bot + nut_slot_h;
plate_screw = screw_for(plate_slot_bot + nut_h + screw_tip - plate_head_z);
plate_tip_z = plate_head_z + plate_screw;

assert(!is_undef(fan_screw) && !is_undef(plate_screw), "no screw in screw_lengths is long enough");
assert(plate_tip_z + 0.5 < auto_plate_room - 2 * fdm_layer_h, "a plate screw's hole breaks into the duct over it");
assert(head_sink >= 0, "a plate screw's head stands out of the base's bottom face");
assert(post_round_z < pull_seat, "a fan nut's seat must stand in its post's straight part, over the underside's round");
assert(fan_tip_z > pull_bot && fan_tip_z < pull_top - nut_h - screw_tip + 1e-9, "a fan screw's tip must stand out of its nut, inside the pocket");
assert(bottom == "auto" || bottom == "bambu", str("unknown bottom: ", bottom));
// How far a hex reaches towards theta, ac across its corners, a flat facing `flat`.
function hex_reach(theta, flat, ac) = let(d = ((theta - flat) % 60 + 60) % 60) ac / 2 * cos(30 - min(d, 60 - d));
// The walls a fan nut's pocket keeps: to the fans' air, which the post is cut back from, and to its wall's face.
pull_air_wall = min([for (s = auto_fan_screws) let(f = [0, abs(s[1] - fan_ys[0]) < abs(s[1] - fan_ys[1]) ? fan_ys[0] : fan_ys[1]])
    norm([s[0], s[1]] - f) - hex_reach(atan2(f[1] - s[1], f[0] - s[0]), s[2], pull_way_ac) - auto_fan_air / 2 - meet]);
pull_face_gap = min([for (s = auto_fan_screws) auto_post_wall - hex_reach(s[3] + 180, s[2], pull_way_ac)]);

// The sealed joints. Across a wall, out from the inside's outline: the groove's inner wall, the groove, a land, and
// the collar's base, which is collar_top + collar_h in from the outside; the upper part's bottom edge is cut back
// collar_play further, at 45 degrees, so it sits in the collar.
wall = (bb_w - in_w) / 2;
seal_groove = [seal_bead[0] + 2 * bead_side, seal_bead[1] * (1 - bead_squeeze)];   // its width and depth
seal_gc = seal_inner + seal_groove[0] / 2;                               // its middle, out from the inside's outline
collar_base = collar_top + collar_h;                                     // the collar at its foot, in from the outside
chamfer_in = collar_base + collar_play;                                  // the upper part's bottom edge, in from the outside
seal_ring = [[for (sx = [1, -1], sy = [1, -1]) [sx * (in_w / 2 + seal_gc), sx * sy * (in_l / 2 + seal_gc)]], in_r + seal_gc];
// The sealed parts' outline, `meet` inside the originals': its side faces at +-seal_x, its end walls at +-seal_y,
// its corners seal_r round [+-seal_xc, +-seal_yc]. The tabs, at the corners: the screw tab_out past the original's
// end wall, its boss tangent to the side face; the outline runs up the side face onto the boss, round it to tab_a0,
// and down the parabola y = seal_y + tab_c (x - tab_x0)^2 into the end wall, tangent to both.
seal_x = bb_w / 2 - meet;
seal_y = bb_l / 2 - meet;
seal_r = bb_r - meet;
seal_xc = bb_w / 2 - bb_r;
seal_yc = bb_l / 2 - bb_r;
tab_sc = [seal_x - tab_boss_r, bb_l / 2 + tab_out];
tab_tip = tab_sc[1] + tab_boss_r;                                         // how far out a tab reaches
tab_p = tab_sc + tab_boss_r * [cos(tab_a0), sin(tab_a0)];
tab_m = -cos(tab_a0) / sin(tab_a0);                                      // the round end's slope there
tab_x0 = tab_p[0] - 2 * (tab_p[1] - seal_y) / tab_m;
tab_c = tab_m / (2 * (tab_p[0] - tab_x0));
tab_zone_y = seal_yc - 1;                                                 // a tab's zone: X past tab_x0, Y past this
// Under a nut's tab, a bracket: its face from tab_blend inside the end wall at its foot out to tab_blend past the
// tab's tip, a cubic in the height, 45 degrees at the tab (bentobox.scad, bracket_f).
bracket_y0 = seal_y - tab_blend;
bracket_l = tab_tip + tab_blend - bracket_y0;
bracket_h = 3 * bracket_l;
tab_upper_h = tab_upper_t + plate_cb[1];                                 // an upper part's tab, its screw's head sunk
tab_screws = [for (sx = [-1, 1], sy = [-1, 1]) [sx * tab_sc[0], sy * tab_sc[1], sy > 0 ? 90 : 270]];
// The screws: through the HEPA holder's tab into the carbon housing's nut; and through the carbon housing's tab and
// the section's pillar into the fan section's nut. Each nut sits in the middle of its tab's height, pulled up
// against its slot's roof.
seal_slot_bot = -tab_lower_t / 2 - nut_slot_h / 2;                      // a nut's slot, below the joint's face
j3_screw = screw_for(tab_upper_t - (seal_slot_bot + nut_slot_h) + nut_h + screw_tip);
j12_screw = screw_for(tab_upper_t + sec_h - (seal_slot_bot + nut_slot_h) + nut_h + screw_tip);

assert(seal_inner + seal_groove[0] + bead_land <= wall - meet - chamfer_in + 1e-9,
    str("the groove, ", seal_groove[0], " mm, does not fit between the inside and the collar"));
assert(seal_bead[1] > seal_groove[1], "the bead must stand proud of its groove");
assert(tab_x0 > 0 && tab_x0 < seal_xc, "the tab's parabola must leave the end wall's straight, between the middle and the corner");
assert(tab_corner_t[0] >= 0 && tab_corner_t[0] < tab_corner_t[1] && tab_corner_t[1] <= 1, "tab_corner_t: two fractions of a bracket's height, rising");
// A bracket's face rises at most this steeply, dy/dz: 1 at the tab, and while it fills the corner, the corner's
// smoothstep at its steepest over the cubic at its top: 1 or under, so nowhere overhangs more than 45 degrees.
bracket_slope = max(3 * bracket_l, (seal_r - tab_blend + 0.5) * 1.5 / (tab_corner_t[1] - tab_corner_t[0])
    + 3 * bracket_l * pow(tab_corner_t[1], 2)) / bracket_h;
assert(bracket_slope <= 1 + 1e-9, str("a bracket overhangs more than 45 degrees: dy/dz up to ", bracket_slope));
assert(!sealed || (bottom == "auto" || bottom == "bambu"), "a sealed stack needs a fan section");

assert(wedge_w > 0 && tooth_w > 0, "the pleats are too narrow for the paper's slot: no channel is left to close");
assert(pack_l > 2 * cap_wedge_l + 10, "the ring is too short for its caps' wedges");
assert(hepa_ledge + ring_h < hepa_h - 1, "the paper is deeper than the HEPA holder is tall");

assert(grid_t >= groove_h + 2 * fdm_layer_h, "the grid's rim must roof the groove in the section's bottom");
assert(ledge_w > -groove_in, "the ledge must reach past the groove's inner face");
assert(cmag[0] < carbon_h - carbon_floor, "the C-MAG must stand inside the carbon housing");

// Wall between a magnet's hole and the joint's tongue or groove, whichever reaches further out. The originals
// have the same holes at the same places: 1.0 mm, so the section has what every BentoBox part has.
mag_to_inside = norm([mag_xy[0] - (in_w / 2 - in_r), mag_xy[1] - (in_l / 2 - in_r)]) - in_r;
mag_wall = mag_to_inside - mag_d / 2 - max(tongue_base, groove_out);
assert(mag_wall > 2 * bead, "a magnet's hole must not break into the joint's groove");

warns = [
    if (ledge_w + groove_in < 2 * bead - 1e-9) str("the groove's inner wall is ", ledge_w + groove_in, " mm, under two beads"),
    if (plenum_h < 3) str("only ", plenum_h, " mm of air above the sheet: the openings above will load it unevenly"),
    if (abs(pack_pitch / paper_pitch - 1) > 0.1)
        str("the paper is ", pack_pitch > paper_pitch ? "stretched" : "squeezed", " ", round(100 * abs(pack_pitch / paper_pitch - 1)),
            " % to fill the ring: ", pack_n, " pleats in ", ring_in[0], " mm"),
    if (wedge_w < 2 * bead - 1e-9) str("the caps' wedges are ", wedge_w, " mm wide at the top, under two beads: they may not print"),
    if (slot_w > paper_t && slot_w < bead - 1e-9) str("the slots for the paper are ", slot_w, " mm, under a bead: they may print shut"),
    if (nut_roof < 5 * fdm_layer_h - 1e-9) str("a fan screw's nut has ", nut_roof, " mm over it: the screw may pull it through"),
    if (pull_air_wall < 2 * bead - 1e-9) str("a fan nut's pocket is ", pull_air_wall, " mm from the fans' air, under two beads"),
    if (pull_face_gap < 0.1) str("a fan nut's pocket comes within ", pull_face_gap, " mm of its wall's face"),
    if (tab_boss_r - plate_cb[0] / 2 < 2 * bead - 1e-9) str("a tab's head counterbore leaves ", tab_boss_r - plate_cb[0] / 2, " mm of wall, under two beads"),
    if (nut_floor < 5 * fdm_layer_h - 1e-9) str("a nut's slot has ", nut_floor, " mm under it"),
];
for (w = warns) echo(str("WARNING: ", w));
