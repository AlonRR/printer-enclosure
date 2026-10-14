// SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
// SPDX-License-Identifier: CC-BY-NC-SA-4.0
// A remix of BentoBox v2.0 by ThrutheFrame (https://www.printables.com/model/272525), CC BY-NC-SA 4.0.

// The BentoBox remix, laid out as scad-tools' docs/project-layout.md says: this file includes the rest in order
// and draws what `draw` names - render this one. Every value set is in bentobox.params.scad, the bought parts' own
// numbers under vitamins/, and README.md here says what goes where. The airflow simulation's view of the stack is
// checks/air.scad, which includes this file.

use <../../scad-tools/lib/fdm.scad>
use <../../scad-tools/lib/nuts.scad>
use <../../scad-tools/lib/gasket.scad>
use <../../scad-tools/lib/shapes.scad>
use <../../scad-tools/lib/patterns.scad>

include <bentobox.params.scad>       // every value set: the Customizer's groups

/* [Hidden] */
$fn = 64;

// THE MODEL'S FILES, in the order they are read. OpenSCAD reads the values in order, top to bottom through the
// included files, and a value read before it is set is undef: so each file comes after every file whose values it
// reads. Modules and functions can be read from anywhere.
include <vitamins/magnets.scad>      // the bought parts: each one's own numbers, and the models the checks use
include <vitamins/carbon.scad>
include <vitamins/hepa-cartridge.scad>
include <vitamins/hepa-paper.scad>
include <vitamins/fasteners.scad>
include <vitamins/fans.scad>
include <vitamins/usb-c-trigger.scad>
include <vitamins/fan-plug.scad>
include <vitamins/wire.scad>
include <vitamins/sensors.scad>
include <lib/helpers.scad>           // the helpers the parts share; they set no values
include <bentobox.layout.scad>       // the values more than one part reads
include <parts/originals.scad>       // the originals' STLs, in the box's frame
include <parts/section.scad>
include <parts/joints.scad>          // the sealed joints, which the section, the fan section, the housing and the holder use
include <parts/paper-frame.scad>     // the glue frame and the clamp - before the HEPA holder, whose ledge's opening they set
include <parts/bottom.scad>          // the base, the tray, the fan section
include <parts/carbon.scad>
include <parts/hepa.scad>
include <parts/cover.scad>
include <parts/cmag.scad>
include <parts/grommet.scad>
include <parts/fan-mate.scad>
include <parts/samples.scad>         // cut from the parts
include <parts/print.scad>           // every part as it prints
include <assembly/stack.scad>        // the parts together, and the drawings
include <checks/fits.scad>           // what the fit checks read
include <checks/guards.scad>         // the asserts
include <checks/report.scad>         // the warnings and the echoes

// ---------------------------------------------------------------- what is drawn: draw, in the params
if (len([for (p = printed) if (p == draw) p]) > 0) print_part(draw);
else if (draw == "stack") stack(0);
else if (draw == "exploded") stack(explode);
else if (draw == "cut") stack(0);
else if (draw == "section_fig") color("seagreen") section();
else if (draw == "cmag") {
    color("sienna") cmag_tray_drawn();
    color("dimgray") translate([0, 0, explode]) cmag_grills_drawn();
    color("sienna") translate([0, 0, 2 * explode]) cmag_lid_drawn();
}
// The section seats in the carbon housing: its tongue in the housing's groove, its magnets under the housing's.
else if (draw == "check_section_carbon") intersection() { section(); translate([0, 0, sec_h + sep - st[2]]) orig(carbon_stl, st[2] - st[1]); }
// The fan case seats in the section the way it seats in the housing.
else if (draw == "check_section_fans") intersection() { translate([0, 0, st[1] + sep]) section(); fan_section(); }
// Each magnet's hole in the section lines up with its partner's in the original.
else if (draw == "check_magnets_top") intersection() {
    union() { section(); translate([0, 0, sec_h + sep - st[2]]) orig(carbon_stl, st[2] - st[1]); }
    magnets_across(sec_h);
}
else if (draw == "check_magnets_bottom") intersection() {
    union() { translate([0, 0, st[1] + sep]) section(); fan_section(); }
    translate([0, 0, st[1]]) magnets_across(0);
}
// The air from the housing's openings reaches the whole sheet.
else if (draw == "check_air") intersection() { section(); air_probe(); }
// The Auto's bottom. The fan section stands on the base, and the tray is screwed on under it.
else if (draw == "check_auto_fans_base") intersection() { translate([0, 0, sep - fans_drop]) fans_printed(); auto_base(); }
else if (draw == "check_auto_tray") intersection() { translate([0, 0, -sep]) auto_tray(); auto_base(); }
// The grommet sits in the fan section's floor, lip in groove. The hole is cut a hole's compensation larger than the
// grommet's outside, and the grommet drawn only its squeeze larger, so in the model the two stand apart.
else if (draw == "check_grommet_hole") intersection() { fans_sealed(); translate([grommet_x, auto_conduit[1], duct_h]) grommet_body(); }
// The floor's hole for the grommet cuts nothing over the floor: what of its cut stands above the floor's top, 0.01 mm
// up, meets nothing of the fan section, whose +X wall stands just past the hole's chamfer.
else if (draw == "check_grommet_wall") intersection() {
    fans_whole();
    translate([grommet_x, auto_conduit[1], duct_h]) intersection() {
        grommet_hole();
        translate([-20, -20, auto_floor_t + sep]) cube([40, 40, 5]);
    }
}
// The fans' plugs, as measured, on the mate: each seated on the block, 0.01 mm up, centred on its pins, its ribs
// either side of the key and clear of the walls, the grip left off; met by the grip (check_fan_mate_grip, which must
// NOT come out empty), and - the grip's bite taken off - clear of it, so its ribs bite the plugs' ends by
// fan_mate_grip and touch nothing else. And the wires' cores, standing as the pins: through their holes in the block
// and up into the plugs' holes, touching neither.
else if (draw == "check_fan_mate") intersection() { fan_mate(false); for (x = fm_xs) translate([0, 0, 0.01]) fan_plug_model(x); }
else if (draw == "check_fan_mate_grip") intersection() { fan_mate_grips(); for (x = fm_xs) translate([0, 0, 0.01]) fan_plug_model(x); }
else if (draw == "check_fan_mate_grip_seat") intersection() { fan_mate_grips(-0.02); for (x = fm_xs) translate([0, 0, 0.01]) fan_plug_model(x); }
// The mate in its place on the fan section's floor, 0.01 mm up, its plugs on it: clear of the fan section, of the
// grommet's hole and the leads' way up out of it, and of the two fans, each drawn as its 40 x 40 x 20 mm frame.
else if (draw == "check_fan_mate_place") intersection() {
    translate([fan_mate_at[0], fan_mate_at[1], duct_h + auto_floor_t + 0.01]) {
        fan_mate();
        for (x = fm_xs) translate([0, 0, 0.01]) fan_plug_model(x);
    }
    union() {
        fans_sealed();
        // the grommet's hole and the leads' way up out of it: the grommet itself is inside the floor
        translate([grommet_x, auto_conduit[1], duct_h]) cylinder(r = grommet_hole_r + grommet_chamfer, h = fans_h, $fn = 48);
        for (y = fan_ys) translate([-20, y - 20, duct_h + auto_floor_t]) cube([40, 40, 20]);
    }
}
else if (draw == "check_fan_mate_pins") intersection() {
    union() { fan_mate(); for (x = fm_xs) translate([0, 0, 0.01]) fan_plug_model(x); }
    fan_mate_pins();
}
// The USB-C board sits in its pocket, the socket through its notch, flush with the end face.
else if (draw == "check_usb_board") intersection() { union() { auto_tray(); auto_base(); } usb_board_model(); }
// The tray's nuts' slots, and their screws' holes, keep two beads of the end walls round them.
else if (draw == "check_tray_slot_walls") intersection() { tray_slot_walls(); base_air(); }
// Each nut fits its slot, and slides in from outside.
else if (draw == "check_auto_nuts") intersection() { auto_base(); auto_nuts(); }
else if (draw == "check_auto_nut_ways") intersection() { auto_base(); auto_nuts(nut_way); }
// Each screw passes the fan section's floor, the base and the tray to its nut, and its tip has room.
else if (draw == "check_auto_screws") intersection() { union() { auto_base(); fans_printed(); auto_tray(); } auto_screws(); }
// The wires pass the floor's hole and the tube to the bay.
else if (draw == "check_auto_wires") intersection() { union() { auto_base(); fans_printed(); } wire_probe(); }
// Nothing of the base stands under the fans' openings in the floor, its posts included.
else if (draw == "check_auto_air") intersection() { auto_base(); fan_air(8); }
// The outlet's SPS30 lies in its pocket clear of the base and the fan section; its plug stands in the end wall's slot;
// its openings face open air; its leads pass down the slot and the tray's groove into the bay; it slides in from the
// outlet, the tray off; its pocket leaves the wires' tube whole; and the tray's stop stands clear in front of it -
// close enough that 1 mm out it meets the stop (check_sps30_held must NOT come out empty).
else if (draw == "check_sps30") intersection() { union() { auto_base(); fans_printed(); } sps30_model(); }
else if (draw == "check_sps30_plug") intersection() { auto_base(); sps30_plug_probe(); }
else if (draw == "check_sps30_air") intersection() { auto_base(); sps30_air_probe(); }
else if (draw == "check_sps30_lead") intersection() { union() { auto_base(); auto_tray(); sps30_model(); } sps30_lead_probe(); }
else if (draw == "check_sps30_way") intersection() { union() { auto_base(); fans_printed(); } sps30_way(); }
else if (draw == "check_sps30_tube") intersection() { sps30_cut(); sps30_tube(); }
else if (draw == "check_sps30_stop") intersection() { auto_tray(); sps30_model(); }
else if (draw == "check_sps30_held") intersection() { auto_tray(); translate([-1, 0, 0]) sps30_model(); }
// The SGP41 sits in its recess clear of the base, its face to open air, and its leads pass down to the bay.
else if (draw == "check_sgp41") intersection() { union() { auto_base(); fans_printed(); } sgp41_model(); }
else if (draw == "check_sgp41_air") intersection() { union() { auto_base(); fans_printed(); } sgp41_air_probe(); }
else if (draw == "check_sgp41_screw") intersection() { union() { auto_base(); fans_printed(); } sgp41_fixings(); }
else if (draw == "check_sgp41_nut_way") intersection() { auto_base(); sgp41_fixings(true); }
else if (draw == "check_sgp41_leads") intersection() { union() { auto_base(); auto_tray(); sps30_model(); sgp41_model(); } sgp41_leads_probe(); }
else if (draw == "bottom") bottom_exploded(explode);
else if (draw == "joints") joints_exploded(explode);
// The sealed joints: each upper part on its lower one - flat on the land, its chamfer in the collar, tab on tab.
else if (draw == "check_seal_j1") intersection() { fans_sealed(); translate([0, 0, sst[1] + sep]) section(); }
else if (draw == "check_seal_j2") intersection() { translate([0, 0, sst[1]]) section(); translate([0, 0, sep]) carbon_sealed(); }
else if (draw == "check_seal_j3") intersection() { carbon_sealed(); translate([0, 0, sep]) hepa_sealed(); }
// Each bead lies in its groove, clear of its walls and floor: against its own lower part only, since it stands
// proud into the part above by design - the squeeze.
else if (draw == "check_seal_beads") union() {
    intersection() { fans_sealed(); translate([0, 0, seal_faces[0] - seal_groove[1] + sep]) bead_ring(); }
    intersection() { translate([0, 0, sst[1]]) section(); translate([0, 0, seal_faces[1] - seal_groove[1] + sep]) bead_ring(); }
    intersection() { carbon_sealed(); translate([0, 0, seal_faces[2] - seal_groove[1] + sep]) bead_ring(); }
}
// The screws, head to tip, through the tabs, the section's pillars and the nuts' slots.
else if (draw == "check_seal_screws") intersection() { seal_parts(); seal_screws(); }
// The nuts in their slots, and their way in from the tabs' ends.
else if (draw == "check_seal_nuts") intersection() { seal_parts(); seal_nuts(); }
else if (draw == "check_seal_nut_ways") intersection() { seal_parts(); seal_nuts(bracket_h); }
// A hex screwdriver on each screw's head, straight up, nothing in its way: the lower joints' screws go in first,
// before the HEPA holder is on; the top joint's last, with everything on but the cover.
else if (draw == "check_seal_access") union() {
    intersection() { union() { fans_sealed(); translate([0, 0, sst[1]]) section(); carbon_sealed(); }
        for (s = seal_screw_list) if (s[3] == sst[2]) hex_driver(s); }
    intersection() { seal_parts(); for (s = seal_screw_list) if (s[3] == sst[3]) hex_driver(s); }
}
else if (draw == "frame") frame_exploded(explode);
else if (draw == "glue") glue_exploded(explode);
else if (draw == "clamp_print") color("orange") clamp_frames_printing();
else if (draw == "paper_cut") paper_cut();
else if (draw == "glue_cut") glue_cut();
// The grommet twice: on the left turned over, its skin and the leads' holes up; on the right as it sits, the holes
// running on up the ring's inside.
else if (draw == "grommet_fig") color("deepskyblue") {
    translate([-6, 0, auto_floor_t]) mirror([0, 0, 1]) grommet_body();
    translate([6, 0, 0]) grommet_body();
}
// The fans' plug mate, its wires' cores standing as the pins, and the fans' plugs lifted off them by `explode`.
else if (draw == "fan_mate_fig") {
    color("dimgray") fan_mate();
    color("goldenrod") fan_mate_pins();
    color("ivory") for (x = fm_xs) translate([0, 0, explode]) fan_plug_model(x);
}
// The clamp stands in the HEPA holder's pocket, on its ledge.
// The glue frame in the holder's pocket, on its ledge; the paper in the frame, drawn 0.01 mm thinner each side, on
// its rim and against its walls; and the rim clear of the ledge's opening.
else if (draw == "check_glue_holder") intersection() { translate([0, 0, sst[3] - meet + ledge_top + sep]) glue_frame(); hepa_sealed(); }
else if (draw == "check_glue_paper") intersection() { glue_frame(); paper_pack(paper_t - 2 * sep); }
else if (draw == "check_glue_opening") intersection() { glue_frame(); glue_opening_probe(); }
else if (draw == "check_clamp_holder") intersection() { translate([0, 0, sst[3] - meet + ledge_top + sep]) clamp_cassette(); hepa_sealed(); }
// The cover on the HEPA holder: its plug in the holder's top, flat on the top face; and a magnet across the joint
// at each corner, in both parts' holes.
else if (draw == "check_cover_holder") intersection() { hepa_sealed(); translate([0, 0, sep]) cover_placed(); }
else if (draw == "check_cover_magnets") intersection() { union() { hepa_sealed(); cover_placed(); } magnets_across(sst[3] - meet + hepa_h, top_mag_xy, magnet[0], magnet[1]); }
// The C-MAG standing in the carbon housing, sep over its floor, clear of its walls and of the HEPA holder above.
else if (draw == "check_cmag_housing") intersection() { union() { carbon_sealed(); hepa_sealed(); } cmag_placed(sep); }
// The C-MAG's halves meet face to face at the joint, held sep apart; a magnet across the joint in both halves' holes;
// and the grills in their slots, touching neither half.
else if (draw == "check_cmag_halves") intersection() { cmag_tray_drawn(); translate(cmag_lid_move + [0, 0, sep]) cmag_lid_drawn(); }
else if (draw == "check_cmag_magnets") intersection() { union() { cmag_tray_drawn(); translate(cmag_lid_move) cmag_lid_drawn(); } cmag_magnets_across(); }
else if (draw == "check_cmag_grills") intersection() { union() { cmag_tray_drawn(); cmag_lid_drawn(); } cmag_grills_drawn(); }
// The frames meet only where the end blocks' halves do - the one hard stop - held sep apart.
else if (draw == "check_clamp_frames") intersection() { clamp_low(); translate([0, 0, sep]) clamp_up(); }
// The paper, drawn from its own values at the slot's thickness less sep each side, stands in the frames'
// zigzag without either frame cutting into it: wedges, teeth, half wedges, long teeth, band and rim.
else if (draw == "check_clamp_paper") intersection() { clamp_cassette(); paper_pack(clamp_slot - 2 * sep); }
// The lower frame leaves the air's way down open, under the paper between the combs.
else if (draw == "check_clamp_opening") intersection() { clamp_low(); opening_probe(); }
// The screws, head to tip, through both frames' end blocks; the nuts in their seats, and down out through the
// lower frame's bottom.
else if (draw == "check_clamp_screws") intersection() { clamp_cassette(); clamp_screws(); }
else if (draw == "check_clamp_nuts") intersection() { clamp_low(); clamp_nuts(); }
else if (draw == "check_clamp_nut_ways") intersection() { clamp_low(); clamp_nuts(clamp_nut_top + 2); }
else if (draw == "none") { }   // a file that includes this one, to draw its own
else assert(false, str("unknown draw: ", draw));
