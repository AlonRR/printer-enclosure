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
  auto_plate section, and the plate that closes the bay. Its heat-set inserts become nuts: pulled into
            pockets for the fans' screws, in slots for the plate's.

COORDINATES are the box as it stands: X across it, Y along it, Z up, with Z = 0 on the floor the duct
stands on. X and Y are centred. The duct's outlet faces -X.

The original's STLs are not in this repository; original/README.md says where they come from. They were
exported in place, assembled, in one frame of their own, which bentobox.layout.scad maps into this one.
*/

/* [Which part] */
part = "section";   /* "section", "auto_base", "auto_fans", "auto_plate", "carbon", "hepa", "bead_ring", "clamp_lower", "clamp_upper", "clamp_sample", "joint_sample" or "joint_sample_bead": the parts the remix adds or changes. bentobox-assembly.scad shows them in place. */

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

/* [Your own HEPA paper, and the clamp that holds it - Alon, 8 Oct 2026: D127] */
// The paper: pleated, sold by the metre. These four describe it; change them for other paper, then export the
// clamp's frames again. A pleat is one fold up and one down: the dirty air comes into the channels open at the
// top and leaves by those open at the bottom. The clamp is a cassette of two ASA frames with the paper between
// them, screwed together at its ends and dropped onto the holder's ledge. The upper frame has a wedge in the end
// of every channel open at the top; the lower frame has a tooth in the end of every channel open at the bottom;
// screwed together they pinch the paper's cut end in the zigzag slot between them. Along each long side the paper
// runs on half a pleat past its last top fold, as a flap, down to the lower frame's rim: the upper frame's half
// wedge outside it and the lower frame's tooth inside it pinch it, the whole length. Each end is a block in two
// halves, the upper on the lower - the one place the frames meet - and two screws draw them together.
hepa_full = true;   /* Cut the HEPA holder's pocket out to the box's whole inside, in_w x in_l, from its ledge up, and the ledge's opening with it (Alon, 8 Oct 2026: "enlarge the HEPA area"). The original's ends are solid funnels round its 80 mm cartridge. The clamp is drawn for this pocket. */
hepa_ledge_w = 2;   /* MEASURED: the ledge round the original's opening; the enlarged opening keeps it. */
paper_depth = 20;   /* The pleats' depth, fold to fold: the pack's thickness. The listing's "folds 20mm". <<CONFIRM with a ruler>> */
paper_pitch = 100 / 30;   /* One pleat, top fold to top fold. DERIVED, not measured: 1200 mm of paper in 20 mm folds packs into 100 mm, so about 30 pleats. <<CONFIRM by counting the folds>> Only the whole number that fills the clamp matters. */
paper_t = 0.3;      /* The paper's thickness - an estimate. <<CONFIRM with calipers>> */
paper_flaps = true; /* The long edges cut on a bottom fold, so each side keeps half a pleat more, as a flap the clamp pinches. false: cut on a top fold. */
clamp_slot = 0.2;   /* The zigzag slot between the frames' wedges and teeth, screwed together: under the paper's thickness, so the screws pinch it. The two sides are separate parts, so it need not print open. A first guess, for the sample to try. */
clamp_play = 0.2;   /* Between the cassette and the holder's pocket, each side. */
clamp_wedge_l = 4;  /* How far the wedges and teeth reach into the paper at each end, along the pleats. */
clamp_rim = 1.2;    /* The lower frame's rim round its bottom, on the ledge: six layers... */
clamp_band = 1.6;   /* ...and the upper frame's band round its top: eight. */
clamp_fold_gap = 0.2;   /* The band and the rim stand this clear of the paper's folds, and the wedges and teeth of the other frame's end block, so the end blocks' halves are the one hard stop. */
clamp_blk = 6.5;    /* Each end block, along the pleats: room for an M2 nut's pocket, its flats along the pleats, and two beads each side. */
clamp_screw_x = 13; /* Each end's two screws, this far either side of the middle. */
small_screw = [2, 3.8, 2];      /* The clamp's screws, M2 socket head, ISO 4762: the thread, the head's diameter and height. */
small_nut = [4, 1.6];           /* The M2 hex nut, ISO 4032: across its flats, and its height. */
small_screw_lengths = [6, 8, 12, 16, 20];   /* The M2 lengths HomeBox records, 8 Oct 2026. */
small_nut_roof = 1.6;           /* Over each nut, under the end block's split: eight layers. */

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
auto_fan_screws = [[-16, -46, 40, 90], [-16, 46, -40, 270], [16, -14, 230, 180], [16, 14, 130, 180]];   /* The fans' screws, X and Y; which way a flat of each nut's pocket faces, in degrees from +X - 5 off the nearer fan, towards the post's wall, so the pocket keeps a wall to both; and the way out of the post's wall into the room: the two at the end walls, the two at the long wall. */
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
nut_floor = 1.5;    /* Under a plate screw's slot, over the seat. */
post_beads = 3;     /* The new post round a fan screw's pocket, past its corners, in beads. */
post_clear_air = true;   /* Cut the posts back clear of the fans' air: round, they would reach under the floor's openings. */
// The Auto has a lug under each insert: 7 mm wide, round at its end, its sides on 2 mm fillets into its wall, standing
// 7 mm out of it; straight down to Z 47, then on a round into 45 degrees, which meets the wall at Z 38. MEASURED by
// sectioning the base, 8 Oct 2026. Each fan screw's post is that lug made big enough for the nut, and holds it inside.
auto_post_wall = 3.4;    /* MEASURED: each fan screw's axis, this far from its wall's face: the end walls' at Y +-49.4, the long wall's at X 19.4. */
post_fillet = 2;    /* A post's sides run into its wall on fillets this round, as the Auto's lugs do... */
post_blend = 0.15;  /* ...tangent to a line this far inside the wall's face, so the fillet and the original's face cross at a slant, not tangent. */
post_round = 2;     /* Under a post, the round from its straight side into its 45-degree underside. */
post_foot = 37.7;   /* Where a post's 45-degree underside meets its wall: 0.3 under the Auto's lug's, so it holds the lug inside it. */
nut_slot_out = 12;  /* How far past its screw each slot is cut towards its mouth: out into the open. */
// Alon, 8 Oct 2026 (D123, D124): the fans' screws take pull nuts. Each nut goes up a hex pocket under its post, on
// the screw's axis, open downwards, into a tight seat under the roof; a screw from above pulls it up into the seat,
// and it stays there. Do it with a spare screw before the fan section goes on.
pull_fit = 0.05;    /* A fan nut's seat, per side, on top of fdm_hole_comp: tighter than a slot, so a nut pulled up into it once, with a spare screw, stays there (D124)... */
pull_way_fit = 0.1; /* ...and the pocket under it, up which the nut slides to the seat. */
pull_rise = 0.8;    /* The pocket starts this far over its post's foot: there a nut slides in under the post, from the room, and goes up the pocket. */
plate_head = [5.5, 3];  /* The plate's screws, M3 socket head, ISO 4762: the head's diameter and height. */
head_sink = 0.2;    /* Each sunk head sits this far inside its face: the plate's screws' in the base's bottom face, the joints' in their tabs' tops... */
head_room = 0.4;    /* ...in a counterbore this much wider than the head, past fdm_hole_comp: room for the key. */
lobe_cap = 1;       /* The plate over each head: the counterbore is in a lobe that rises from the plate into a pocket in the base... */
lobe_play = 0.2;    /* ...with this much room round it and over it, so the plate's ends bear on the seats, not the lobes. */
meet = 0.05;        /* A new face kept this far off an imported one it would otherwise share: the STL's float32 corners are not where the same number computed here is, and faces a hair apart make slivers the slicer removes. */

/* [The sealed joints - Alon, 8 Oct 2026: D114, D116, D118, D119, D120; seamless tabs, flush heads] */
// The three joints under suction - the section on the fan section, the carbon housing on the section, the HEPA
// holder on the carbon housing - are sealed. A TPU bead lies in a groove in the lower part's top; the upper part's
// flat bottom presses it, nested in a collar round the lower part's top edge, whose inner face is at 45 degrees as
// the upper part's bottom edge is; and four screws in tabs at the corners, where the magnets were, hold each joint.
// The tabs stand out past the end walls, their outline a parabola leaving the end wall and flush with the side
// face; under a nut's tab, a bracket whose face is a cubic, tangent to the wall. One screw at each corner holds
// both of the section's joints: from the carbon housing's tab, through a pillar in the section, into the fan
// section's nut. The tabs are seamless with the walls and floors (Alon, 8 Oct): each sealed part's outside is the
// one outline, tabs and all, drawn here - the originals' own faces are cut `meet` inside it - and each part's
// floor and top at a joint are cut there too. A screw's head sinks flush into its tab (Alon, 8 Oct).
sealed = true;      /* false: the originals' magnets, tongue and groove, as they come. */
seal_bead = [2, 2, 0.45];   /* The bead: its width, its height free, its wall. */
bead_squeeze = 0.2; /* The upper part presses it this fraction of its height, as the faces meet. */
bead_side = 0.25;   /* Room each side of the bead in its groove, to bulge into. */
seal_inner = 0.9;   /* The wall between the inside and the groove: two beads. */
bead_land = 0.45;   /* At least this flat between the groove and the collar, for the upper part to stop on. */
collar_h = 1;       /* The collar round the lower part's top edge: its height... */
collar_top = 0.9;   /* ...its width at its top - two beads - its inner face at 45 degrees below that... */
collar_play = 0.2;  /* ...and the gap to the upper part's chamfer, which sits in it. */
tab_out = 5;        /* A tab's screw stands this far out past the end wall... */
tab_boss_r = 4.4;   /* ...the tab round it: the nut's slot and three beads each side. */
tab_a0 = 150;       /* Where the tab's parabola meets its round end, in degrees round the screw: it leaves the end wall nearer the middle for a smaller angle. */
tab_blend = 0.05;   /* A bracket's face starts this far inside the wall and the corner it leaves, so the two cross at a slant, under a degree, not tangent. */
tab_corner_t = [0.1, 0.5];  /* Up a bracket, from its foot (0) to the tab (1): between these it fills the rounded corner under the tab, smoothly, so the side face runs on into the bracket's side. */
tab_lower_t = 6;    /* The lower part's tab, with the nut in it. */
tab_upper_t = 5;    /* The upper part's tab under the screw's head; the tab stands a head's counterbore higher, so the head sinks flush. */

/* [The joint sample - Alon, 8 Oct 2026: D121] */
// Before the 7-hour carbon housing, one end of a sealed joint to try: sliced off the parts themselves, the carbon
// housing's top end with its two nut tabs and the HEPA holder's bottom end with its two head tabs, and a block with
// one fan nut's pocket, to try its seat (D124) - on one plate, in ASA - and in TPU, a short bead for that end's groove.
sample_l = 30;      /* How far in from the end wall the pieces run. */
sample_low_h = 12;  /* The carbon housing's piece: this much under its top face, its two nut tabs and their brackets' tops. */
sample_up_h = 10;   /* The HEPA holder's piece: this much over its floor, its two tabs with the heads' counterbores. */
sample_gap = 8;     /* Between the pieces on the plate. */

/* [Printing - mirrors the print profile; scad-check.sh compares the first two with the slicer's] */
fdm_layer_h     = 0.2;
fdm_extrusion_w = 0.45;
fdm_hole_comp   = 0.15;   /* Added to every hole's radius - fdm-design-rules section 2. Not cross-checked. */
