#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
# SPDX-License-Identifier: MPL-2.0
# /// script
# requires-python = ">=3.11"
# dependencies = ["matplotlib"]
# ///
"""The chimney's concept, before anything is drawn to the enclosure's measurements (Alon, 15 Oct 2026: D282 a,
D283 a): the scrubber on the Lack's top, its clean air back down a back corner, the extraction's vent in the wall.
From the repository's root:

  uv run scripts/figures/chimney-concept.py       writes docs/diagrams/chimney/concept.png

Not to scale. The chamber is the 55 x 55 cm, 46 cm tall one; everything else is placed, not measured: the
lettered labels are the measurements and choices to be confirmed against the enclosure itself.
"""
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.patches as mp
import matplotlib.pyplot as plt

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "docs" / "diagrams" / "chimney" / "concept.png"

CH = (550, 550, 460)        # the chamber inside: X across, Y front to back, Z up (mm)
TOP = 50                    # the Lack's top
CHIM = (40, 380, 200, 160)  # the chimney on the top: x, y, across, deep
CHIM_H = 170
RET = (40, 110)             # the return duct in the back wall: x, across
VENT = (400, 120, 290, 150) # the extraction's vent in the back wall: x, across, z, tall


def arrows(ax, origin, a, b, size=60):
    """The view's two axes, as arrows from origin: a and b are their names, right and up."""
    x, y = origin
    ax.annotate("", (x + size, y), (x, y), arrowprops={"arrowstyle": "->", "color": "crimson", "lw": 1.5})
    ax.annotate("", (x, y + size), (x, y), arrowprops={"arrowstyle": "->", "color": "crimson", "lw": 1.5})
    ax.text(x + size + 8, y, a, color="crimson", va="center", fontsize=9)
    ax.text(x, y + size + 8, b, color="crimson", ha="center", fontsize=9)


def box(ax, x, y, w, h, fc, ec="black", **kw):
    ax.add_patch(mp.Rectangle((x, y), w, h, facecolor=fc, edgecolor=ec, lw=1.2, **kw))


def label(ax, x, y, text, **kw):
    ax.text(x, y, text, fontsize=8.5, ha="center", va="center", **kw)


fig, (side, top) = plt.subplots(1, 2, figsize=(14, 7.5))

# ---- side section, looking along -X: Y to the right (front to back), Z up
w, d, h = CH
box(side, 0, 0, d, h, "#f6f3ea")
box(side, 0, h, d, TOP, "#d9c7a7")
label(side, d / 2, h + TOP / 2, "the Lack's top  [D: how thick]")
box(side, 70, 0, 400, 380, "none", ec="#888", ls="--")
label(side, 270, 200, "printer\n[C: its room\nto the back wall]", color="#666")
cx, cy, cw, cd = CHIM
box(side, cy, h + TOP, cd, CHIM_H, "#cfe3f5")
label(side, cy + cd / 2, h + TOP + CHIM_H / 2, "chimney:\ntwo Mijia standing,\nthe Deltas, carbon")
side.annotate("", (cy + 40, h + TOP + 5), (cy + 40, h - 60),
              arrowprops={"arrowstyle": "->", "color": "tab:orange", "lw": 2})
label(side, cy - 25, h - 40, "plume up\ninto it", color="tab:orange")
box(side, d - 25, 0, 25, h, "#cfe3f5", hatch="//")
side.annotate("", (cy + cd - 15, h - 30), (cy + cd - 15, h + TOP + 20),
              arrowprops={"arrowstyle": "->", "color": "tab:blue", "lw": 2})
side.annotate("", (d - 45, 45), (d - 45, h - 40), arrowprops={"arrowstyle": "->", "color": "tab:blue", "lw": 2})
label(side, d - 110, 170, "clean air back\ndown the corner,\nits duct part\nof the wall [A]", color="tab:blue")
label(side, d - 95, 25, "out low", color="tab:blue")
box(side, d, VENT[2], 30, VENT[3], "#f5d0cf")
side.annotate("", (d + 130, VENT[2] + 60), (d + 30, VENT[2] + 60), arrowprops={"arrowstyle": "->", "color": "darkred", "lw": 2})
label(side, d + 120, VENT[2] + VENT[3] + 35, "extraction vent, part of\nthe wall in the other\nback corner [B]", color="darkred")
label(side, d + 120, VENT[2] + 30, "to the duct,\noutside [E]", color="darkred")
label(side, -40, 15, "door\n(front)")
label(side, d + 40, 15, "back")
side.annotate("", (60, 30), (-20, 30), arrowprops={"arrowstyle": "->", "color": "tab:green", "lw": 2})
label(side, 30, 60, "makeup air\nin low [F]", color="tab:green")
arrows(side, (-120, -90), "+Y", "+Z")
side.set_xlim(-160, d + 230)
side.set_ylim(-110, h + TOP + CHIM_H + 40)
side.set_aspect("equal")
side.axis("off")
side.set_title("Side, cut through the chamber: the front (door) on the left, the back on the right", fontsize=10)

# ---- top view: X right, Y up (the back at the top)
box(top, 0, 0, w, d, "#f6f3ea")
box(top, 70, 50, 400, 450, "none", ec="#888", ls="--")
label(top, 270, 270, "printer", color="#666")
box(top, cx, cy, cw, cd, "#cfe3f5")
label(top, cx + cw / 2, cy + cd / 2, "chimney\non the top")
box(top, RET[0], d - 25, RET[1], 25, "#cfe3f5", hatch="//")
label(top, RET[0] + RET[1] / 2, d + 25, "[A] return duct,\npart of the back wall", color="tab:blue")
box(top, VENT[0], d - 30, VENT[1], 30, "#f5d0cf")
label(top, VENT[0] + VENT[1] / 2, d + 25, "[B] extraction vent,\npart of the back wall", color="darkred")
label(top, w / 2, -30, "door (front)")
label(top, -55, d / 2, "[G]\nside", rotation=90)
label(top, w + 55, d / 2, "[G]\nside", rotation=90)
arrows(top, (-120, -90), "+X", "+Y")
top.set_xlim(-160, w + 120)
top.set_ylim(-110, d + 80)
top.set_aspect("equal")
top.axis("off")
top.set_title("From above, the Lack's top taken off: the back at the top", fontsize=10)

fig.suptitle("The chimney, a concept - not to scale; the letters are what the enclosure has to answer", fontsize=12)
fig.tight_layout()
OUT.parent.mkdir(parents=True, exist_ok=True)
fig.savefig(OUT, dpi=110)
print("wrote", OUT.relative_to(ROOT))
