#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
# SPDX-License-Identifier: MPL-2.0
# /// script
# requires-python = ">=3.11"
# dependencies = ["matplotlib"]
# ///
"""The filter wall's layout (Alon, 15 Oct 2026: D294 a, D291 a, D298 a, D302 a, D300 a, D301, D303 a): the enclosure's
left wall, printed, is the one filter unit, standing between the floor and the roof and between the legs. Its top row
is IKEA's STARKVIND particle filter, uncut; its bottom row the carbon lying flat across the whole width, its dust
floss, the Deltas, the sensors, the clean air's outlet and the purge to the window. From the repository's root:

  uv run scripts/figures/filter-wall.py       writes docs/diagrams/filter-wall/layout.png

The Lack, its legs, the chamber and the filter are to scale; the rest is placed, not designed. The wall is 90 deep,
40 of it out past the Lack's edge, so the filter's 40 mm leaves a plenum behind it; two Deltas in a plate cut for
four, and a servo's damper on the purge.
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
DEPTH = 50          # the wall within the Lack: the room on the floor and the roof is 50 or more (Q296)
PANEL = (370, 290, 40)            # IKEA STARKVIND particle filter, as IKEA lists it (D303 a)
# placed, not designed
PROUD = 40          # the wall, out past the edge into the room (D301)
RAIL = 15           # on the floor and under the roof, carrying the seal
FRAME = 8           # the filter's frame round it, each side
HEPA_ROW = (CH_H - RAIL - PANEL[1] - 2 * FRAME, CH_H - RAIL)
CARB_ROW = (RAIL, HEPA_ROW[0])
SKIN = 3
BED_Z, BED_D = 100, 36            # the carbon: its floor, and its depth at two Deltas, mid grade
FLOSS_Z = 90
FAN_Z, DELTA = 64, (40, 20)
FANS_Y = (100, 180, 260, 340)     # four places, the middle two fitted
FITTED = (180, 260)
OUTLET = (65, 250, 22, 52)        # the clean air's louvre in the inner face: y from, to, z from, to
SENSORS = (262, 330, 26, 38)
PURGE = (345, 485, 20, 58)        # the purge's slot in the outer face, to a 100 mm collar

WOOD, WOOD_EDGE = "#e6d3b1", "#8a6d3b"
FRAME_C, MOD_C, SEAL = "#f2b98a", "#fde0c5", "#2d7d46"
HEPA_C, CARBON_C, FLOSS_C, FAN_C = "#fff3b0", "#555555", "#e8e8e8", "#9ecae1"
PURGE_C = "darkred"


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
for z0, z1 in (HEPA_ROW, CARB_ROW):
    box(wall, LEG, z0, LACK - 2 * LEG, z1 - z0, MOD_C, ec="#c26a1b", lw=1.6)
for y in (LACK / 2,):                     # the rows' frames, in pieces
    wall.plot([y, y], [CARB_ROW[0], HEPA_ROW[1]], color="#c26a1b", lw=0.8, ls=":")
wall.plot([LEG, LACK - LEG], [(HEPA_ROW[0] + HEPA_ROW[1]) / 2] * 2, color="#c26a1b", lw=0.8, ls=":")
# the top row: the filter
pl, ph, pt = PANEL
py0 = (LACK - pl) / 2
pz0 = HEPA_ROW[0] + FRAME
box(wall, py0, pz0, pl, ph, HEPA_C, ec="#9a6a00", lw=1.6)
for y in range(int(py0) + 10, int(py0 + pl), 12):
    wall.plot([y, y], [pz0 + 6, pz0 + ph - 6], color="#e0c060", lw=0.5)
label(wall, LACK / 2, pz0 + ph / 2 + 12, "IKEA STARKVIND particle filter, 370 × 290 × 40, EPA12, uncut [D303 a]",
      color="#9a6a00", fontsize=8.5, bbox={"facecolor": HEPA_C, "edgecolor": "none"})
label(wall, LACK / 2, pz0 + ph / 2 - 14, "its frame in pieces; it changes from the chamber", color="#c26a1b",
      fontsize=7.5, bbox={"facecolor": HEPA_C, "edgecolor": "none"})
# the bottom row: carbon, floss, Deltas, sensors, outlet, purge
box(wall, LEG + 8, BED_Z, LACK - 2 * LEG - 16, BED_D, "none", ec=CARBON_C, ls="--")
label(wall, LACK / 2, BED_Z + BED_D / 2, "carbon, lying flat across the whole row, behind the skin; the dust floss under it",
      color=CARBON_C, fontsize=7.5)
box(wall, LEG + 8, FLOSS_Z, LACK - 2 * LEG - 16, 6, FLOSS_C, ec="#777", ls="--")
for fy in FANS_Y:
    box(wall, fy, FAN_Z, DELTA[0], DELTA[1], FAN_C if fy in FITTED else "white", ls="--")
label(wall, 442, FAN_Z + 10, "two Deltas; room\nfor two more", color="#3182bd", fontsize=6.5)
y_a, y_b, z_a, z_b = OUTLET
box(wall, y_a, z_a, y_b - y_a, z_b - z_a, "white", ec="tab:blue")
for y in range(y_a + 12, y_b, 16):
    wall.plot([y, y + 5], [z_a + 5, z_b - 5], color="tab:blue", lw=0.8)
label(wall, (y_a + y_b) / 2, z_b + 6, "the clean air back in, low", color="tab:blue", fontsize=6.5)
y_a, y_b, z_a, z_b = SENSORS
box(wall, y_a, z_a, y_b - y_a, z_b - z_a, "#fdd0a2", ec="#d94801")
label(wall, (y_a + y_b) / 2, (z_a + z_b) / 2, "SPS30, SGP41", color="#d94801", fontsize=6)
y_a, y_b, z_a, z_b = PURGE
box(wall, y_a, z_a, y_b - y_a, z_b - z_a, "none", ec=PURGE_C, ls="--", lw=1.4)
label(wall, (y_a + y_b) / 2, (z_a + z_b) / 2, "purge, outer face: a servo's\ndamper, to a 100 mm collar", color=PURGE_C,
      fontsize=6.5)
dim(wall, (LACK + 30, 0), (LACK + 30, CH_H), "460", dx=22)
dim(wall, (LACK + 12, HEPA_ROW[0]), (LACK + 12, HEPA_ROW[1]), f"{HEPA_ROW[1] - HEPA_ROW[0]:.0f}", dx=14, fontsize=7)
dim(wall, (LACK + 12, CARB_ROW[0]), (LACK + 12, CARB_ROW[1]), f"{CARB_ROW[1] - CARB_ROW[0]:.0f}", dx=14, fontsize=7)
dim(wall, (LEG, -TOP - 30), (LACK - LEG, -TOP - 30), "450, between the legs", dy=-16)
label(wall, LACK / 2, -TOP - 78,
      f"rails of {RAIL} on the floor and under the roof; the pieces each fit the 250 × 210 bed; the electronics in a box\n"
      "on the outer face; dashed green: the TPU seal, on the floor, the roof and the legs", fontsize=8)
label(wall, 25, -TOP - 115, "front\n(door)")
label(wall, LACK - 25, -TOP - 115, "back")
arrows(wall, (-125, -190), "+Y", "+Z")
wall.set_xlim(-140, LACK + 90)
wall.set_ylim(-205, CH_H + TOP + 20)
wall.set_aspect("equal")
wall.axis("off")
wall.set_title("The filter wall, seen from inside: the door on the left, the back on the right", fontsize=10)

# ---- cut across the wall at a Delta, seen from the front: X right (the room left, the chamber right), Z up
x0 = -PROUD
box(cut, -60, -TOP, 300, TOP, WOOD, ec=WOOD_EDGE)
label(cut, 165, -TOP / 2, "the floor")
box(cut, -60, CH_H, 300, TOP, WOOD, ec=WOOD_EDGE)
label(cut, 165, CH_H + TOP / 2, "the roof")
cut.plot([0, 0], [-TOP - 15, CH_H + TOP + 15], color="#777", lw=1, ls=":")
label(cut, -2, CH_H + TOP + 10, "the Lack's edge", color="#777", fontsize=7, ha="right")
for z0, z1 in ((0, RAIL), (CH_H - RAIL, CH_H)):
    box(cut, x0, z0, DEPTH - x0, z1 - z0, FRAME_C, ec="#c26a1b")
for z in (0, CH_H - 3):
    box(cut, x0 + 2, z, DEPTH - x0 - 4, 3, SEAL, ec=SEAL)
for z0, z1 in (HEPA_ROW, CARB_ROW):
    box(cut, x0, z0, DEPTH - x0, z1 - z0, MOD_C, ec="#c26a1b", lw=1.6)
    box(cut, x0 + SKIN, z0 + SKIN, DEPTH - x0 - 2 * SKIN, z1 - z0 - 2 * SKIN, "white", ec="none")
box(cut, x0 + SKIN, HEPA_ROW[0] - 4, DEPTH - x0 - 2 * SKIN, 8, "white", ec="none")   # open between the rows
box(cut, DEPTH - pt, pz0, pt, ph, HEPA_C, ec="#9a6a00")
box(cut, x0 + SKIN, BED_Z, DEPTH - x0 - 2 * SKIN, BED_D, CARBON_C)
box(cut, x0 + SKIN, FLOSS_Z, DEPTH - x0 - 2 * SKIN, 6, FLOSS_C, ec="#777")
box(cut, x0 + SKIN, FAN_Z - 3, DEPTH - x0 - 2 * SKIN, 3, MOD_C, ec="#c26a1b")
box(cut, (DEPTH + x0 - DELTA[0]) / 2, FAN_Z, DELTA[0], DELTA[1], FAN_C)
box(cut, DEPTH - SKIN - 1, OUTLET[2], SKIN + 2, OUTLET[3] - OUTLET[2], "white", ec="tab:blue")
box(cut, DEPTH - SKIN - 14, SENSORS[2], 11, SENSORS[3] - SENSORS[2], "#fdd0a2", ec="#d94801")
box(cut, x0 - 30, PURGE[2], 30, PURGE[3] - PURGE[2], "white", ec=PURGE_C)
cut.plot([x0 - 4, x0 - 4], [PURGE[2] + 5, PURGE[3] - 5], color=PURGE_C, lw=3)
flow(cut, (200, 330), (DEPTH + 2, 330), "tab:orange")
label(cut, 170, 355, "the plume, drawn in\nunder the roof", color="tab:orange", fontsize=8)
flow(cut, (-12, 320), (-12, BED_Z + BED_D + 5), "tab:orange")
flow(cut, (5, FLOSS_Z - 3), (5, FAN_Z + DELTA[1] + 4), "tab:blue")
flow(cut, (5, FAN_Z - 6), (5, 45), "tab:blue")
flow(cut, (DEPTH + 2, 37), (210, 26), "tab:blue")
flow(cut, (x0 - 30, 39), (x0 - 100, 39), PURGE_C)
label(cut, 175, 52, "most back in, low", color="tab:blue", fontsize=8)
label(cut, -105, 85, "a little out: the\npurge, a servo's\ndamper", color=PURGE_C, fontsize=7.5)
label(cut, x0 - 10, pz0 + ph / 2, "closed on the\nroom's side:\nthe filter\nchanges from\nthe chamber", color="#c26a1b",
      fontsize=7, ha="right")
label(cut, 75, pz0 + 25, "the filter, 40 thick;\nthe plenum behind it", color="#9a6a00", fontsize=8, ha="left")
label(cut, 75, BED_Z + 22, "carbon, lying flat,\nthe air down through it", color=CARBON_C, fontsize=8, ha="left")
label(cut, 75, FLOSS_Z + 2, "carbon-dust floss", color="#555", fontsize=8, ha="left")
label(cut, 75, FAN_Z + 10, "a Delta", color="#3182bd", fontsize=8, ha="left")
label(cut, 75, CH_H - 10, "the seal under the roof", color=SEAL, fontsize=7, ha="left")
label(cut, 75, 8, "and on the floor", color=SEAL, fontsize=7, ha="left")
dim(cut, (x0, CH_H + TOP + 32), (DEPTH, CH_H + TOP + 32), f"{DEPTH - x0}: {DEPTH} within, {PROUD} out", dy=10,
    fontsize=7.5)
dim(cut, (x0, -TOP - 25), (DEPTH, -TOP - 25), f"the whole wall {DEPTH - x0} deep", dy=-15, fontsize=7.5)
label(cut, 190, 230, "the chamber", fontsize=9, color="#555")
label(cut, -160, 200, "the room", fontsize=9, color="#555")
arrows(cut, (-215, -150), "+X", "+Z")
cut.set_xlim(-235, 255)
cut.set_ylim(-185, CH_H + TOP + 60)
cut.set_aspect("equal")
cut.axis("off")
cut.set_title("Cut across the wall at a Delta, seen from the front", fontsize=10)

fig.suptitle("The filter wall, IKEA's STARKVIND and one carbon row between the floor and the roof - the Lack, the "
             "chamber and the filter to scale; the rest placed, not designed", fontsize=12)
fig.tight_layout(rect=(0, 0, 1, 0.95))
OUT.parent.mkdir(parents=True, exist_ok=True)
fig.savefig(OUT, dpi=110)
print("wrote", OUT.relative_to(ROOT))
