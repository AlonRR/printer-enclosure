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

// The stack, bottom up: the Z of each part's bottom face, with the section or without.
function stack(with_section) = let(
    fans_z = duct_h,
    sec_z = fans_z + fans_h,
    carbon_z = sec_z + (with_section ? sec_h : 0),
    hepa_z = carbon_z + carbon_h
) [fans_z, sec_z, carbon_z, hepa_z, hepa_z + hepa_h + cover_top];
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
ring_out = [in_w - 2 * ring_play, hepa_pocket_l - 2 * ring_play];   // X, Y
ring_in = ring_out - 2 * [ring_wall, ring_wall];
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

// The Auto's bottom, its heat-set inserts made nuts. Each nut lies flat in a slot that opens one way, its
// flats against the slot's sides; its back corner stops against the slot's closed end with the nut on the
// screw's axis. A fan screw comes down through the fan, the fan section's floor and the base's top into its
// nut, which it pulls up against the slot's roof; a plate screw comes up through the plate into its nut, which
// it pulls down onto the slot's floor. Each screw is the shortest of screw_lengths that stands screw_tip out.
function up_to_layer(z) = ceil(z / fdm_layer_h - 1e-9) * fdm_layer_h;
function screw_for(need) = [for (l = screw_lengths) if (l >= need - 1e-9) l][0];
hole_d = 2 * (screw_d / 2 + fdm_hole_comp);
nut_ac = nut_af / cos(30);
nut_slot_w = nut_af + 2 * (fdm_hole_comp + nut_fit);
nut_slot_h = up_to_layer(nut_h + 2 * nut_fit);
fan_slot_top = duct_h - nut_roof;
fan_slot_bot = fan_slot_top - nut_slot_h;
post_r = nut_slot_w / 2 + post_beads * bead;           // the post round a fan screw's slot...
post_reach = nut_ac / 2;                               // ...running on this far towards its mouth, past the nut
post_bot = fan_slot_bot - nut_floor;                   // ...its foot, with a 45-degree cone under it
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
assert(fan_tip_z - 0.5 > post_bot - post_r + hole_d / 2, "a fan screw's tip runs out of its post's cone");
assert(bottom == "auto" || bottom == "bambu", str("unknown bottom: ", bottom));

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
    if (nut_floor < 5 * fdm_layer_h - 1e-9) str("a nut's slot has ", nut_floor, " mm under it"),
];
for (w = warns) echo(str("WARNING: ", w));
