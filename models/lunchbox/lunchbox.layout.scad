// SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
// SPDX-License-Identifier: CC-BY-SA-4.0
// A remix of LunchBox by GekoPrime (https://www.printables.com/model/468166), CC BY-SA 4.0.

/*
The LunchBox remix's layout: every dimension that follows from lunchbox.params.scad, the rules those
dimensions must keep, and where the original STLs sit in the box's frame. Values, functions, asserts and
warnings only - no geometry. lunchbox.scad includes this file and draws the parts from it.

Included, never used: -D can override any name here. Each value may use the settings and the values above
it - top-level assignments are worked out in order, so one that uses a later one gets undef.
*/
include <lunchbox.params.scad>

eps  = 0.01;                    // the overlap that joins two solids by a face, not an edge
bead = fdm_extrusion_w;
hx   = lb_l / 2;                // the end walls' outside faces, at X = +/-hx
function hole_r(d) = d / 2 + fdm_hole_comp;
function up_to_layer(z) = ceil(z / fdm_layer_h - 1e-6) * fdm_layer_h;
function first_fit(need, room, ls) = [for (l = ls) if (l >= need - 1e-6 && l <= room + 1e-6) l][0];

// =================================================================== the original, in the box's frame
// The body's and the lid's STLs share one frame: Z down from the fan joint's plane at Z = 2, Y towards -Y
// from the grid. Turned over about X and lifted by 2, they land in the box's frame. The fan section's STL
// stands on its own, turned 180 degrees about Z against the body - its fans blow out of the box's front,
// under the HEPA paper, and its plenum sits under the channel at the back. Turned over about Y instead,
// then moved, it lands under the body.
body_stl = "original/filter_caddy_110x74x21.stl";
lid_stl  = "original/filter_lid_110x74x21.stl";
fans_stl = "original/axial_fan_caddy_40x28.stl";
stl_z0 = 2;   // every original STL has a face at Z = 2: the body's and the fan section's bottoms, as they stand
body_from_stl = [[180, 0, 0], [0, 0, stl_z0]];                // rotate, then translate
fans_from_stl = [[0, 180, 0], [0, lb_d, stl_z0 - fans_h]];    // its rim at Z = 0, its lip in the groove

// The body's bottom face: the groove inside its wall, and the island inside the groove - the carbon bed's
// floor, the HEPA holder's ends and the channel's ribs - flush with the wall.
groove_x0 = hx - lb_wall - groove_w;            // the groove's inner edge along each end
groove_y0 = lb_wall + groove_w;                 // ... along the front
groove_y1 = lb_d - lb_wall - groove_w;          // ... along the back
// The fan section's lip, and the slot its fans stand in.
lip_x0 = plenum_hw;
lip_x1 = plenum_hw + lip_t_side;
lip_back_y1 = lip_back_y0 + lip_t_back;
fan_slot_h = fans_h - fans_floor;               // floor to rim
bay_w = 2 * fan_slot_hw / 3;                    // one fan's share of the slot

// =================================================================== the insert
// It takes the fan section's place under the body, so its top carries the fan section's lip and its bottom
// the body's groove; anything that fits one fits the other. Its cavity runs from the fan slot's back edge
// to the groove: the body's island stays clear of it above, the fan section's plenum takes its air below.
ins_h  = grid_t + sheet_t + plenum_h;
cav_hw = groove_x0;
cav_y0 = fan_slot_y1;
cav_y1 = groove_y1;
sheet_cut = [ceil(2 * cav_hw), ceil(cav_y1 - cav_y0)];   // cut the sheet to this, a little over, so it seals at its edges
rib_w  = grid_beads * bead;
ledge_w = ledge_beads * bead;
rib_xs = [for (x = [-floor(cav_hw / grid_pitch) * grid_pitch : grid_pitch : cav_hw]) x];
rib_ys = [cav_y0 + (cav_y1 - cav_y0) / 3, cav_y0 + 2 * (cav_y1 - cav_y0) / 3];
ins_groove_from = fan_slot_y1 - groove_w;       // the bottom groove only where the fan section's lip runs
sheet_area = 2 * cav_hw * (cav_y1 - cav_y0);    // mm^2, before the ribs
chan_area  = 2 * cav_hw * (groove_y1 - cap_y1); // the channel's opening it replaces as the filter's face

// =================================================================== the tabs
tab_x   = hx + tab_axis;                        // the screw's axis, +/-
hole_d  = 2 * hole_r(screw_d);
nut_ac  = nut_af / cos(30);
nut_slot_w = nut_af + 2 * (fdm_hole_comp + nut_fit);
nut_slot_h = up_to_layer(nut_h + 2 * nut_fit);
nut_inner  = tab_axis - (nut_ac / 2 + fdm_hole_comp + nut_fit);   // the slot's inner end, from the end wall
chamfer_h  = tab_l;                             // the 45-degree support under a tab that overhangs in print
lid_tab_z   = body_h;                           // the lid's tabs: level with its plate
fans_tab_z0 = -tab_t;                           // the fan section's tabs: under its rim

// The screw stacks, head to tip. A nut sits mid-way up the lower tab of its joint.
nut_drop = (tab_t - nut_slot_h) / 2;            // from the lower tab's top to the nut's top
function need(above) = above + nut_drop + nut_h + screw_tip;
function room(above) = above + tab_t + chamfer_h;
stack_lid  = lid_t + gasket_t;                                  // lid tab, gasket, then the body's tab
stack_fans = tab_t + gasket_t;                                  // body tab, gasket, then the fan section's
stack_ins  = tab_t + gasket_t + ins_h + gasket_t;               // ... with the insert between
screw_lid  = first_fit(need(stack_lid), room(stack_lid), screw_lengths);
screw_fans = first_fit(need(stack_fans), room(stack_fans), screw_lengths);
screw_ins  = first_fit(need(stack_ins), room(stack_ins), screw_lengths);

// =================================================================== the gaskets
gasket_clear = 0.3;                             // round the lid's plug and the fan section's lip
gasket_hx = hx - lb_wall + gasket_clear;        // the gaskets' opening: the body's inside, which the lid's plug fills...
gasket_y0 = lb_wall - gasket_clear;             // ...and its front and back
gasket_y1 = lb_d - lb_wall + gasket_clear;
gasket_open_y0 = fan_slot_y1 - gasket_clear;    // the fans' gasket is open behind this

// =================================================================== the blank
blank_w = bay_w - 2 * blank_fit;
blank_d = fan_slot_y1 - lb_wall - 2 * blank_fit;
blank_h = fan_slot_h - blank_fit;
blank_wall = blank_beads * bead;

// =================================================================== rules: BLOCK - the geometry would be wrong
assert(lip_x0 >= groove_x0 && lip_x1 <= hx - lb_wall, "the fan section's lip no longer fits the groove's ends");
assert(lip_back_y0 >= groove_y1 && lip_back_y1 <= lb_d - lb_wall, "the fan section's lip no longer fits the groove's back");
assert(cav_hw <= plenum_hw && cav_y1 <= lip_back_y0 && cav_y0 >= fan_slot_y1,
       "the insert's cavity reaches past the fan section's plenum: air would leave it over the fans");
assert(cap_y1 > cav_y0 && cap_y1 < cav_y1, "the body's channel does not open into the insert's cavity");
assert(sheet_t > 0 && plenum_h > 0 && grid_t > 0, "the insert's layers must all be there");
assert(nut_inner > 0, str("the nut's slot cuts into the original's end wall (", nut_inner, ")"));
assert(tab_w / 2 - nut_slot_w / 2 >= bead - 1e-9, "the nut's slot breaks out of the tab's sides");
assert(nut_drop >= bead - 1e-9, "the nut's slot breaks out of the tab's top or bottom");
assert(!is_undef(screw_lid) && !is_undef(screw_fans) && !is_undef(screw_ins), "no listed screw length fits a stack");
assert(gasket_clear > 0 && gasket_hx < hx - 4 * fdm_layer_h, "the gaskets' ring has no width left");
assert(blank_w > 2 * blank_wall && blank_d > blank_face, "the blank has no inside");

// =================================================================== rules: WARN - it builds, but look
warns = [
    if (rib_w < 2 * bead - 1e-9) str("the grid's ribs are under two beads (", rib_w, ")"),
    if (grid_pitch > 15) str("the grid's ribs are ", grid_pitch, " apart: loose floss sags through"),
    if (plenum_h < 3) str("the plenum over the sheet is ", plenum_h, " mm: the air will not spread forward"),
    if (nut_inner < 2 * bead - 1e-9) str("the nut's slot ends ", nut_inner, " mm from the original's wall"),
    if (gasket_t < 3 * fdm_layer_h - 1e-9) str("the gaskets are under three layers"),
];
