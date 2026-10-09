#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
# SPDX-License-Identifier: MPL-2.0
# /// script
# requires-python = ">=3.11,<3.14"
# dependencies = ["build123d==0.10.0", "ocp-gordon==0.2.0", "cadquery-ocp==7.8.1.1.post1"]
# ///
"""Strangwooduk's BentoBox Auto comes as one STEP file, and the models import STLs: this writes them. From
the repository's root:

  uv run scripts/bentobox-auto-stl.py [STEP]

STEP defaults to the one file in models/bentobox/original/ whose name has "Auto" in it and ends in .step.
Beside it, this writes:

  bentobox-auto-base.stl    the base: the duct, the wires' tube, and the bay for the electronics under it -
                            measured, not used: the remix draws its own
  bentobox-auto-fans.stl    the fan section
  bentobox-auto-plate.stl   the plate that closes the bay - not used: the remix's tray replaces it

The STEP's fourth solid, a spacer for a sensor between the HEPA holder and the carbon housing, is not used.
Each solid is found by its height, not by its place in the file, and written in the STEP's own frame;
models/bentobox/bentobox.params.scad says where each one goes in the box's.

Every STL is read back with scad-tools' mesh check before it counts. An open edge, an edge on more than two
faces or wound the same way twice, or more than one body fails the run (exit 1). Degenerate facets are only
reported: the slicer removes them as it loads the part.

The base's curved floor is one cylinder face whose seam OpenCASCADE's mesher cannot follow at a fine
tolerance: two of its edges are single points, and at 0.01 mm the mesher skips the face and leaves a hole in
the STL. At 0.05 mm and 0.2 rad it meshes whole, with 8 slivers of no width: two at those points, six in
the channel down the long wall at one end. The other two parts mesh cleanly at 0.01 mm.
"""
import sys
from pathlib import Path

from build123d import export_stl, import_step
from OCP.BRepTools import BRepTools

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "scad-tools" / "scripts"))
from scadtools import mesh_problems  # noqa: E402

ORIGINAL = ROOT / "models" / "bentobox" / "original"
# Each part: its height in the STEP, in mm, to 0.1; and the mesh's tolerance, linear (mm) and angular (rad).
PARTS = {
    "bentobox-auto-fans.stl": (34.6, 0.01, 0.1),
    "bentobox-auto-base.stl": (46.0, 0.05, 0.2),
    "bentobox-auto-plate.stl": (1.8, 0.01, 0.1),
}
FAILS = ("open edges", "edges on more than two faces", "edges wound the same way twice", "bodies")


def find_step(args):
    if args:
        return Path(args[0])
    found = [p for p in ORIGINAL.glob("*.step") if "auto" in p.name.lower()]
    if len(found) != 1:
        sys.exit(f"give the STEP's path: {len(found)} files in {ORIGINAL} look like it")
    return found[0]


def main(args):
    step = find_step(args)
    solids = import_step(str(step)).solids()
    by_height = {}
    for s in solids:
        bb = s.bounding_box()
        by_height.setdefault(round(bb.max.Z - bb.min.Z, 1), []).append(s)
    print(f"{step.name}: {len(solids)} solids, heights {sorted(by_height)}")
    ok = True
    for name, (height, tol, ang) in PARTS.items():
        match = by_height.get(height, [])
        if len(match) != 1:
            print(f"  {name}: {len(match)} solids {height} mm tall - expected one")
            ok = False
            continue
        solid = match[0]
        BRepTools.Clean_s(solid.wrapped)   # mesh afresh at this tolerance, not reuse an earlier one
        out = step.parent / name
        export_stl(solid, str(out), tolerance=tol, angular_tolerance=ang)
        found = mesh_problems(out)
        bad = {k: v for k, v in found.items() if k in FAILS}
        note = ", ".join(f"{k} {v}" for k, v in found.items()) or "one closed body"
        print(f"  {name}: {'FAIL ' if bad else ''}{note}")
        ok &= not bad
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
