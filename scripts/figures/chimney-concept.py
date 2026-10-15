#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
# SPDX-License-Identifier: MPL-2.0
# /// script
# requires-python = ">=3.11"
# dependencies = ["matplotlib"]
# ///
"""The chimney's layout, drawn to the enclosure (Alon, 15 Oct 2026: D282 a, D283 a, Q285, T286, D287 a): the scrubber
on the Lack's top, and a printed left wall that carries its intake, its return and the extraction's vent, sealed round
its edge, so the top is not drilled. From the repository's root:

  uv run scripts/figures/chimney-concept.py       writes docs/diagrams/chimney/concept.png

To scale where measured (the Lack, its top, the legs, the chamber's height); the wall's parts, the chimney and what
stands on the top are placed, not designed, and the printer's gaps are read off photos. The chimney's ducts are drawn
centred on the wall, so the wall turned round to go on the right keeps them where they are (D292 open). The lettered
labels are what is still open; docs/bentobox-scrubber.md has the table of values and where each came from.
"""
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.patches as mp
import matplotlib.pyplot as plt

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "docs" / "diagrams" / "chimney" / "concept.png"

# measured or stated (mm)
LACK = 550          # the top, square
TOP = 50            # its thickness: 50.07 by caliper (T286)
LEG = 50            # the legs, square
SHEET = 3           # the other walls: 3 mm plexiglass (T286)
CH_H = 460          # the chamber: 40 cm under the top and 6 more (Q157)
# read off photos, to confirm (Q288)
GAP_NEAR = (50, 75)  # the left wall to a foot, and to the frame
GAP_FAR = 100        # the right wall
# placed, not designed
SKIN = 6                          # the printed wall, in place of the left sheet
MID = LACK / 2                    # the chimney's ducts, centred along the wall
DUCT_L, DUCT_D = 60, 33           # each duct: along the wall, and deep outside it
INTAKE_Y = MID - 5 - DUCT_L       # [J] the chimney's intake, its slot just under the top
RET_Y = MID + 5                   # [A] the return, out low
SLOT_Z = (CH_H - 65, CH_H - 15)   # the intake's slot
CHIM = (6, MID - 90, 110, 180, 150)   # the chimney: x, y, across, along, tall
VENT = (60, 135, 77, 300, 135)    # [B] the extraction's vent: y, along, deep outside, z, tall
DRYBOX_NOW = (20, 240, 400, 300)  # the drybox where it stands now: x, y, across, deep (from the photos)

WOOD, WOOD_EDGE, SHEET_C = "#e6d3b1", "#8a6d3b", "#9ecae1"
PRINTED, SEAL = "#fde0c5", "#2d7d46"
CLEAN, INTAKE_C, VENT_C = "#cfe3f5", "#ffe9a8", "#f5d0cf"


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


def dim(ax, a, b, text, color="black", **kw):
    """A dimension line from a to b, its text beside the middle."""
    ax.annotate("", b, a, arrowprops={"arrowstyle": "<->", "color": color, "lw": 1})
    label(ax, (a[0] + b[0]) / 2 + kw.pop("dx", 0), (a[1] + b[1]) / 2 + kw.pop("dy", 0), text, color=color, **kw)


def flow(ax, a, b, color, lw=2):
    ax.annotate("", b, a, arrowprops={"arrowstyle": "->", "color": color, "lw": lw})


fig, (plan, wall) = plt.subplots(1, 2, figsize=(16, 8.6), gridspec_kw={"width_ratios": [1.1, 1]})

# ---- plan: from above, X right (left to right from the door), Y up (front to back)
box(plan, 0, LACK + SHEET, LACK, 22, "#ddd", ec="#999", hatch="///")
label(plan, LACK / 2, LACK + 40, "the room's wall: nothing behind  [C = 0]", color="#555")
box(plan, 0, 0, LACK, LACK, WOOD, ec=WOOD_EDGE)
for x, y in ((0, 0), (LACK - LEG, 0), (0, LACK - LEG), (LACK - LEG, LACK - LEG)):
    box(plan, x, y, LEG, LEG, "none", ec=WOOD_EDGE, ls="--", hatch="..")
for x, y, w, h in ((LACK, 0, SHEET, LACK), (0, LACK, LACK, SHEET), (0, -SHEET, LACK, SHEET)):
    box(plan, x, y, w, h, SHEET_C, ec="#3182bd", lw=0.8)
box(plan, -SKIN, 0, SKIN, LACK, PRINTED, ec="#c26a1b")
box(plan, GAP_NEAR[0], 20, LACK - GAP_NEAR[0] - GAP_FAR, LACK - 20, "none", ec="#777", ls=":")
label(plan, 300, 110, "the printer, below,\nagainst the back (outline ≈)", color="#666")
dim(plan, (0, 140), (GAP_NEAR[0], 140), "≈ 5 to a foot,\n7-8 to the frame\n[H]", color="#555", dx=95)
dim(plan, (LACK - GAP_FAR, 140), (LACK, 140), "≈ 10", color="#555", dy=18)
x, y, w, h = DRYBOX_NOW
box(plan, x, y, w, h, "none", ec="#666", ls="--", lw=1)
label(plan, x + w - 120, y + h - 45, "the drybox, now (≈ 40 × 30):\nmoves [I], with its tubes'\nfeed-through", color="#555")
cx, cy, cw, cl, ch = CHIM
box(plan, cx, cy, cw, cl, CLEAN)
label(plan, cx + cw / 2, cy + cl / 2, "chimney\n(the top\nnot drilled)", fontsize=8)
box(plan, -SKIN - DUCT_D, INTAKE_Y, DUCT_D, DUCT_L, INTAKE_C)
box(plan, -SKIN - DUCT_D, RET_Y, DUCT_D, DUCT_L, CLEAN, hatch="//")
vy, vl, vd, vz, vh = VENT
box(plan, -SKIN - vd, vy, vd, vl, VENT_C)
label(plan, -SKIN - DUCT_D - 8, RET_Y + DUCT_L / 2, "[A] return", color="tab:blue", ha="right")
label(plan, -SKIN - DUCT_D - 8, INTAKE_Y + DUCT_L / 2, "[J] intake", color="#9a6a00", ha="right")
label(plan, -SKIN - vd - 8, vy + vl / 2 + 25, "[B] extraction\nvent", color="darkred", ha="right")
flow(plan, (-SKIN - vd, vy + 40), (-SKIN - vd - 150, vy + 40), "darkred")
label(plan, -SKIN - vd - 85, vy - 5, "100 mm flex to the\nwindow's fan [E]", color="darkred")
label(plan, -SKIN - 185, LACK - 20, "the left wall, printed:\nsealed round its edge in TPU;\nturned round, it goes on the right\n(the ducts stay centred: D292)",
      color="#c26a1b")
flow(plan, (LACK + 90, 470), (LACK - 30, 470), "tab:green")
label(plan, LACK + 25, 525, "[F] makeup air in\nlow, at the Einsy?", color="tab:green", ha="left")
dim(plan, (0, -40), (LACK, -40), "550: the top; the legs 50 square; the other walls 3 mm plexiglass", dy=-22)
label(plan, LACK / 2, -95, "door (front)")
arrows(plan, (-290, -100), "+X", "+Y")
plan.set_xlim(-345, LACK + 190)
plan.set_ylim(-130, LACK + 70)
plan.set_aspect("equal")
plan.axis("off")
plan.set_title("From above: the Lack's top, the printed wall on the window's side", fontsize=10)

# ---- the printed left wall, seen from inside the chamber: Y right (front to back), Z up
box(wall, 0, -TOP, LACK, TOP, WOOD, ec=WOOD_EDGE)
label(wall, LACK / 2, -TOP / 2, "the floor: the lower Lack's top")
box(wall, 0, 0, LACK, CH_H, PRINTED, ec="#c26a1b")
wall.add_patch(mp.Rectangle((6, 6), LACK - 12, CH_H - 12, fill=False, ec=SEAL, lw=2.5, ls="--"))
label(wall, 130, 22, "TPU seal round the wall's edge", color=SEAL, fontsize=8)
for y in (0, LACK - LEG):
    box(wall, y, 0, LEG, CH_H, WOOD, ec=WOOD_EDGE)
box(wall, 0, CH_H, LACK, TOP, WOOD, ec=WOOD_EDGE)
label(wall, 105, CH_H + TOP / 2, "the top, 50 [D]")
top_z = CH_H + TOP + 30
box(wall, INTAKE_Y, SLOT_Z[0], DUCT_L, top_z - SLOT_Z[0], INTAKE_C)
box(wall, INTAKE_Y + 6, SLOT_Z[0] + 8, DUCT_L - 12, SLOT_Z[1] - SLOT_Z[0] - 16, "white", ec="#9a6a00", lw=1)
box(wall, RET_Y, 40, DUCT_L, top_z - 40, CLEAN, hatch="//")
box(wall, cy, CH_H + TOP, cl, ch, CLEAN)
label(wall, cy + cl / 2, CH_H + TOP + ch / 2 + 15, "chimney (≈):\ntwo Mijia standing,\nthe Deltas, carbon")
flow(wall, (INTAKE_Y + DUCT_L / 2, SLOT_Z[0] - 70), (INTAKE_Y + DUCT_L / 2, SLOT_Z[0] - 5), "tab:orange")
flow(wall, (INTAKE_Y + DUCT_L / 2, SLOT_Z[1]), (INTAKE_Y + DUCT_L / 2, CH_H + TOP + 25), "tab:orange")
label(wall, RET_Y + DUCT_L + 85, CH_H - 85, "[J] the plume drawn\nin just under the top,\nup past the top's edge", color="#9a6a00")
flow(wall, (RET_Y + DUCT_L / 2, CH_H + TOP + 20), (RET_Y + DUCT_L / 2, 120), "tab:blue")
flow(wall, (RET_Y + DUCT_L + 5, 70), (RET_Y + DUCT_L + 60, 70), "tab:blue")
label(wall, RET_Y + DUCT_L + 85, 175, "[A] the clean air\nback down,\nout low", color="tab:blue")
box(wall, vy, vz, vl, vh, VENT_C)
label(wall, vy + vl / 2, vz + vh / 2, "[B] extraction:\nHEPA facing in,\ncarbon, a 100 mm\ncollar outside", color="darkred")
dim(wall, (LACK + 30, 0), (LACK + 30, CH_H), "460\n(40 + 6)", dx=35)
dim(wall, (0, -TOP - 30), (LACK, -TOP - 30), "550", dy=-16)
label(wall, 25, -TOP - 70, "front\n(door)")
label(wall, LACK - 25, -TOP - 70, "back")
label(wall, LACK / 2, CH_H + TOP + ch + 50,
      "[K] the sheet it replaces: its size, and how it is held\n"
      "[H] the printer's narrowest gap to this wall, at any height", color="#555")
arrows(wall, (-120, -110), "+Y", "+Z")
wall.set_xlim(-160, LACK + 110)
wall.set_ylim(-150, CH_H + TOP + ch + 90)
wall.set_aspect("equal")
wall.axis("off")
wall.set_title("The printed left wall, seen from inside: the door on the left", fontsize=10)

fig.suptitle("The chimney, drawn to the enclosure - the Lack, its top and the legs to scale; "
             "the wall's parts and the chimney placed, not designed", fontsize=11.5)
fig.tight_layout(rect=(0, 0, 1, 0.95))
OUT.parent.mkdir(parents=True, exist_ok=True)
fig.savefig(OUT, dpi=110)
print("wrote", OUT.relative_to(ROOT))
