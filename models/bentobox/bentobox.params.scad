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
  hepa_ring a frame for pleated HEPA paper off a roll, in place of the bought cartridge: a ring that stands
  hepa_cap  on the HEPA holder's ledge, and two TPU caps, one at each end of a cut piece of paper, whose
            wedges close the ends of the pleats that the dirty air comes into. Everything about it follows
            from the paper's three values below, so other paper means changing those and exporting again.
  auto_base the bottom from Strangwooduk's BentoBox Auto in place of the duct and the fan case: a base
  auto_fans with a bay for the electronics under the duct and a tube for the wires down to it, its fan
  auto_plate section, and the plate that closes the bay. Its heat-set inserts become nuts in slots.

COORDINATES are the box as it stands: X across it, Y along it, Z up, with Z = 0 on the floor the duct
stands on. X and Y are centred. The duct's outlet faces -X.

The original's STLs are not in this repository; original/README.md says where they come from. They were
exported in place, assembled, in one frame of their own, which bentobox.layout.scad maps into this one.
*/

/* [Which part] */
part = "section";   /* "section", "hepa_ring", "hepa_cap", "auto_base", "auto_fans", "auto_plate" or "gasket_test": the parts the remix adds or changes. bentobox-assembly.scad shows them in place. */

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
hepa_ledge = 4;     /* The ledge the cartridge rests on, at the holder's bottom. */
hepa_open = [36.8, 78];     /* The ledge's opening, X and Y, its corners rounded 2 mm: the air's way down. */
hepa_open_r = 2;
hepa_pocket_l = 82; /* The pocket above the ledge, along Y; across, it is the inside, in_w. Square corners. */
hepa_pocket_straight = 15.6;   /* Its end walls run straight this high above the ledge, then flare out; its side walls stay straight. */
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

/* [Your own HEPA paper, and the frame that holds it] */
// The paper: pleated, sold by the metre. These three describe it; change them for other paper, then export
// the ring and the cap again. A pleat is one fold up and one down: the dirty air comes into the channels
// open at the top and leaves by those open at the bottom. Each cap has a wedge in the end of every channel
// open at the top, and a tooth in the end of every channel open at the bottom, so the paper's cut end sits
// in a zigzag slot between them; the air's pressure, higher on the dirty side, presses the paper onto the
// teeth and closes the slot. Along the long sides the paper runs on half a pleat past its last top fold,
// down to the foot of the ring's wall, into a slot between the wall and a strip moulded onto it: the dirty
// air between that flap and the wall presses it onto the strip, the whole length.
paper_depth = 20;   /* The pleats' depth, fold to fold: the pack's thickness. The listing's "folds 20mm". <<CONFIRM with a ruler>> */
paper_pitch = 100 / 30;   /* One pleat, top fold to top fold. DERIVED, not measured: 1200 mm of paper in 20 mm folds packs into 100 mm, so about 30 pleats. <<CONFIRM by counting the folds>> Only the whole number of pleats in the ring follows from it: 28 to 30 folds in 100 mm all give the same parts. */
paper_t = 0.3;      /* The paper's thickness - an estimate. <<CONFIRM with calipers>> The slots are slot_play wider than this: paper thicker than a slot will not go in, thinner sits loose in it, and the air presses it onto the teeth and the strips. */
paper_flaps = true; /* The long edges cut on a bottom fold, so each side keeps half a pleat more, as a flap held in the ring's slot. false: cut on a top fold, which rests against the wall. */
ring_play = 0.2;    /* Between the ring and the holder's pocket, each side. */
ring_beads = 3;     /* The ring's wall, in beads. */
ring_strip_beads = 3;   /* With flaps: the strip along the foot of each long wall that the flap is pressed onto, in beads... */
ring_strip_h = 8;   /* ...and its height. It stands in the clean channel between the flap and the first full pleat, which narrows upwards to the fold: fit check check_ring_paper says whether it clears the paper. */
cap_plate = 1.6;    /* Each cap's plate, behind its wedges: eight layers. */
cap_wedge_l = 4;    /* How far the wedges and teeth reach into the pack, along the pleats. */
cap_teeth_below = true;   /* The teeth from below. Without them each wedge fills its channel to the paper's faces, and the air's pressure pushes the paper away from it. */
slot_play = 0.2;    /* The slots the paper sits in - the caps' zigzag, and the ring's along its long walls - are this much wider than the paper. They must print open: at least a bead wide. */
cap_squeeze = 0.1;  /* Each cap is this much wider than the ring's inside, each side: TPU, pressed in, so its edges seal on the ring's walls. */

/* [The bottom: Strangwooduk's BentoBox Auto, or ThrutheFrame's duct and fan case] */
bottom = "auto";    /* "auto": the Auto's base, fan section and plate, its inserts made nuts. "bambu": ThrutheFrame's duct and fan case, as they come. The airflow simulation keeps the duct either way. */
// The BentoBox Auto VOC Sensor system, by Strangwooduk (MakerWorld 1882240), comes as one STEP file;
// scripts/bentobox-auto-stl.py writes its STLs into original/. MEASURED by sectioning them, 8 Oct 2026, in
// this frame. The base is ThrutheFrame's duct with its floor raised over a bay for the electronics: 46 tall
// where the duct is 52, its outlet the whole -X face between its end walls, 101 x 37. The fan section is the
// fan case's top exactly - tongue, inside and magnet holes, at four cuts - with each fan held by two screws
// through its floor into the base, and a hole for the wires between the fans, down a tube to the bay.
auto_fans_dz  = -30;    /* The fan section, from where the STEP has it, to the stack: its tongue is then the fan case's. */
auto_plate_dz = 35.7;   /* The plate, from where the STEP has it, up into the base's recess: its ends against the seats' ceiling. */
auto_floor_t  = 3;      /* The fan section's floor, which the fans' screws pass. */
auto_fan_air  = 37;     /* The fan section's floor opening under each fan, at fan_ys. Nothing new may stand under one. */
auto_fan_screws = [[-16, -46, 180], [-16, 46, 180], [16, -14, 135], [16, 14, 225]];   /* The fans' screws, X and Y, and the way each nut's slot opens, in degrees from +X: the two at the end walls to the outlet, the two at the long wall between the fans, clear of their air. */
auto_fan_insert = [4.2, 4];     /* The heat-set inserts' holes the nuts replace, d and depth, down from the base's top. */
auto_plate_screws = [[-1, -48, 270], [-1, 48, 90]];   /* The plate's two screws, X and Y, 1.6 mm nearer the end walls than the Auto's, where the end wall's fillet stands high enough over a sunk head's screw; their slots open out through the end walls, so a nut goes in from outside. */
auto_plate_inserts = [[-1, -46.4], [-1, 46.4]];   /* The Auto's own plate screws: their inserts' holes in the base, filled, and their countersunk holes in the plate, filled. */
auto_plate_insert = [3.8, 3.5]; /* ...those inserts' holes, d and depth, up from the seats' ceiling. */
auto_base_z0  = 6;      /* The base's bottom face. */
auto_seat_z   = 8.5;    /* The seats' ceiling, which the plate's ends press against, 2.5 mm up inside the base's bottom face. The Auto's plate is 1.8 thick; this remix's fills the recess, flush with the bottom face. */
auto_plate_room = 18.8; /* Over each plate screw, Y +/-48, the end wall's fillet - the duct's floor - stands this high: the screw's hole stops under it. */
auto_conduit  = [16.38, 0, 6];  /* The wires' way down: X, Y and d - the floor's hole, and the tube under it to the bay. */
auto_conduit_z = [16, 55];      /* ...from the bay's ceiling to the floor's top. */

/* [Nuts and screws, where the Auto had heat-set inserts] */
screw_d   = 3.0;    /* M3. */
nut_af    = 5.5;    /* The M3 hex nut, across its flats - ISO 4032... */
nut_h     = 2.4;    /* ...and its height, the largest allowed. */
nut_fit   = 0.15;   /* A nut's slot, per side, on top of fdm_hole_comp: the nut slides in and the screw holds it. */
screw_tip = 1.5;    /* A screw must stand this far out of its nut. */
screw_lengths = [6, 8, 10, 12, 16, 20, 25, 30, 35, 40];   /* M3 lengths to choose from: the build has many. */
fan_t     = 20;     /* The fans, 40 x 40 x 20: their screws pass through them, the heads on their top flanges. */
nut_roof  = 2;      /* Over a fan screw's nut, under the base's top face: ten layers. */
nut_floor = 1.5;    /* Under a slot: a fan screw's, and a plate screw's over the seat. */
post_beads = 3;     /* The new post round a fan screw's slot, each side of it, in beads. */
post_clear_air = true;   /* Cut the posts back clear of the fans' air: round, they would reach 0.3 mm under the floor's openings. */
nut_slot_out = 12;  /* How far past its screw each slot is cut towards its mouth: out into the open. */
plate_head = [5.5, 3];  /* The plate's screws, M3 socket head, ISO 4762: the head's diameter and height. */
head_sink = 0.2;    /* Each head sits this far up inside the base's bottom face... */
head_room = 0.4;    /* ...in a counterbore this much wider than the head, past fdm_hole_comp: room for the key. */
lobe_cap = 1;       /* The plate over each head: the counterbore is in a lobe that rises from the plate into a pocket in the base... */
lobe_play = 0.2;    /* ...with this much room round it and over it, so the plate's ends bear on the seats, not the lobes. */
meet = 0.05;        /* A new face kept this far off an imported one it would otherwise share: the STL's float32 corners are not where the same number computed here is, and faces a hair apart make slivers the slicer removes. */

/* [Gaskets - the test before any ring] */
// The joints between the HEPA and the fans are under suction, and printed TPU is stiff: what a millimetre of
// hollow bead pushes back with is on no datasheet, and it decides whether the stack's magnets can squeeze one.
coupon_beads = [[1.6, 1.6, 0.45], [2, 2, 0.45], [2.5, 2.5, 0.45]];   /* The beads to try: width, height, wall. */
coupon_l = 60;      /* Each bead's length in the test piece. */

/* [Printing - mirrors the print profile; scad-check.sh compares the first two with the slicer's] */
fdm_layer_h     = 0.2;
fdm_extrusion_w = 0.45;
fdm_hole_comp   = 0.15;   /* Added to every hole's radius - fdm-design-rules section 2. Not cross-checked. */
