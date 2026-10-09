#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
# SPDX-License-Identifier: MPL-2.0
"""How many pleats the paper clamp should hold: the air through one pleat of the paper, in 2-D, for each pleat
count the clamp might take, and what each does to the whole box's flow. From the repository's root:

  uv run --project sim/bentobox-cfd sim/bentobox-cfd/pleat.py lumped
        the pleat's drop worked out by hand - the paper's own resistance, and the channels' - for each count
  uv run --project sim/bentobox-cfd sim/bentobox-cfd/pleat.py cases
        write one OpenFOAM case per pleat count, paper grade and face velocity into sim/bentobox-cfd/cases/pleats/,
        and print the command that runs them all in WSL
  uv run --project sim/bentobox-cfd sim/bentobox-cfd/pleat.py results [--out docs/bentobox/cfd]
        read the solved cases: the pleat's drop for each count, and the box's flow with the C-MAG filled to its
        line and filled full, by cfd.py's lumped model of the fans and the other filters

The clamp holds n full pleats across 2 * pack_edge, and half a pleat more at each long edge (bentobox.layout.scad):
pitch = 2 * pack_edge / (n + 1). Each case is half a pitch wide, between two symmetry planes through a top fold and
a bottom fold, with 5 mm of air above and below the pack. The paper is a porous band paper_t thick (Darcy), its
middle running straight from the top fold to the bottom fold; where the two sheets of a fold meet, near its
crease, the band is solid paper, as a sharp fold of real paper is. Laminar: the channels' Reynolds number is
under 100. The paper's grade is not known (HomeBox: "HEPA-grade", the fibre not stated), so three are run, by the
drop across the flat paper at 5.33 cm/s, the velocity HEPA media are rated at.
"""
import argparse
import csv
import importlib.util
import json
import math
import os
import re
import shutil
import subprocess
import sys
import tempfile
from collections import deque
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
sys.path.insert(0, str(HERE))
import cfd

CASES = HERE / "cases" / "pleats"
CASES_MESH = HERE / "cases" / "pleats-mesh"
OPENSCAD = os.environ.get("OPENSCAD") or "openscad"

GRADES = {"100": 100.0, "200": 200.0, "300": 300.0}   # Pa across the flat paper at 5.33 cm/s - assumptions
V_RATED = 0.0533                                      # m/s
V_FACE = (0.1, 0.2, 0.35)                             # m/s into the pack's top face: the box runs near 0.2
COUNTS = (8, 10, 11, 12, 13, 14, 15, 16, 17, 18, 20, 22, 24, 26)
CLAMP_MAX = 18      # the most pleats the clamp builds: at 19 its half wedges come out under 3 mm (bentobox.layout.scad)
PLENUM = 5.0                                          # mm of air above and below the pack
DX, DY = 0.02, 0.05                                   # mm: 20 cells across the 0.4 mm paper, the band near upright


# ------------------------------------------------------------------ the clamp, from the model
def clamp():
    """The paper and the clamp's numbers, echoed by the model, so this cannot disagree with it."""
    src = ROOT / "models" / "bentobox" / "bentobox.scad"
    with tempfile.TemporaryDirectory() as tmp:
        f = Path(tmp) / "c.scad"
        f.write_text(f"include <{src.as_posix()}>\ndraw_model = false;\n"
                     "echo(pleat = [paper_t, paper_depth, 2 * pack_edge, 2 * comb_y - 2 * clamp_wedge_l, pack_n]);\n",
                     encoding="utf-8")
        out = Path(tmp) / "c.echo"
        subprocess.run([OPENSCAD, "-o", str(out), str(f)], capture_output=True, text=True, check=False)
        m = re.search(r"pleat = (\[.*\])", out.read_text(encoding="utf-8") if out.exists() else "")
    if not m:
        sys.exit("the model echoed no clamp numbers - is OPENSCAD set?")
    t, depth, width, length, n_now = json.loads(m.group(1))
    return {"t": t, "depth": depth, "width": width, "length": length, "n_now": int(n_now)}


def geometry(c, n):
    """Half a pitch of the pack, in mm: its width b; the paper's middle from the top fold (0, depth - t/2) to the
    bottom fold (b, t/2); its lean from upright; its thickness across, along X."""
    p = c["width"] / (n + 1)
    b = p / 2
    run = c["depth"] - c["t"]
    lean = math.atan2(b, run)
    return {"pitch": p, "b": b, "lean": lean, "t_x": c["t"] / math.cos(lean), "length": math.hypot(b, run)}


# ------------------------------------------------------------------ worked out by hand
def lumped(c, n, dp_rated, v):
    """The paper's drop where both its faces see air, and the channels' Poiseuille drop as uniform suction along
    a channel of the V's mean gap. A cross-check, not the answer: near a fold the gap closes and the flow there
    redistributes, which only the simulation follows."""
    g = geometry(c, n)
    mu, R = cfd.AIR["rho"] * cfd.AIR["nu"], dp_rated / V_RATED
    meet = (c["t"] / 2) / math.sin(g["lean"])         # from a fold's crease to where its two sheets part
    open_len = max(g["length"] - 2 * meet, 1e-6) * 1e-3   # m of paper, per half pitch, with air on both sides
    q = v * g["b"] * 1e-3                             # m2/s per metre of pleat: what half a pitch takes in
    media = R * q / open_len
    # A channel takes in 2q at its mouth, pitch - t_x wide, and gives it up evenly along its length to nothing at
    # its end: between plates of the V's mean gap, dp = 12 mu (2q) l / (2 w^3). The inlet's and the outlet's.
    gap = max((g["pitch"] - g["t_x"]) / 2, 1e-6) * 1e-3
    channel = 2 * 12 * mu * q * (open_len * math.cos(g["lean"])) / gap ** 3
    return media, channel


def show_lumped():
    c = clamp()
    print(f"the paper: {c['t']} mm thick, folds {c['depth']} mm deep; the clamp {c['width']} mm across, "
          f"{c['length']} mm open along the folds; it holds {c['n_now']} pleats now")
    print(f"{'pleats':>6} {'pitch mm':>9} {'lean deg':>9} " + " ".join(f"{g + ' Pa grade':>22}" for g in GRADES))
    print(f"{'':>26}" + " ".join(f"{'paper + channels, Pa':>22}" for _ in GRADES) + "   at 0.2 m/s")
    for n in COUNTS:
        g = geometry(c, n)
        cols = []
        for dp in GRADES.values():
            m, ch = lumped(c, n, dp, 0.2)
            cols.append(f"{m:>9.1f} + {ch:>6.1f} = {m + ch:>5.0f}")
        print(f"{n:>6} {g['pitch']:>9.3f} {math.degrees(g['lean']):>9.2f} " + " ".join(cols))


# ------------------------------------------------------------------ the cases
def name(n, grade, v):
    return f"n{n:02d}-g{grade}-v{round(v * 1000):03d}"


def mask(c, g, nx, ny):
    """Which cells are paper: their centres inside the band, as topoSet's rotatedBoxToCell and the two clipping
    boxes choose them. Returned row by row from the bottom; and the band's corner and edges for topoSet, in mm."""
    t, depth, b = c["t"], c["depth"], g["b"]
    top, bot = (0.0, depth - t / 2), (b, t / 2)
    L = math.dist(top, bot)
    u = ((bot[0] - top[0]) / L, (bot[1] - top[1]) / L)     # along the band, top fold to bottom fold
    nrm = (-u[1], u[0])                                    # across it
    ext = 2 * t                                            # past each fold, so the crease is closed; clipped below
    origin = (top[0] - ext * u[0] - t / 2 * nrm[0], top[1] - ext * u[1] - t / 2 * nrm[1])
    i_vec, j_vec = (t * nrm[0], t * nrm[1]), ((L + 2 * ext) * u[0], (L + 2 * ext) * u[1])
    rows = []
    for jy in range(ny):
        y = -PLENUM + (jy + 0.5) * (depth + 2 * PLENUM) / ny
        row = []
        for ix in range(nx):
            x = (ix + 0.5) * b / nx
            dx, dy = x - origin[0], y - origin[1]
            a = (dx * i_vec[0] + dy * i_vec[1]) / (t * t)
            s = (dx * j_vec[0] + dy * j_vec[1]) / ((L + 2 * ext) ** 2)
            row.append(0 <= a <= 1 and 0 <= s <= 1 and 0 < y < depth)
        rows.append(row)
    return rows, origin, i_vec, j_vec


def bypass(rows):
    """Whether air can get from the plenum above to the plenum below without crossing paper, cell face to face."""
    ny, nx = len(rows), len(rows[0])
    seen = {(ny - 1, i) for i in range(nx) if not rows[ny - 1][i]}
    todo = deque(seen)
    while todo:
        j, i = todo.popleft()
        if j == 0:
            return True
        for dj, di in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            jj, ii = j + dj, i + di
            if 0 <= jj < ny and 0 <= ii < nx and not rows[jj][ii] and (jj, ii) not in seen:
                seen.add((jj, ii))
                todo.append((jj, ii))
    return False


def write_case(c, n, grade, v, root=CASES, dx=DX, dy=DY, tag=""):
    g = geometry(c, n)
    case = root / (name(n, grade, v) + tag)
    if case.exists():
        shutil.rmtree(case)
    nx = max(40, math.ceil(g["b"] / dx))
    ny = math.ceil((c["depth"] + 2 * PLENUM) / dy)
    rows, origin, i_vec, j_vec = mask(c, g, nx, ny)
    if bypass(rows):
        sys.exit(f"{case.name}: air gets past the paper without crossing it - the band is not closed")
    # The band's thickness as meshed, across X, on the rows where all of it is inside the half pitch: its
    # coefficient is scaled by true over meshed, as cfd.py scales the box's zones.
    dxc = g["b"] / nx
    full = [sum(r) * dxc for r in rows if not r[0] and not r[-1] and any(r)]
    meshed = sum(full) / len(full)
    scale = g["t_x"] / meshed
    d = cfd.darcy_d(GRADES[grade] / V_RATED, c["t"] * 1e-3) * scale
    mm = 1e-3
    w = cfd.write
    w(case, "system/blockMeshDict", f"""scale {mm};
vertices ( (0 {-PLENUM} 0) ({g['b']:.6f} {-PLENUM} 0) ({g['b']:.6f} {c['depth'] + PLENUM:.6f} 0) (0 {c['depth'] + PLENUM:.6f} 0)
           (0 {-PLENUM} {DY}) ({g['b']:.6f} {-PLENUM} {DY}) ({g['b']:.6f} {c['depth'] + PLENUM:.6f} {DY}) (0 {c['depth'] + PLENUM:.6f} {DY}) );
blocks ( hex (0 1 2 3 4 5 6 7) ({nx} {ny} 1) simpleGrading (1 1 1) );
boundary
(
    inlet {{ type patch; faces ((3 7 6 2)); }}
    outlet {{ type patch; faces ((0 1 5 4)); }}
    topFold {{ type symmetryPlane; faces ((0 4 7 3)); }}
    bottomFold {{ type symmetryPlane; faces ((1 2 6 5)); }}
    frontBack {{ type empty; faces ((0 3 2 1) (4 5 6 7)); }}
);
""")
    m3 = lambda p: f"({p[0] * mm:.9g} {p[1] * mm:.9g} {-1 * mm:.9g})"
    v3m = lambda p: f"({p[0] * mm:.9g} {p[1] * mm:.9g} 0)"
    w(case, "system/topoSetDict", f"""actions
(
    // i, j, k must be right-handed: the source tests a cell's centre against the box's faces by their normals, and
    // with a left-handed set it selects nothing at all.
    {{ name paperCells; type cellSet; action new; source rotatedBoxToCell;
      origin {m3(origin)}; i {v3m(j_vec)}; j {v3m(i_vec)}; k (0 0 {3 * mm}); }}
    {{ name paperCells; type cellSet; action subtract; source boxToCell; box (-1 -1 -1) (1 0 1); }}
    {{ name paperCells; type cellSet; action subtract; source boxToCell; box (-1 {c['depth'] * mm:.9g} -1) (1 1 1); }}
    {{ name paper; type cellZoneSet; action new; source setToCellZone; set paperCells; }}
);
""")
    w(case, "constant/fvOptions", f"""paperPorosity
{{
    type            explicitPorositySource;
    explicitPorositySourceCoeffs
    {{
        selectionMode   cellZone;
        cellZone        paper;
        type            DarcyForchheimer;
        DarcyForchheimerCoeffs
        {{
            d   d [0 -2 0 0 0 0 0] ({d:.6g} {d:.6g} {d:.6g});
            f   f [0 -1 0 0 0 0 0] (0 0 0);
            coordinateSystem {{ origin (0 0 0); e1 (1 0 0); e2 (0 1 0); }}
        }}
    }}
}}
""")
    w(case, "constant/transportProperties", f"transportModel Newtonian;\nnu {cfd.AIR['nu']};\n")
    w(case, "constant/turbulenceProperties", "simulationType laminar;\n")

    def field(fname, cls, dim, internal, inlet, outlet):
        w(case, f"0/{fname}", f"""dimensions {dim};
internalField uniform {internal};
boundaryField
{{
    inlet {{ {inlet} }}
    outlet {{ {outlet} }}
    "(topFold|bottomFold)" {{ type symmetryPlane; }}
    frontBack {{ type empty; }}
}}
""", cls)

    field("U", "volVectorField", "[0 1 -1 0 0 0 0]", f"(0 {-v} 0)", f"type fixedValue; value uniform (0 {-v} 0);",
          "type zeroGradient;")
    field("p", "volScalarField", "[0 2 -2 0 0 0 0]", "0", "type zeroGradient;", "type fixedValue; value uniform 0;")
    fo = lambda nm, patch, op, fld: (f"{nm} {{ type surfaceFieldValue; libs (fieldFunctionObjects); writeControl timeStep; "
                                     f"writeInterval 5; log false; writeFields false; regionType patch; name {patch}; "
                                     f"operation {op}; fields ({fld}); }}")
    w(case, "system/controlDict", f"""application simpleFoam;
startFrom startTime; startTime 0; stopAt endTime; endTime 800; deltaT 1;
writeControl timeStep; writeInterval 800; purgeWrite 1; writeFormat binary; writePrecision 8;
writeCompression off; timeFormat general; timePrecision 6; runTimeModifiable false;
functions
{{
    {fo("inletP", "inlet", "areaAverage", "p")}
    {fo("inletFlux", "inlet", "sum", "phi")}
    {fo("outletFlux", "outlet", "sum", "phi")}
}}
""")
    w(case, "system/fvSchemes", """ddtSchemes { default steadyState; }
gradSchemes { default Gauss linear; }
divSchemes { default none; div(phi,U) bounded Gauss linearUpwind grad(U); div((nuEff*dev2(T(grad(U))))) Gauss linear; }
laplacianSchemes { default Gauss linear corrected; }
interpolationSchemes { default linear; }
snGradSchemes { default corrected; }
""")
    w(case, "system/fvSolution", """solvers
{
    p { solver GAMG; smoother GaussSeidel; tolerance 1e-9; relTol 0.01; }
    U { solver smoothSolver; smoother symGaussSeidel; tolerance 1e-10; relTol 0.05; }
}
SIMPLE
{
    consistent yes;
    nNonOrthogonalCorrectors 0;
    // No residual control: every case runs 800 iterations and is judged by its inlet pressure's drift over its
    // last fifth (results). Stopped by residuals, the dense pleats' cases stopped at 80 to 120 iterations with
    // their drop still moving by up to 0.3 %; the open ones took 350.
}
relaxationFactors { fields { p 1; } equations { U 0.9; } }
""")
    meta = {"n": n, "grade_Pa": GRADES[grade], "v_face": v, **g, "nx": nx, "ny": ny, "paper_cells": sum(map(sum, rows)),
            "t_x_meshed": meshed, "d_scale": scale, "d": d}
    (case / "pleat.json").write_text(json.dumps(meta, indent=1), encoding="utf-8")
    return case


def make_cases(mesh_check=False):
    """Every count, grade and velocity; or, for the mesh check, three counts on the mesh and on one of half the
    cells' size, side by side."""
    c = clamp()
    root = CASES_MESH if mesh_check else CASES
    if root.exists():
        shutil.rmtree(root)
    names = []
    if mesh_check:
        for n in (11, 18, 26):
            names.append(write_case(c, n, "200", 0.2, root, DX, DY, "-m1").name)
            names.append(write_case(c, n, "200", 0.2, root, DX / 2, DY / 2, "-m2").name)
    else:
        for n in COUNTS:
            for grade in GRADES:
                for v in V_FACE:
                    names.append(write_case(c, n, grade, v).name)
    (root / "list.txt").write_text("\n".join(names) + "\n", encoding="utf-8", newline="\n")
    (root / "clamp.json").write_text(json.dumps(c, indent=1), encoding="utf-8")
    shutil.copy(HERE / "run_pleats.sh", root / "run_pleats.sh")
    wsl = "/mnt/" + root.as_posix()[0].lower() + root.as_posix()[2:]
    print(f"{len(names)} cases in {root}")
    print(f"run them:  wsl.exe -d Ubuntu -- bash -s -- {wsl} < sim/bentobox-cfd/run_pleats.sh")


def show_mesh_check():
    """The mesh check's drops: each count on the mesh and on half its cells' size."""
    print("the mesh check, 200 Pa paper at 0.2 m/s: the drop on the mesh, and on half its cells' size")
    for n in (11, 18, 26):
        r1, r2 = (read_case(CASES_MESH / (name(n, "200", 0.2) + t)) for t in ("-m1", "-m2"))
        if r1 is None or r2 is None:
            print(f"{n:>3} pleats: not run")
            continue
        print(f"{n:>3} pleats: {r1['dp_Pa']:.2f} Pa, {r2['dp_Pa']:.2f} Pa on half the cells: "
              f"{100 * (r1['dp_Pa'] / r2['dp_Pa'] - 1):+.2f} %")


# ------------------------------------------------------------------ the results
def last(path, col=1):
    rows = [ln.split() for ln in path.read_text(encoding="utf-8").splitlines() if ln and not ln.startswith("#")]
    return float(rows[-1][col]), rows


def read_case(case):
    meta = json.loads((case / "pleat.json").read_text(encoding="utf-8"))
    res = case / "results"
    pp = {k: next((res / "postProcessing" / k).rglob("surfaceFieldValue.dat"), None) for k in ("inletP", "inletFlux", "outletFlux")}
    if not all(pp.values()):
        return None
    p_in, rows = last(pp["inletP"])
    q_in, _ = last(pp["inletFlux"])
    q_out, _ = last(pp["outletFlux"])
    tail = [float(r[1]) for r in rows[-max(2, len(rows) // 5):]]
    log = (res / "log.simpleFoam").read_text(encoding="utf-8", errors="replace")
    its = re.findall(r"^Time = (\d+)", log, re.MULTILINE)
    topo = (res / "log.topoSet").read_text(encoding="utf-8", errors="replace")
    cz = re.findall(r"cellSet paperCells now size (\d+)", topo)
    return {**meta, "dp_Pa": p_in * cfd.AIR["rho"], "q_in": q_in, "q_out": q_out,
            "drift_pct": 100 * (max(tail) - min(tail)) / abs(tail[-1]) if tail[-1] else None,
            "iterations": int(its[-1]) if its else 0, "converged": "SIMPLE solution converged" in log,
            "topo_cells": int(cz[-1]) if cz else None}


def fit(vs, dps):
    """dp = a v + b v^2, least squares through the origin."""
    s11 = sum(v * v for v in vs); s12 = sum(v ** 3 for v in vs); s22 = sum(v ** 4 for v in vs)
    r1 = sum(v * p for v, p in zip(vs, dps)); r2 = sum(v * v * p for v, p in zip(vs, dps))
    det = s11 * s22 - s12 * s12
    return (r1 * s22 - r2 * s12) / det, (s11 * r2 - s12 * r1) / det


def box(dp_hepa, layer_t, with_section=True):
    """cfd.py's lumped model, the fans against every filter in series, with the paper's drop as a function of
    the flow in place of the cartridge's straight line."""
    d_c, f_c = cfd.ergun(cfd.MEDIA["carbon"]["eps"], cfd.MEDIA["carbon"]["dp"])
    k_sheet = cfd.MEDIA["sheet"]["dp"] / cfd.MEDIA["sheet"]["at"] / cfd.A_SHEET

    def loss(q):
        v_c = q / cfd.A_CARBON
        carbon = cfd.AIR["rho"] * cfd.LAYERS * layer_t * (cfd.AIR["nu"] * d_c * v_c + 0.5 * f_c * v_c ** 2)
        return dp_hepa(q) + carbon + (k_sheet * q if with_section else 0.0)

    def fans(q):
        return cfd.FAN["p_max"] * (1 - q / (2 * cfd.FAN["q_max"]))

    lo, hi = 0.0, 2 * cfd.FAN["q_max"]
    for _ in range(60):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if fans(mid) > loss(mid) else (lo, mid)
    return lo, dp_hepa(lo), loss(lo) - dp_hepa(lo)


def results(out):
    c = json.loads((CASES / "clamp.json").read_text(encoding="utf-8"))
    rows = []
    for case in sorted(p for p in CASES.iterdir() if p.is_dir()):
        r = read_case(case)
        if r is None:
            print(f"{case.name}: no results")
            continue
        rows.append(r)
    bad = [r for r in rows if abs(r["q_in"] + r["q_out"]) > 1e-3 * abs(r["q_in"]) or r["topo_cells"] != r["paper_cells"]
           or r["drift_pct"] is None or r["drift_pct"] > 0.05]
    for r in bad:
        print(f"CHECK n{r['n']} g{r['grade_Pa']:.0f} v{r['v_face']}: in {r['q_in']:.4g} out {r['q_out']:.4g}, "
              f"paper cells {r['topo_cells']} vs {r['paper_cells']}, drift {r['drift_pct']} %, {r['iterations']} its")
    with open(out / "pleats.csv", "w", newline="", encoding="utf-8") as f:
        keys = ["n", "pitch", "grade_Pa", "v_face", "dp_Pa", "lumped_Pa", "iterations", "drift_pct", "d_scale"]
        wr = csv.writer(f, lineterminator="\n")
        wr.writerow(keys)
        for r in sorted(rows, key=lambda r: (r["grade_Pa"], r["n"], r["v_face"])):
            m, ch = lumped(c, r["n"], r["grade_Pa"], r["v_face"])
            r["lumped_Pa"] = m + ch
            wr.writerow([f"{r[k]:.6g}" if isinstance(r[k], float) else r[k] for k in keys])
    # Each count and grade: the drop as a function of the face velocity, then the box's flow with it.
    lay_line = cfd.LAYER_T
    tray = 0.0214                                        # a tray, full: cmag_tray (bentobox.layout.scad)
    summary = {}
    print(f"{'grade':>6} {'pleats':>6} {'pitch':>6} {'Pa at 0.2':>9} {'lumped':>7} {'flow, line':>11} {'paper Pa':>8} "
          f"{'flow, full':>11} {'chamber every':>14}")
    for grade in sorted({r["grade_Pa"] for r in rows}):
        for n in sorted({r["n"] for r in rows}):
            rs = sorted((r for r in rows if r["grade_Pa"] == grade and r["n"] == n), key=lambda r: r["v_face"])
            if len(rs) < 2:
                continue
            a, b2 = fit([r["v_face"] for r in rs], [r["dp_Pa"] for r in rs])
            g = geometry(c, n)
            face = n * g["pitch"] * c["length"] * 1e-6       # the n full pleats' top face, between the wedges
            hepa = lambda q, a=a, b2=b2, face=face: a * (q / face) + b2 * (q / face) ** 2
            q_line, p_line, _ = box(hepa, lay_line)
            q_full, p_full, _ = box(hepa, tray)
            m, ch = lumped(c, n, grade, 0.2)
            summary[f"{grade:.0f}/{n}"] = {"pitch_mm": g["pitch"], "a": a, "b": b2, "face_m2": face,
                                            "dp_at_0.2_Pa": a * 0.2 + b2 * 0.04, "lumped_at_0.2_Pa": m + ch,
                                            "flow_line_L_s": q_line * 1e3, "paper_line_Pa": p_line,
                                            "flow_full_L_s": q_full * 1e3, "paper_full_Pa": p_full}
            print(f"{grade:>6.0f} {n:>6} {g['pitch']:>6.2f} {a * 0.2 + b2 * 0.04:>9.1f} {m + ch:>7.1f} "
                  f"{q_line * 1e3:>7.3f} L/s {p_line:>8.1f} {q_full * 1e3:>7.3f} L/s {0.18 / q_line / 60:>10.1f} min")
    # The bought cartridge, as the box's simulation takes it, for comparison.
    cart = lambda q: cfd.MEDIA["hepa"]["dp_at_1"] / cfd.A_HEPA * q
    q_c, p_c, _ = box(cart, lay_line)
    q_cf, _, _ = box(cart, tray)
    summary["cartridge"] = {"flow_line_L_s": q_c * 1e3, "paper_line_Pa": p_c, "flow_full_L_s": q_cf * 1e3}
    print(f"the bought cartridge, as the box's simulation takes it: {q_c * 1e3:.3f} L/s filled to the line, "
          f"{q_cf * 1e3:.3f} full; it takes {p_c:.1f} Pa")
    summary["carbon"] = carbon_options(summary)
    (out / "pleats.json").write_text(json.dumps(summary, indent=1), encoding="utf-8", newline="\n")
    chart(summary, c, out / "pleats.png")
    print(f"written: {out / 'pleats.csv'}, {out / 'pleats.json'}, {out / 'pleats.png'}")


def chart(summary, c, path):
    """The box's flow against the clamp's pleat count, a line per grade, the C-MAG filled to its line."""
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    fig, ax = plt.subplots(figsize=(8, 4.8), dpi=150)
    for grade, colour in zip(GRADES.values(), ("tab:green", "tab:blue", "tab:red")):
        pts = sorted((int(k.split("/")[1]), v["flow_line_L_s"]) for k, v in summary.items()
                     if k.startswith(f"{grade:.0f}/"))
        ax.plot([p[0] for p in pts], [p[1] for p in pts], "o-", color=colour, ms=4,
                label=f"paper {grade:.0f} Pa at 5.33 cm/s")
    ax.axhline(summary["cartridge"]["flow_line_L_s"], color="grey", ls="--", lw=1,
               label="the bought cartridge, as the box's simulation takes it")
    ax.axvspan(CLAMP_MAX + 0.5, max(COUNTS) + 0.5, color="0.9", zorder=0)
    n_now = clamp()["n_now"]                                 # what the model holds now, not when the cases were written
    ax.axvline(n_now, color="0.4", lw=1, ls=":")
    lo, hi = ax.get_ylim()
    ax.set_ylim(lo - 0.25 * (hi - lo), hi)                 # room under the curves for the legend
    ax.text(CLAMP_MAX + 0.8, 0.27, "past what the clamp builds", fontsize=8, color="0.3",
            transform=ax.get_xaxis_transform())               # x in pleats, y in the axes: between curves and legend
    ax.text(n_now - 0.15, 0.27, f"the clamp: {n_now}", fontsize=8, color="0.3", ha="right",
            transform=ax.get_xaxis_transform())
    ax.set_xlabel(f"pleats across the clamp's {c['width']:.1f} mm")
    ax.set_ylabel("air through the box, L/s")
    ax.set_xlim(min(COUNTS) - 0.5, max(COUNTS) + 0.5)
    ax.set_xticks(COUNTS)
    ax.grid(alpha=0.3)
    ax.legend(fontsize=8, loc="lower left", ncol=2)
    fig.tight_layout()
    fig.savefig(path)
    plt.close(fig)


# ------------------------------------------------------------------ the carbon: the C-MAG, or the housing filled
HOUSING = (0.0408, 0.1008, 0.0044)                    # in_w, in_l, in_r (bentobox.params.scad): the housing's inside
A_HOUSING = HOUSING[0] * HOUSING[1] - (4 - math.pi) * HOUSING[2] ** 2
TRAY = 0.0214                                         # a C-MAG tray, full (cmag_tray)
BEDS = (0.015, 0.025, 0.035, 0.045, 0.055, 0.065)     # m of loose pellets on a grid over the housing's floor


def life_hours(cm3, flow_l_s):
    """scripts/carbon-life.py's estimate, at its middle emission (1.5 mg/h of ASA VOCs)."""
    spec = importlib.util.spec_from_file_location("carbon_life", ROOT / "scripts" / "carbon-life.py")
    cl = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(cl)
    fit, e = cl.fit_isotherm(), 1.5
    held = cl.loading(fit, e / (flow_l_s * 3.6 * cl.ETA), cl.CARBON_C)
    return cm3 * cl.BED_DENSITY * held * 1000 / e


def bed_loss(q, area, depth):
    d_c, f_c = cfd.ergun(cfd.MEDIA["carbon"]["eps"], cfd.MEDIA["carbon"]["dp"])
    v = q / area
    return cfd.AIR["rho"] * depth * (cfd.AIR["nu"] * d_c * v + 0.5 * f_c * v ** 2)


def box_with(dp_hepa, carbon, with_section=True):
    """The fans against the paper, a carbon bed given as dp(q), and the section's sheet."""
    k_sheet = cfd.MEDIA["sheet"]["dp"] / cfd.MEDIA["sheet"]["at"] / cfd.A_SHEET
    lo, hi = 0.0, 2 * cfd.FAN["q_max"]
    for _ in range(60):
        mid = (lo + hi) / 2
        fans = cfd.FAN["p_max"] * (1 - mid / (2 * cfd.FAN["q_max"]))
        lo, hi = (mid, hi) if fans > dp_hepa(mid) + carbon(mid) + (k_sheet * mid if with_section else 0) else (lo, mid)
    return lo


def carbon_options(summary):
    """For each grade, at the clamp's best count the cases found: the box's flow, the carbon's volume and its
    life, with the C-MAG filled to its line or full, or with no C-MAG and the housing filled on a grid. The C-MAG's
    three layers resist as one of their total depth, over its inside; a loose bed spans the housing's whole inside."""
    cmag_area = cfd.A_CARBON
    options = [("C-MAG, to its line", cmag_area, cfd.LAYERS * cfd.LAYER_T),
               ("C-MAG, trays full", cmag_area, cfd.LAYERS * TRAY)]
    options += [(f"housing filled, {d * 1000:.0f} mm", A_HOUSING, d) for d in BEDS]
    out = {}
    for grade in GRADES.values():
        keys = [k for k in summary if k.startswith(f"{grade:.0f}/")]
        if not keys:
            continue
        best = max((k for k in keys if int(k.split("/")[1]) <= CLAMP_MAX), key=lambda k: summary[k]["flow_line_L_s"])
        s = summary[best]
        hepa = lambda q, s=s: s["a"] * q / s["face_m2"] + s["b"] * (q / s["face_m2"]) ** 2
        print(f"\nthe carbon, with the {grade:.0f} Pa paper at {best.split('/')[1]} pleats:")
        print(f"{'':>26} {'carbon':>9} {'flow':>9} {'carbon Pa':>9} {'hours':>7}")
        for label, area, depth in options:
            q = box_with(hepa, lambda q, a=area, dd=depth: bed_loss(q, a, dd))
            cm3 = area * depth * 1e6
            hours = life_hours(cm3, q * 1e3)
            out[f"{grade:.0f}: {label}"] = {"cm3": cm3, "flow_L_s": q * 1e3, "carbon_Pa": bed_loss(q, area, depth), "hours": hours}
            print(f"{label:>26} {cm3:>6.0f} cm3 {q * 1e3:>5.3f} L/s {bed_loss(q, area, depth):>8.1f} {hours:>7,.0f}")
    return out


if __name__ == "__main__":
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("what", choices=["lumped", "cases", "results"])
    ap.add_argument("--out", default=str(CASES))
    ap.add_argument("--mesh", action="store_true", help="cases: the mesh check's six; results: its comparison")
    a = ap.parse_args()
    if a.what == "lumped":
        show_lumped()
    elif a.what == "cases":
        make_cases(a.mesh)
    elif a.mesh:
        show_mesh_check()
    else:
        results(Path(a.out))
