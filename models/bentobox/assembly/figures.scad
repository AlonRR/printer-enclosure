// SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
// SPDX-License-Identifier: CC-BY-NC-SA-4.0
// A remix of BentoBox v2.0 by ThrutheFrame (https://www.printables.com/model/272525), CC BY-NC-SA 4.0.

// assembly/figures.scad - THE BUILD PAGE'S PICTURES: the model as `draw` names it, with the xyz arrows - or, on a
// flat drawing, its key - every picture carries. A drawing file: it includes the model and draws its own on top;
// scripts/checks/bentobox-checks.py renders it to an image with -D draw=..., never to an STL. The arrows are here,
// not in the model, so no printed part loads axes.scad.
include <../bentobox.scad>
use <../../../scad-tools/lib/axes.scad>

if (show_axes && (draw == "stack" || draw == "exploded")) axes([-bb_w / 2 - 40, -bb_l / 2, 0], l = 25);

if (show_axes && draw == "section_fig") axes([-bb_w / 2 - 32, -bb_l / 2, 0], l = 15, cam = axes_cam);
if (show_axes && draw == "frame") axes([-cas[0] / 2 - 25, -cas[1] / 2, 0], l = 15, cam = axes_cam);
if (show_axes && draw == "glue") axes([-cas[0] / 2 - 25, -cas[1] / 2, 0], l = 15, cam = axes_cam);
if (show_axes && draw == "joints") axes([bb_w / 2 + 20, bb_l / 2, sst[0] + 30], l = 20, cam = axes_cam);
if (show_axes && draw == "bottom") axes([bb_w / 2 + 15, bb_l / 2, 0], l = 20, cam = axes_cam);
if (show_axes && draw == "grommet_fig") axes([-13, -5, 0], l = 3.5, cam = axes_cam);
if (show_axes && draw == "fan_mate_fig") axes([fm_x1 + 8, fm_y1, 0], l = 4, cam = axes_cam);
if (show_axes && draw == "clamp_print") axes([-cas[0] - 32, -cas[1] / 2, 0], l = 15, cam = axes_cam);

// The cut's across is +y, along the box; the paper's cut's is +x, across it.
if (show_axes && draw == "cut") translate([-bb_l / 2 - 30, 10]) flat_key("+y");
if (show_axes && draw == "paper_cut") translate([-cas[0] - 4 - 22, 2]) scale(0.5) flat_key("+x");
if (show_axes && draw == "glue_cut") translate([-cas[0] / 2 - 15, 2]) scale(0.5) flat_key("+x");
