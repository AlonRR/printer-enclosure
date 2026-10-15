// SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
// SPDX-License-Identifier: CC-BY-4.0

// checks/guards.scad - THE ASSERTS: geometry that is impossible stops the render. Included by filter-wall.scad; not
// a model on its own. The judgement calls are warnings, in checks/report.scad.

// Every printed part fits the bed as it prints.
for (p = pieces) let(s = print_size(p))
    assert(s[0] <= bed[0] + 1e-6 && s[1] <= bed[1] + 1e-6 && s[2] <= bed[2] + 1e-6,
           str(p[0], " is ", s, " as it prints: past the bed's ", bed));

// The filter, with its clearance, fits the pocket, and the stop overlaps its rim.
assert(pocket[0] >= starkvind[0] && pocket[1] >= starkvind[1], "the filter is larger than its pocket");
assert(cass_wall[0] >= wall_t - 1e-6 && cass_wall[1] >= wall_t - 1e-6,
       str("the cassette's walls round the pocket are ", cass_wall, ", under a wall's ", wall_t,
           ": the filter, with its clearance, outgrows the cassette - make the filter row taller"));
assert(window[0] > 0 && window[1] > 0, "the stop's window has closed: the filter's rim is wider than half the filter");
assert(cass_d <= depth - wall_t, "the cassette is deeper than the wall");
assert(retain >= retain_min - 1e-6, str("behind the filter only ", retain, " for its retainers: the filter is too thick ",
                                       "for the cassette's depth"));

// The filter row's plenum is open behind the cassette, and the carbon row holds its stack over the clean plenum.
assert(plenum_d > 0, str("no plenum behind the cassette: ", plenum_d));
assert(plenum_h >= plenum_min - 1e-6, str("the clean air's plenum is ", plenum_h, ", under the least of ", plenum_min));
assert(carbon_row_h > 0 && filter_row_h <= lack_chamber, "the rows do not fit the chamber");

// The fans each sit in their own carbon tray, clear of its walls.
for (y = fans_at) assert(len([for (h = [[0, split_y], [split_y, open_l]])
    if (y - delta[0] / 2 >= h[0] + wall_t && y + delta[0] / 2 <= h[1] - wall_t) h]) == 1, str("a fan at ", y, " is not inside one tray"));

// The louvre stays within its tray's inner face, under the fans' plate.
assert(louvre[0] <= split_y - 2 * wall_t, "the louvre is wider than a tray");
assert(wall_t + louvre_z + louvre[1] <= plate_bot, "the louvre reaches over the fans' plate");
