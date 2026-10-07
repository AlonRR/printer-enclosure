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
// fills it with its folds along Y, and a cap closes each end. The piece's two long edges are cut along a
// top fold, so it holds a whole number of pleats across: as many as come nearest the ring's inside,
// stretched or squeezed to fill it, as a pleated pack will - and the caps' wedges are spaced to match.
ring_wall = ring_beads * bead;
ring_out = [in_w - 2 * ring_play, hepa_pocket_l - 2 * ring_play];   // X, Y
ring_in = ring_out - 2 * [ring_wall, ring_wall];
ring_h = paper_depth;
pack_n = max(1, round(ring_in[0] / paper_pitch));   // pleats across: the channels open at the top
pack_pitch = ring_in[0] / pack_n;
pack_l = ring_in[1] - 2 * cap_plate;                 // the piece's length, along the folds
// Seen along the folds, the paper's middle runs from a top fold paper_t / 2 under the pack's top face to a
// bottom fold paper_t / 2 over its bottom, leaning pleat_alpha from upright. The paper sits in a slot
// cap_slot wide, centred on that middle, so the side of a wedge or a tooth is the middle moved
// cap_slot / (2 cos(alpha)) sideways. A wedge, in a channel open at the top, is wedge_w wide at the top face
// and comes to a point cap_slot / (2 sin(alpha)) above the bottom fold's middle - in a narrow pleat,
// millimetres, not the slot's width. A tooth, in a channel open at the bottom, is the same shape upside down.
cap_slot = cap_teeth_below ? paper_t + cap_slot_play : paper_t;
pleat_alpha = atan((pack_pitch / 2) / (paper_depth - paper_t));
wedge_w = 2 * ((paper_depth - paper_t / 2) * tan(pleat_alpha) - cap_slot / (2 * cos(pleat_alpha)));   // at the top face
wedge_z0 = paper_t / 2 + cap_slot / (2 * sin(pleat_alpha));    // its point, above the pack's bottom face
tooth_w = 2 * ((paper_depth - paper_t / 2) * tan(pleat_alpha) - cap_slot / (2 * cos(pleat_alpha)));   // at the bottom face
tooth_z1 = paper_depth - paper_t / 2 - cap_slot / (2 * sin(pleat_alpha));   // its point, above the pack's bottom face

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
    if (cap_teeth_below && cap_slot < bead - 1e-9) str("the caps' slot for the paper is ", cap_slot, " mm, under a bead: it may print shut"),
];
for (w = warns) echo(str("WARNING: ", w));
