// SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
// SPDX-License-Identifier: CC-BY-NC-SA-4.0
// A remix of BentoBox v2.0 by ThrutheFrame (https://www.printables.com/model/272525), CC BY-NC-SA 4.0.

// vitamins/fasteners.scad - THE SCREWS AND NUTS, M3 and M2, by their standards. Included by bentobox.scad; not a model on its own.

/* [Screws and nuts, by their standards] */
small_screw = [2, 3.8, 2];      /* The clamp's screws, M2 socket head, ISO 4762: the thread, the head's diameter and height. */
small_nut = [4, 1.6];           /* The M2 hex nut, ISO 4032: across its flats, and its height. */
m25_nut = [5, 2];               /* The M2.5 hex nut, ISO 4032: across its flats, and its height - the SGP41's. */

screw_d   = 3.0;    /* M3. */
nut_af    = 5.5;    /* The M3 hex nut, across its flats - ISO 4032... */
nut_h     = 2.4;    /* ...and its height, the largest allowed. */

m3_head = [5.5, 3];     /* The M3 socket head, ISO 4762: the head's diameter and height. */
/* [Hidden] */
