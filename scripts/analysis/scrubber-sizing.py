#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
# SPDX-License-Identifier: MPL-2.0
# /// script
# requires-python = ">=3.11"
# ///
"""How large the scrubber must be for more air, at each pressure its fans can give (Alon, 15 Oct 2026: D275 c).
From the repository's root:

  uv run scripts/analysis/scrubber-sizing.py          the sizes, per fan pressure and flow
  uv run scripts/analysis/scrubber-sizing.py check    this loss model against cfd.py's, run both ways, and a control

THE ORDER, as asked: the HEPA's face first, then the carbon under it. During a print the chamber's air settles
at the emissions over the box's flow, so the flow is the target: today's 0.72 L/s, and two, four and eight times
it. For each flow, and each pressure the fans give AT that flow, the HEPA's face is made as large as it must be
for the whole box to drop that pressure. The carbon bed lies under it on the box's inside, in today's proportion
(41.1 cm2 of inside to the HEPA opening's 28.7), as deep as keeps the air in it as long as today's 184 cm3 bed
does at 0.72 L/s, 0.26 s; the section's floss lies on the same inside.

THE PHYSICS is cfd.py's, read from sim/bentobox-cfd/, so the two cannot disagree: the HEPA a mid-grade pack in
15 mm pleats, its drop proportional to the speed through its face (380 Pa at 1 m/s); the pellets by Ergun; the
floss linear. The paper's grade is not known, and the face needed scales with it: about half for an H11-like
paper, 5/3 for an H13-like one. The walls, the plenums and the duct are left out: at these speeds they take a
few pascals.

THE FANS: a fan's pressure at a flow is read off its curve. For the two Deltas, cfd.py's straight line from
103.6 Pa at no flow to 9.5 L/s at no pressure; their row gives what they give at each flow.
"""
import importlib.util
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
_spec = importlib.util.spec_from_file_location("cfd", ROOT / "sim" / "bentobox-cfd" / "cfd.py")
cfd = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(cfd)

Q_NOW = 0.72e-3                  # m3/s: the remix as decided, by pleat.py's lumped model (docs/bentobox-scrubber.md)
BED_NOW = 184e-6                 # m3: its carbon, 45 mm over the box's inside
EBCT = BED_NOW / Q_NOW           # s: the time the air spends in it, kept for every size
INSIDE_NOW = 0.1008 * 0.0408     # m2: the box's inside, which the bed and the floss fill
FOOT = INSIDE_NOW / cfd.A_HEPA   # the inside over the HEPA's opening
CHAMBER = 0.139                  # m3
RHO_BED = 450.0                  # kg/m3, AP4-60's data sheet
PRESSURES = (25, 50, 100, 200, 400)
MULTIPLES = (1, 2, 4, 8)


def losses(q, a_hepa, a_bed, depth, a_sheet, hepa_at_1=None):
    """Pa across the HEPA, the carbon and the floss at flow q [m3/s], each through its own face [m2]."""
    hepa = (hepa_at_1 or cfd.MEDIA["hepa"]["dp_at_1"]) * q / a_hepa
    d_c, f_c = cfd.ergun(cfd.MEDIA["carbon"]["eps"], cfd.MEDIA["carbon"]["dp"])
    v = q / a_bed
    carbon = cfd.AIR["rho"] * depth * (cfd.AIR["nu"] * d_c * v + 0.5 * f_c * v ** 2)
    sheet = cfd.MEDIA["sheet"]["dp"] / cfd.MEDIA["sheet"]["at"] * q / a_sheet
    return hepa, carbon, sheet


def scaled_bed(q, a_hepa):
    """The bed and the floss under a HEPA face a_hepa, in today's proportion, as deep as keeps EBCT at q."""
    a_bed = FOOT * a_hepa
    return a_bed, q * EBCT / a_bed, a_bed


def solve(q, p, bed=scaled_bed):
    """The HEPA face [m2] at which the whole box drops p [Pa] at q: the losses fall as the face grows."""
    lo, hi = 1e-5, 100.0
    for _ in range(200):
        mid = (lo * hi) ** 0.5
        a_bed, depth, a_sheet = bed(q, mid)
        if sum(losses(q, mid, a_bed, depth, a_sheet)) > p:
            lo = mid
        else:
            hi = mid
    return hi


def deltas(q):
    """The two Deltas' pressure at q, on cfd.py's straight line."""
    return cfd.FAN["p_max"] * (1 - q / (2 * cfd.FAN["q_max"]))


def size(q, p):
    """Everything at flow q and fan pressure p: the HEPA face, the bed's face, depth and volume, and each drop."""
    a = solve(q, p)
    a_bed, depth, a_sheet = scaled_bed(q, a)
    return a, a_bed, depth, a_bed * depth, losses(q, a, a_bed, depth, a_sheet)


def show():
    print(f"the remix as decided: {Q_NOW * 1000:.2f} L/s, the chamber's {CHAMBER * 1000:.0f} L through it every "
          f"{CHAMBER / Q_NOW / 60:.1f} min; carbon {BED_NOW * 1e6:.0f} cm3, the air {EBCT:.2f} s in it")
    print(f"the sizes are in the bought cartridge's terms (cfd.py): there the original's {cfd.A_HEPA * 1e4:.1f} cm2 "
          f"opening gives {cfd.network()[0] * 1000:.2f} L/s")
    # At one pressure every speed through every face is fixed, so each size grows in step with the flow: per L/s.
    print("\nper L/s of flow, by the pressure the fans give at that flow:")
    print(f"{'fans give':>10} {'HEPA face':>11} {'its speed':>10} {'box inside':>11} {'carbon':>12} "
          f"{'bed deep':>9} {'HEPA takes':>11} {'carbon takes':>13} {'floss takes':>12}")
    for p in PRESSURES:
        q = 1e-3
        a, a_bed, depth, vol, (hepa, carbon, sheet) = size(q, p)
        print(f"{p:>7} Pa {a * 1e4:>7.0f} cm2 {q / a:>6.2f} m/s {a_bed * 1e4:>7.0f} cm2 "
              f"{vol * 1e6:>4.0f} cm3 {vol * RHO_BED * 1000:>3.0f} g {depth * 1000:>6.0f} mm "
              f"{hepa:>8.0f} Pa {carbon:>10.1f} Pa {sheet:>9.1f} Pa")
    print("\nfor today's flow and its multiples - the chamber's level during a print falls as 1/multiple:")
    print("each cell: HEPA face cm2 (as a square, mm side), carbon g")
    print(f"{'fans give':>14}" + "".join(f"{f'{m} x, {m * Q_NOW * 1000:.2f} L/s':>26}" for m in MULTIPLES))
    rows = [(f"{p} Pa", lambda q, p=p: p) for p in PRESSURES] + [("two Deltas", deltas)]
    for label, pressure in rows:
        cells = []
        for m in MULTIPLES:
            q = m * Q_NOW
            p = pressure(q)
            if p <= 0:
                cells.append(f"{'beyond the fans':>26}")
                continue
            a, a_bed, depth, vol, _ = size(q, p)
            txt = f"{a * 1e4:.0f} ({a ** 0.5 * 1000:.0f}), {vol * RHO_BED * 1000:.0f} g"
            if label == "two Deltas":
                txt = f"{p:.0f} Pa: " + txt
            cells.append(f"{txt:>26}")
        print(f"{label:>14}" + "".join(cells))
    print("\nthe two Deltas' pressure is on a straight line between their end points; a real curve dips between them.")
    print("the face scales with the paper's grade: about x0.5 for an H11-like paper, x5/3 for an H13-like one.")


def check():
    """The loss model against cfd.py's lumped network on its own geometry, both ways, and a control that must
    break the agreement."""
    q, p = cfd.network()
    bed = (cfd.A_CARBON, cfd.LAYERS * cfd.LAYER_T, cfd.A_SHEET)
    fixed = lambda _q, _a: bed
    results = []
    here = sum(losses(q, cfd.A_HEPA, *bed))
    results.append(("losses at cfd.py's operating point = its fans' pressure", abs(here - p) < 0.01,
                    f"{here:.3f} vs {p:.3f} Pa"))
    a = solve(q, p, fixed)
    results.append(("the face solved back from that point = cfd.py's HEPA opening", abs(a / cfd.A_HEPA - 1) < 1e-3,
                    f"{a * 1e4:.3f} vs {cfd.A_HEPA * 1e4:.3f} cm2"))
    for name, ok, detail in results:
        print(f"{'ok' if ok else 'FAILED':>6}  {name}: {detail}")
    wrong = sum(losses(q, cfd.A_HEPA, *bed, hepa_at_1=2 * cfd.MEDIA["hepa"]["dp_at_1"]))
    caught = abs(wrong - p) >= 0.01
    print(f"{'ok' if caught else 'MISSED':>6}  control, the HEPA's drop doubled here only: {wrong:.1f} vs {p:.1f} Pa")
    passed = sum(ok for _, ok, _ in results)
    print(f"checks: {passed} of {len(results)} agree; controls: {int(caught)} of 1 caught")
    return passed == len(results) and caught


if __name__ == "__main__":
    if sys.argv[1:] == ["check"]:
        sys.exit(0 if check() else 1)
    if sys.argv[1:]:
        sys.exit(__doc__)
    show()
