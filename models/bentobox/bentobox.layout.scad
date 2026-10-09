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
// airflow simulation asks for the originals' stack. Sealed, it is the remix's, its carbon housing housing_h tall.
function stack(with_section, seal = false) = let(
    drop = seal ? meet : 0,
    fans_z = duct_h,
    sec_z = fans_z + fans_h - drop,
    carbon_z = sec_z + (with_section ? sec_h : 0),
    hepa_z = carbon_z + (seal ? housing_h : carbon_h) - 2 * drop
) [fans_z, sec_z, carbon_z, hepa_z, hepa_z + hepa_h - drop + cover_top];
// The remix's carbon housing: as tall as its floor, the bed and the air over it, or the original's for the C-MAG.
housing_h = carbon == "bed" ? carbon_floor + bed_depth + bed_head : carbon_h;
bed_web = bed_mesh[1] * fdm_extrusion_w;
bed_hole_ac = bed_mesh[0] / cos(30);
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
// The C-MAG drawn: its walls' thickness; the grills' honeycomb - its webs, its rim, a hole across its corners.
cmag_wall = cmag_round - cmag_fillet;
cmag_web = cmag_mesh[1] * fdm_extrusion_w;
cmag_rim = cmag_mesh[2] * fdm_extrusion_w;
cmag_hole_ac = cmag_mesh[0] / cos(30);

// The frame for your own HEPA paper. The ring stands on the HEPA holder's ledge, in its pocket; the paper
// fills it with its folds along Y, and a cap closes each end. Across, the piece holds a whole number of
// pleats: as many as come nearest filling the ring, stretched or squeezed to fill it, as a pleated pack
// will - and the caps' wedges and teeth are spaced to match. Its long edges are cut on a top fold, which
// rests against the ring's wall; or, with paper_flaps, on a bottom fold, so each side keeps half a pleat more
// as a flap whose cut end stands in a slot at the wall's foot.
// The HEPA holder's pocket and its ledge's opening: the original's, or cut out to the whole inside (hepa_full),
// its ledge then cut `meet` under the original's.
pocket_l = hepa_full ? in_l : hepa_pocket_l;
ledge_top = hepa_ledge - (hepa_full ? meet : 0);             // over the original's floor
pocket_r = in_r + meet;
hepa_in_grow = meet;                                            // the drawn holder's inside over the ledge, as the cut-out original's
// The clamp (D127): a cassette, its outline the pocket's, clamp_play in; X across, Y along the folds, Z from its
// bottom face, which stands on the ledge. The paper's bottom face clamp_fold_gap over the lower frame's rim, its
// top as deep again, and the upper frame's band clamp_fold_gap over that.
cas = [in_w + 2 * meet - 2 * clamp_play, pocket_l + 2 * meet - 2 * clamp_play];
pack_z = clamp_rim + clamp_fold_gap;
pack_top = pack_z + paper_depth;
band_z = pack_top + clamp_fold_gap;
cas_h = band_z + clamp_band;
comb_y = cas[1] / 2 - clamp_blk;                     // each end block's inner face; the combs reach in from it
slot_w = clamp_slot;                                 // the slot the paper sits in, pinched
pack_edge = paper_flaps ? cas[0] / 2 - slot_w / 2 : cas[0] / 2;   // the paper's middle at its long edges, +/- X
pack_halves = paper_flaps ? 1 : 0;                   // the flaps: a half pleat each side
pack_n = max(1, round(2 * pack_edge / paper_pitch) - pack_halves);   // full pleats across
pack_pitch = 2 * pack_edge / (pack_n + pack_halves);
pack_l = 2 * (comb_y - clamp_fold_gap);              // the piece's length, along the folds, clear of the end blocks
// The ledge's opening, cut out with the pocket: hepa_ledge_w inside the walls across, and along to the combs.
open_wl = hepa_full ? [in_w - 2 * hepa_ledge_w, 2 * comb_y] : hepa_open;
// The folds across the piece, from one long edge to the other: the i-th is at fold_x(i), a top fold or a
// bottom one. With flaps, the first and the last are the flaps' cut ends.
fold_last = 2 * (pack_n + pack_halves);
function fold_x(i) = -pack_edge + i * pack_pitch / 2;
function fold_top(i) = (i % 2 == 0) != paper_flaps;
// Seen along the folds, the paper's middle runs from a top fold paper_t / 2 under the pack's top face to a
// bottom fold paper_t / 2 over its bottom, leaning pleat_alpha from upright. Screwed together, the frames leave
// it a slot slot_w wide, centred on that middle, so the side of a wedge or a tooth is the middle moved
// slot_w / (2 cos(alpha)) sideways. A wedge, in a channel open at the top, is wedge_w wide at the top face
// and comes to a point slot_w / (2 sin(alpha)) above the bottom fold's middle - in a narrow pleat,
// millimetres, not the slot's width. A tooth, in a channel open at the bottom, is the same shape upside down.
// Heights here are over the pack's bottom face.
pleat_alpha = atan((pack_pitch / 2) / (paper_depth - paper_t));
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
// A tray screw comes up through a counterbore in the tray, its head head_sink inside the tray's bottom face, on up
// through the tray and the base's floor to its nut, in a slot that opens out through the end face.
m3_cb = [m3_head[0] + 2 * fdm_hole_comp + head_room, m3_head[1] + head_sink];   // a head's counterbore, d and depth
tray_top = auto_bay_top;                               // the tray's top: the base's bottom face
tray_head_z = auto_base_z0 + m3_cb[1];                 // where a head bears, up in the tray
tray_slot_bot = auto_bay_top + nut_floor;
tray_slot_top = tray_slot_bot + nut_slot_h;
tray_screw = screw_for(tray_slot_bot + nut_h + screw_tip - tray_head_z);
tray_tip_z = tray_head_z + tray_screw;
// Each: X, Y, the way out of its slot, through its end face, and how far past the axis the slot runs.
tray_screws = [for (x = tray_screws_x, sy = [-1, 1]) [x, sy * tray_screw_y, sy > 0 ? 90 : 270, bb_l / 2 - tray_screw_y + tray_slot_past]];
// The duct's inside: the +X wall's face and the end walls' faces; the turn's centre, X and Z.
duct_in = [bb_w / 2 - base_wall, bb_l / 2 - base_wall];
turn_c = [duct_in[0] - base_turn_r, base_floor + base_turn_r];
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
// The grommet in the fan section's floor, from Z = duct_h for auto_floor_t: its radii - the hole's as cut, the
// grommet's drawn, the leads' - the lip's and the groove's mid-height, and how deep the groove goes past the hole.
grommet_hole_r = grommet_d[0] / 2 + fdm_hole_comp;
grommet_r = grommet_d[0] / 2 + grommet_squeeze;
grommet_in_r = grommet_d[1] / 2;
grommet_mid = auto_floor_t / 2;
grommet_groove = grommet_r + grommet_lip + grommet_play - grommet_hole_r;
// The leads' holes in its skin: as cut, and how far out their centres stand - as close to the ring as leaves two
// lines of skin between neighbours.
grommet_lead_d = grommet_leads[1] + 2 * fdm_hole_comp;
grommet_lead_r = (grommet_lead_d + 2 * fdm_extrusion_w) / (2 * sin(180 / grommet_leads[0]));
// The fans' plug mate, in its own frame: the pins along X at Y = 0, standing up from Z = 0, the block's underside;
// the plug's text face towards +Y, its ribs towards -Y. Out from the pins' line: the plug's text face, its ribbed
// face, its ribs' tips; the wall's inside, the key's face and its width; the holes as cut; each plug's X; the
// block's ends and its back and front faces; and how much of each wire to bare.
fmp_text = fan_plug_d + fan_plug_hole / 2;
fmp_back = fan_plug[1] - fmp_text;
fmp_ribs = fan_plug_ribs[2] - fmp_text;
fm_wall_y = -(fmp_ribs + fan_mate_play);
fm_key_y = -(fmp_back + fan_mate_play);
fm_key_w = fan_plug_ribs[1] - 2 * fan_mate_play;
fm_core_d = fan_wire[0] + 2 * fdm_hole_comp;
fm_ins_d = fan_wire[1] + 2 * fdm_hole_comp;
fm_xs = [for (i = [0 : fan_mate_n - 1]) (i - (fan_mate_n - 1) / 2) * (fan_plug[0] + fan_mate_gap)];
fm_x0 = min(fm_xs) - fan_plug[0] / 2 - fan_mate_play;
fm_x1 = max(fm_xs) + fan_plug[0] / 2 + fan_mate_play;
fm_y0 = fm_wall_y - fan_mate_wall[0];
fm_y1 = fmp_text + fan_mate_front;
fm_strip = fan_mate_base[1] + fan_mate_pin;
// What a tray screw leaves: its hole to the board's pocket, beside it; its counterbore to the magnets' holes.
tray_usb_wall = min([for (x = tray_screws_x) abs(x - usb_x) - usb_pocket[0] / 2 - hole_d / 2]);
tray_magnet_wall = min([for (x = tray_screws_x, m = auto_magnets) norm([x, tray_screw_y] - m) - (m3_cb[0] + auto_magnet[0]) / 2]);

assert(!is_undef(fan_screw) && !is_undef(tray_screw), "no screw in screw_lengths is long enough");
assert(head_sink >= 0, "a tray screw's head stands out of the tray's bottom face");
assert(base_turn_r > base_fillet && base_floor + base_turn_r < duct_h, "the duct's turn must be rounder than its fillets and meet the +X wall under the top");
assert([for (s = auto_fan_screws) if (abs(min(duct_in[0] - s[0], duct_in[1] - abs(s[1])) - auto_post_wall) > 1e-6) s] == [],
    "every fan screw must stand auto_post_wall from its wall's face");
assert(usb_pcb_y1 < -bay_size[1] / 2, "the USB-C board must sit in the -Y end block, the bay behind it");
assert(usb_pcb_z > auto_seat_z, "the USB-C board's pocket must stand on the end block");
assert(grommet_groove + grommet_chamfer < grommet_mid, "the grommet's groove must stand clear of the floor's faces");
assert(grommet_skin >= 0 && grommet_skin * fdm_layer_h < grommet_mid - grommet_lip,
    "the grommet's skin must stay at its foot, under its lip");
assert(grommet_leads[0] >= 2 && grommet_lead_r > grommet_lead_d / 2 + 2 * fdm_extrusion_w,
    "the grommet's lead holes must leave two lines of skin at its middle");
assert(grommet_lead_r + grommet_lead_d / 2 < grommet_r - 2 * fdm_extrusion_w,
    "the grommet's lead grooves must leave two lines of ring behind them");
assert(fan_mate_n >= 1 && fm_key_w > 2 * fdm_extrusion_w && fm_key_y > fm_wall_y,
    "the plug mate's key must be wide enough to print and stand out from its wall");
assert(fan_mate_base[0] - fan_mate_base[1] > fm_ins_d && fan_pitch - fm_core_d > fdm_extrusion_w,
    "the plug mate's block must hold the insulation's slot under the cores' holes, a line of it between them");
assert(grommet_x + grommet_hole_r + grommet_chamfer < auto_fans_in_x - 0.2, "the grommet's hole must stay under the fan section's chamber, clear of its +X wall");
assert(abs(grommet_x - auto_conduit[0]) + auto_conduit[2] / 2 + meet < grommet_hole_r, "the grommet's hole must take the fan section's old hole in");
assert(post_round_z < pull_seat, "a fan nut's seat must stand in its post's straight part, over the underside's round");
assert(fan_tip_z > pull_bot && fan_tip_z < pull_top - nut_h - screw_tip + 1e-9, "a fan screw's tip must stand out of its nut, inside the pocket");
assert(bottom == "auto" || bottom == "bambu", str("unknown bottom: ", bottom));
// How far a hex reaches towards theta, ac across its corners, a flat facing `flat`.
function hex_reach(theta, flat, ac) = let(d = ((theta - flat) % 60 + 60) % 60) ac / 2 * cos(30 - min(d, 60 - d));
// The walls a fan nut's pocket keeps: to the fans' air, which the post is cut back from, and to its wall's face.
pull_air_wall = min([for (s = auto_fan_screws) let(f = [0, abs(s[1] - fan_ys[0]) < abs(s[1] - fan_ys[1]) ? fan_ys[0] : fan_ys[1]])
    norm([s[0], s[1]] - f) - hex_reach(atan2(f[1] - s[1], f[0] - s[0]), s[2], pull_way_ac) - auto_fan_air / 2 - meet]);
pull_face_gap = min([for (s = auto_fan_screws) auto_post_wall - hex_reach(s[3] + 180, s[2], pull_way_ac)]);

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
assert(!is_undef(clamp_screw), "no M2 screw in small_screw_lengths is long enough for the clamp");
assert(clamp_head_z - clamp_screw > 0, "a clamp screw reaches out of the lower frame's bottom");

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
tab_upper_h = tab_upper_t + m3_cb[1];                                    // an upper part's tab, its screw's head sunk
tab_screws = [for (sx = [-1, 1], sy = [-1, 1]) [sx * tab_sc[0], sy * tab_sc[1], sy > 0 ? 90 : 270]];
// A tab in the middle of an end wall (top_tabs = "middle"): the corner tab's boss and parabola, moved to X = 0, the
// parabola run down into the end wall on both sides, its feet at +-tab_mx0.
tab_mx0 = tab_sc[0] - tab_x0;
function joint_screws(style) = style == "middle" ? [for (sy = [-1, 1]) [0, sy * tab_sc[1], sy > 0 ? 90 : 270]] : tab_screws;
top_screws = joint_screws(top_tabs);                                   // the top joint's, the HEPA holder's
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
assert(hepa_full, "the clamp is drawn for the HEPA holder's pocket cut out to the whole inside");
assert(pack_l > 2 * clamp_wedge_l + 10, "the clamp is too short for its combs");
assert(hepa_ledge + cas_h < hepa_h - 1, "the clamp is taller than the HEPA holder");
assert(half_wedge_z0 < paper_depth - 3, "the half wedges outside the flaps come out shorter than 3 mm");

assert(grid_t >= groove_h + 2 * fdm_layer_h, "the grid's rim must roof the groove in the section's bottom");
assert(ledge_w > -groove_in, "the ledge must reach past the groove's inner face");
assert(top_tabs == "middle" || top_tabs == "corners", "top_tabs is \"middle\" or \"corners\"");
assert(carbon == "bed" || carbon == "cmag", "carbon is \"bed\" or \"cmag\"");
assert(cmag[0] < carbon_h - carbon_floor, "the C-MAG must stand inside the carbon housing");
assert(bed_hole_ac < cmag_pellet, "the floor's holes must be smaller than a pellet, even across their corners");
assert(bed_mesh[2] >= carbon_chamfer + 2 * bead - 1e-9, "the floor's honeycomb must stay clear of the inside's chamfer, two beads of floor past it");
assert(bed_head > 0, "the bed needs air over it, under the HEPA holder");
assert(cmag_hole_ac < cmag_pellet, "the grills' holes must be smaller than a pellet, even across their corners");
assert(cmag_rail[1] > cmag_rail[2] && cmag_rail[2] <= cmag_fillet, "a rail's tray side drops less deep than the rail, and no deeper than the inside's fillets");

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
            " % to fill the clamp: ", pack_n, " pleats in ", cas[0], " mm"),
    if (wedge_w < 2 * bead - 1e-9) str("the clamp's wedges are ", wedge_w, " mm wide at the top, under two beads: they may not print"),
    if (clamp_slot > paper_t) str("the clamp's slot is wider than the paper: it holds the paper but does not pinch it"),
    if (small_nut_wall < 2 * bead - 1e-9) str("the clamp's nut pockets leave ", small_nut_wall, " mm of the end blocks, under two beads"),
    if (nut_roof < 5 * fdm_layer_h - 1e-9) str("a fan screw's nut has ", nut_roof, " mm over it: the screw may pull it through"),
    if (pull_air_wall < 2 * bead - 1e-9) str("a fan nut's pocket is ", pull_air_wall, " mm from the fans' air, under two beads"),
    if (pull_face_gap < 0.1) str("a fan nut's pocket comes within ", pull_face_gap, " mm of its wall's face"),
    if (tab_boss_r - m3_cb[0] / 2 < 2 * bead - 1e-9) str("a tab's head counterbore leaves ", tab_boss_r - m3_cb[0] / 2, " mm of wall, under two beads"),
    if (bb_l / 2 - tray_screw_y - m3_cb[0] / 2 < 2 * bead - 1e-9) str("a tray screw's counterbore leaves ", bb_l / 2 - tray_screw_y - m3_cb[0] / 2, " mm of the end face, under two beads"),
    if (tray_usb_wall < 2 * bead - 1e-9) str("a tray screw's hole leaves ", tray_usb_wall, " mm to the USB-C board's pocket, under two beads"),
    if (tray_magnet_wall < 2 * bead - 1e-9) str("a tray screw's counterbore leaves ", tray_magnet_wall, " mm to a magnet's hole, under two beads"),
    if (nut_floor < 4 * fdm_layer_h - 1e-9) str("a tray nut's slot has ", nut_floor, " mm under it, under four layers"),
];
for (w = warns) echo(str("WARNING: ", w));
