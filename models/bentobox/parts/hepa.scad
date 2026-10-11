// SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
// SPDX-License-Identifier: CC-BY-NC-SA-4.0
// A remix of BentoBox v2.0 by ThrutheFrame (https://www.printables.com/model/272525), CC BY-NC-SA 4.0.

// parts/hepa.scad - THE HEPA HOLDER, drawn and sealed. Included by bentobox.scad; not a model on its own.

// The HEPA holder drawn (Alon, 9 Oct 2026), to its STL's measurements, from Z = z0: the outline, its top edge
// chamfered; the pocket - the whole inside - over the ledge; the ledge's opening; and the magnets' holes in its top,
// where the original cover sits on it. Drawn as the cut-out original was, the pocket and the opening `meet` past its
// faces and the ledge `meet` under: the clamp is sized to that. Its bottom is the sealed joint's (sealed_part). The
// outside is the sealed joint's own outline, its chamfer made from the same points: a chamfer from the box's rounded
// rectangle crossed that outline's prism at the corners a hair off, and made slivers.
module hepa_drawn(z0) let(c = bb_chamfer, t = z0 + hepa_h) difference() {
    hull() {
        translate([0, 0, z0 - 1]) linear_extrude(hepa_h + 1 - c) polygon(outline_pts());
        translate([0, 0, t - eps]) linear_extrude(eps) offset(delta = -c) polygon(outline_pts());
    }
    translate([0, 0, z0 + ledge_top]) linear_extrude(hepa_h) inside_offset(hepa_in_grow);
    translate([0, 0, z0 - 1]) linear_extrude(hepa_ledge + 2) offset(delta = meet) rrect_c(open_wl[0], open_wl[1], hepa_open_r);
    magnet_holes(z0 + hepa_h, false, top_mag_xy, top_mag_d, magnet[1]);
}
module hepa_sealed() sealed_part(sst[3], undef, sst[3] - meet, sst[3] - meet + hepa_h, top_tabs) hepa_drawn(sst[3] - meet);
