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
];
for (w = warns) echo(str("WARNING: ", w));
