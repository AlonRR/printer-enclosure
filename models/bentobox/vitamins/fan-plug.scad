// SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
// SPDX-License-Identifier: CC-BY-NC-SA-4.0
// A remix of BentoBox v2.0 by ThrutheFrame (https://www.printables.com/model/272525), CC BY-NC-SA 4.0.

// vitamins/fan-plug.scad - THE FANS' OWN 3-PIN PLUG, the KK 254 kind, as Alon measured it: its numbers, and its model for the checks, never printed. Included by bentobox.scad; not a model on its own.

/* [The fans' plug, as measured] */
fan_plug = [8.0, 5.2, 12.77];   /* MEASURED (Alon, 9 Oct 2026): the fan's plug across its pins (A), its thickness without the ribs (B) - over the 0.3 mm lip across its open end between the ribs, 4.9 elsewhere between them, so the key keyed to B clears both - and its length along the wires (C). */
fan_plug_d = 2.55;      /* MEASURED: from the plug's face with the text to the nearer wall of a pin's hole (D). */
fan_plug_hole = 1.45;   /* MEASURED: a pin hole's size in the plug's end face. The pins stand in line with the holes' middles. */
fan_plug_ribs = [1.1, 5.2, 6.67];   /* MEASURED: the ribs on the face opposite the text: each one's width, the gap between them, and the plug's thickness over them. */
fan_plug_lip = [0.3, 2.2];  /* MEASURED (Alon, 9 Oct 2026): the lip across the plug's open end between the ribs - its height and its length along the plug. */
fan_plug_pitch = 2.54;  /* KK 254's pitch, between the plug's holes - the plug's, so the checks hold it fixed. */
/* [Hidden] */

// The fan's plug as measured, to check the mate against and to draw, never printed: its body, the lip across its
// open end between the ribs, the two ribs on the face opposite the text, and a hole over each pin at the plug's own
// pitch, 1 mm deeper than the pins stand - a real plug takes a header's 6 mm pins and more, and the fan connector's
// female has 7 mm cavities. Seated on the block, at plug x.
module fan_plug_model(x) let(a = fmp_plug_a, b = fan_plug[1], c = fan_plug[2], rw = fan_plug_ribs[0], rg = fan_plug_ribs[1],
                             o = fan_plug_hole, l = fan_plug_lip, bk = fmp_back - fan_plug_lip[0])
    translate([x, 0, fan_mate_base[0]]) difference() {
        union() {
            translate([-a / 2, -bk, 0]) cube([a, b - l[0], c]);
            translate([-rg / 2 - 0.01, -fmp_back, 0]) cube([rg + 0.02, l[0] + 0.01, fmp_plug_lip_l]);
            for (s = [-1, 1]) translate([s * (rg + rw) / 2 - rw / 2, -fmp_ribs, 0]) cube([rw, fmp_ribs - bk + 0.01, c]);
        }
        for (k = [-1 : 1]) translate([k * fan_plug_pitch - o / 2, -o / 2, -1]) cube([o, o, fan_mate_pin + 2]);
    }
