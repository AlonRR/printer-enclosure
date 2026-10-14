// SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
// SPDX-License-Identifier: CC-BY-NC-SA-4.0
// A remix of BentoBox v2.0 by ThrutheFrame (https://www.printables.com/model/272525), CC BY-NC-SA 4.0.

// bentobox.layout.scad - THE VALUES MORE THAN ONE PART READS: the section's heights and where every part of the stack stands, the HEPA holder's pocket, the screws and nuts, the duct, the sealed joints' outline and tabs, the cover joint's magnets. The values only one part reads are in its file under parts/. Draws nothing. Included by bentobox.scad; not a model on its own.

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

// [fan case, section, carbon housing, HEPA holder, the cover's top]

// The HEPA holder's pocket and its ledge's opening: the original's, or cut out to the whole inside (hepa_full),
// its ledge then cut `meet` under the original's.
pocket_l = hepa_full ? in_l : hepa_pocket_l;
ledge_top = hepa_ledge - (hepa_full ? meet : 0);             // over the original's floor
pocket_r = in_r + meet;
hepa_in_grow = meet;                                            // the drawn holder's inside over the ledge, as the cut-out original's

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
tray_room_z = tray_head_z + tray_screw_max + 0.5;     // ...and the top of its hole: room for a screw up to tray_screw_max
// A tray screw's set: the thread, the head's diameter and height, the nut's flats and height, and the lengths there
// are. Its hole, counterbore, nut slot and length follow from the set.
m3_kit = [screw_d, m3_head[0], m3_head[1], nut_af, nut_h, screw_lengths];
m2_kit = [small_screw[0], small_screw[1], small_screw[2], small_nut[0], small_nut[1], small_screw_lengths];
function kit_hole(k) = 2 * (k[0] / 2 + fdm_hole_comp);
function kit_cb(k) = [k[1] + 2 * fdm_hole_comp + head_room, k[2] + head_sink];
function kit_slot_w(k) = k[3] + 2 * (fdm_hole_comp + nut_fit);
function kit_slot_h(k) = up_to_layer(k[4] + 2 * nut_fit);
function kit_head_z(k) = auto_base_z0 + kit_cb(k)[1];
function kit_screw(k) = [for (l = k[5]) if (l >= tray_slot_bot + k[4] + screw_tip - kit_head_z(k) - 1e-9) l][0];
function kit_room_z(k) = kit_head_z(k) + tray_screw_max + 0.5;
// Each: X, Y, the way out of its slot, through its end face, how far past the axis the slot runs, and its set. An
// M2 stands as far out as its counterbore keeps two beads of the end face, as the M3's tray_screw_y does.
tray_kits = [for (k = tray_screw_kind) k == "M2" ? m2_kit : m3_kit];
tray_screws = [for (e = [0, 1], x = tray_screws_x[e]) let(sy = e == 0 ? -1 : 1, k = tray_kits[e],
        y = k == m2_kit ? bb_l / 2 - kit_cb(k)[0] / 2 - 2 * bead : tray_screw_y)
    [x, sy * y, sy > 0 ? 90 : 270, bb_l / 2 - y + tray_slot_past, k]];
// The duct's inside: the +X wall's face and the end walls' faces; the turn's centre, X and Z.
duct_in = [bb_w / 2 - base_wall, bb_l / 2 - base_wall];
turn_c = [duct_in[0] - base_turn_r, base_floor + base_turn_r];

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
// the section's pillar into the fan section's nut. Each nut is a pull nut (D213, Alon 11 Oct 2026), as the fans'
// are: in a seat in the middle of its tab's height, pulled up against its roof; under it, its pocket runs straight
// down through the tab and the bracket under it, out past the bracket's foot, so the nut goes in from below and a
// longer screw runs on down the pocket.
seal_slot_bot = -tab_lower_t / 2 - nut_slot_h / 2;                      // a nut's seat's bottom, below the joint's face
seal_way = seal_slot_bot + tab_lower_t + bracket_h + 1;                // ...and its pocket under it, to 1 mm past the bracket's foot
j3_screw = screw_for(tab_upper_t - (seal_slot_bot + nut_slot_h) + nut_h + screw_tip);
j12_screw = screw_for(tab_upper_t + sec_h - (seal_slot_bot + nut_slot_h) + nut_h + screw_tip);

// The cover's joint: the remix's magnets, each moved in from the outline's corner's centre - where the originals'
// are - along the diagonal by top_mag_in, which leaves the wall inside it, to the holder's inside, as thick as the
// wall outside it at the top's chamfer. From the outline, not from mag_xy, so the originals' holes move alone.
top_mag_d = magnet[0] + 0.2;
_mag_c = [bb_w / 2 - bb_r, bb_l / 2 - bb_r];
top_mag_in = (norm(_mag_c - [in_w / 2 - in_r, in_l / 2 - in_r]) - in_r - bb_r + bb_chamfer) / (1 + 1 / sqrt(2));
top_mag_xy = _mag_c - top_mag_in / sqrt(2) * [1, 1];
top_mag_wall_in = norm([top_mag_xy[0] - (in_w / 2 - in_r), top_mag_xy[1] - (in_l / 2 - in_r)]) - in_r - top_mag_d / 2;
top_mag_wall_out = min(bb_w / 2 - top_mag_xy[0], bb_l / 2 - top_mag_xy[1]) - top_mag_d / 2 - bb_chamfer;

// The sealed stack's parts in place: the fan section, the carbon housing, the HEPA holder. Each part's body stands
// `meet` lower than its joint's face, whose cut takes that much off its floor.
sst = stack(true, true);
