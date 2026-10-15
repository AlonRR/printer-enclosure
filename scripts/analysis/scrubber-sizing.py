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
  uv run scripts/analysis/scrubber-sizing.py candidates
        filters that can be bought, flat or round, and the flow the two Deltas would draw through each (D276)
  uv run scripts/analysis/scrubber-sizing.py wall
        the filter wall: the pressure its filters need at each flow, and two or four Deltas through each layout

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

THE FANS: a fan's pressure at a flow is read off its curve. For the two Deltas, Delta's own: the VH curve of the
EFB 40 x 40 x 20 series' P & Q graph, at rated voltage, taken from the datasheet's vector drawing (15 Oct 2026,
D280). It sags well under the straight line cfd.py draws between the same two ends - a third less pressure at half
the flow - and its row gives what the two give at each flow, side by side.
"""
import importlib.util
import itertools
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


# One EFB0412VHD at rated voltage: (m3/min, mmH2O), its datasheet's VH curve. The graph's own points, read from the
# PDF's vector path against its tick labels, less the 0.13 mmH2O by which the path's end sits over the zero line;
# its ends then land on the table's 10.57 mmH2O and 0.286 m3/min.
DELTA_VH = [
    (0.000, 10.58), (0.010, 10.11), (0.018, 9.71), (0.025, 9.35), (0.032, 9.04), (0.037, 8.77), (0.042, 8.53),
    (0.046, 8.32), (0.050, 8.13), (0.053, 7.94), (0.056, 7.77), (0.059, 7.61), (0.062, 7.45), (0.064, 7.31),
    (0.067, 7.16), (0.069, 7.03), (0.071, 6.89), (0.073, 6.76), (0.075, 6.63), (0.077, 6.50), (0.079, 6.37),
    (0.081, 6.24), (0.084, 6.10), (0.086, 5.97), (0.088, 5.83), (0.091, 5.68), (0.093, 5.53), (0.096, 5.38),
    (0.099, 5.22), (0.102, 5.06), (0.105, 4.91), (0.107, 4.75), (0.110, 4.60), (0.113, 4.45), (0.115, 4.30),
    (0.118, 4.16), (0.121, 4.01), (0.124, 3.87), (0.129, 3.73), (0.134, 3.59), (0.140, 3.45), (0.147, 3.31),
    (0.155, 3.16), (0.164, 3.02), (0.173, 2.87), (0.183, 2.72), (0.193, 2.56), (0.202, 2.39), (0.212, 2.22),
    (0.221, 2.04), (0.231, 1.84), (0.239, 1.62), (0.248, 1.37), (0.257, 1.09), (0.267, 0.78), (0.276, 0.41),
    (0.286, 0.00),
]
MMH2O = 9.80665                  # Pa
M3MIN = 1 / 60                   # m3/s


def one_delta(q):
    """One Delta's pressure [Pa] at flow q [m3/s], straight between the curve's points; none past its end."""
    x = q / M3MIN
    for (x0, y0), (x1, y1) in itertools.pairwise(DELTA_VH):
        if x <= x1:
            return (y0 + (y1 - y0) * (max(x, x0) - x0) / (x1 - x0)) * MMH2O
    return 0.0


def deltas(q):
    """The two Deltas side by side at total flow q: each takes half, at the same pressure."""
    return one_delta(q / 2)


def four_deltas(q):
    """Four Deltas side by side (Alon, 15 Oct 2026: D300): each takes a quarter, at the same pressure."""
    return one_delta(q / 4)


def deltas_line(q):
    """cfd.py's straight line between the same ends, for comparison."""
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
    rows = [(f"{p} Pa", lambda q, p=p: p) for p in PRESSURES] + [("two Deltas", deltas), ("on a line", deltas_line)]
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
            if label in ("two Deltas", "on a line"):
                txt = f"{p:.0f} Pa: " + txt
            cells.append(f"{txt:>26}")
        print(f"{label:>14}" + "".join(cells))
    print("\n'two Deltas' is on Delta's published curve; 'on a line', cfd.py's straight line between its ends.")
    print("the face scales with the paper's grade: about x0.5 for an H11-like paper, x5/3 for an H13-like one.")


# Filters that can be bought, as their listings size them (read 15 Oct 2026; a listing's size can be its box's):
# name, the face the air enters by [m2], and the pleats' depth [mm]. A round filter takes its air in round its
# side, so its face is its side's area. Every pleat depth not stated is taken as the model's 15 mm: deeper pleats
# carry more paper per face, so those flows are low if anything. A fourth value, where given, is the carbon's face
# in place of BED_FACE: the filter wall's bed lies across its channel, 44 mm thick between the legs' 450 mm; in
# its modules (Alon, 15 Oct 2026), across one module's inside, 219 mm by the module's depth less two 3 mm skins.
CANDIDATES = [
    ("Mijia 1C / Dreame F9, flat: the chosen", 0.150 * 0.049, 15),
    ("two Mijia cartridges, standing as two walls", 2 * 0.150 * 0.049, 15),
    ("two Mijia in a filter wall, a 44 x 450 bed", 2 * 0.150 * 0.049, 15, 0.044 * 0.450),
    ("two Mijia, a 50 mm carbon module", 2 * 0.150 * 0.049, 15, 0.044 * 0.219),
    ("two Mijia, a 70 mm carbon module", 2 * 0.150 * 0.049, 15, 0.064 * 0.219),
    ("two Mijia, a 90 mm carbon module", 2 * 0.150 * 0.049, 15, 0.084 * 0.219),
    ("four Mijia, a 50 mm carbon module", 4 * 0.150 * 0.049, 15, 0.044 * 0.219),
    ("four Mijia, a 70 mm carbon module", 4 * 0.150 * 0.049, 15, 0.064 * 0.219),
    ("four Mijia, a 90 mm carbon module", 4 * 0.150 * 0.049, 15, 0.084 * 0.219),
    ("120 x 120 x 15 pad", 0.120 * 0.120, 15),
    ("two 120 x 120 x 15 pads, as two walls", 2 * 0.120 * 0.120, 15),
    ("FlyBy Tom's two Roomba filters", 0.0132, 10),
    ("Levoit Core 300, round, 193 x 147", 3.14159 * 0.193 * 0.147, 15),
    ("Xiaomi Mi purifier, round, 200 x 293", 3.14159 * 0.200 * 0.293, 15),
]
BED_FACE = 0.020                 # m2: the carbon under every candidate, 14 cm square, as deep as keeps EBCT


def flow_through(face, pleat_mm, grade, fans=deltas, bed=BED_FACE):
    """The flow at which the fans' pressure meets the losses of this HEPA face, the carbon and the floss."""
    k = cfd.MEDIA["hepa"]["dp_at_1"] * grade * 15 / pleat_mm
    lo, hi = 0.0, 2 * cfd.FAN["q_max"]
    for _ in range(100):
        q = (lo + hi) / 2
        loss = sum(losses(q, face, bed, q * EBCT / bed, bed, hepa_at_1=k))
        lo, hi = (q, hi) if fans(q) > loss else (lo, q)
    return lo


def show_candidates():
    print(f"the two Deltas through each filter, on Delta's published curve, with {BED_FACE * 1e4:.0f} cm2 of carbon kept at "
          f"{EBCT:.2f} s and the floss; flows in L/s, and as a multiple of today's {Q_NOW * 1000:.2f}")
    print(f"{'filter':>46} {'face':>9} {'pleats':>7} {'mid grade':>17} {'H13-like (x5/3)':>17} {'mid, on a line':>15}")
    for name, face, pleat, *bed in CANDIDATES:
        bed = bed[0] if bed else BED_FACE
        cells = []
        for grade in (1.0, 5 / 3):
            q = flow_through(face, pleat, grade, bed=bed)
            cells.append(f"{q * 1000:>5.2f} ({q / Q_NOW:>3.1f} x) {deltas(q):>3.0f} Pa")
        q_line = flow_through(face, pleat, 1.0, deltas_line, bed)
        cells.append(f"{q_line * 1000:>5.2f} ({q_line / Q_NOW:>3.1f} x)")
        print(f"{name:>46} {face * 1e4:>5.0f} cm2 {pleat:>4} mm " + " ".join(f"{c:>17}" for c in cells))
    print(f"no face lets the two Deltas past {2 * cfd.FAN['q_max'] * 1000:.1f} L/s, their flow with nothing in the way")
    print("\nfour Deltas (D300) through the filter wall's four cartridges, over each depth of carbon module:")
    for depth in (50, 70, 90):
        bed = (depth - 6) / 1000 * 0.219
        cells = []
        for grade in (1.0, 5 / 3):
            q = flow_through(4 * 0.150 * 0.049, 15, grade, four_deltas, bed)
            cells.append(f"{q * 1000:>5.2f} ({q / Q_NOW:>3.1f} x) {four_deltas(q):>3.0f} Pa")
        name = f"four Mijia, four Deltas, a {depth} mm module"
        q = flow_through(4 * 0.150 * 0.049, 15, 1.0, four_deltas, bed)
        print(f"{name:>46} {4 * 0.150 * 0.049 * 1e4:>5.0f} cm2 {15:>4} mm " + " ".join(f"{c:>17}" for c in cells)
              + f"   bed at mid grade {q * EBCT / bed * 1000:.0f} mm, {q * EBCT * 1e6:.0f} cm3")


# The filter wall's layouts (Alon, 15 Oct 2026): its HEPA - four Mijia in one module, or one flat purifier panel
# across the top row, sold at 400 x 220 x 30 mm and so on - over its carbon, in one module or across the whole bottom
# row. A panel is modelled as the paper is, at 15 mm pleats; it is sold as H13, so read its H13-like column.
WALL_HEPA = {"four Mijia": 4 * 0.150 * 0.049, "a 400 x 220 panel": 0.400 * 0.220}
WALL_BED = {"carbon in one module": 0.084 * 0.219, "carbon across the bottom row": 0.084 * 0.444}
WALL_FLOWS = (2, 3, 4, 5, 6, 8)  # L/s


def wall_need(q, face, bed, grade=1.0):
    """The pressure [Pa] the wall's HEPA, carbon and floss take at flow q, the carbon kept at today's dwell time."""
    k = cfd.MEDIA["hepa"]["dp_at_1"] * grade
    return sum(losses(q, face, bed, q * EBCT / bed, bed, hepa_at_1=k))


def show_wall():
    print(f"the filter wall: Pa its filters take at each flow (mid grade), the carbon kept at {EBCT:.2f} s")
    print(f"{'':>50} " + " ".join(f"{q:>5} L/s" for q in WALL_FLOWS))
    for (hname, face), (bname, bed) in itertools.product(WALL_HEPA.items(), WALL_BED.items()):
        cells = " ".join(f"{wall_need(q / 1000, face, bed):>6.0f} Pa" for q in WALL_FLOWS)
        print(f"{hname + ', ' + bname:>50} " + cells)
    print("\nthe Deltas through each, on Delta's published curve:")
    for (hname, face), (bname, bed) in itertools.product(WALL_HEPA.items(), WALL_BED.items()):
        for gname, grade in (("mid grade", 1.0), ("H13-like", 5 / 3)):
            for fname, fans in (("two Deltas", deltas), ("four Deltas", four_deltas)):
                q = flow_through(face, 15, grade, fans, bed)
                print(f"{hname + ', ' + bname:>50}  {gname:9} {fname:11} {q * 1000:5.2f} L/s, {q / Q_NOW:4.1f} x,"
                      f" {fans(q):3.0f} Pa; carbon {q * EBCT * 1e6:5.0f} cm3, {q * EBCT * RHO_BED * 1000:4.0f} g")


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
    results.append(("the Deltas' curve ends on the datasheet's 10.57 mmH2O and 0.286 m3/min, and only falls",
                    curve_ok(DELTA_VH), f"{DELTA_VH[0][1]} mmH2O, {DELTA_VH[-1][0]} m3/min"))
    for name, ok, detail in results:
        print(f"{'ok' if ok else 'FAILED':>6}  {name}: {detail}")
    controls = []
    wrong = sum(losses(q, cfd.A_HEPA, *bed, hepa_at_1=2 * cfd.MEDIA["hepa"]["dp_at_1"]))
    controls.append(("the HEPA's drop doubled here only", abs(wrong - p) >= 0.01, f"{wrong:.1f} vs {p:.1f} Pa"))
    bumped = DELTA_VH[:20] + [(DELTA_VH[20][0], DELTA_VH[19][1] + 0.5)] + DELTA_VH[21:]
    controls.append(("a curve that rises once", not curve_ok(bumped), "refused" if not curve_ok(bumped) else "passed"))
    shifted = [(x, y + 0.3) for x, y in DELTA_VH]
    controls.append(("a curve 0.3 mmH2O high", not curve_ok(shifted), "refused" if not curve_ok(shifted) else "passed"))
    for name, caught, detail in controls:
        print(f"{'ok' if caught else 'MISSED':>6}  control, {name}: {detail}")
    passed = sum(ok for _, ok, _ in results)
    caught = sum(c for _, c, _ in controls)
    print(f"checks: {passed} of {len(results)} agree; controls: {caught} of {len(controls)} caught")
    return passed == len(results) and caught == len(controls)


def curve_ok(curve):
    """A fan curve that starts on the datasheet's no-flow pressure, ends on its free-air flow, and only falls."""
    ends = abs(curve[0][1] - 10.57) <= 0.1 and abs(curve[-1][0] - 0.286) <= 0.002 and abs(curve[-1][1]) <= 0.05
    falls = all(y1 < y0 and x1 > x0 for (x0, y0), (x1, y1) in itertools.pairwise(curve))
    return ends and falls


if __name__ == "__main__":
    if sys.argv[1:] == ["check"]:
        sys.exit(0 if check() else 1)
    if sys.argv[1:] == ["candidates"]:
        show_candidates()
        sys.exit(0)
    if sys.argv[1:] == ["wall"]:
        show_wall()
        sys.exit(0)
    if sys.argv[1:]:
        sys.exit(__doc__)
    show()
