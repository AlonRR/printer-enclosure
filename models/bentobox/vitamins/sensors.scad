// SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
// SPDX-License-Identifier: CC-BY-NC-SA-4.0
// A remix of BentoBox v2.0 by ThrutheFrame (https://www.printables.com/model/272525), CC BY-NC-SA 4.0.

// vitamins/sensors.scad - THE OUTLET'S SENSORS, as bought: an SPS30 and an SGP41, the same as the air-quality
// monitor's, reading the air after the carbon (Alon, 12 Oct 2026: D112, both). The SPS30 lies in a pocket on the
// outlet's floor (parts/bottom.scad, D252); the SGP41's place is not drawn yet.
// Included by bentobox.scad; not a model on its own.

/* [The outlet's sensors, as bought] */
sps30 = [40.69, 40.6, 12.2];    /* Sensirion SPS30 particle sensor: along its air face, the other side of its big
                                   face, and thick. MEASURED 3 Oct 2026 with calipers on the monitor's unit (40.69);
                                   40.6 and 12.2 are the datasheet's. Its air face is one of the 40.69 x 12.2 sides:
                                   its two inlets at one end, its outlet grille at the other. */
sps30_air = [15.22, 20.38];     /* Along the air face, from its inlet end: where the inlets end, and where the outlet
                                   grille starts. MEASURED 4 Oct 2026 (calipers). Its connector is at the outlet end. */
sps30_open = [5.2, 1.0];        /* Along the air face, how much of each end has no opening: the inlet end - the inlets
                                   start 5.20 from it, MEASURED 4 Oct 2026 - and the outlet end, at least the 1.0 the
                                   monitor's ledges reach under it. */
sps30_nub = 0.155;              /* Each end of the air face: the plastic nubs on the faces there. MEASURED 3 Oct 2026:
                                   41.00 across them. */
sps30_plug = [2.0, 10.5];       /* Its plug and lead, along the connector face - the face opposite the air face - from
                                   the outlet end. From a photo, 2 Oct 2026, scaled against the sensor... */
sps30_wires = [3.0, 8.6];       /* ...and where its five leads leave the plug, along the face from the same end. The last
                                   three are the air-quality monitor's (sps_nub, conn_from, conn_to), as are its rules:
                                   Sensirion's, in that repository's docs/design.md. */
sps30_wire = 1.0;               /* A lead's outside, about: the monitor's "an SPS30 lead wire of about 1 mm". */
sps30_plug_out = 0;             /* How far the plug, with its lead in it, stands out of the connector face: it sits
                                   flush. MEASURED (Alon, 14 Oct 2026: Q256)... */
sps30_lead_bend = 1.95;         /* ...and the leads, turned down out of it, reach this far out of the face, all told.
                                   MEASURED (Alon, 14 Oct 2026: Q256). */
sgp41 = [13.14, 10.6, 3.24];    /* The GY-SGP41 module: long, wide, and thick with its parts - the sensor on one
                                   face, the rest of its electronics on the other. MEASURED 2 Oct 2026. */
sgp41_hole = 3.13;              /* Its one mounting hole, for an M2.5. MEASURED 2 Oct 2026. */
/* [Hidden] */

// The SPS30 as it lies in its pocket (parts/bottom.scad): label up, its body and the nubs on its ends, sep off the
// floor. A control moves it (sps30_shift).
module sps30_model() translate(sps30_shift + [0, 0, sep]) {
    translate([sps30_x[0], sps30_yy[0], base_floor]) cube([sps30[0], sps30[1], sps30[2]]);
    for (x = [sps30_x[0] - sps30_nub, sps30_x[1]]) translate([x, sps30_yy[0], base_floor]) cube([sps30_nub, sps30[1], sps30[2]]);
}
