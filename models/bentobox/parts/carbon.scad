// SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
// SPDX-License-Identifier: CC-BY-NC-SA-4.0
// A remix of BentoBox v2.0 by ThrutheFrame (https://www.printables.com/model/272525), CC BY-NC-SA 4.0.

// parts/carbon.scad - THE CARBON HOUSING: the bed's honeycomb floor, or the C-MAG's openings; the fill marks; sealed. Included by bentobox.scad; not a model on its own.

bed_web = bed_mesh[1] * fdm_extrusion_w;
bed_hole_ac = bed_mesh[0] / cos(30);

// The carbon housing drawn (Alon, 9 Oct 2026), to its STL's measurements, from Z = z0, housing_h tall: the outline,
// its edges chamfered; the inside over the floor, its edge on the floor chamfered; and through the floor, for the bed
// a honeycomb across the whole inside (D146), for the C-MAG the original's two openings, chamfered underneath, and a
// fill mark on each inside wall for the bed. Its two faces are the sealed joints' (sealed_part cuts them). The
// original's text on its -X face is left off.
module carbon_open2d() let(o = carbon_open) hull() {
    translate([0, o[2] - o[0]]) circle(r = o[0], $fn = 96);
    translate([o[0] - o[3], o[1] + o[3]]) circle(r = o[3], $fn = 32);
    intersection() { translate([0, o[1] + o[0]]) circle(r = o[0], $fn = 96); translate([-o[0], o[1]]) square(o[0]); }
}
// The floor's honeycomb: whole holes inside the inside's outline, bed_mesh[2] in, its rounded corners included.
function in_rrect(c, size, r, margin) = let(dx = max(abs(c[0]) - (size[0] / 2 - r), 0), dy = max(abs(c[1]) - (size[1] / 2 - r), 0))
    norm([dx, dy]) <= r - margin + 1e-9;
function bed_holes() = let(size = [in_w - 2 * bed_mesh[2], in_l - 2 * bed_mesh[2]], r = max(in_r - bed_mesh[2], 0.01))
    [for (c = honeycomb_centres(size, bed_mesh[0], bed_web)) if (in_rrect(c, size, r, bed_hole_ac / 2)) c];
module bed_holes2d() for (c = bed_holes()) translate(c) rotate(90) circle(d = bed_hole_ac, $fn = 6);
// A fill mark at the origin, on a wall in the XZ plane, standing out towards +Y: a slot's shape, its edges at 45
// degrees; it starts 0.05 inside the wall, so it joins it. One in the middle of each inside wall, at the bed's top.
module bed_mark1() let(l = bed_mark, k = bed_mark[2] + 0.05) translate([0, -0.05, 0]) rotate([-90, 0, 0])
    hull() for (s = [[l[0], l[1], 0], [l[0] - 2 * k, l[1] - 2 * k, k - eps]]) translate([0, 0, s[2]]) linear_extrude(eps)
        hull() for (sx = [-1, 1]) translate([sx * (s[0] - s[1]) / 2, 0]) circle(d = s[1], $fn = 32);
module bed_marks(z0) let(z = z0 + carbon_floor + bed_depth)
    for (w = [[0, -in_l / 2, 0], [0, in_l / 2, 180], [in_w / 2, 0, 90], [-in_w / 2, 0, -90]])
        translate([w[0], w[1], z]) rotate(w[2]) bed_mark1();
// Its outside runs 1 mm past both ends: each end is a sealed joint, which cuts it there, and the outline's own
// chamfers, left inside the cut, crossed the joint's outline under the collar and made slivers.
module carbon_drawn(z0) let(c = carbon_chamfer, f = carbon_floor, h = housing_h) union() {
    difference() {
        translate([0, 0, z0 - 1]) outline_solid(h + 2);
        hull() {
            translate([0, 0, z0 + f]) linear_extrude(eps) inside_offset(-c);
            translate([0, 0, z0 + f + c]) linear_extrude(h) inside_offset(0);
        }
        if (carbon == "bed") translate([0, 0, z0 - 2]) linear_extrude(f + 3, convexity = 10) bed_holes2d();
        else for (r = [0, 180]) rotate(r) {
            hull() {
                translate([0, 0, z0 - 1]) linear_extrude(1 + eps) offset(delta = c) carbon_open2d();
                translate([0, 0, z0 + c]) linear_extrude(eps) carbon_open2d();
            }
            translate([0, 0, z0 + c]) linear_extrude(f) carbon_open2d();
        }
    }
    if (carbon == "bed") bed_marks(z0);
}
module carbon_sealed() sealed_part(sst[2], sst[3], sst[2] - meet, sst[2] - meet + housing_h, "corners", top_tabs) carbon_drawn(sst[2] - meet);
