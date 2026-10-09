#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
# SPDX-License-Identifier: MPL-2.0
# /// script
# requires-python = ">=3.11"
# dependencies = ["numpy"]
# ///
"""How many hours of ASA printing each scrubber's carbon takes before it is spent - an estimate, from the
carbon's own datasheet and published printer emissions. From the repository's root:

  uv run scripts/carbon-life.py

THE CARBON: Chemviron/Calgon AP4-60, 4 mm steam-activated coal pellets. Its Envirocarb data sheet gives a
bed density of 450 kg/m3 and the benzene it holds in dry air at 20 C: 39, 34, 22 and 13 % of its weight at
90, 10, 1 and 0.1 % of saturation. A Dubinin-Astakhov isotherm is fitted to those four points and carried to
styrene - the main fume from ASA and ABS - by its affinity coefficient (the two liquids' molar volumes).
A scrubber holds the chamber's air at tens to hundreds of micrograms per m3, three decades and more below
the data sheet's lowest point: there the carbon takes up a few per cent of its weight, not tens.

THE FUMES: total VOCs from ASA, 0.5 to 3.5 mg per hour of printing. UL's consolidated chamber data (58 VOC
tests, Environment International, 2023) put three quarters of all printers' total-VOC rates under 1 mg/h,
ABS's median at 1.02 mg/h, and its highest cases, ASA among them, over 3 mg/h. Azimi et al. (2016) measured
12 to 113 ug/min of styrene from ABS; Wojnowski et al. (2022), on a Prusa i3 MK2S, found ASA's styrene under
a quarter of ABS's. All of it is counted as if it were styrene: the light ones (acrylonitrile, aldehydes)
hold poorly and mostly pass, so the carbon really sees less, and lasts longer than this says.

THE CHAMBER: every fume goes through the carbon and nowhere else, the carbon removes 90 % of what passes it,
and it sits at 45 C - the chamber during an ASA print. At steady state the chamber's concentration is the
emission over the air the carbon cleans; the carbon is spent when it is in equilibrium with that air. It
lets more through well before then: read the hours as the end, not the point to change it.
"""
import math

import numpy as np

R = 8.314

# AP4-60's benzene isotherm, dry air, 20 C: (relative pressure, weight fraction) - the data sheet's table.
BENZENE = [(0.9, 0.39), (0.1, 0.34), (0.01, 0.22), (0.001, 0.13)]
RHO_BENZENE = 0.877                     # g/cm3, liquid
BED_DENSITY = 0.45                      # g/cm3
STYRENE = {"beta": 115.0 / 88.9, "rho": 0.906, "M": 0.10415}   # affinity by molar volume; liquid g/cm3; kg/mol
CARBON_C = 45.0                         # the carbon's temperature while printing ASA
ETA = 0.9                               # what one pass through fresh carbon removes

# Carbon (cm3) and the air through it with every leak sealed (L/s): the LunchBox's bed, 116 x 71.6 x 18.1 mm,
# and its CFD flow through the HEPA with the insert; the BentoBox's three C-MAG trays (models/bentobox), and
# its flow with the section (sim/bentobox-cfd), filled to the guide's line or to the top.
BOXES = {
    "LunchBox": (150.0, 1.30),
    "BentoBox, to the line": (55.5, 0.68),
    "BentoBox, trays full": (222.0, 0.58),
    # The remix (Alon, 9 Oct 2026: D146): no C-MAG, a 45 mm bed over the housing's whole inside, 40.8 x 100.8 less its
    # rounded corners, with the paper clamp at 18 pleats - its flow by sim/bentobox-cfd/pleat.py, on the middle grade.
    "BentoBox remix, a 45 mm bed": (184.3, 0.72),
}
EMISSIONS = (0.5, 1.5, 3.5)             # mg/h


def fit_isotherm():
    """Dubinin-Astakhov W = W0 exp(-(A/E0)^n), A = RT ln(1/x), fitted to the benzene points."""
    t = 293.15
    x = np.array([p for p, _ in BENZENE])
    w = np.array([q for _, q in BENZENE]) / RHO_BENZENE
    a = R * t * np.log(1 / x) / 1000
    best = None
    for n in np.arange(1.0, 3.001, 0.05):
        X = np.vstack([np.ones_like(a), -(a ** n)]).T
        coef, *_ = np.linalg.lstsq(X, np.log(w), rcond=None)
        err = float(np.sum((X @ coef - np.log(w)) ** 2))
        if best is None or err < best[0]:
            best = (err, float(n), math.exp(coef[0]), coef[1] ** (-1 / n))
    return best


def p_sat_styrene(tc):
    return 10 ** (7.14016 - 1574.51 / (224.09 + tc)) * 133.322     # Antoine, Pa


def loading(fit, c_mg_m3, tc):
    """Styrene the carbon holds, g per g, in equilibrium with c mg/m3 at tc."""
    _, n, w0, e0 = fit
    t = tc + 273.15
    c_sat = p_sat_styrene(tc) * STYRENE["M"] / (R * t) * 1e6        # mg/m3
    a = R * t * math.log(c_sat / c_mg_m3) / 1000
    return w0 * math.exp(-(a / (STYRENE["beta"] * e0)) ** n) * STYRENE["rho"]


def main():
    fit = fit_isotherm()
    err, n, w0, e0 = fit
    print(f"AP4-60 benzene isotherm, Dubinin-Astakhov: n {n:.2f}, W0 {w0:.3f} cm3/g, E0 {e0:.1f} kJ/mol")
    for (x, q) in BENZENE:
        a = R * 293.15 * math.log(1 / x) / 1000
        print(f"   {x * 100:5.1f} % of saturation: data sheet {q * 100:4.0f} %, fit {w0 * math.exp(-(a / e0) ** n) * RHO_BENZENE * 100:5.1f} %")
    assert math.sqrt(err / len(BENZENE)) < 0.05, "the isotherm does not fit the data sheet"
    for tc in (20, CARBON_C):
        print(f"styrene held at {tc:.0f} C: " + ", ".join(f"{loading(fit, c, tc) * 100:.1f} % at {c:g} mg/m3" for c in (0.1, 1, 10)))
    print(f"\nASA print hours until the carbon is spent ({CARBON_C:.0f} C, {ETA:.0%} removed per pass, every fume through it)")
    print(f"{'VOCs':>9}" + "".join(f"{name:>32}" for name in BOXES))
    for e in EMISSIONS:
        cells = []
        for cm3, q in BOXES.values():
            c = e / (q * 3.6 * ETA)                 # mg/m3 in the chamber
            held = loading(fit, c, CARBON_C)
            cells.append(f"{cm3 * BED_DENSITY * held * 1000 / e:,.0f} h, {held * 100:.1f} % of {cm3 * BED_DENSITY:.0f} g")
        print(f"{e:>5} mg/h" + "".join(f"{s:>32}" for s in cells))


if __name__ == "__main__":
    main()
