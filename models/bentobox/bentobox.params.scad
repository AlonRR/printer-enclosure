// SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
// SPDX-License-Identifier: CC-BY-NC-SA-4.0
// A remix of BentoBox v2.0 by ThrutheFrame (https://www.printables.com/model/272525), CC BY-NC-SA 4.0.

/*
Everything you SET for the BentoBox remix. Render bentobox.scad, not this file.

BentoBox v2.0 is a carbon + HEPA scrubber: a stack of parts, each held to the next by four magnets and a
tongue in a groove. Air comes in through the cover on top and passes an 80 x 40 x 15 mm HEPA cartridge.
Then it goes through the C-MAG, a cartridge holding the carbon pellets in three thin trays, one above the
other. Two 40 mm fans in the fan case pull it down and blow it into the duct, which turns it out of one
long side, at the floor. This remix adds:

  section   a section between the carbon housing and the fan case, holding a flat filter sheet that stops
            carbon dust reaching the fans. Its top is the fan case's tongue and its bottom the carbon
            housing's groove, and it has the same magnets, so it drops into any BentoBox v2.0 stack.

COORDINATES are the box as it stands: X across it, Y along it, Z up, with Z = 0 on the floor the duct
stands on. X and Y are centred. The duct's outlet faces -X.

The original's STLs are not in this repository; original/README.md says where they come from. They were
exported in place, assembled, in one frame of their own, which bentobox.layout.scad maps into this one.
*/

/* [Which part] */
part = "section";   /* "section": the only part the remix adds. bentobox-assembly.scad shows it in the stack. */

/* [The original BentoBox v2.0 - MEASURED by sectioning its STLs, 7 Oct 2026] */
// Every part has the same outline and the same inside, to 0.05 mm; read from horizontal and vertical cuts of
// each STL (scad-tools stl-inspect.py).
bb_w     = 52.8;    /* Outside, across (X). */
bb_l     = 112.8;   /* Outside, along (Y). */
bb_r     = 3.9;     /* The outline's corner radius. */
bb_chamfer = 0.4;   /* Every part's outside edges, top and bottom. */
in_w     = 40.8;    /* The inside of every part, across... */
in_l     = 100.8;   /* ...and along... */
in_r     = 4.4;     /* ...and its corner radius. */
stl_origin = [163.25, 286, -201.2];   /* Where this frame's origin is in the STLs' frame: the box's centre, and the duct's underside. */
duct_h   = 52;      /* The duct, from the floor to the fan case. */
fans_h   = 33;      /* The fan case, from the duct to the carbon housing. */
fans_floor = 2;     /* The fan case's floor; the fans stand on it, blowing down through a 37 mm hole each. */
fan_ys   = [-30, 30];   /* The two fans' centres, along Y, on X = 0. Their screws are on a 32 mm square. */
carbon_h = 77.6;    /* The carbon housing, from the fan case to the HEPA holder. */
carbon_floor = 4;   /* Its floor, with an opening over each fan: X +/-18, Y 2 to 48 each side of the middle. */
hepa_h   = 50;      /* The HEPA holder. */
hepa_ledge = 4;     /* The ledge the cartridge rests on, at the holder's bottom. Its opening: X +/-18.4, Y +/-39. */
cover_top = 3.4;    /* The cover's top, above the holder's top. */
// The joint, the same at every one: a tongue on the top of the part below, in a groove in the bottom of the
// part above, both rings round the inside. Offsets are outwards from the inside's outline.
tongue_h    = 1.6;  /* The tongue's height... */
tongue_base = 1.6;  /* ...its outer face at its base... */
tongue_top  = 0.8;  /* ...and at its top: the face slopes. Its inner face is the inside's outline. */
groove_h    = 2.0;  /* The groove's depth... */
groove_out  = 1.7;  /* ...its outer face, straight up from the bottom face for groove_flat... */
groove_flat = 0.4;
groove_out_top = 0.9;   /* ...then sloping to here at its top... */
groove_in   = -0.1; /* ...and its inner face, 0.1 mm INSIDE the inside's outline: the part's floor or rim makes that wall. */
mag_d    = 4.2;     /* The magnets' holes: 4 x 2 mm magnets, a hole in each face of each joint... */
mag_h    = 2.0;
mag_xy   = [22.5, 52.5];    /* ...at the four corners, +/-X, +/-Y. */
// The C-MAG, in its own frame: L along its trays' stacking, W along the box, T across it. It stands in the
// carbon housing on its end, trays horizontal, filling the inside but for 0.4 mm all round.
cmag     = [72, 100, 40];   /* L, W, T: its outside. Its walls are 2 mm; its ends are open behind grills. */
cmag_grills = [1.8, 24.6, 47.4, 70.2];   /* The four grills' slots, along L. The grills are 1.4 mm thick, in 1.6 mm slots. */
cmag_grill_t = 1.4;
cmag_fill = 9;      /* The pellets fill each tray this deep with the C-MAG lying open on its side: the line moulded inside it (the user guide: "to the indicator line"), 9 mm above its floor. */
hepa_cart = [80, 40, 15];   /* The HEPA cartridge, bought: L x W x H. */
duct_out = [-49.4, 49.4, 6, 52];   /* The duct's outlet, the whole -X face between its end walls: Y and Z. */
cover_win = [18, 48];       /* The cover's window, X and Y +/-: the pattern's bars span it. */

/* [The section and its filter sheet] */
grid_t   = 3;       /* The grid the sheet lies on. The groove under it is groove_h deep, so the grid's rim roofs it. */
sheet_t  = 5;       /* The space the sheet lies in. Polyester filter floss, about 5 mm loose; it is not compressed. */
plenum_h = 5;       /* Free air above the sheet: the carbon housing's floor has an opening over each fan only, and this lets their air spread over the whole sheet. */
grid_pitch = 10;    /* Ribs across the box (along X), this far apart; two more ribs cross them along Y. */
grid_beads = 2;     /* Each rib is this many beads wide. */
ledge_beads = 3;    /* A ledge round the inside at the grid's level: the ribs end on it, the sheet's edges seal on it, and it is the groove's inner wall. */

/* [Printing - mirrors the print profile; scad-check.sh compares the first two with the slicer's] */
fdm_layer_h     = 0.2;
fdm_extrusion_w = 0.45;
fdm_hole_comp   = 0.15;   /* Added to every hole's radius - fdm-design-rules section 2. Not cross-checked. */
