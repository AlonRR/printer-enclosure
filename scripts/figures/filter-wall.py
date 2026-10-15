#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
# SPDX-License-Identifier: MPL-2.0
# /// script
# requires-python = ">=3.11"
# dependencies = ["matplotlib"]
# ///
"""The filter wall's layout (Alon, 15 Oct 2026: D294 a, D291 a, T293, Q296, D297 b, D298 a): the enclosure's left wall,
printed, is the one filter unit. It stands between the floor and the roof and between the legs, built as four modules,
one job each - seen from inside, four HEPA cartridges top right; the carbon, the Deltas, the sensors, the outlet and
a purge to the window bottom right; the electronics bottom left; the top left free. From the repository's root:

  uv run scripts/figures/filter-wall.py       writes docs/diagrams/filter-wall/layout.png

The Lack, its legs and the chamber are to scale, and so is the modules' size against the printer's bed; what is in
them is placed, not designed. Drawn with the options recommended and still open: one unit, four Deltas and a
servo's damper on the purge (D300), the carbon module standing 40 mm out past the edges (D301).
"""
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.patches as mp
import matplotlib.pyplot as plt

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "docs" / "diagrams" / "filter-wall" / "layout.png"

# measured or stated (mm)
LACK = 550          # the top, square
TOP = 50            # its thickness (T286)
LEG = 50            # the legs, square
CH_H = 460          # the chamber, floor to roof (Q157)
INSIDE = 50         # how far in the wall may stand over the floor and under the roof: 50 or more (Q296)
BED_XY = (250, 210)  # the printer's bed
# placed, not designed
MOD = (225, 205)    # a module: along the wall, tall; face down on the bed
COLS = (LEG, LEG + MOD[0])        # the modules' columns, between the legs
RAIL = (CH_H - 2 * MOD[1]) / 2    # the rails on the floor and under the roof, which carry the seal
ROWS = (RAIL, RAIL + MOD[1])
SKIN = 3
PROUD = 40          # the carbon module, out past the edges (D301)
SLOT = (49, 150)    # a Mijia cartridge standing: wide, tall
BED_Z, BED_D, FLOSS_Z = 172, 53, 160   # in the carbon module: the bed's floor and depth, the floss's frame
FAN_Z, DELTA = 133, (40, 20)
FANS_Y = [COLS[1] + 12 + i * 52 for i in range(4)]
OUTLET = (COLS[1] + 10, COLS[1] + 112, 35, 85)
SENSORS = (COLS[1] + 15, COLS[1] + 105, 95, 107)
PURGE = (COLS[1] + 168, ROWS[0] + 54, 50)   # the purge's collar on the outer face: y, z of its centre, its radius

WOOD, WOOD_EDGE = "#e6d3b1", "#8a6d3b"
FRAME_C, MOD_C, SEAL = "#f2b98a", "#fde0c5", "#2d7d46"
HEPA_C, CARBON_C, FLOSS_C, FAN_C = "#fff3b0", "#555555", "#e8e8e8", "#9ecae1"
PURGE_C, ELEC_C, FREE_C = "darkred", "#e5dcf2", "#f4f4f4"


def arrows(ax, origin, a, b, size=60):
    """The view's two axes, as arrows from origin: a and b are their names, right and up."""
    x, y = origin
    for dx, dy in ((size, 0), (0, size)):
        ax.annotate("", (x + dx, y + dy), (x, y), arrowprops={"arrowstyle": "->", "color": "crimson", "lw": 1.5})
    ax.text(x + size + 8, y, a, color="crimson", va="center", fontsize=9)
    ax.text(x, y + size + 8, b, color="crimson", ha="center", fontsize=9)


def box(ax, x, y, w, h, fc, ec="black", **kw):
    ax.add_patch(mp.Rectangle((x, y), w, h, facecolor=fc, edgecolor=ec, lw=kw.pop("lw", 1.2), **kw))


def label(ax, x, y, text, **kw):
    ax.text(x, y, text, fontsize=kw.pop("fontsize", 8.5), ha=kw.pop("ha", "center"), va="center", **kw)


def flow(ax, a, b, color, lw=2):
    ax.annotate("", b, a, arrowprops={"arrowstyle": "->", "color": color, "lw": lw})


def dim(ax, a, b, text, color="black", **kw):
    """A dimension line from a to b, its text beside the middle."""
    ax.annotate("", b, a, arrowprops={"arrowstyle": "<->", "color": color, "lw": 1})
    label(ax, (a[0] + b[0]) / 2 + kw.pop("dx", 0), (a[1] + b[1]) / 2 + kw.pop("dy", 0), text, color=color, **kw)


fig, (wall, cut) = plt.subplots(1, 2, figsize=(17, 9.2), gridspec_kw={"width_ratios": [1.5, 1]})

# ---- the wall seen from inside the chamber: Y right (front to back), Z up
box(wall, 0, -TOP, LACK, TOP, WOOD, ec=WOOD_EDGE)
box(wall, 0, CH_H, LACK, TOP, WOOD, ec=WOOD_EDGE)
label(wall, LACK / 2, -TOP / 2, "the floor: the wall stands on it")
label(wall, LACK / 2, CH_H + TOP / 2, "the roof: the wall stands under it; nothing on it, not drilled")
for y in (0, LACK - LEG):
    box(wall, y, 0, LEG, CH_H, WOOD, ec=WOOD_EDGE)
    label(wall, y + LEG / 2, CH_H / 2, "leg", rotation=90, color=WOOD_EDGE)
box(wall, LEG, 0, LACK - 2 * LEG, CH_H, FRAME_C, ec="#c26a1b")
wall.add_patch(mp.Rectangle((LEG + 3, 3), LACK - 2 * LEG - 6, CH_H - 6, fill=False, ec=SEAL, lw=2.5, ls="--"))
for y, z in ((COLS[0], ROWS[0]), (COLS[0], ROWS[1]), (COLS[1], ROWS[0]), (COLS[1], ROWS[1])):
    box(wall, y, z, MOD[0], MOD[1], MOD_C, ec="#c26a1b", lw=1.6)
# top left: free
y0, z0 = COLS[0], ROWS[1]
box(wall, y0 + 25, z0 + 30, 175, 145, FREE_C, ec="#999", ls="--")
label(wall, y0 + 112, z0 + 102, "free: filler, or a\nwindow to see in", color="#777", fontsize=8)
# top right: the HEPA, four cartridges
y0 = COLS[1]
gap = (MOD[0] - 4 * SLOT[0]) / 5
z_slot = ROWS[1] + (MOD[1] - SLOT[1]) / 2
for i in range(4):
    ys = y0 + gap + i * (SLOT[0] + gap)
    box(wall, ys, z_slot, SLOT[0], SLOT[1], HEPA_C, ec="#9a6a00")
    label(wall, ys + SLOT[0] / 2, z_slot + SLOT[1] / 2, "Mijia", rotation=90, color="#9a6a00", fontsize=8)
label(wall, y0 + MOD[0] / 2, ROWS[1] + 12, "the HEPA: four Mijia cartridges", color="#9a6a00", fontsize=7.5)
# bottom right: the carbon, its dust filter, four Deltas, the sensors, the outlet, the purge
box(wall, y0 + 8, BED_Z, MOD[0] - 16, BED_D, "none", ec=CARBON_C, ls="--")
label(wall, y0 + MOD[0] / 2, BED_Z + BED_D / 2, "carbon, lying flat, behind the skin;\nthe carbon-dust floss under it",
      color=CARBON_C, fontsize=7)
box(wall, y0 + 8, FLOSS_Z, MOD[0] - 16, 7, FLOSS_C, ec="#777", ls="--")
for fy in FANS_Y:
    box(wall, fy, FAN_Z, DELTA[0], DELTA[1], FAN_C, ls="--")
label(wall, y0 + MOD[0] / 2, FAN_Z - 9, "four Deltas [D300]", color="#3182bd", fontsize=7)
y_a, y_b, z_a, z_b = SENSORS
box(wall, y_a, z_a, y_b - y_a, z_b - z_a, "#fdd0a2", ec="#d94801", ls="--")
label(wall, (y_a + y_b) / 2, (z_a + z_b) / 2, "SPS30, SGP41", color="#d94801", fontsize=6.5)
y_a, y_b, z_a, z_b = OUTLET
box(wall, y_a, z_a, y_b - y_a, z_b - z_a, "white", ec="tab:blue")
for y in range(int(y_a) + 12, int(y_b), 16):
    wall.plot([y, y + 7], [z_a + 6, z_b - 6], color="tab:blue", lw=0.8)
label(wall, (y_a + y_b) / 2, z_a - 17, "the clean air back in, low", color="tab:blue", fontsize=7.5)
py, pz, pr = PURGE
wall.add_patch(mp.Circle((py, pz), pr, fill=False, ec=PURGE_C, ls="--", lw=1.4))
label(wall, py, pz, "purge:\na servo's\ndamper, the\n100 mm\ncollar out", color=PURGE_C, fontsize=6.5)
# bottom left: the electronics
y0, z0 = COLS[0], ROWS[0]
box(wall, y0 + 25, z0 + 30, 175, 140, ELEC_C, ec="#6a51a3", ls="--")
label(wall, y0 + 112, z0 + 100, "the electronics:\nthe SuperMini, the USB-C\ntrigger, the fans', the\nservo's and the sensors'\nconnectors",
      color="#6a51a3", fontsize=7.5)
dim(wall, (COLS[0], ROWS[1] + MOD[1] + 4), (COLS[1], ROWS[1] + MOD[1] + 4), "225", dy=-9, fontsize=7.5)
dim(wall, (LACK + 30, 0), (LACK + 30, CH_H), "460", dx=22)
dim(wall, (LEG, -TOP - 30), (LACK - LEG, -TOP - 30), "450, between the legs", dy=-16)
label(wall, LACK / 2, -TOP - 80,
      f"each module {MOD[0]} × {MOD[1]}, face down on the {BED_XY[0]} × {BED_XY[1]} bed; rails of {RAIL:.0f} on the floor "
      "and under the roof;\ndashed green: the TPU seal, on the floor, the roof and the legs", fontsize=8)
label(wall, 25, -TOP - 115, "front\n(door)")
label(wall, LACK - 25, -TOP - 115, "back")
arrows(wall, (-125, -190), "+Y", "+Z")
wall.set_xlim(-140, LACK + 90)
wall.set_ylim(-205, CH_H + TOP + 20)
wall.set_aspect("equal")
wall.axis("off")
wall.set_title("The filter wall, seen from inside: the door on the left, the back on the right", fontsize=10)

# ---- cut across the right column at the purge, seen from the front: X right (the room left, the chamber right), Z up
hd, cd = INSIDE, INSIDE + PROUD
box(cut, -60, -TOP, 280, TOP, WOOD, ec=WOOD_EDGE)
label(cut, 150, -TOP / 2, "the floor")
box(cut, -60, CH_H, 280, TOP, WOOD, ec=WOOD_EDGE)
label(cut, 150, CH_H + TOP / 2, "the roof")
cut.plot([0, 0], [-TOP - 15, CH_H + TOP + 15], color="#777", lw=1, ls=":")
label(cut, 2, CH_H + TOP + 26, "the Lack's edge", color="#777", fontsize=7, ha="left")
box(cut, 0, 0, hd, RAIL, FRAME_C, ec="#c26a1b")
box(cut, 0, ROWS[1] + MOD[1], hd, RAIL, FRAME_C, ec="#c26a1b")
for z in (0, CH_H - 3):
    box(cut, 2, z, hd - 4, 3, SEAL, ec=SEAL)
box(cut, -PROUD, ROWS[0], cd, MOD[1], MOD_C, ec="#c26a1b", lw=1.6)          # the carbon module, 40 proud
box(cut, 0, ROWS[1], hd, MOD[1], MOD_C, ec="#c26a1b", lw=1.6)               # the HEPA module
box(cut, -PROUD + SKIN, ROWS[0] + SKIN, cd - 2 * SKIN, MOD[1] - 2 * SKIN, "white", ec="none")
box(cut, SKIN, ROWS[1] + SKIN, hd - 2 * SKIN, MOD[1] - 2 * SKIN, "white", ec="none")
box(cut, SKIN, ROWS[1] - 4, hd - 2 * SKIN, 8, "white", ec="none")       # the port between them
label(cut, -PROUD - 8, ROWS[1] + 12, "port,\ngasketed", fontsize=7, ha="right", color="#c26a1b")
box(cut, hd - SKIN - 15, z_slot, 15 + SKIN, SLOT[1], HEPA_C, ec="#9a6a00")
box(cut, -PROUD + SKIN, BED_Z, cd - 2 * SKIN, BED_D, CARBON_C)
box(cut, -PROUD + SKIN, FLOSS_Z, cd - 2 * SKIN, 7, FLOSS_C, ec="#777")
box(cut, -PROUD + SKIN, FAN_Z - 3, cd - 2 * SKIN, 3, MOD_C, ec="#c26a1b")
box(cut, PROUD / 2 - 40, FAN_Z, DELTA[0], DELTA[1], FAN_C)
box(cut, hd - SKIN - 12, SENSORS[2], 12, SENSORS[3] - SENSORS[2], "#fdd0a2", ec="#d94801")
box(cut, hd - SKIN - 1, OUTLET[2], SKIN + 2, OUTLET[3] - OUTLET[2], "white", ec="tab:blue")
box(cut, -PROUD - 30, pz - pr, 30, 2 * pr, "white", ec=PURGE_C)                # the collar, out to the duct
cut.plot([-PROUD - 4, -PROUD - 4], [pz - pr + 8, pz + pr - 8], color=PURGE_C, lw=3)
flow(cut, (170, 400), (hd + 2, 400), "tab:orange")
label(cut, 170, 372, "the plume, drawn in\nunder the roof", color="tab:orange", fontsize=8)
flow(cut, (hd / 2, 380), (hd / 2, BED_Z + BED_D + 6), "tab:orange")
flow(cut, (0, FLOSS_Z - 3), (0, FAN_Z + DELTA[1] + 6), "tab:blue")
flow(cut, (0, FAN_Z - 6), (0, 70), "tab:blue")
flow(cut, (hd + 2, 58), (200, 45), "tab:blue")
flow(cut, (-PROUD, pz), (-PROUD - 95, pz), PURGE_C)
label(cut, 165, 72, "most back in, low", color="tab:blue", fontsize=8)
label(cut, -PROUD - 60, pz + pr + 22, "a little out:\nthe purge, to\nthe window [D300]", color=PURGE_C, fontsize=7.5)
label(cut, 75, z_slot + 40, "the cartridges,\nstanding", color="#9a6a00", fontsize=8, ha="left")
label(cut, 75, BED_Z + 26, "carbon, lying flat,\nthe air down through it", color=CARBON_C, fontsize=8, ha="left")
label(cut, 75, FLOSS_Z - 2, "carbon-dust filter (floss)", color="#555", fontsize=8, ha="left")
label(cut, 75, FAN_Z + 10, "Deltas, in the fans' plate", color="#3182bd", fontsize=8, ha="left")
label(cut, 75, SENSORS[2] + 6, "the sensors, in the clean air", color="#d94801", fontsize=7.5, ha="left")
label(cut, 75, CH_H - 10, "the seal under the roof", color=SEAL, fontsize=7, ha="left")
label(cut, 75, 12, "and on the floor", color=SEAL, fontsize=7, ha="left")
dim(cut, (0, CH_H + TOP + 45), (hd, CH_H + TOP + 45), f"{hd} in (Q296)", dy=11, fontsize=7.5)
dim(cut, (-PROUD, -TOP - 22), (hd, -TOP - 22), f"{cd}: the carbon module, {PROUD} of it out past the edges [D301]",
    dy=-15, fontsize=7.5)
label(cut, 200, 330, "the chamber", fontsize=9, color="#555")
label(cut, -150, 350, "the room", fontsize=9, color="#555")
arrows(cut, (-215, -150), "+X", "+Z")
cut.set_xlim(-235, 235)
cut.set_ylim(-185, CH_H + TOP + 70)
cut.set_aspect("equal")
cut.axis("off")
cut.set_title("Cut across the right column at the purge, seen from the front", fontsize=10)

fig.suptitle("The filter wall, one unit between the floor and the roof - the Lack, the chamber and the modules' size to "
             "scale; what is in them placed, not designed", fontsize=12)
fig.tight_layout(rect=(0, 0, 1, 0.95))
OUT.parent.mkdir(parents=True, exist_ok=True)
fig.savefig(OUT, dpi=110)
print("wrote", OUT.relative_to(ROOT))
