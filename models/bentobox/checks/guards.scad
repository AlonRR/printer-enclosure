// SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
// SPDX-License-Identifier: CC-BY-NC-SA-4.0
// A remix of BentoBox v2.0 by ThrutheFrame (https://www.printables.com/model/272525), CC BY-NC-SA 4.0.

// checks/guards.scad - THE GUARDS: the asserts that stop a render whose geometry is impossible, and the values only they read. Included by bentobox.scad; not a model on its own.

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
assert(fan_mate_base[1] - (fm_ins_d - fm_core_d) / 2 >= 1,
    "the plug mate's cores' holes must run on 1 mm or more over the slot's roof, to hold the pins upright");
assert(fan_mate_n == 1 || fan_mate_gap - 2 * fan_mate_play > 2 * fdm_extrusion_w,
    "the plug mate's wall between two plugs must be two lines thick");
assert(fan_mate_grip[0] > 0 && fan_mate_grip[1] >= 2 * fdm_extrusion_w && fan_mate_play + fan_mate_grip[0] < fan_mate_grip[1] / 2
       && 0.4 + fan_mate_play + fan_mate_grip[0] < (fan_mate_n == 1 ? fan_mate_wall[0] : min(fan_mate_wall[0], fan_mate_gap - 2 * fan_mate_play)),
    "the plug mate's grip must bite the plugs' ends, its ribs two lines wide, standing out of their wall by less than their radius and inside it at its top");
assert(fm_grip_y[0] - fan_mate_grip[1] / 2 > -(fmp_back - fan_plug_lip[0]) + 0.2 && fm_grip_y[1] + fan_mate_grip[1] / 2 < fmp_text - 0.2,
    "the plug mate's grip must stand on the plugs' end faces, clear of their edges");
assert(grommet_x + grommet_hole_r + grommet_chamfer < auto_fans_in_x - 0.2, "the grommet's hole must stay under the fan section's chamber, clear of its +X wall");
assert(abs(grommet_x - auto_conduit[0]) + auto_conduit[2] / 2 + meet < grommet_hole_r, "the grommet's hole must take the fan section's old hole in");
assert(post_round_z < pull_seat, "a fan nut's seat must stand in its post's straight part, over the underside's round");
assert(fan_tip_z > pull_bot && fan_tip_z < pull_top - nut_h - screw_tip + 1e-9, "a fan screw's tip must stand out of its nut, inside the pocket");
assert(bottom == "auto" || bottom == "bambu", str("unknown bottom: ", bottom));

assert(!is_undef(clamp_screw), "no M2 screw in small_screw_lengths is long enough for the clamp");
assert(clamp_head_z - clamp_screw > 0, "a clamp screw reaches out of the lower frame's bottom");

assert(tab_boss_r - pull_way_ac / 2 >= 2 * bead - 1e-9, str("a joint's nut pocket leaves ", tab_boss_r - pull_way_ac / 2, " mm of its tab's boss, under two beads"));
assert(tab_out - pull_way_ac / 2 * cos(30) >= 2 * bead - 1e-9, "a joint's nut pocket must stay two beads clear of the end wall");
assert(seal_slot_bot > -tab_lower_t, "a joint's nut seat must stand in its tab, over the bracket");
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

assert(hepa_frame == "glue" || hepa_frame == "clamp", "hepa_frame is \"glue\" or \"clamp\"");
assert(hepa_full, "the paper's frame is drawn for the HEPA holder's pocket cut out to the whole inside");
// The clamp's own: they hold only when it is the frame drawn.
assert(glue || (wedge_w > 0 && tooth_w > 0), "the pleats are too narrow for the paper's slot: no channel is left to close");
assert(glue || pack_l > 2 * clamp_wedge_l + 10, "the clamp is too short for its combs");
assert(glue || hepa_ledge + cas_h < hepa_h - 1, "the clamp is taller than the HEPA holder");
assert(glue || half_wedge_z0 < paper_depth - 3, "the half wedges outside the flaps come out shorter than 3 mm");
assert(glue_wall[0] >= 2 * fdm_extrusion_w - 1e-9 && glue_wall[1] >= 2 * fdm_extrusion_w - 1e-9 && glue_lip >= 0,
    "the glue frame's walls must be two lines thick and stand over the paper");
assert(gf_in[0] > gf_rim[0] / 2 && gf_in[1] > gf_rim[1] / 2, "the glue frame's walls must stand outside the ledge's opening");
assert(hepa_ledge + gf_h < hepa_h - 1, "the glue frame is taller than the HEPA holder");
assert(pack_l > 20, "the glue frame is too short for its paper");
assert(!glue || (jig_top_w >= 2 * fdm_extrusion_w - 1e-9 && glue_jig[0] > 0 && glue_jig[0] < paper_depth / 2),
    "the glue frame's fins must stay two lines wide to their tops, and stand under half the paper's depth");

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

assert(min(top_mag_wall_in, top_mag_wall_out) >= 2 * bead - 1e-9,
    str("the cover joint's magnets leave ", top_mag_wall_in, " mm inside and ", top_mag_wall_out, " mm outside at the chamfer: under two beads"));
