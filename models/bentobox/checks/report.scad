// SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
// SPDX-License-Identifier: CC-BY-NC-SA-4.0
// A remix of BentoBox v2.0 by ThrutheFrame (https://www.printables.com/model/272525), CC BY-NC-SA 4.0.

// checks/report.scad - THE REPORT: the warnings - builds, but compromised - and the echoes each part prints, with the values only they read. Included by bentobox.scad; not a model on its own.

// What a tray screw leaves: its hole to the board's pocket, beside it; its counterbore to the magnets' holes.
tray_usb_wall = min([for (x = tray_screws_x[0]) abs(x - usb_x) - usb_pocket[0] / 2 - hole_d / 2]);
tray_magnet_wall = min([for (e = tray_screws_x, x = e, m = auto_magnets) norm([x, tray_screw_y] - m) - (m3_cb[0] + auto_magnet[0]) / 2]);

// How far a hex reaches towards theta, ac across its corners, a flat facing `flat`.
function hex_reach(theta, flat, ac) = let(d = ((theta - flat) % 60 + 60) % 60) ac / 2 * cos(30 - min(d, 60 - d));
// The walls a fan nut's pocket keeps: to the fans' air, which the post is cut back from, and to its wall's face.
pull_air_wall = min([for (s = auto_fan_screws) let(f = [0, abs(s[1] - fan_ys[0]) < abs(s[1] - fan_ys[1]) ? fan_ys[0] : fan_ys[1]])
    norm([s[0], s[1]] - f) - hex_reach(atan2(f[1] - s[1], f[0] - s[0]), s[2], pull_way_ac) - auto_fan_air / 2 - meet]);
pull_face_gap = min([for (s = auto_fan_screws) auto_post_wall - hex_reach(s[3] + 180, s[2], pull_way_ac)]);

warns = [
    if (ledge_w + groove_in < 2 * bead - 1e-9) str("the groove's inner wall is ", ledge_w + groove_in, " mm, under two beads"),
    if (plenum_h < 3) str("only ", plenum_h, " mm of air above the sheet: the openings above will load it unevenly"),
    if (abs(pack_pitch / paper_pitch - 1) > 0.1)
        str("the paper is ", pack_pitch > paper_pitch ? "stretched" : "squeezed", " ", round(100 * abs(pack_pitch / paper_pitch - 1)),
            " % to fill the ", glue ? "glue frame" : "clamp", ": ", pack_n, " pleats in ", 2 * pack_edge, " mm"),
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
    if (bb_l / 2 - sps30_slot_y < 2 * bead - 1e-9) str("the end wall behind the SPS30's lead slot is ", bb_l / 2 - sps30_slot_y, " mm, under two beads"),
];
for (w = warns) echo(str("WARNING: ", w));

module say_sps30() echo(str("sps30: in its pocket on the outlet's floor, label up, its air face at Y ", sps30_yy[0],
    " facing the duct's middle, its connector face ", round(10 * (duct_in[1] - sps30_yy[1])) / 10, " mm off the +Y end wall; its front ", sps30_in,
    " mm inside the outlet's face, behind the tray's stop; its plug flush, its leads bent down in the end wall's slot, ",
    sps30_slot_y - sps30_yy[1], " mm out from its face, then along the tray's groove into the bay"));

module say_usb() echo(str("usb-c: the socket's face flush with the -Y end face, its axis at X ", usb_x, ", Z ", usb_axis_z,
    " (", usb_axis_z - auto_base_z0, " over the bottom face); the board on a floor ", usb_pcb_z - auto_base_z0, " over the bottom face"));
module say_auto_hardware() echo(str("auto: eight M3 nuts, the fans' four pulled up into pockets, the tray's four in slots; the fans' four screws M3 x ",
    fan_screw, " socket head, through the fans; the tray's four M3 x ", tray_screw, " socket head, sunk ", head_sink,
    " mm into its bottom face"));

module say_cmag() let(n = len(cmag_mesh_holes()), open = n * 3 * sqrt(3) / 8 * pow(cmag_hole_ac, 2))
    echo(str("C-MAG grills: ", n, " holes each, ", cmag_mesh[0], " mm across their flats, ", cmag_hole_ac, " across their corners, ",
        "for ", cmag_pellet, " mm pellets; ", round(open), " mm2 open, ", round(100 * open / (cmag_grill[0] * cmag_grill[1])), " % of a grill"));
function _count(n) = n == 1 ? "one" : n == 2 ? "two" : n == 4 ? "four" : n == 6 ? "six" : n == 8 ? "eight" : str(n);
module say_seal_hardware() echo(str("sealed joints: three TPU bead rings, ", seal_bead[0], " mm; ", _count(len(top_screws)),
    " M3 x ", j3_screw, " socket head into nuts, HEPA holder to carbon housing; four M3 x ", j12_screw,
    " through the carbon housing's tabs and the section's pillars into the fan section's nuts; ",
    _count(len(tab_screws) + len(top_screws)), " M3 nuts; every head sunk in its tab, turned with a 2.5 mm hex screwdriver"));

module say_nut_coupon() echo(str("nut coupon, as cut across the flats: seats 1-", nc_n, " ", [for (f = coupon_pull) nc_w(f)],
    " (pull_fit ", coupon_pull, "); slots ", nc_n + 1, "-", 2 * nc_n, " ", [for (c = coupon_slot) [nc_w(c[0]), c[1]]],
    " (the taper from ", nc_w(coupon_taper[0]), " at its mouth)"));

module say_fan_mate() echo(str("fan plug mate: ", fan_mate_n, fan_mate_n == 1 ? " plug" : " plugs", "; bare each wire ",
    fm_strip, " mm, push it up from below until its insulation stops, and bend it over into the groove underneath"));

module say_sample_hardware() let(n = _count(len(top_screws) / 2)) echo(str("joint sample: ", n, " M3 x ", j3_screw,
    " socket head and ", n, len(top_screws) == 2 ? " M3 nut" : " M3 nuts", " for the joint, one M3 nut and an M3 x 8 for the pocket's seat"));

// How to cut the paper for the clamp, from the values above: what the build page quotes. Only the length is
// measured; across the folds the piece is counted, since the clamp sets its width.
module say_paper_cut() if (glue) echo(str("paper: cut a piece ", round(pack_l * 10) / 10, " mm long along the folds and ", pack_n,
    " pleats across, both long edges on a top fold (about ", round(pack_n * paper_pitch * 10) / 10, " mm as folded; the frame takes ",
    round(2 * pack_edge * 10) / 10, " mm, ", round(pack_pitch * 100) / 100, " mm a pleat). Glue it in from the top: fill the end of",
    " every channel open at the top, at both ends, and run a bead across each end and along each long side's top fold"));
else echo(str("paper: cut a piece ", round(pack_l * 10) / 10, " mm long along the folds and ", pack_n,
    flaps ? " pleats across and a half pleat more each side, both long edges on a bottom fold"
                : " pleats across, both long edges on a top fold",
    " (about ", round((pack_n + pack_halves) * paper_pitch * 10) / 10, " mm as folded; the clamp spreads it to ",
    round(2 * pack_edge * 10) / 10, " mm, ", round(pack_pitch * 100) / 100, " mm a pleat). The clamp's slot is ",
    clamp_slot, " mm; its four screws M2 x ", clamp_screw, " socket head, into M2 nuts pulled into the lower frame"));
