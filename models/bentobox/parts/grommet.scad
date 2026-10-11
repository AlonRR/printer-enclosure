// SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
// SPDX-License-Identifier: CC-BY-NC-SA-4.0
// A remix of BentoBox v2.0 by ThrutheFrame (https://www.printables.com/model/272525), CC BY-NC-SA 4.0.

// parts/grommet.scad - THE WIRES' GROMMET, in TPU, and the fan section floor's hole for it. Included by bentobox.scad; not a model on its own.

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

// ------------------------------------------------------------------ the wires' grommet (D117)
// See bentobox.params.scad. Drawn on its axis, Z = 0 at the floor's underside. The floor's hole: opened out to the
// grommet, a groove round it at mid-height with 45-degree sides, and a chamfer at its top for the lip.
module grommet_hole() let(r = grommet_hole_r, g = grommet_groove, c = grommet_chamfer, h = auto_floor_t, m = grommet_mid)
    rotate_extrude($fn = 64) polygon([[0, -1], [r, -1], [r, m - g], [r + g, m], [r, m + g], [r, h - c], [r + c + 1, h + 1], [0, h + 1]]);
// The grommet, one piece (Alon, 9 Oct 2026): a ring through the floor, the lip round it at mid-height, a small
// chamfer at its foot, and a thin skin across the leads' hole there - with grommet_skin 0, an open hole. It prints
// as drawn, on its foot. The skin is a disc of its own, reaching halfway into the ring: a profile with points on the
// axis would leave a sliver facet round each of them. In the skin, a hole for each lead (Alon, 9 Oct 2026), out by
// the ring; each runs on up the ring's inside as a groove, so its lead goes straight up.
module grommet_body() let(r = grommet_r, i = grommet_in_r, l = grommet_lip, h = auto_floor_t, m = grommet_mid, s = grommet_skin * fdm_layer_h)
    difference() {
        union() {
            rotate_extrude($fn = 64) polygon([[i, 0], [r - 0.3, 0], [r, 0.3], [r, m - l], [r + l, m], [r, m + l], [r, h], [i, h]]);
            if (s > 0) cylinder(r = (i + r - 0.3) / 2, h = s, $fn = 64);
        }
        if (s > 0) for (k = [0 : grommet_leads[0] - 1]) rotate(k * 360 / grommet_leads[0])
            translate([grommet_lead_r, 0, -1]) cylinder(d = grommet_lead_d, h = h + 2, $fn = 32);
    }
// The floor's hole on a coupon of the floor, to try the grommet in before the fan section: 3 mm, in ASA.
module grommet_coupon() difference() {
    translate([-10, -10, 0]) cube([20, 20, auto_floor_t]);
    grommet_hole();
}
