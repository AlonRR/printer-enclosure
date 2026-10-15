// SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
// SPDX-License-Identifier: CC-BY-4.0

// filter-wall.params.scad - EVERY VALUE SET for the filter wall, and nothing else: no geometry, no derived values.
// Included by filter-wall.scad; not a model on its own. The bought parts' own numbers are under vitamins/.

/* [What is drawn] */
draw = "wall";      // [wall, outside, exploded, ring_front_low, ring_back_low, ring_front_high, ring_back_high, cassette_front_low, cassette_back_low, cassette_front_high, cassette_back_high, carbon_front, carbon_back]
explode = 70;       /* How far apart the exploded drawing sets the parts, mm. */
cam = [0, 0, 0];    /* The figure's --camera angles, which the xyz arrows' labels turn to face. */

/* [The printer: the slicer's facts] */
fdm_layer_h = 0.2;        /* The print profile's layer height (0.2mm QUALITY @MK3). */
fdm_extrusion_w = 0.45;   /* Its perimeters' extrusion width. */
bed = [250, 210, 210];    /* The MK3S's print volume: X, Y and Z. */

/* [The wall] */
in_depth = 50;      /* How far in from the Lack's edge the wall stands, on the floor and under the roof: the room
                       there is 50 or more (Alon, 15 Oct 2026: Q296). */
proud = 40;         /* How far out past the edge, into the room: the carbon row 90 deep (D301), and the whole wall
                       with it, to leave a plenum behind the filter (D303 a). */
wall_perims = 4;    /* A wall's perimeters. */
face_layers = 10;   /* The inner face and the end flanges: their thickness in layers. */
split_y = 225;      /* Where the wall splits along its length, from the front leg: each half fits the bed. */
filter_row_h = 310; /* The filter row, tall, and the carbon row the rest. Set, not derived from the filter, so
                       that measuring the filter changes only the cassette's pocket. */
cass_l = 390;       /* The cassette's outside, along the wall; its height is the filter row's inside. */
cass_depth = 50;    /* ...and how deep it is, from the inner face: the retainers' room, the filter, the seal and
                       the land. Set, so the ports behind it do not move with the filter's thickness. */

/* [The filter's pocket] */
clearance = 4;      /* The pocket over the filter's listed size, each side: IKEA's whole centimetres hide up to
                       5 mm either way; measure the filter, then set this and starkvind (vitamins/starkvind.scad). */
land_layers = 10;   /* The land at the pocket's back that the filter seals on: its thickness in layers. */
seal_t = 3;         /* The seal on the land, before it is squeezed: TPU, printed in lengths (Alon, 15 Oct 2026:
                       D306 b). */
seal_squeeze = 0.25;/* How much of the seal the filter squeezes. */
retain_min = 4;     /* In front of the filter, at the inner face, the least room its retainers (not drawn yet) take. */

/* [The carbon row] */
bed_depth = 36;     /* The carbon's depth: two Deltas through STARKVIND at mid grade, kept at today's dwell time
                       (scripts/analysis/scrubber-sizing.py wall, 15 Oct 2026); 48 with four. */
head_room = 8;      /* Over the carbon, for the air from the port to spread across it. */
floss_t = 6;        /* The carbon-dust floss, on its own frame under the carbon. */
fan_gap = 3;        /* Between the floss's frame and the fans. */
plate_layers = 10;  /* The fans' plate: its thickness in layers. */
plenum_min = 30;    /* Under the fans, the least the clean air's plenum may be: the outlet and the purge open from it. */
louvre = [110, 40]; /* The clean air's opening in each carbon half's inner face: along the wall, and tall. */
louvre_z = 6;       /* ...its bottom over the plenum's floor. */
fans_at = [112.5, 337.5];   /* Each Delta's centre along the wall, one in each carbon half (D300 a: two now). */

/* [Materials] */
asa_density = 1.07; /* g/cm3, for the mass estimate. */
