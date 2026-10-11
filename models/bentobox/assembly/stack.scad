// SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
// SPDX-License-Identifier: CC-BY-NC-SA-4.0
// A remix of BentoBox v2.0 by ThrutheFrame (https://www.printables.com/model/272525), CC BY-NC-SA 4.0.

// assembly/stack.scad - THE PARTS TOGETHER: where each part stands in the stack, and the drawings - the stack, exploded and cut, the bottom, the joints, the paper's frames. Drawings, not parts: render them to an image. Included by bentobox.scad; not a model on its own.

// One part of the stack, in its colour - or, for "cut", its cut at X = cut_x, laid out with the box's
// length (Y) across and its height (Z) up. The cut's frame is a rotation, not a mirror: (y, z, x).
module piece(c) color(c) if (draw == "cut")
    projection(cut = true) multmatrix([[0, 1, 0, 0], [0, 0, 1, 0], [1, 0, 0, -cut_x]]) children();
    else children();

module stack(ex) if (sealed) stack_sealed(ex); else stack_magnets(ex);
module stack_magnets(ex) {
    st = stack(with_section);
    dz = st[2] - st[1];
    if (bottom == "auto") {
        piece("dimgray") translate([0, 0, -ex]) auto_tray();
        piece("dimgray") auto_base();
    }
    else piece("dimgray") orig(duct_stl);
    piece("steelblue") translate([0, 0, ex]) fan_section();
    if (with_section) piece("seagreen") translate([0, 0, st[1] + 2 * ex]) section();
    piece("tan") translate([0, 0, 3 * ex]) orig(carbon_stl, dz);
    piece("sienna") translate([0, 0, 3 * ex]) cmag_standing(st[2] + cmag_z0);
    piece("lightsteelblue") translate([0, 0, 4 * ex]) hepa_body(dz);
    piece("darkslategray") translate([0, 0, 5 * ex]) orig(cover_stl, dz);
}

// The sealed stack: each sealed part in its place, a bead ring in each lower part's groove, the screws.
module stack_sealed(ex) {
    assert(with_section, "the sealed stack is built for the section: without it, the carbon housing's screws have no fan section's nuts to reach");
    if (bottom == "auto") {
        piece("dimgray") translate([0, 0, -ex]) auto_tray();
        piece("dimgray") auto_base();
    }
    else piece("dimgray") orig(duct_stl);
    piece("steelblue") translate([0, 0, ex]) fans_sealed();
    piece("seagreen") translate([0, 0, sst[1] + 2 * ex]) section();
    piece("tan") translate([0, 0, 3 * ex]) carbon_sealed();
    if (carbon == "cmag") piece("sienna") translate([0, 0, 3 * ex]) cmag_placed();
    else piece("#303030") translate([0, 0, 3 * ex]) bed_pellets();
    piece("lightsteelblue") translate([0, 0, 4 * ex]) hepa_sealed();
    piece("darkslategray") translate([0, 0, 4 * ex]) cover_placed();
}
// Where the sealed joints' parts are, and what goes in them. A lower part's face, sealed: J1 the fan section's
// top, J2 the section's, J3 the carbon housing's.
seal_faces = [sst[1], sst[2], sst[3]];
module seal_beads(lift = 0) for (z = seal_faces) translate([0, 0, z - seal_groove[1] + lift]) bead_ring();
// Each joint's screws: [x, y, which way its nut's slot opens, the joint's face, the screw's length]. The top joint's,
// through the HEPA holder into the carbon housing; the lower two's, through the carbon housing and the section's
// pillars into the fan section.
seal_screw_list = concat([for (s = top_screws) [s[0], s[1], s[2], sst[3], j3_screw]],
    [for (s = tab_screws) [s[0], s[1], s[2], sst[2], j12_screw]]);

module seal_parts() { fans_sealed(); translate([0, 0, sst[1]]) section(); carbon_sealed(); hepa_sealed(); }
module joints_exploded(ex) {
    color("steelblue") fans_sealed();
    color("seagreen") translate([0, 0, sst[1] + ex]) section();
    color("tan") translate([0, 0, 2 * ex]) carbon_sealed();
    color("lightsteelblue") translate([0, 0, 3 * ex]) hepa_sealed();
    color("orange") for (i = [0 : 2]) translate([0, 0, seal_faces[i] - seal_groove[1] + (i + 0.5) * ex]) bead_ring();
    color("silver") for (s = seal_screw_list)
        translate([s[0], s[1], s[3] + tab_upper_t + (s[3] == sst[3] ? 3.5 : 2.5) * ex]) {
            translate([0, 0, -s[4]]) cylinder(d = screw_d, h = s[4]);
            cylinder(d = m3_head[0], h = m3_head[1]);
        }
}

st = stack(true);
// The drawn cover on the HEPA holder, moved by cover_shift: [0, 0] but in a check's positive control.

module cover_placed() translate([cover_shift[0], cover_shift[1], 0]) cover_drawn(cover_z0);
// The drawn C-MAG standing in the sealed stack's carbon housing, moved by cmag_shift; and its lid on its tray, moved
// by cmag_lid_move. Both are zero but in a check's positive control.

module cmag_placed(lift = 0) translate(cmag_shift) cmag_stood(sst[2] - meet + cmag_z0 + lift) cmag_drawn();
// The bed of pellets on the housing's floor, for the pictures.
module bed_pellets() translate([0, 0, sst[2] - meet + carbon_floor]) linear_extrude(bed_depth) inside_offset(-0.3);

// The bottom pulled apart along Z, the nuts and screws drawn in their places.
module bottom_exploded(ex) {
    color("dimgray") translate([0, 0, -ex]) auto_tray();
    color("lightslategray") auto_base();
    color("gold") auto_nuts();
    color("silver") { auto_screws(); }
    color("steelblue", 0.85) translate([0, 0, ex]) if (sealed) fans_sealed(); else auto_fans();
}

// The HEPA holder's ledge, with the section in the stack: where the clamp stands.
ledge_z = st[3] + ledge_top;

// The clamp pulled apart: the paper lifted off the lower frame, the upper frame and the screws over it.
module frame_exploded(ex) {
    color("orange") clamp_low();
    color("ivory") paper_pack(z = ex);
    color("steelblue") translate([0, 0, 2 * ex]) clamp_up();
    color("silver") translate([0, 0, 3 * ex]) clamp_screws();
}
// The glue frame with the paper lifted out of it.
module glue_exploded(ex) {
    color("orange") glue_frame();
    color("ivory") paper_pack(z = ex);
}

// Across the folds, flat, through the glue frame's fins at one end: the frame - rim, walls and a fin in every
// channel open at the bottom - and the paper standing on the rim between them.
module glue_cut() let(y = (gf_rim[1] / 2 + gf_in[1]) / 2) {
    color("orange") projection(cut = true) multmatrix([[1, 0, 0, 0], [0, 0, 1, 0], [0, 1, 0, -y]]) glue_frame();
    color("black") translate([0, pack_z]) paper_2d();
}
// Across the folds, flat: the clamp through an end's combs - the teeth, the wedges, the half wedges, the paper
// in its zigzag slot - and beside it, through its middle - the long teeth and half wedges round each flap.
module paper_cut() {
    gap = cas[0] / 2 + 4;
    for (side = [[-gap, comb_y - clamp_wedge_l / 2], [gap, 0]]) translate([side[0], 0]) {
        color("orange") projection(cut = true) multmatrix([[1, 0, 0, 0], [0, 0, 1, 0], [0, 1, 0, -side[1]]]) clamp_low();
        color("steelblue") projection(cut = true) multmatrix([[1, 0, 0, 0], [0, 0, 1, 0], [0, 1, 0, -side[1]]]) clamp_up();
        color("black") translate([0, pack_z]) paper_2d();
    }
}

// A flat view gets a flat key: an arrow across, labelled with the box's axis it shows, and +z up.
module flat_key(across) color("black") {
    translate([0, -0.6]) square([16, 1.2]);
    translate([16, 0]) polygon([[0, -2.5], [5, 0], [0, 2.5]]);
    translate([-0.6, 0]) square([1.2, 16]);
    translate([0, 16]) polygon([[-2.5, 0], [2.5, 0], [0, 5]]);
    translate([23, 0]) text(across, size = 3.5, valign = "center");
    translate([0, 24]) text("+z up", size = 3.5, halign = "center");
}
