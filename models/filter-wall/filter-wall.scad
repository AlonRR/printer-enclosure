// SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
// SPDX-License-Identifier: CC-BY-4.0

// The filter wall: the enclosure's left wall, printed, is the chamber's one filter unit - IKEA's STARKVIND particle
// filter over a bed of carbon and the Deltas, standing between the floor and the roof and between the legs (docs/
// bentobox-scrubber.md, "One panel and one carbon row" and "Which panel"). Laid out as scad-tools' docs/
// project-layout.md says: this file includes the rest in order and draws what `draw` names - render this one. Every
// value set is in filter-wall.params.scad, the bought parts' own numbers under vitamins/, and README.md here says
// what goes where and what is not drawn yet.

use <../../scad-tools/lib/axes.scad>

include <filter-wall.params.scad>   // every value set: the Customizer's groups

/* [Hidden] */
$fn = 48;

// THE MODEL'S FILES, in the order they are read: each after every file whose values it reads.
include <vitamins/lack.scad>        // the bought parts: each one's own numbers, and its model
include <vitamins/starkvind.scad>
include <vitamins/fans.scad>
include <vitamins/sensors.scad>
include <filter-wall.layout.scad>   // the values more than one part reads, and the printed pieces' boxes
include <parts/ring.scad>           // the filter row's frame
include <parts/cassette.scad>       // the filter's frame, the one fit-critical part
include <parts/carbon.scad>         // the carbon row's trays
include <parts/print.scad>          // every part as it prints
include <assembly/wall.scad>        // the parts together, and the drawings
include <checks/guards.scad>        // the asserts
include <checks/report.scad>        // the echoes and the warnings

// ---------------------------------------------------------------- what is drawn: draw, in the params
if (len([for (p = printed) if (p == draw) p]) > 0) print_part(draw);
else if (draw == "wall") wall_figure(0, cam);
else if (draw == "outside") wall_figure(0, cam, outside = true);
else if (draw == "exploded") wall_figure(1, cam);
