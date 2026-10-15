// SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
// SPDX-License-Identifier: CC-BY-4.0

// checks/report.scad - THE ECHOES: the numbers the drawing rests on, the mass, and the warnings - each a judgement
// call that still builds. Included by filter-wall.scad; not a model on its own.

// The mass, from the walls' areas: an estimate, the hatches and the parts not drawn yet left out. The checks script
// weighs the exported parts themselves.
ring_mm3 = 2 * open_l * depth * wall_t + 2 * filter_row_h * depth * wall_t
    + 2 * (cass_y0 - wall_t) * (filter_row_h - 2 * wall_t) * face_t - (open_l - 2 * wall_t) * wall_t * plenum_d;
cass_mm3 = (cass[0] * cass[1] - window[0] * window[1]) * land_t
    + 2 * (pocket[0] + pocket[1] + 2 * wall_t) * wall_t * (cass_d - land_t);
carbon_mm3 = 2 * (split_y * z_row * face_t + 2 * (split_y + z_row) * depth * wall_t - split_y * wall_t * plenum_d);
hatch_mm3 = open_l * lack_chamber * face_t;     // the room's side, to come
mass_g = (ring_mm3 + cass_mm3 + carbon_mm3) / 1000 * asa_density;
hatch_g = hatch_mm3 / 1000 * asa_density;

echo(str("filter wall: ", open_l, " x ", lack_chamber, " x ", depth, " (", in_depth, " in, ", proud, " out); rows ",
         filter_row_h, " for the filter, ", carbon_row_h, " for the carbon"));
echo(str("filter: ", starkvind, " in a pocket of ", pocket, "; the land's window ", window, "; the cassette ", cass,
         " x ", cass_d, " deep, its walls ", cass_wall, "; the plenum behind it ", plenum_d));
echo(str("the largest filter the rows take, at this clearance: ", [cass[0] - 2 * wall_t - 2 * clearance,
         cass[1] - 2 * wall_t - 2 * clearance]));
echo(str("carbon row: the bed ", bed_bot, "..", bed_top, ", the floss from ", floss_bot, ", the fans ", fan_bot, "..",
         fan_top, ", the plate from ", plate_bot, "; the clean plenum ", plenum_h, " tall"));
for (p = pieces) echo(str("part ", p[0], ": ", print_size(p), " as it prints"));
echo(str("mass, about: ", round(mass_g), " g of ASA in the parts drawn, and ", round(hatch_g),
         " g more in the hatches to come"));

warns = [
    if (starkvind_rim < clearance + 3) str("the land overlaps the filter's rim by under 3 mm if the filter sits to one side: ",
                                          "rim ", starkvind_rim, ", clearance ", clearance),
    if (plenum_d < 30) str("the plenum behind the cassette is only ", plenum_d, " deep"),
];
for (w = warns) echo(str("WARNING: ", w));
echo(len(warns) == 0 ? "warnings : none" : str("warnings : ", len(warns)));
