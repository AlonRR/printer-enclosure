#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
# SPDX-License-Identifier: MPL-2.0
# /// script
# requires-python = ">=3.11"
# dependencies = ["matplotlib"]
# ///
"""The filter wall's layout (Alon, 15 Oct 2026: D294 a, Q295, D291 a, T293, Q296, D297 b, D298 a): the enclosure's left
wall, printed, is the scrubber, built as a frame and four modules, one job each - seen from inside, four HEPA
cartridges top right, the carbon, the Deltas, the sensors and the outlet bottom right, the extraction's vent top
left, the electronics bottom left. From the repository's root:

  uv run scripts/figures/filter-wall.py       writes docs/diagrams/filter-wall/layout.png

The Lack, its legs and the chamber are to scale, and so is the modules' size against the printer's bed; what is in
them is placed, not designed. No makeup inlet: the room's air comes in round the other walls' and the doors' gaps.
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
CH_H = 460          # the chamber (Q157)
BED_XY = (250, 210)  # the printer's bed
# placed, not designed
OVER = 20           # the frame's rails over the top's and the floor's edges, where the seal presses (50 there: Q296)
MOD = (225, 205)    # a module: along the wall, tall; face down on the bed
COLS = (LEG, LEG + MOD[0])        # the modules' columns, from the front
ROWS = (25, 25 + MOD[1])          # the modules' rows, from the floor
SKIN = 3
DEPTH = {"hepa": 50, "carbon": 90}  # the right column's two modules, deep
SLOT = (49, 150)                  # a Mijia cartridge standing: wide, tall; four slots across the module
FITTED = 4
BED_Z, BED_D, FLOSS_Z = 168, 40, 150   # in the carbon module: the bed's floor and depth, the floss's frame
FAN_Z, DELTA = 100, (40, 20)
FANS_Y = (COLS[1] + 25, COLS[1] + 75)
OUTLET = (COLS[1] + 10, COLS[1] + 125, 35, 80)
SENSORS = (COLS[1] + 20, COLS[1] + 110, 88, 100)

WOOD, WOOD_EDGE = "#e6d3b1", "#8a6d3b"
FRAME_C, MOD_C, SEAL = "#f2b98a", "#fde0c5", "#2d7d46"
HEPA_C, CARBON_C, FLOSS_C, FAN_C = "#fff3b0", "#555555", "#e8e8e8", "#9ecae1"
VENT_C, ELEC_C = "#f5d0cf", "#e5dcf2"


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
box(wall, 0, -OVER, LACK, CH_H + 2 * OVER, FRAME_C, ec="#c26a1b")          # the frame, under everything
wall.add_patch(mp.Rectangle((4, -OVER + 4), LACK - 8, CH_H + 2 * OVER - 8, fill=False, ec=SEAL, lw=2.5, ls="--"))
for y, z in ((COLS[0], ROWS[0]), (COLS[0], ROWS[1]), (COLS[1], ROWS[0]), (COLS[1], ROWS[1])):
    box(wall, y, z, MOD[0], MOD[1], MOD_C, ec="#c26a1b", lw=1.6)
for y in (0, LACK - LEG):
    box(wall, y, 0, LEG, CH_H, WOOD, ec=WOOD_EDGE, alpha=0.55)
box(wall, 0, -TOP, LACK, TOP, WOOD, ec=WOOD_EDGE, alpha=0.9)
box(wall, 0, CH_H, LACK, TOP, WOOD, ec=WOOD_EDGE, alpha=0.9)
label(wall, LACK / 2, -TOP / 2, "the floor: the frame's rail behind its edge, the seal on it")
label(wall, LACK / 2, CH_H + TOP / 2, "the top: the same at its edge; nothing on it, not drilled")
# top left: the extraction's vent
y0, z0 = COLS[0], ROWS[1]
box(wall, y0 + 25, z0 + 25, 175, 155, VENT_C, ec="darkred")
wall.add_patch(mp.Circle((y0 + 112, z0 + 102), 50, fill=False, ec="darkred", ls="--", lw=1.2))
label(wall, y0 + 112, z0 + 102, "[B] extraction:\nits own HEPA and\ncarbon; the 100 mm\ncollar outside,\nto the window", color="darkred",
      fontsize=7.5)
# top right: the scrubber's HEPA, four slots
y0 = COLS[1]
gap = (MOD[0] - 4 * SLOT[0]) / 5
z_slot = ROWS[1] + (MOD[1] - SLOT[1]) / 2
for i in range(4):
    ys = y0 + gap + i * (SLOT[0] + gap)
    fitted = i < FITTED
    box(wall, ys, z_slot, SLOT[0], SLOT[1], HEPA_C if fitted else "white", ec="#9a6a00", ls="-" if fitted else "--")
    label(wall, ys + SLOT[0] / 2, z_slot + SLOT[1] / 2, "Mijia" if fitted else "blank", rotation=90,
          color="#9a6a00", fontsize=8)
label(wall, y0 + MOD[0] / 2, ROWS[1] + 12, "the scrubber's HEPA: four Mijia cartridges", color="#9a6a00",
      fontsize=7.5)
# bottom right: the carbon, its dust filter, the Deltas, the sensors, the clean air out
box(wall, y0 + 8, BED_Z, MOD[0] - 16, BED_D, "none", ec=CARBON_C, ls="--")
label(wall, y0 + MOD[0] / 2, BED_Z + BED_D / 2, "carbon, lying flat, behind the skin", color=CARBON_C, fontsize=7.5)
box(wall, y0 + 8, FLOSS_Z, MOD[0] - 16, 8, FLOSS_C, ec="#777", ls="--")
label(wall, y0 + MOD[0] / 2, FLOSS_Z - 9, "carbon-dust filter: floss, on its own frame", color="#555", fontsize=7.5)
for fy in FANS_Y:
    box(wall, fy, FAN_Z + 10, DELTA[0], DELTA[1], FAN_C, ls="--")
label(wall, COLS[1] + 145, FAN_Z + 20, "the Deltas", color="#3182bd", fontsize=7)
y_a, y_b, z_a, z_b = SENSORS
box(wall, y_a, z_a, y_b - y_a, z_b - z_a, "#fdd0a2", ec="#d94801", ls="--")
label(wall, COLS[1] + 145, (z_a + z_b) / 2, "SPS30,\nSGP41", color="#d94801", fontsize=7)
y_a, y_b, z_a, z_b = OUTLET
box(wall, y_a, z_a, y_b - y_a, z_b - z_a, "white", ec="tab:blue")
for y in range(int(y_a) + 12, int(y_b), 16):
    wall.plot([y, y + 7], [z_a + 6, z_b - 6], color="tab:blue", lw=0.8)
label(wall, (y_a + y_b) / 2, z_a - 17, "the clean air out, across the floor", color="tab:blue", fontsize=7.5)
# bottom left: the electronics
y0, z0 = COLS[0], ROWS[0]
box(wall, y0 + 25, z0 + 30, 175, 140, ELEC_C, ec="#6a51a3", ls="--")
label(wall, y0 + 112, z0 + 100, "the electronics:\nthe SuperMini, the USB-C\ntrigger, the fans' and\nsensors' connectors",
      color="#6a51a3", fontsize=7.5)
# the modules' size against the bed
dim(wall, (COLS[0], ROWS[1] + MOD[1] + 6), (COLS[1], ROWS[1] + MOD[1] + 6), "225", dy=9, fontsize=7.5)
dim(wall, (COLS[0] - 8, ROWS[1]), (COLS[0] - 8, ROWS[1] + MOD[1]), "205", dx=-16, fontsize=7.5, rotation=90)
dim(wall, (LACK + 30, -OVER), (LACK + 30, CH_H + OVER), f"{CH_H + 2 * OVER}\n(460 and\n{OVER} over\neach edge)", dx=32)
dim(wall, (0, -TOP - 30), (LACK, -TOP - 30), "550", dy=-16)
label(wall, LACK / 2, -TOP - 80,
      f"each module {MOD[0]} × {MOD[1]}, face down on the {BED_XY[0]} × {BED_XY[1]} bed; the frame in pieces; "
      "dashed green: the TPU seal, and at every joint", fontsize=8)
label(wall, 25, -TOP - 115, "front\n(door)")
label(wall, LACK - 25, -TOP - 115, "back")
arrows(wall, (-120, -150), "+Y", "+Z")
wall.set_xlim(-150, LACK + 110)
wall.set_ylim(-185, CH_H + TOP + 20)
wall.set_aspect("equal")
wall.axis("off")
wall.set_title("The filter wall, seen from inside: the door on the left, the back on the right",
               fontsize=10)

# ---- cut across the right column, seen from the front: X right (the room left, the chamber right), Z up
hd, cd = DEPTH["hepa"], DEPTH["carbon"]
box(cut, 0, -TOP, 200, TOP, WOOD, ec=WOOD_EDGE)
label(cut, 100, -TOP / 2, "the floor")
box(cut, 0, CH_H, 200, TOP, WOOD, ec=WOOD_EDGE)
label(cut, 100, CH_H + TOP / 2, "the top")
box(cut, -hd, -OVER, hd, ROWS[0] + OVER, FRAME_C, ec="#c26a1b")                # the bottom rail
box(cut, -hd, ROWS[1] + MOD[1], hd, CH_H + OVER - ROWS[1] - MOD[1], FRAME_C, ec="#c26a1b")  # the top rail
box(cut, -cd, ROWS[0], cd, MOD[1], MOD_C, ec="#c26a1b", lw=1.6)                # the carbon module, deeper
box(cut, -hd, ROWS[1], hd, MOD[1], MOD_C, ec="#c26a1b", lw=1.6)                # the HEPA module
box(cut, -cd + SKIN, ROWS[0] + SKIN, cd - 2 * SKIN, MOD[1] - 2 * SKIN, "white", ec="none")
box(cut, -hd + SKIN, ROWS[1] + SKIN, hd - 2 * SKIN, MOD[1] - 2 * SKIN, "white", ec="none")
box(cut, -hd + SKIN, ROWS[1] - 4, hd - 2 * SKIN, 8, "white", ec="none")       # the port between them
label(cut, -cd - 8, ROWS[1] + 10, "port,\ngasketed", fontsize=7, ha="right", color="#c26a1b")
for z in (-OVER, CH_H + 5):
    box(cut, -2, z, 2, OVER - 5, SEAL, ec=SEAL)
box(cut, -SKIN - 15, z_slot, 15 + SKIN, SLOT[1], HEPA_C, ec="#9a6a00")
box(cut, -cd + SKIN, BED_Z, cd - 2 * SKIN, BED_D, CARBON_C)
box(cut, -cd + SKIN, FLOSS_Z, cd - 2 * SKIN, 8, FLOSS_C, ec="#777")
box(cut, -cd + SKIN, FAN_Z, cd - 2 * SKIN, 3, MOD_C, ec="#c26a1b")
box(cut, -cd / 2 - DELTA[0] / 2, FAN_Z + 3, DELTA[0], DELTA[1], FAN_C)
box(cut, -SKIN - 12, SENSORS[2], 12, SENSORS[3] - SENSORS[2], "#fdd0a2", ec="#d94801")
box(cut, -SKIN - 1, OUTLET[2], SKIN + 2, OUTLET[3] - OUTLET[2], "white", ec="tab:blue")
box(cut, -cd - 2, ROWS[0] + 20, SKIN + 4, MOD[1] - 40, "white", ec="#c26a1b", ls="--")
flow(cut, (110, 400), (2, 400), "tab:orange")
label(cut, 110, 425, "the plume, drawn in\nunder the top", color="tab:orange", fontsize=8)
flow(cut, (-hd / 2, 380), (-hd / 2, BED_Z + BED_D + 6), "tab:orange")
flow(cut, (-cd / 2, FLOSS_Z - 3), (-cd / 2, FAN_Z + DELTA[1] + 6), "tab:blue")
flow(cut, (-cd / 2 + 25, FAN_Z - 4), (-cd / 2 + 25, 62), "tab:blue")
flow(cut, (2, 58), (140, 45), "tab:blue")
label(cut, 135, 22, "out low, across the floor", color="tab:blue", fontsize=8)
label(cut, 30, z_slot + 40, "the cartridges,\nstanding", color="#9a6a00", fontsize=8, ha="left")
label(cut, 30, BED_Z + 22, "carbon, lying flat,\nthe air down through it", color=CARBON_C, fontsize=8, ha="left")
label(cut, 30, FLOSS_Z - 4, "carbon-dust filter (floss)", color="#555", fontsize=8, ha="left")
label(cut, 30, FAN_Z + 14, "a Delta, in the fans' plate", color="#3182bd", fontsize=8, ha="left")
label(cut, 30, SENSORS[2] + 4, "the sensors, in the clean air", color="#d94801", fontsize=7.5, ha="left")
label(cut, -cd - 12, ROWS[0] + MOD[1] / 2 - 20, "a hatch:\nthe carbon\nand the floss\nchange from\noutside", fontsize=7,
      color="#c26a1b", ha="right")
label(cut, 30, CH_H - 8, "the seal on the top's edge", color=SEAL, fontsize=7, ha="left")
label(cut, 30, -8, "and on the floor's", color=SEAL, fontsize=7, ha="left")
dim(cut, (-hd, CH_H + TOP + 20), (0, CH_H + TOP + 20), f"{hd}", dy=12, fontsize=7.5)
dim(cut, (-cd, -TOP - 22), (0, -TOP - 22), f"{cd}: the carbon module, deeper", dy=-15, fontsize=7.5)
label(cut, 165, 355, "the chamber", fontsize=9, color="#555")
label(cut, -170, 330, "the room", fontsize=9, color="#555")
arrows(cut, (-215, -150), "+X", "+Z")
cut.set_xlim(-235, 215)
cut.set_ylim(-185, CH_H + TOP + 45)
cut.set_aspect("equal")
cut.axis("off")
cut.set_title("Cut across the right column, seen from the front: the room left, the chamber right", fontsize=10)

fig.suptitle("The filter wall: a frame and four modules - the Lack, the chamber and the modules' size to scale; "
             "what is in them placed, not designed", fontsize=12)
fig.tight_layout(rect=(0, 0, 1, 0.95))
OUT.parent.mkdir(parents=True, exist_ok=True)
fig.savefig(OUT, dpi=110)
print("wrote", OUT.relative_to(ROOT))
