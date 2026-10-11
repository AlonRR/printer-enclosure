// SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
// SPDX-License-Identifier: CC-BY-NC-SA-4.0
// A remix of BentoBox v2.0 by ThrutheFrame (https://www.printables.com/model/272525), CC BY-NC-SA 4.0.

// The fans' plug mate, in ASA, on its underside as it prints: each fan's own 3-pin plug pushes onto pins made of
// the bared ends of 22 AWG solid wire, standing up out of it. Everything is in bentobox.scad, and this file only
// pins the part; it is drawn there, and needs no original.
// ON HOLD, not to print (Alon, 11 Oct 2026): it waits for the fan connector it copies to be settled, and then
// takes that connector's hold and sizes. scripts/bentobox-print.sh leaves it out.
include <bentobox.scad>
part = "fan_mate";
