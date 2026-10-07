// SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
// SPDX-License-Identifier: CC-BY-SA-4.0
// A remix of LunchBox by GekoPrime (https://www.printables.com/model/468166), CC BY-SA 4.0.

/*
Everything you SET for the LunchBox remix. Render lunchbox.scad, not this file.

The LunchBox is a carbon + HEPA scrubber. Air enters the grid on the body's front and passes the HEPA paper,
then the carbon bed between two perforated walls. It goes down a channel at the back to the fan section
underneath, whose fans blow it out at the front. This remix adds, for a build with two 40 x 40 x 20 fans
(Delta EFB0412VHD):

  insert      a drop-in section between the body and the fan section, holding a flat filter sheet that
              stops carbon dust reaching the fans. It mates with the unmodified parts on both faces.
  gaskets     flat TPU, one for the lid joint and one for each joint at the fans.
  blank       closes the fan section's middle bay.
  tabs        two per short end at the fan joint, clamped with an M3 screw and a nut in a side slot. The
              body and the fan section get them added to the original STLs. The lid has none: it keeps
              its own two screws, which clamp its gasket (Alon, 7 Oct 2026).

COORDINATES are the box as it stands: X along its length, Y from the front (the grid, where air comes in)
to the back, Z up, with Z = 0 at the joint between the body and the fan section. X is centred.

The original's STLs use a different frame (Z points down, Y from the front towards -Y) and are not in
this repository; lunchbox.layout.scad maps them into this one. Download them from the Printables page into
original/ - see the README there.
*/

/* [Which part] */
part = "insert";   /* "insert", "gasket-lid", "gasket-fans", "blank", "body" or "fans". The last two are the originals with tabs added, and need original/. lunchbox-assembly.scad shows them together. */
insert_tabs = true;   /* false makes the insert a plain drop-in, for a LunchBox built without tabs. */
/* [The original LunchBox - measured by sectioning its STLs, 6-7 Oct 2026] */
// All MEASURED: horizontal sections of filter_caddy_110x74x21.stl (the body), filter_lid_110x74x21.stl and
// axial_fan_caddy_40x28.stl (the fan section), read to 0.1 mm. The originals agree with each other to that
// precision (the outlines are identical), so the numbers are the author's design values.
lb_l    = 124;      /* Outside length (X). */
lb_d    = 60;       /* Outside depth (Y). */
lb_r    = 2;        /* The outline's corner radius. */
lb_wall = 2;        /* The body's wall; the lid's plug fills the inside of it, 120 x 56. */
body_h  = 117.43;   /* The body, from the fan joint to the lid joint. */
lid_t   = 2;        /* The lid's plate. Its plug, lid_t more, sits inside the body's top. */
lid_screw_ys = [5, 55];   /* The lid's own two screws, at X = 0. They clamp the lid's gasket. Their 3 mm holes in the body start in bosses 5.4 to 7.9 mm below its rim and run at least 12.5 mm deep (MEASURED: cut every 2.5 mm, 7 Oct 2026). */
lid_screw_l  = 20;  /* So M3 x 20: the lid's top stands 3 mm above the rim on its gasket, so the tip ends 17 mm below it - 9 to 11.6 mm into a boss, inside the hole. */
groove_w = 2.6;     /* The channel in the body's bottom face, inside its wall, that the fan section's lip seats in... */
groove_h = 2;       /* ...and its depth. */
hepa_hw  = 55;      /* The HEPA holder's opening in the body's bottom face: X +/-55, from the wall to Y = hepa_y1. */
hepa_y1  = 23;
cap_y1   = 41.1;    /* The carbon bed's floor, at the body's bottom face, ends here; behind it is the channel that takes the air down to the fans. */
fans_h   = 44.6;    /* The fan section, from its bottom to the rim the body sits on. Its lip stands groove_h higher. */
fans_floor = 4;     /* The fan section's floor, under the fans. */
fan_slot_hw = 60.3; /* The slot the three fans stand in, side by side: X +/-60.3 ... */
fan_slot_y1 = 30.6; /* ...from the front wall (Y = lb_wall) to here, where the walls step in. Behind it, the plenum with its curved floor. */
plenum_hw   = 58;   /* The plenum's opening in the rim, X +/-58, from fan_slot_y1 to lip_back_y0. */
lip_t_side  = 1.7;  /* The fan section's lip: along each side, X 58 to 59.7, from fan_slot_y1 back... */
lip_back_y0 = 55.7; /* ...and across the back, Y 55.7 to 57.7, its two outer corners rounded to lb_r. It rises groove_h above the rim. */
lip_t_back  = 2;

/* [The insert and its filter sheet] */
sheet_t  = 5;       /* The space the sheet lies in. Polyester filter floss, about 5 mm loose; it is not compressed. */
plenum_h = 5;       /* Free air above the sheet: the channel is only 14 mm deep, and this lets its air spread forward over the whole sheet. */
grid_t   = 2;       /* The grid the sheet lies on. */
grid_pitch = 10;    /* Ribs along Y, this far apart; two more ribs cross them along X. */
grid_beads = 2;     /* Each rib is this many beads wide. */
ledge_beads = 3;    /* A ledge round the cavity at the grid's level: the ribs end on it, and the sheet's edges seal on it. */

/* [The gaskets - TPU] */
gasket_t = 1.0;     /* Five layers. Every joint's stack height counts it, uncompressed. */

/* [The tabs and their screws] */
tab_ys    = [15, 45];   /* The two tabs on each short end, by Y. Alon, Q81, 7 Oct 2026: two per side. */
tab_l     = 9;      /* How far a tab stands out from the end wall. */
tab_w     = 10;     /* Its width, along Y. */
tab_t     = 6;      /* Its height, on the body and on the fan section. */
tab_axis  = 4.5;    /* The screw, this far out from the end wall: the nut's slot then stops about 1 mm short of it. */
screw_d   = 3.0;    /* M3. */
nut_af    = 5.5;    /* The M3 hex nut, across its flats - ISO 4032... */
nut_h     = 2.4;    /* ...and its height, the largest allowed. */
nut_fit   = 0.15;   /* The nut's side slot, per side, on top of fdm_hole_comp: the nut slides in and the screw holds it. */
screw_tip = 1.5;    /* A screw must stand this far out of its nut. */
screw_lengths = [8, 10, 12, 16, 20, 25, 30, 35, 40];   /* M3 lengths to choose from. */

/* [The blank for the middle bay] */
blank_fit = 0.2;    /* Less than the bay, per side, in X and in depth. The fans beside it are 40 mm on the nose. */
blank_face = 2;     /* Its front face, which closes the bay. */
blank_beads = 3;    /* Its side walls. */

/* [Printing - mirrors the print profile; scad-check.sh compares the first two with the slicer's] */
fdm_layer_h     = 0.2;
fdm_extrusion_w = 0.45;
fdm_hole_comp   = 0.15;   /* Added to every hole's radius - fdm-design-rules section 2. Not cross-checked. */
