// SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
// SPDX-License-Identifier: CC-BY-4.0

// vitamins/sensors.scad - THE OUTLET'S SENSORS: a Sensirion SPS30 and a GY-SGP41 module, in the clean air after the
// fans. Included by filter-wall.scad; not a model on its own. Drawn at their own origins, corner at 0. Their numbers
// are the BentoBox remix's, measured there (models/bentobox/vitamins/sensors.scad).

/* [Hidden] */
sps30 = [40.69, 40.6, 12.2];    /* Along its air face, the other side of its big face, and thick. MEASURED 3 Oct 2026
                                   (the BentoBox's). */
sgp41 = [13.14, 10.6, 3.24];    /* The GY-SGP41 module: long, wide, and thick with its parts. MEASURED 2 Oct 2026
                                   (the BentoBox's). */

module sps30_sensor() color([0.85, 0.85, 0.8]) cube(sps30);
module sgp41_sensor() color([0.2, 0.45, 0.25]) cube(sgp41);
