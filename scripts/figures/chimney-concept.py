#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
# SPDX-License-Identifier: MPL-2.0
# /// script
# requires-python = ">=3.11"
# dependencies = ["matplotlib"]
# ///
"""The chimney's layout, drawn to the enclosure (Alon, 15 Oct 2026: D282 a, D283 a, Q285, T286): the scrubber on the
Lack's top, its clean air back down the side wall, the extraction's vent in the same wall. From the repository's root:

  uv run scripts/figures/chimney-concept.py       writes docs/diagrams/chimney/concept.png

To scale where measured (the Lack, its top, the legs, the sheets, the chamber's height); the chimney, the duct, the
vent and what stands on the top are placed, not designed, and the printer's gaps are read off photos. The lettered
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
SHEET = 3           # the walls: 3 mm plexiglass (T286)
CH_H = 460          # the chamber: 40 cm under the top and 6 more (Q157)
# read off photos, to confirm (Q288)
GAP_NEAR = (50, 75)  # one wall to a foot, and to the frame
GAP_FAR = 100        # the other wall
# placed, not designed
CHIM = (6, 300, 110, 180, 150)    # the chimney: x, y, across, along, tall
RET = (410, 66, 33)               # the return duct: y, along the wall, deep outside it
VENT = (110, 135, 77, 300, 135)   # the extraction's vent: y, along, deep outside, z, tall
DRYBOX_NOW = (20, 240, 400, 300)  # the drybox where it stands now: x, y, across, deep (from the photos)

WOOD, WOOD_EDGE, SHEET_C = "#e6d3b1", "#8a6d3b", "#9ecae1"
CLEAN, VENT_C = "#cfe3f5", "#f5d0cf"


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


fig, (plan, wall) = plt.subplots(1, 2, figsize=(16, 8.4), gridspec_kw={"width_ratios": [1.1, 1]})

# ---- plan: from above, X right (left to right from the door), Y up (front to back)
box(plan, 0, LACK + SHEET, LACK, 22, "#ddd", ec="#999", hatch="///")
label(plan, LACK / 2, LACK + 40, "the room's wall: nothing behind  [C = 0]", color="#555")
box(plan, 0, 0, LACK, LACK, WOOD, ec=WOOD_EDGE)
for x, y in ((0, 0), (LACK - LEG, 0), (0, LACK - LEG), (LACK - LEG, LACK - LEG)):
    box(plan, x, y, LEG, LEG, "none", ec=WOOD_EDGE, ls="--", hatch="..")
for x, y, w, h in ((-SHEET, 0, SHEET, LACK), (LACK, 0, SHEET, LACK), (0, LACK, LACK, SHEET), (0, -SHEET, LACK, SHEET)):
    box(plan, x, y, w, h, SHEET_C, ec="#3182bd", lw=0.8)
box(plan, GAP_NEAR[0], 20, LACK - GAP_NEAR[0] - GAP_FAR, LACK - 20, "none", ec="#777", ls=":")
label(plan, 270, 110, "the printer, below,\nagainst the back (outline ≈)", color="#666")
dim(plan, (0, 160), (GAP_NEAR[0], 160), "≈ 5 to a foot,\n7-8 to the frame\n[H]", color="#555", dx=95, dy=0)
dim(plan, (LACK - GAP_FAR, 160), (LACK, 160), "≈ 10\n[H]", color="#555", dx=-75)
x, y, w, h = DRYBOX_NOW
box(plan, x, y, w, h, "none", ec="#666", ls="--", lw=1)
label(plan, x + w - 120, y + h - 45, "the drybox, now (≈ 40 × 30):\nmoves [I], with its tubes'\nfeed-through", color="#555")
cx, cy, cw, cl, ch = CHIM
box(plan, cx, cy, cw, cl, CLEAN)
plan.add_patch(mp.Circle((cx + cw / 2, cy + cl / 2), 30, fill=False, ls="--", ec="tab:orange", lw=1.4))
label(plan, cx + cw / 2, cy + cl - 25, "chimney", fontsize=8)
label(plan, cx + cw / 2, cy + cl / 2, "intake\nthrough\nthe top", color="tab:orange", fontsize=7.5)
ry, rl, rd = RET
box(plan, -SHEET - rd, ry, rd, rl, CLEAN, hatch="//")
vy, vl, vd, vz, vh = VENT
box(plan, -SHEET - vd, vy, vd, vl, VENT_C)
label(plan, -SHEET - rd - 70, ry + rl / 2 + 10, "[A] return", color="tab:blue", ha="right")
label(plan, -SHEET - vd - 8, vy + vl / 2 + 20, "[B] extraction\nvent", color="darkred", ha="right")
plan.annotate("", (-SHEET - vd - 170, vy + 30), (-SHEET - vd, vy + 30),
              arrowprops={"arrowstyle": "->", "color": "darkred", "lw": 2})
label(plan, -SHEET - vd - 95, vy - 20, "100 mm flex to the\nwindow's fan [E]", color="darkred")
plan.annotate("", (LACK - 30, 470), (LACK + 90, 470), arrowprops={"arrowstyle": "->", "color": "tab:green", "lw": 2})
label(plan, LACK + 25, 525, "[F] makeup air in\nlow, at the Einsy?", color="tab:green", ha="left")
dim(plan, (0, -40), (LACK, -40), "550: the top; the legs 50 square; the walls 3 mm plexiglass outside the legs", dy=-22)
label(plan, LACK / 2, -95, "door (front)")
arrows(plan, (-250, -100), "+X", "+Y")
plan.set_xlim(-290, LACK + 190)
plan.set_ylim(-130, LACK + 70)
plan.set_aspect("equal")
plan.axis("off")
plan.set_title("From above: the Lack's top, the vents on the window's side", fontsize=10)

# ---- the window's side wall, seen from inside the chamber: Y right (front to back), Z up
box(wall, 0, -TOP, LACK, TOP, WOOD, ec=WOOD_EDGE)
label(wall, LACK / 2, -TOP / 2, "the floor: the lower Lack's top")
box(wall, 0, 0, LACK, CH_H, "#eef6fb", ec="#3182bd", lw=0.8)
for y in (0, LACK - LEG):
    box(wall, y, 0, LEG, CH_H, WOOD, ec=WOOD_EDGE)
box(wall, 0, CH_H, LACK, TOP, WOOD, ec=WOOD_EDGE)
label(wall, 150, CH_H + TOP / 2, "the top, 50 [D]")
label(wall, cy + cl / 2, CH_H + TOP + ch / 2, "chimney (≈):\ntwo Mijia standing,\nthe Deltas, carbon")
wall.annotate("", (cy + 40, CH_H + TOP + 10), (cy + 40, CH_H - 90),
              arrowprops={"arrowstyle": "->", "color": "tab:orange", "lw": 2})
label(wall, cy + 40, CH_H - 125, "plume up, through\nthe top's hole", color="tab:orange")
box(wall, ry, 40, rl, CH_H + TOP + 30 - 40, CLEAN, hatch="//")
box(wall, cy, CH_H + TOP, cl, ch, CLEAN)
wall.annotate("", (ry + rl / 2, 120), (ry + rl / 2, CH_H + TOP + 20),
              arrowprops={"arrowstyle": "->", "color": "tab:blue", "lw": 2})
wall.annotate("", (ry - 50, 70), (ry, 70), arrowprops={"arrowstyle": "->", "color": "tab:blue", "lw": 2})
label(wall, ry - 120, 165, "[A] the clean air:\nout of the chimney,\ndown past the top's\nedge, outside the\nleg line, and out low",
      color="tab:blue")
box(wall, vy, vz, vl, vh, VENT_C)
label(wall, vy + vl / 2, vz + vh / 2, "[B] extraction:\nHEPA facing in,\ncarbon, a 100 mm\ncollar outside", color="darkred")
dim(wall, (LACK + 30, 0), (LACK + 30, CH_H), "460\n(40 + 6)", dx=35)
dim(wall, (0, -TOP - 30), (LACK, -TOP - 30), "550", dy=-16)
label(wall, 25, -TOP - 70, "front\n(door)")
label(wall, LACK - 25, -TOP - 70, "back")
label(wall, LACK / 2, CH_H + TOP + ch + 45,
      "[H] the printer's narrowest gap to this wall, at any height,\nsets how far the duct and the vent can sit inside it",
      color="#555")
arrows(wall, (-120, -110), "+Y", "+Z")
wall.set_xlim(-160, LACK + 110)
wall.set_ylim(-150, CH_H + TOP + ch + 80)
wall.set_aspect("equal")
wall.axis("off")
wall.set_title("The window's side wall, seen from inside: the door on the left", fontsize=10)

fig.suptitle("The chimney, drawn to the enclosure - the Lack, its top, the legs and the walls to scale; "
             "the chimney, the duct and the vent placed, not designed", fontsize=11.5)
fig.tight_layout(rect=(0, 0, 1, 0.95))
OUT.parent.mkdir(parents=True, exist_ok=True)
fig.savefig(OUT, dpi=110)
print("wrote", OUT.relative_to(ROOT))
