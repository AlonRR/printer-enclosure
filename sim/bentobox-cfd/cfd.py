#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
# SPDX-License-Identifier: MPL-2.0
"""Airflow through the BentoBox v2.0 scrubber with its C-MAG - an OpenFOAM case built from the OpenSCAD
model. From the repository's root:

  uv run --project sim/bentobox-cfd sim/bentobox-cfd/cfd.py case [--plain] [--fine] [--cores N]
        render the geometry from models/bentobox/bentobox-cfd.scad, write the case into
        sim/bentobox-cfd/cases/<name>/, and print the command that runs it in WSL
  uv run --project sim/bentobox-cfd sim/bentobox-cfd/cfd.py network
        the same physics as a lumped model: the fans' operating point with and without the section, across
        the HEPA grades and pellet-bed voidages it might be, beside the LunchBox's on the same assumptions -
        the cross-check for the simulation's total flow

--plain is the stack as designed, without the remix's section; --fine meshes the box at 1 mm instead of
2 mm; --cores sets the MPI ranks (14, or 7 each to run two cases side by side).

Built the same way as sim/lunchbox-cfd/, whose README says how a case runs and what a result must pass
before it is quoted. The two are kept apart, so that one box's case can change without moving the other's
results; what they share - the fans, the air, the filter media - is the same here, value for value.
"""
import argparse
import importlib.util
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
MODEL = ROOT / "models" / "bentobox" / "bentobox-cfd.scad"
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
    # (Darcy) unless an f is given.
    # HEPA: the cartridge's grade is not known. The LunchBox's case takes 300 Pa at 1 m/s for a mid-grade
    # pack with 19 mm pleats; this one's pleats are 15 mm, so the same media at the same pitch has 15/19 of
    # the area, and 19/15 of the drop. `network` shows the spread.
    "hepa": {"dp_at_1": 300.0 * 19 / 15, "thickness": 0.015, "lateral": 100.0},   # pleats block sideways flow
    # Carbon: 4 mm pellets, 40 % voids, by the Ergun equation - the LunchBox's values, for comparison. A bed
    # one or two pellets deep packs looser than that; `network` shows 50 % beside it.
    "carbon": {"eps": 0.40, "dp": 0.004},
    # Filter floss: 20 Pa at 0.75 m/s through 5 mm, a G3-class pad - an estimate.
    "sheet": {"dp": 20.0, "at": 0.75, "thickness": 0.005},
}


def darcy_d(dp_per_velocity, thickness):
    """OpenFOAM's DarcyForchheimer d [1/m2] for dp [Pa] = dp_per_velocity * v across `thickness` [m].
    The incompressible solver works in kinematic pressure: dp/rho = nu * d * v * L."""
    return dp_per_velocity / (AIR["rho"] * AIR["nu"] * thickness)


def ergun(eps, dp):
    """Ergun's d [1/m2] and f [1/m] for a bed of particles of diameter dp [m] and voidage eps."""
    return 150 * (1 - eps) ** 2 / (eps ** 3 * dp ** 2), 2 * 1.75 * (1 - eps) / (eps ** 3 * dp)


def coefficients():
    h, c, s = MEDIA["hepa"], MEDIA["carbon"], MEDIA["sheet"]
    d_h = darcy_d(h["dp_at_1"], h["thickness"])
    d_c, f_c = ergun(c["eps"], c["dp"])
    return {
        "hepa": {"d": (d_h * h["lateral"], d_h * h["lateral"], d_h), "f": (0, 0, 0)},   # through it is Z
        "carbon": {"d": (d_c,) * 3, "f": (f_c,) * 3},
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


def geometry(case, with_section):
    tri = case / "constant" / "triSurface"
    tri.mkdir(parents=True, exist_ok=True)
    flag = ["-D", f"with_section={'true' if with_section else 'false'}"]
    echo = case / "numbers.echo"
    openscad(flag + ["-D", 'view="numbers"'], echo)
    m = re.search(r"cfd = (\[.*\])", echo.read_text(encoding="utf-8"))
    if not m:
        sys.exit("the model echoed no cfd numbers")
    nums = {k: v for k, v in json.loads(m.group(1))}
    openscad(flag + ["-D", 'view="solid"', "--backend=manifold"], tri / "bentobox.stl")
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


def off_grid(z):
    """A measuring plane must not lie on a mesh plane, where it would catch no faces or two rows of them: the
    mesh's planes are on whole millimetres, so nudge a plane to a quarter past one."""
    return math.floor(z) + 0.25 if abs(z - round(z)) < 0.24 else z


def case_files(case, nums, fine, cores):
    mm = 0.001
    cell = 4.0                                        # the background mesh, mm
    box_level = 2 if fine else 1                      # 1 mm or 2 mm inside the box
    bx = nums["box"]
    x0, x1, y0, y1, z0 = -120.0, 60.0, -100.0, 100.0, 0.0   # the outlet faces -X: more room on that side
    nz = math.ceil((bx[5] + 70.0 - z0) / cell)
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
    ox = nums["outlet"]
    write(case, "system/snappyHexMeshDict", f"""castellatedMesh true;
snap false;
addLayers false;
geometry
{{
    bentobox.stl {{ type triSurfaceMesh; name bentobox; }}
    boxRegion {{ type searchableBox; min ({bx[0] - 3} {bx[2] - 12} {z0 - 1}); max ({bx[1] + 3} {bx[3] + 3} {bx[5] + 3}); }}
    outletRegion {{ type searchableBox; min ({bx[0] - 50} {ox[1] - 15} {z0 - 1}); max ({bx[0]} {ox[2] + 15} {ox[4] + 20}); }}
    coverRegion {{ type searchableBox; min ({bx[0] - 10} {bx[2] - 10} {bx[5] - 10}); max ({bx[1] + 10} {bx[3] + 10} {bx[5] + 25}); }}
}}
castellatedMeshControls
{{
    maxLocalCells 6000000; maxGlobalCells 30000000; minRefinementCells 0; maxLoadUnbalance 0.10;
    nCellsBetweenLevels 3;
    features ();
    refinementSurfaces {{ bentobox {{ level ({box_level} {box_level}); patchInfo {{ type wall; }} }} }}
    resolveFeatureAngle 30;
    refinementRegions
    {{
        boxRegion {{ mode inside; levels ((1e15 {box_level})); }}
        outletRegion {{ mode inside; levels ((1e15 1)); }}
        coverRegion {{ mode inside; levels ((1e15 1)); }}
    }}
    locationInMesh (-100.13 0.17 150.31);
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

    def boxzone(name, boxes):
        for i, b in enumerate(boxes):
            acts.append(f"{{ name {name}Cells; type cellSet; action {'new' if i == 0 else 'add'}; source boxToCell; "
                        f"box ({b[0]} {b[2]} {b[4]}) ({b[1]} {b[3]} {b[5]}); }}")
        acts.append(f"{{ name {name}; type cellZoneSet; action new; source setToCellZone; set {name}Cells; }}")

    def hplate(name, b, z):                           # a horizontal plate: X and Y span, at Z
        acts.append(f"{{ name {name}; type faceZoneSet; action new; source searchableSurfaceToFaceZone; "
                    f"surfaceType searchablePlate; origin {v3((b[0], b[2], off_grid(z)))}; "
                    f"span {v3((b[1] - b[0], b[3] - b[2], 0))}; }}")

    boxzone("hepa", [nums["hepa"]])
    boxzone("carbon", nums["carbon"])
    if nums["sheet"]:
        boxzone("sheet", [nums["sheet"]])
    fz0, fz1 = nums["fan_z"]
    for i, (fx, fy) in enumerate(nums["fans"], 1):
        acts.append(f"{{ name fan{i}Cells; type cellSet; action new; source cylinderToCell; "
                    f"p1 ({fx} {fy} {fz0}); p2 ({fx} {fy} {fz1}); radius {nums['fan_r']}; }}")
        acts.append(f"{{ name fan{i}; type cellZoneSet; action new; source setToCellZone; set fan{i}Cells; }}")
        acts.append(f"{{ name fan{i}Faces; type faceSet; action new; source cellToFace; option outside; set fan{i}Cells; }}")
        acts.append(f"{{ name fan{i}Around; type faceZoneSet; action new; source setsToFaceZone; "
                    f"faceSet fan{i}Faces; cellSet fan{i}Cells; }}")
    ix = nums["inlet"]
    planes = {
        "inlet": ((ix[0], ix[1], ix[2], ix[3]), ix[4]),                  # the cover's window, air in
        "belowHepa": (nums["hepa_face"], nums["below_hepa"]),            # the ledge's opening, under the paper
        "carbonFloor": ((-18.5, 18.5, -48.5, 48.5), nums["carbon_floor"]),   # the housing floor's two openings
        "fanFloor": ((-19, 19, -51, 51), nums["fan_floor"]),             # the fan case floor's two holes
    }
    if nums["sheet"]:
        s = nums["sheet"]
        planes["sheetFace"] = ((s[0], s[1], s[2], s[3]), (s[4] + s[5]) / 2)
    for name, (b, z) in planes.items():
        hplate(name, b, z)
    # The duct's outlet: a vertical plate just inside its open -X face.
    acts.append(f"{{ name outlet; type faceZoneSet; action new; source searchableSurfaceToFaceZone; "
                f"surfaceType searchablePlate; origin {v3((ox[0] + 1.65, ox[1], ox[3]))}; "
                f"span {v3((0, ox[2] - ox[1], ox[4] - ox[3]))}; }}")
    write(case, "system/topoSetDict", "actions\n(\n    " + "\n    ".join(acts) + "\n);\n")

    co = coefficients()
    zone_names = ["hepa", "carbon"] + (["sheet"] if nums["sheet"] else [])
    opts = []
    for zone in zone_names:
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
    flowDir         (0 0 -1);
    thickness       {FAN['depth']};
    rho             {AIR['rho']};
    fanCurve        table ((0 {FAN['p_max']}) ({FAN['q_max']:.6g} 0));
}}""")
    write(case, "constant/fvOptions", "\n".join(opts) + "\n")
    write(case, "constant/transportProperties", f"transportModel Newtonian;\nnu {AIR['nu']};\n")
    write(case, "constant/turbulenceProperties",
          "simulationType RAS;\nRAS { RASModel kOmegaSST; turbulence on; printCoeffs on; }\n")

    walls = ("floor", "bentobox")

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

    c = nums["carbon"]
    fx, fy = nums["fans"][0]
    probes = {
        "ambient_side": (-60, 0, 150), "above_cover": (0, 0, bx[5] + 10), "funnel": (0, 0, nums["hepa_z"] + 35),
        "above_hepa": (0, 0, nums["hepa"][5] + 3), "below_hepa": (0, 0, nums["hepa_z"] - 0.8),
        "above_layer1": (0, 0, c[0][5] + 5), "above_layer3": (0, 0, c[2][5] + 5),
        "below_cmag": (0, -30, nums["carbon_floor"] - 3.5),
        "fan_in": (fx, fy, nums["fan_z"][1] + 3), "fan_out": (fx, fy, nums["fans_z"] - 3),
        "duct": (0, 0, 25), "jet": (-50, 0, 20),
    }
    if nums["sheet"]:
        s = nums["sheet"]
        probes["above_sheet"] = (0, -30, s[5] + 2.5)
        probes["below_sheet"] = (0, -30, s[4] - 4.5)
    (case / "probes.json").write_text(json.dumps(probes, indent=1), encoding="utf-8")
    zone_fos = [f"""pressureIn_{z}
    {{
        type volFieldValue; libs (fieldFunctionObjects); writeControl timeStep; writeInterval 25;
        log false; writeFields false; regionType cellZone; name {z}; operation volAverage; fields (p);
    }}""" for z in zone_names]
    faces = ["inlet", "outlet", *(f for f in planes if f != "inlet")]
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


def make_case(with_section, fine, cores):
    name = ("section" if with_section else "plain") + ("-fine" if fine else "")
    case = HERE / "cases" / name
    if case.exists():
        shutil.rmtree(case)
    case.mkdir(parents=True)
    nums = geometry(case, with_section)
    case_files(case, nums, fine, cores)
    win = str(case.resolve())
    wsl = "/mnt/" + win[0].lower() + win[2:].replace("\\", "/")
    print(f"case written: {case.relative_to(ROOT)}")
    print(f"run it:  wsl.exe -d Ubuntu -- bash -s -- {wsl} {name} < sim/bentobox-cfd/run_case.sh")
    return case


# ------------------------------------------------------------------ the lumped cross-check
LAYERS, LAYER_T = 3, 0.00535                          # the C-MAG's trays, standing (bentobox.layout.scad)
A_HEPA = 0.078 * 0.0368                               # the ledge's opening under the cartridge, m2
A_CARBON = 0.096 * 0.036                              # the C-MAG's inside, m2
A_SHEET = 0.1008 * 0.0408                             # the section's inside, m2


def network(dp_hepa_at_1=None, with_section=True, eps=None):
    """Two fans in parallel against the filters in series: the flow where the fans' pressure equals the
    filters' loss. Areas are the open faces each filter sees; every coefficient is the one the CFD uses."""
    d_c, f_c = ergun(eps or MEDIA["carbon"]["eps"], MEDIA["carbon"]["dp"])
    k_hepa = (dp_hepa_at_1 or MEDIA["hepa"]["dp_at_1"]) / A_HEPA          # Pa per (m3/s)
    k_sheet = MEDIA["sheet"]["dp"] / MEDIA["sheet"]["at"] / A_SHEET

    def loss(q):
        v_c = q / A_CARBON
        carbon = AIR["rho"] * LAYERS * LAYER_T * (AIR["nu"] * d_c * v_c + 0.5 * f_c * v_c ** 2)
        return k_hepa * q + carbon + (k_sheet * q if with_section else 0.0)

    def fans(q):
        return FAN["p_max"] * (1 - q / (2 * FAN["q_max"]))

    lo, hi = 0.0, 2 * FAN["q_max"]
    for _ in range(60):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if fans(mid) > loss(mid) else (lo, mid)
    return lo, fans(lo)


def lunchbox():
    """The LunchBox's own lumped model, from sim/lunchbox-cfd/, read as it is."""
    spec = importlib.util.spec_from_file_location("lunchbox_cfd", HERE.parent / "lunchbox-cfd" / "cfd.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def show_network():
    lb = lunchbox()
    bed = LAYERS * LAYER_T * A_CARBON * 1e6                                # cm3 of pellets
    print("operating point of the two fans: total flow, and the pressure they work against")
    print(f"{'HEPA grade':>12} {'voids':>6} {'BentoBox plain':>22} {'with section':>22} {'section costs':>14} {'LunchBox, insert':>22}")
    for grade, scale in (("H11-ish", 0.5), ("mid", 1.0), ("H13-ish", 5 / 3)):
        for eps in (0.40, 0.50):
            q0, p0 = network(MEDIA["hepa"]["dp_at_1"] * scale, False, eps)
            q1, p1 = network(MEDIA["hepa"]["dp_at_1"] * scale, True, eps)
            lb_q, lb_p = lb.network(lb.MEDIA["hepa"]["dp_at_1"] * scale, True)
            lb_txt = f"{lb_q * 1000:>9.2f} L/s {lb_p:>6.1f} Pa" if eps == 0.40 else ""
            print(f"{grade:>12} {eps:>6.2f} {q0 * 1000:>9.2f} L/s {p0:>6.1f} Pa {q1 * 1000:>9.2f} L/s {p1:>6.1f} Pa "
                  f"{100 * (1 - q1 / q0):>12.0f} % {lb_txt:>22}")
    print(f"carbon: BentoBox {LAYERS} trays of {LAYER_T * 1000:.2f} mm over {A_CARBON * 1e4:.1f} cm2 = {bed:.0f} cm3; "
          f"LunchBox one bed of 18.1 mm over {0.116 * 0.0716 * 1e4:.1f} cm2 = {0.116 * 0.0716 * 0.0181 * 1e6:.0f} cm3")
    q_bb, q_lb = network(with_section=True)[0], lb.network(with_insert=True)[0]
    print(f"time the air spends in the carbon (bed volume / flow, mid grade): BentoBox {bed / 1e6 / q_bb * 1000:.0f} ms, "
          f"LunchBox {0.116 * 0.0716 * 0.0181 / q_lb * 1000:.0f} ms")


if __name__ == "__main__":
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("what", choices=["case", "network"])
    ap.add_argument("--plain", action="store_true")
    ap.add_argument("--fine", action="store_true")
    ap.add_argument("--cores", type=int, default=14)
    a = ap.parse_args()
    if a.what == "network":
        show_network()
    else:
        make_case(not a.plain, a.fine, a.cores)
