#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
# SPDX-License-Identifier: MPL-2.0
# /// script
# requires-python = ">=3.11"
# dependencies = ["matplotlib"]
# ///
"""The filter wall's layout (Alon, 15 Oct 2026: D294 a, Q295, Q290): the enclosure's left wall, printed and about
50 mm thick, is the scrubber - two Mijia cartridges in its inner face at the top, the carbon lying flat across its
channel, the two Deltas under it, the clean air out low - with the extraction's vent at its front end and the makeup
air in at its back end, at the Einsy. From the repository's root:

  uv run scripts/figures/filter-wall.py       writes docs/diagrams/filter-wall/layout.png

The Lack, its legs and the chamber are to scale; the wall's parts are placed, not designed, and its outline is the
chamber's side until the sheet it replaces is measured [K]. The lettered labels are what is still open.
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
# placed, not designed
SKIN = 3            # each of the wall's two skins
CHAN = 44           # the channel between them: the Deltas' 40 mm and a wall each side
MIJIA = (150, 49, 15)            # a cartridge: long, wide, its pleats deep
HEPA_Y = 250                     # the two cartridges, one above the other, from here along the wall
HEPA_Z = (334, 389)              # the bottom of each row
BED_Z, BED_D, FLOSS = 230, 30, 6  # the carbon: its floor, its depth, the floss under it
FAN_Z, DELTA = 140, (40, 20)     # the fans' plate, and a Delta: square, deep
FANS_Y = (205, 305)
OUTLET = (120, 400, 25, 85)      # the clean air's louvre: y from, to, z from, to
VENT = (60, 195, 300, 435, 30)   # the extraction's vent: y from, to, z from, to, and how far past the outer skin
MAKEUP = (430, 490, 20, 95)      # the makeup air's grille, across the channel in a sleeve
HATCH_Z = (200, 450)             # the outer skin's hatch, for the filters

WOOD, WOOD_EDGE = "#e6d3b1", "#8a6d3b"
PRINTED, SEAL = "#fde0c5", "#2d7d46"
HEPA_C, CARBON_C, FLOSS_C, FAN_C = "#fff3b0", "#555555", "#f2f2f2", "#9ecae1"
VENT_C, MAKEUP_C = "#f5d0cf", "#c7e9c0"


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


def flow(ax, a, b, color, lw=2, style="->"):
    ax.annotate("", b, a, arrowprops={"arrowstyle": style, "color": color, "lw": lw})


def dim(ax, a, b, text, color="black", **kw):
    """A dimension line from a to b, its text beside the middle."""
    ax.annotate("", b, a, arrowprops={"arrowstyle": "<->", "color": color, "lw": 1})
    label(ax, (a[0] + b[0]) / 2 + kw.pop("dx", 0), (a[1] + b[1]) / 2 + kw.pop("dy", 0), text, color=color, **kw)


fig, (wall, cut) = plt.subplots(1, 2, figsize=(16, 8.8), gridspec_kw={"width_ratios": [1.45, 1]})

# ---- the wall seen from inside the chamber: Y right (front to back), Z up
box(wall, 0, -TOP, LACK, TOP, WOOD, ec=WOOD_EDGE)
label(wall, LACK / 2, -TOP / 2, "the floor")
box(wall, 0, CH_H, LACK, TOP, WOOD, ec=WOOD_EDGE)
label(wall, LACK / 2, CH_H + TOP / 2, "the Lack's top: nothing on it, not drilled")
box(wall, 0, 0, LACK, CH_H, PRINTED, ec="#c26a1b")
wall.add_patch(mp.Rectangle((6, 6), LACK - 12, CH_H - 12, fill=False, ec=SEAL, lw=2.5, ls="--"))
for y in (0, LACK - LEG):
    box(wall, y, 0, LEG, CH_H, WOOD, ec=WOOD_EDGE)
label(wall, LEG / 2, CH_H / 2, "leg", rotation=90, color=WOOD_EDGE)
label(wall, LACK - LEG / 2, CH_H / 2, "leg", rotation=90, color=WOOD_EDGE)
# the bed and the fans' plate lie behind the inner skin: dashed
box(wall, LEG + 2, BED_Z, LACK - 2 * LEG - 4, BED_D, "none", ec=CARBON_C, ls="--", lw=1.2)
label(wall, LACK / 2 + 70, BED_Z + BED_D / 2, "carbon, lying flat across the channel, behind the skin", color=CARBON_C,
      fontsize=7.5)
for fy in FANS_Y:
    box(wall, fy, FAN_Z, DELTA[0], DELTA[1], FAN_C, ls="--")
label(wall, FANS_Y[0] - 85, FAN_Z + 10, "the two Deltas, in a plate\nacross the channel", color="#3182bd", fontsize=7.5)
long, wide, _ = MIJIA
for z in HEPA_Z:
    box(wall, HEPA_Y, z, long, wide, HEPA_C, ec="#9a6a00")
label(wall, HEPA_Y + long / 2, HEPA_Z[1] + wide / 2, "Mijia", color="#9a6a00", fontsize=8)
label(wall, HEPA_Y + long / 2, HEPA_Z[0] + wide / 2, "Mijia", color="#9a6a00", fontsize=8)
label(wall, HEPA_Y + long / 2 + 20, HEPA_Z[0] - 28, "the scrubber's intake: two cartridges, stacked",
      color="#9a6a00", fontsize=8)
y0, y1, z0, z1 = OUTLET
box(wall, y0, z0, y1 - y0, z1 - z0, "white", ec="tab:blue")
for y in range(y0 + 15, y1, 20):
    wall.plot([y, y + 8], [z0 + 6, z1 - 6], color="tab:blue", lw=0.8)
label(wall, (y0 + y1) / 2, z1 + 14, "the clean air out low, across the floor", color="tab:blue", fontsize=8)
y0, y1, z0, z1, _ = VENT
box(wall, y0, z0, y1 - y0, z1 - z0, VENT_C, ec="darkred")
label(wall, (y0 + y1) / 2, (z0 + z1) / 2, "[B] extraction:\nits own HEPA\nand carbon, a\n100 mm collar\nout to the window", color="darkred",
      fontsize=7.5)
y0, y1, z0, z1 = MAKEUP
box(wall, y0, z0, y1 - y0, z1 - z0, MAKEUP_C, ec=SEAL)
label(wall, (y0 + y1) / 2, z1 + 30, "[F] makeup\nair in, at\nthe Einsy", color=SEAL, fontsize=7.5)
label(wall, LACK / 2, CH_H + TOP + 15, "dashed green: the TPU seal round the wall's edge", color=SEAL, fontsize=8)
dim(wall, (LACK + 30, 0), (LACK + 30, CH_H), "460", dx=25)
dim(wall, (0, -TOP - 30), (LACK, -TOP - 30), "550, the outline until the sheet is measured [K]", dy=-16)
label(wall, 25, -TOP - 75, "front\n(door)")
label(wall, LACK - 25, -TOP - 75, "back")
arrows(wall, (-110, -120), "+Y", "+Z")
wall.set_xlim(-140, LACK + 90)
wall.set_ylim(-160, CH_H + TOP + 30)
wall.set_aspect("equal")
wall.axis("off")
wall.set_title("The filter wall, seen from inside: the door on the left, the back (and the Einsy) on the right",
               fontsize=10)

# ---- a section through the wall at a fan, seen from the front: X right (the room left, the chamber right), Z up
out_x = -(2 * SKIN + CHAN)
box(cut, 0, -TOP, 220, TOP, WOOD, ec=WOOD_EDGE)
label(cut, 110, -TOP / 2, "the floor")
box(cut, 0, CH_H, 220, TOP, WOOD, ec=WOOD_EDGE)
label(cut, 110, CH_H + TOP / 2, "the top")
box(cut, out_x, 0, SKIN, CH_H, PRINTED, ec="#c26a1b")
box(cut, -SKIN, 0, SKIN, CH_H, PRINTED, ec="#c26a1b")
box(cut, out_x, 0, 2 * SKIN + CHAN, 3, PRINTED, ec="#c26a1b")
box(cut, out_x, CH_H - 3, 2 * SKIN + CHAN, 3, PRINTED, ec="#c26a1b")
box(cut, out_x - 2, HATCH_Z[0], SKIN + 4, HATCH_Z[1] - HATCH_Z[0], "white", ec="#c26a1b", ls="--")
label(cut, out_x - 50, (HATCH_Z[0] + HATCH_Z[1]) / 2, "a hatch in\nthe outer skin:\nthe filters\nchange from\noutside", fontsize=7.5,
      color="#c26a1b")
box(cut, -SKIN - MIJIA[2], HEPA_Z[0], MIJIA[2] + SKIN, HEPA_Z[1] + MIJIA[1] - HEPA_Z[0], HEPA_C, ec="#9a6a00")
box(cut, out_x + SKIN, BED_Z, CHAN, BED_D, CARBON_C, ec="black")
box(cut, out_x + SKIN, BED_Z - FLOSS, CHAN, FLOSS, FLOSS_C, ec="#777")
box(cut, out_x + SKIN, FAN_Z - 3, CHAN, 3, PRINTED, ec="#c26a1b")
box(cut, out_x + SKIN + 2, FAN_Z, DELTA[0], DELTA[1], FAN_C)
box(cut, -SKIN - 1, OUTLET[2], SKIN + 2, OUTLET[3] - OUTLET[2], "white", ec="tab:blue")
flow(cut, (120, 400), (2, 400), "tab:orange")
label(cut, 120, 425, "the plume, drawn in\nunder the top", color="tab:orange", fontsize=8)
mid = out_x + SKIN + CHAN / 2
flow(cut, (mid, 380), (mid, BED_Z + BED_D + 5), "tab:orange")
flow(cut, (mid, BED_Z - FLOSS - 2), (mid, FAN_Z + DELTA[1] + 3), "tab:blue")
flow(cut, (mid, FAN_Z - 5), (mid, 60), "tab:blue")
flow(cut, (2, 55), (150, 40), "tab:blue")
label(cut, 120, 85, "out low,\nacross the floor", color="tab:blue", fontsize=8)
label(cut, 70, HEPA_Z[0] + 25, "two Mijia,\n15 mm pleats", color="#9a6a00", fontsize=8, ha="left")
label(cut, 70, BED_Z + 10, "carbon, 30 mm deep,\nlying flat: the air\ndown through it", color=CARBON_C, fontsize=8, ha="left")
label(cut, 70, FAN_Z + 10, "a Delta in the\nfans' plate", color="#3182bd", fontsize=8, ha="left")
label(cut, 70, BED_Z - 25, "the floss under it", color="#777", fontsize=7.5, ha="left")
dim(cut, (out_x, -TOP - 25), (0, -TOP - 25), "50: two 3 mm skins, a 44 mm channel", dy=-16)
label(cut, -140, 30, "the room:\nthe wall stands\nout into it (Q295)", fontsize=8, color="#555")
label(cut, 160, 315, "the chamber", fontsize=9, color="#555")
cut.plot([0, 0], [-TOP, CH_H + TOP], color=SEAL, lw=1, ls=":")
label(cut, 6, CH_H + TOP + 18, "where the sheet's inner face is now", color=SEAL, fontsize=7.5, ha="left")
arrows(cut, (-190, -130), "+X", "+Z")
cut.set_xlim(-210, 230)
cut.set_ylim(-170, CH_H + TOP + 40)
cut.set_aspect("equal")
cut.axis("off")
cut.set_title("Cut across the wall at a fan, seen from the front: the room left, the chamber right", fontsize=10)

fig.suptitle("The filter wall - the Lack and the chamber to scale; the wall's parts placed, not designed", fontsize=12)
fig.tight_layout(rect=(0, 0, 1, 0.95))
OUT.parent.mkdir(parents=True, exist_ok=True)
fig.savefig(OUT, dpi=110)
print("wrote", OUT.relative_to(ROOT))
