// SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
// SPDX-License-Identifier: CC-BY-NC-SA-4.0
// A remix of BentoBox v2.0 by ThrutheFrame (https://www.printables.com/model/272525), CC BY-NC-SA 4.0.

// vitamins/sensors.scad - THE OUTLET'S SENSORS, as bought: an SPS30 and an SGP41, the same as the air-quality
// monitor's, reading the air after the carbon (Alon, 12 Oct 2026: D112, both). Their mount is not drawn yet.
// Included by bentobox.scad; not a model on its own.

/* [The outlet's sensors, as bought] */
sps30 = [40.69, 40.6, 12.2];    /* Sensirion SPS30 particle sensor: along its air face, the other side of its big
                                   face, and thick. MEASURED 3 Oct 2026 with calipers on the monitor's unit (40.69);
                                   40.6 and 12.2 are the datasheet's. Its air face is one of the 40.69 x 12.2 sides. */
sps30_air = [15.22, 20.38];     /* Along the air face, from its inlet end: where the inlets end, and where the outlet
                                   grille starts. MEASURED 4 Oct 2026 (calipers). Its connector is at the outlet end. */
sgp41 = [13.14, 10.6, 3.24];    /* The GY-SGP41 module: long, wide, and thick with its parts - the sensor on one
                                   face, the rest of its electronics on the other. MEASURED 2 Oct 2026. */
sgp41_hole = 3.13;              /* Its one mounting hole, for an M2.5. MEASURED 2 Oct 2026. */
/* [Hidden] */
