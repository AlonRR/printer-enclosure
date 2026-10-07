#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
# SPDX-License-Identifier: MPL-2.0
"""Airflow through the LunchBox scrubber - an OpenFOAM case built from the OpenSCAD model. From the
repository's root:

  uv run --project sim/lunchbox-cfd sim/lunchbox-cfd/cfd.py case [--plain] [--fine] [--open-top] [--cores N]
        render the geometry from models/lunchbox/lunchbox-cfd.scad, write the case into
        sim/lunchbox-cfd/cases/<name>/, and print the command that runs it in WSL
  uv run --project sim/lunchbox-cfd sim/lunchbox-cfd/cfd.py network
        the same physics as a lumped model: the fans' operating point, with and without the insert,
        across the HEPA grades it might be - the cross-check for the simulation's total flow

--plain is the stack without the insert; --fine meshes the box at 1 mm instead of 2 mm; --open-top leaves
the slot over the HEPA frame open, as built (sealed by default); --cores sets the MPI ranks (14, or 7 each
to run two cases side by side).

The case runs in WSL with OpenFOAM v2412 (conda-forge, in a micromamba env called `of`) through
run_case.sh; post.py turns its result into pictures and numbers. README.md says what is modelled and
what is assumed.
"""
import argparse
import json
import math
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
MODEL = ROOT / "models" / "lunchbox" / "lunchbox-cfd.scad"
OPENSCAD = os.environ.get("OPENSCAD") or "openscad"

# ------------------------------------------------------------------ physics: every assumption in one place
AIR = {"nu": 1.5e-5, "rho": 1.2}                     # air near 20 °C
FAN = {                                              # Delta EFB0412VHD, from Delta's figures via Digi-Key
    "q_max": 10.1 * 0.000471947,                     # 10.1 CFM = 4.77e-3 m3/s at no back-pressure
    "p_max": 103.6,                                  # Pa, 0.416 inH2O, at no flow
    "depth": 0.020,                                  # m
}                                                    # the curve between them is taken as a straight line
MEDIA = {
    # Pressure drop through each filter, Pa, at a superficial velocity of 1 m/s through its own face, linear
    # (Darcy) unless an f is given. HEPA: the paper's grade is not known - 300 Pa at 1 m/s is a mid-grade
    # pleated pack (H11 about half that, H13 nearly twice); `network` shows the spread.
    "hepa": {"dp_at_1": 300.0, "thickness": 0.019, "lateral": 100.0},   # pleats block sideways flow
    # Carbon: 4 mm pellets, 40 % voids - the Ergun equation, d and f in OpenFOAM's units (1/m2, 1/m).
    "carbon": {"eps": 0.40, "dp": 0.004},
    # Filter floss: 20 Pa at 0.75 m/s through 5 mm, a G3-class pad - an estimate.
    "sheet": {"dp": 20.0, "at": 0.75, "thickness": 0.005},
}


def darcy_d(dp_per_velocity, thickness):
    """OpenFOAM's DarcyForchheimer d [1/m2] for dp [Pa] = dp_per_velocity * v across `thickness` [m].
    The incompressible solver works in kinematic pressure: dp/rho = nu * d * v * L."""
    return dp_per_velocity / (AIR["rho"] * AIR["nu"] * thickness)


def coefficients():
    h, c, s = MEDIA["hepa"], MEDIA["carbon"], MEDIA["sheet"]
    eps, dp = c["eps"], c["dp"]
    d_h = darcy_d(h["dp_at_1"], h["thickness"])
    return {
        "hepa": {"d": (d_h * h["lateral"], d_h, d_h * h["lateral"]), "f": (0, 0, 0)},
        "carbon": {"d": (150 * (1 - eps) ** 2 / (eps ** 3 * dp ** 2),) * 3,
                   "f": (2 * 1.75 * (1 - eps) / (eps ** 3 * dp),) * 3},
        "sheet": {"d": (darcy_d(s["dp"] / s["at"], s["thickness"]),) * 3, "f": (0, 0, 0)},
    }


# ------------------------------------------------------------------ geometry from the model
def openscad(args, out):
    run = subprocess.run([OPENSCAD, "-o", str(out), *args, str(MODEL)], capture_output=True, text=True, cwd=ROOT)
    log = run.stdout + run.stderr
    bad = [l for l in log.splitlines() if re.match(r"(ERROR|WARNING):", l)]
    if run.returncode or bad or not Path(out).exists():
        sys.exit(f"OpenSCAD failed for {out.name}:\n" + "\n".join(bad or log.splitlines()[-10:]))
    return log


def geometry(case, with_insert, sealed=True):
    tri = case / "constant" / "triSurface"
    tri.mkdir(parents=True, exist_ok=True)
    flag = ["-D", f"with_insert={'true' if with_insert else 'false'}",
            "-D", f"hepa_top_sealed={'true' if sealed else 'false'}"]
    echo = case / "numbers.echo"
    openscad(flag + ["-D", 'view="numbers"'], echo)
    m = re.search(r"cfd = (\[.*\])", echo.read_text(encoding="utf-8"))
    if not m:
        sys.exit("the model echoed no cfd numbers")
    nums = {k: v for k, v in json.loads(m.group(1))}
    openscad(flag + ["-D", 'view="solid"'], tri / "lunchbox.stl")
    (case / "numbers.json").write_text(json.dumps(nums, indent=1), encoding="utf-8")
    return nums


# ------------------------------------------------------------------ the case
HEAD = "FoamFile {{ version 2.0; format ascii; class {cls}; object {obj}; }}\n"


def write(case, rel, text, cls="dictionary"):
    p = case / rel
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(HEAD.format(cls=cls, obj=p.name) + text, encoding="utf-8", newline="\n")


def v3(v, scale=1.0):
    return "(" + " ".join(f"{x * scale:.6g}" for x in v) + ")"


def case_files(case, nums, fine, cores):
    mm = 0.001
    cell = 4.0                                        # the background mesh, mm
    box_level = 2 if fine else 1                      # 1 mm or 2 mm inside the box
    x0, x1, y0, y1 = -80.0, 80.0, -80.0, 64.0
    z0 = nums["floor_z"]                              # the box stands on the chamber's floor
    nz = math.ceil((160.0 - z0) / cell)
    z1 = z0 + nz * cell
    n = [round((x1 - x0) / cell), round((y1 - y0) / cell), nz]
    write(case, "system/blockMeshDict", f"""scale 1;
vertices ( ({x0} {y0} {z0}) ({x1} {y0} {z0}) ({x1} {y1} {z0}) ({x0} {y1} {z0})
           ({x0} {y0} {z1}) ({x1} {y0} {z1}) ({x1} {y1} {z1}) ({x0} {y1} {z1}) );
blocks ( hex (0 1 2 3 4 5 6 7) ({n[0]} {n[1]} {n[2]}) simpleGrading (1 1 1) );
boundary
(
    floor {{ type wall; faces ((0 3 2 1)); }}
    atmosphere {{ type patch; faces ((4 5 6 7) (0 1 5 4) (2 3 7 6) (1 2 6 5) (0 4 7 3)); }}
);
""")
    bx = nums["box"]
    write(case, "system/snappyHexMeshDict", f"""castellatedMesh true;
snap false;
addLayers false;
geometry
{{
    lunchbox.stl {{ type triSurfaceMesh; name lunchbox; }}
    boxRegion {{ type searchableBox; min ({bx[0] - 3} {bx[2] - 2} {z0 - 1}); max ({bx[1] + 3} {bx[3] + 2} {bx[5] + 3}); }}
    frontRegion {{ type searchableBox; min ({bx[0] - 10} -40 {z0 - 1}); max ({bx[1] + 10} {bx[2]} {bx[5] - 10}); }}
}}
castellatedMeshControls
{{
    maxLocalCells 6000000; maxGlobalCells 30000000; minRefinementCells 0; maxLoadUnbalance 0.10;
    nCellsBetweenLevels 3;
    features ();
    refinementSurfaces {{ lunchbox {{ level ({box_level} {box_level}); patchInfo {{ type wall; }} }} }}
    resolveFeatureAngle 30;
    refinementRegions
    {{
        boxRegion {{ mode inside; levels ((1e15 {box_level})); }}
        frontRegion {{ mode inside; levels ((1e15 1)); }}
    }}
    locationInMesh (0.13 -60.17 100.31);
    allowFreeStandingZoneFaces true;
}}
snapControls {{ nSmoothPatch 3; tolerance 2.0; nSolveIter 30; nRelaxIter 5; }}
addLayersControls {{ relativeSizes true; layers {{}} expansionRatio 1; finalLayerThickness 0.3; minThickness 0.1;
    nGrow 0; featureAngle 60; nRelaxIter 3; nSmoothSurfaceNormals 1; nSmoothNormals 3; nSmoothThickness 10;
    maxFaceThicknessRatio 0.5; maxThicknessToMedialRatio 0.3; minMedialAxisAngle 90; nBufferCellsNoExtrude 0;
    nLayerIter 50; }}
meshQualityControls {{ #includeEtc "caseDicts/meshQualityDict" }}
mergeTolerance 1e-6;
""")
    # Zones, in mm - topoSet runs before the mesh is scaled to metres.
    acts = []

    def boxzone(name, b):
        acts.append(f"{{ name {name}Cells; type cellSet; action new; source boxToCell; "
                    f"box ({b[0]} {b[2]} {b[4]}) ({b[1]} {b[3]} {b[5]}); }}")
        acts.append(f"{{ name {name}; type cellZoneSet; action new; source setToCellZone; set {name}Cells; }}")

    def plate(name, origin, span):
        acts.append(f"{{ name {name}; type faceZoneSet; action new; source searchableSurfaceToFaceZone; "
                    f"surfaceType searchablePlate; origin {v3(origin)}; span {v3(span)}; }}")

    boxzone("hepa", nums["hepa"])
    boxzone("carbon", nums["carbon"])
    if nums["sheet"]:
        boxzone("sheet", nums["sheet"])
    fy0, fy1 = nums["fan_y"]
    for i, (fx, fz) in enumerate(nums["fans"], 1):
        acts.append(f"{{ name fan{i}Cells; type cellSet; action new; source cylinderToCell; "
                    f"p1 ({fx} {fy0} {fz}); p2 ({fx} {fy1} {fz}); radius {nums['fan_r']}; }}")
        acts.append(f"{{ name fan{i}; type cellZoneSet; action new; source setToCellZone; set fan{i}Cells; }}")
        acts.append(f"{{ name fan{i}Faces; type faceSet; action new; source cellToFace; option outside; set fan{i}Cells; }}")
        acts.append(f"{{ name fan{i}Around; type faceZoneSet; action new; source setsToFaceZone; "
                    f"faceSet fan{i}Faces; cellSet fan{i}Cells; }}")
    ix0, ix1, iz0, iz1 = nums["inlet"]
    plate("inlet", (ix0, 0.25, iz0), (ix1 - ix0, 0, iz1 - iz0))           # the grid's plane, air in
    ox0, ox1, oz0, oz1 = nums["outlet"]
    plate("outlet", (ox0, 0.25, oz0), (ox1 - ox0, 0, oz1 - oz0))          # the fans' face, air out
    if nums["sheet"]:
        s = nums["sheet"]
        plate("sheetFace", (s[0], s[2], (s[4] + s[5]) / 2 + 0.25), (s[1] - s[0], s[3] - s[2], 0))
    write(case, "system/topoSetDict", "actions\n(\n    " + "\n    ".join(acts) + "\n);\n")

    co = coefficients()
    opts = []
    for zone in ["hepa", "carbon"] + (["sheet"] if nums["sheet"] else []):
        opts.append(f"""{zone}Porosity
{{
    type            explicitPorositySource;
    explicitPorositySourceCoeffs
    {{
        // With a Coeffs dictionary present, the source reads its cell selection from inside it.
        selectionMode   cellZone;
        cellZone        {zone};
        type            DarcyForchheimer;
        DarcyForchheimerCoeffs
        {{
            d   d [0 -2 0 0 0 0 0] {v3(co[zone]['d'])};
            f   f [0 -1 0 0 0 0 0] {v3(co[zone]['f'])};
            coordinateSystem {{ origin (0 0 0); e1 (1 0 0); e2 (0 1 0); }}
        }}
    }}
}}""")
    for i in range(1, len(nums["fans"]) + 1):
        opts.append(f"""fan{i}
{{
    type            fanMomentumSource;
    selectionMode   cellZone;
    cellZone        fan{i};
    faceZone        fan{i}Around;
    flowDir         (0 -1 0);
    thickness       {FAN['depth']};
    rho             {AIR['rho']};
    fanCurve        table ((0 {FAN['p_max']}) ({FAN['q_max']:.6g} 0));
}}""")
    write(case, "constant/fvOptions", "\n".join(opts) + "\n")
    write(case, "constant/transportProperties", f"transportModel Newtonian;\nnu {AIR['nu']};\n")
    write(case, "constant/turbulenceProperties",
          "simulationType RAS;\nRAS { RASModel kOmegaSST; turbulence on; printCoeffs on; }\n")

    walls = ("floor", "lunchbox")

    def field(name, cls, dim, internal, atmos, wall):
        bf = "\n".join([f"    atmosphere {{ {atmos} }}"] + [f"    {w} {{ {wall} }}" for w in walls])
        write(case, f"0/{name}", f"dimensions {dim};\ninternalField uniform {internal};\nboundaryField\n{{\n{bf}\n}}\n", cls)

    field("U", "volVectorField", "[0 1 -1 0 0 0 0]", "(0 0 0)",
          "type pressureInletOutletVelocity; value uniform (0 0 0);", "type noSlip;")
    field("p", "volScalarField", "[0 2 -2 0 0 0 0]", "0", "type totalPressure; p0 uniform 0; value uniform 0;",
          "type zeroGradient;")
    field("k", "volScalarField", "[0 2 -2 0 0 0 0]", "1e-4", "type inletOutlet; inletValue uniform 1e-4; value uniform 1e-4;",
          "type kqRWallFunction; value uniform 1e-4;")
    field("omega", "volScalarField", "[0 0 -1 0 0 0 0]", "10", "type inletOutlet; inletValue uniform 10; value uniform 10;",
          "type omegaWallFunction; value uniform 10;")
    field("nut", "volScalarField", "[0 2 -1 0 0 0 0]", "0", "type calculated; value uniform 0;",
          "type nutkWallFunction; value uniform 0;")
    field("s", "volScalarField", "[0 0 0 0 0 0 0]", "0", "type inletOutlet; inletValue uniform 0; value uniform 0;",
          "type zeroGradient;")

    def m(p):                                        # probe points, given in mm, written in metres
        return v3(p, mm)

    hz = (nums["hepa"][4] + nums["hepa"][5]) / 2
    fx, fz = nums["fans"][0]
    probes = {
        "ambient_front": (0, -40, hz), "grid_gap": (0, 2.6, hz), "behind_hepa": (0, 23.5, hz),
        "channel": (0, 50, hz), "channel_low": (0, 50, 6), "below_insert": (0, 45, nums["fans_rim"] - 4),
        "fan_in": (fx, fy1 + 1.5, fz + 12), "fan_out": (fx, fy0 - 2, fz + 12), "jet": (fx, -10, fz + 12),
    }
    if nums["sheet"]:
        s = nums["sheet"]
        probes["above_sheet"] = (0, 45, s[5] + 2.5)
        probes["below_sheet"] = (0, 45, s[4] - 3.0)
    (case / "probes.json").write_text(json.dumps(probes, indent=1), encoding="utf-8")
    zone_names = ["hepa", "carbon"] + (["sheet"] if nums["sheet"] else [])
    zone_fos = [f"""pressureIn_{z}
    {{
        type volFieldValue; libs (fieldFunctionObjects); writeControl timeStep; writeInterval 25;
        log false; writeFields false; regionType cellZone; name {z}; operation volAverage; fields (p);
    }}""" for z in zone_names]
    faces = ["inlet", "outlet"] + (["sheetFace"] if nums["sheet"] else [])
    fos = [f"""flowThrough_{f}
    {{
        type surfaceFieldValue; libs (fieldFunctionObjects); writeControl timeStep; writeInterval 25;
        log true; writeFields false; regionType faceZone; name {f};
        operation sum; fields (phi);
    }}
    tracer_{f}
    {{
        type surfaceFieldValue; libs (fieldFunctionObjects); writeControl timeStep; writeInterval 25;
        log false; writeFields false; regionType faceZone; name {f};
        operation weightedAverage; weightField phi; fields (s);
    }}""" for f in faces]
    end, every = (1500 if fine else 1000), 250
    # The solver writes its fields only every `every` iterations; an end between two writes leaves the last
    # stretch unsaved - a 1600-iteration run kept nothing past 1500.
    assert end % every == 0, "endTime must be a multiple of writeInterval"
    write(case, "system/controlDict", f"""application simpleFoam;
startFrom latestTime; startTime 0; stopAt endTime; endTime {end}; deltaT 1;
writeControl timeStep; writeInterval {every}; purgeWrite 2; writeFormat binary; writePrecision 8;
writeCompression off; timeFormat general; timePrecision 6; runTimeModifiable true;
functions
{{
    probes
    {{
        type probes; libs (sampling); writeControl timeStep; writeInterval 25;
        fields (p U s);
        probeLocations ( {" ".join(m(p) for p in probes.values())} );
    }}
    {chr(10).join("    " + x for x in zone_fos)}
    {chr(10).join("    " + x for x in fos)}
    tracer
    {{
        type scalarTransport; libs (solverFunctionObjects); field s; nut nut; alphaD 1; alphaDt 1;
        // Only at the solver's own write times. Left to itself it writes s every iteration, a time folder
        // per step, and purgeWrite then counts those and deletes the real results.
        writeControl writeTime;
        fvOptions
        {{
{chr(10).join(f'            fixAtFan{i} {{ type scalarFixedValueConstraint; selectionMode cellZone; cellZone fan{i}; fieldValues {{ s 1; }} }}' for i in range(1, len(nums['fans']) + 1))}
        }}
    }}
    residuals {{ type solverInfo; libs (utilityFunctionObjects); fields (U p k omega); writeResidualFields no; }}
}}
""")
    write(case, "system/fvSchemes", """ddtSchemes { default steadyState; }
gradSchemes { default Gauss linear; grad(U) cellLimited Gauss linear 1; }
divSchemes
{
    default none;
    div(phi,U) bounded Gauss linearUpwindV grad(U);
    div(phi,k) bounded Gauss upwind;
    div(phi,omega) bounded Gauss upwind;
    div(phi,s) bounded Gauss upwind;
    div((nuEff*dev2(T(grad(U))))) Gauss linear;
}
laplacianSchemes { default Gauss linear corrected; }
interpolationSchemes { default linear; }
snGradSchemes { default corrected; }
wallDist { method meshWave; }
""")
    write(case, "system/fvSolution", """solvers
{
    p { solver GAMG; smoother GaussSeidel; tolerance 1e-7; relTol 0.05; }
    "(U|k|omega|s)" { solver smoothSolver; smoother symGaussSeidel; tolerance 1e-8; relTol 0.1; }
}
SIMPLE
{
    nNonOrthogonalCorrectors 0;
    residualControl { p 2e-4; U 2e-5; "(k|omega)" 2e-5; }
}
relaxationFactors
{
    fields { p 0.3; }
    equations { U 0.7; k 0.7; omega 0.7; s 0.9; }
}
""")
    write(case, "system/decomposeParDict", f"numberOfSubdomains {cores};\nmethod scotch;\n")
    shutil.copy(HERE / "run_case.sh", case / "run_case.sh")


def make_case(with_insert, fine, cores, sealed=True):
    name = ("insert" if with_insert else "plain") + ("" if sealed else "-open-top") + ("-fine" if fine else "")
    case = HERE / "cases" / name
    if case.exists():
        shutil.rmtree(case)
    case.mkdir(parents=True)
    nums = geometry(case, with_insert, sealed)
    case_files(case, nums, fine, cores)
    win = str(case.resolve())
    wsl = "/mnt/" + win[0].lower() + win[2:].replace("\\", "/")
    print(f"case written: {case.relative_to(ROOT)}")
    print(f"run it:  wsl.exe -d Ubuntu -- bash -s -- {wsl} {name} < sim/lunchbox-cfd/run_case.sh")
    return case


# ------------------------------------------------------------------ the lumped cross-check
def network(dp_hepa_at_1=None, with_insert=True, sheet_open=None):
    """Two fans in parallel against the filters in series: the flow where the fans' pressure equals the
    filters' loss. Areas are the open faces each filter sees; every coefficient is the one the CFD uses."""
    h = MEDIA["hepa"]
    a_hepa = 6 * 0.1054 * 0.011                              # six windows of the HEPA frame, m2
    a_carbon = 0.116 * 0.0716                                # the bed's face, m2
    a_sheet = sheet_open if sheet_open else 0.1148 * 0.0248  # the insert's cavity, m2
    co = coefficients()
    d_c, f_c = co["carbon"]["d"][0], co["carbon"]["f"][0]
    L_c = 0.0181
    k_hepa = (dp_hepa_at_1 or h["dp_at_1"]) / a_hepa         # Pa per (m3/s)
    k_sheet = MEDIA["sheet"]["dp"] / MEDIA["sheet"]["at"] / a_sheet

    def loss(q):
        v_c = q / a_carbon
        carbon = AIR["rho"] * L_c * (AIR["nu"] * d_c * v_c + 0.5 * f_c * v_c ** 2)
        return k_hepa * q + carbon + (k_sheet * q if with_insert else 0.0)

    def fans(q):
        return FAN["p_max"] * (1 - q / (2 * FAN["q_max"]))

    lo, hi = 0.0, 2 * FAN["q_max"]
    for _ in range(60):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if fans(mid) > loss(mid) else (lo, mid)
    return lo, fans(lo)


def show_network():
    print("operating point of the two fans: total flow, and the pressure they work against")
    print(f"{'HEPA, Pa at 1 m/s':>20} {'without insert':>22} {'with insert':>22} {'insert costs':>13}")
    for dp in (150, 300, 500):
        q0, p0 = network(dp, with_insert=False)
        q1, p1 = network(dp, with_insert=True)
        print(f"{dp:>20} {q0 * 1000:>9.2f} L/s {p0:>6.1f} Pa {q1 * 1000:>9.2f} L/s {p1:>6.1f} Pa {100 * (1 - q1 / q0):>11.0f} %")
    print("A Lack enclosure holds about 180 L: at 1.5 L/s the scrubber passes the chamber's volume every 2 minutes.")


if __name__ == "__main__":
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("what", choices=["case", "network"])
    ap.add_argument("--plain", action="store_true")
    ap.add_argument("--fine", action="store_true")
    ap.add_argument("--cores", type=int, default=14)
    ap.add_argument("--open-top", action="store_true", help="leave the slot over the HEPA frame open, as built")
    a = ap.parse_args()
    if a.what == "network":
        show_network()
    else:
        make_case(not a.plain, a.fine, a.cores, not a.open_top)
