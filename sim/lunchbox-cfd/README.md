# Airflow through the LunchBox scrubber

An OpenFOAM simulation of the air through the [LunchBox remix](../../docs/lunchbox-scrubber.md), built
from the same OpenSCAD model the parts are printed from, plus a lumped model of the same physics to
check it against. What it found is on the build page; this folder is how to run it again.

## What is modelled

- **The geometry** is `models/lunchbox/lunchbox-cfd.scad`: the assembled stack with its gaskets, the
  HEPA frame in its holder, the blank, and the two fans' frames and hubs, standing on the chamber's floor
  with the chamber's air in front of it. The model also echoes every zone below, so the case cannot
  disagree with it.
- **The mesh** is castellated (cubes, no surface fitting): 2 mm inside the box, or 1 mm with `--fine`,
  2 mm in front of it, 4 mm beyond.
- **Steady, incompressible, k-omega SST** (`simpleFoam`), air at 20 °C.
- **The filters are porous zones** (Darcy-Forchheimer):
  - **HEPA paper:** 300 Pa at 1 m/s through the paper, flowing front to back only. ⚠️ An assumption:
    the paper's grade is not known, and it decides the flow more than anything else. The lumped model
    shows the spread from 150 to 500 Pa.
  - **Carbon bed:** 4 mm pellets, 40 % voids, by the Ergun equation. Its perforated walls are part of
    the zone, not meshed.
  - **Filter floss** in the insert: 20 Pa at 0.75 m/s through 5 mm. ⚠️ An estimate for a G3-class pad.
- **The fans** are Delta EFB0412VHD, 40 x 40 x 20: a momentum source on their own curve, a straight line
  from 103.6 Pa at no flow to 4.77 L/s at no pressure (Delta's figures). Pushed back against the slot's
  step. Their bore and hub are estimated, not measured.
- **A tracer** is held at 1 in the fans and carried by the air: where it reads 0.3, 30 % of that air came
  straight out of the fans. The chamber beyond the domain counts as clean, so it is an upper bound on
  how much the scrubber re-filters its own output.

Not modelled: leaks round the gaskets, the filter's loading over time, the fans' real curve shape (a
straight line between the two published points), heat.

## Setting up (once)

OpenFOAM v2412 from conda-forge, in WSL, without root:

```sh
mkdir -p ~/.local/bin && cd ~/.local && curl -Ls https://micro.mamba.pm/api/micromamba/linux-64/latest | tar -xj bin/micromamba
~/.local/bin/micromamba create -y -n of -c conda-forge openfoam=2412
```

`run_case.sh` works round one fault of that package: its binaries look for the MPI library in
`lib/sys-mpich`, which it does not ship (it is in `lib/mpich-*`), and fall back to a dummy that cannot run
in parallel. The script links the one to the other, once.

## Running it

From the repository's root, with `OPENSCAD` set to an OpenSCAD nightly and the original STLs in
`models/lunchbox/original/`:

```sh
uv run --project sim/lunchbox-cfd sim/lunchbox-cfd/cfd.py network          # the lumped model, seconds
uv run --project sim/lunchbox-cfd sim/lunchbox-cfd/cfd.py case [--plain] [--fine] [--open-top] [--cores 7]
#   ... then the wsl.exe command it prints: meshes and solves in WSL, copies the results back
uv run --project sim/lunchbox-cfd sim/lunchbox-cfd/post.py insert [--out docs/lunchbox/cfd]
```

- `--plain`: the stack without the insert. `--fine`: 1 mm cells inside the box instead of 2 mm.
- `--open-top`: the 2.6 mm slot over the HEPA frame left open, as the original is built; by default it is
  sealed, as by a strip on the frame's top. ⚠️ The slot is barely wider than a 2 mm cell: whether a coarse
  mesh opens it depends on where the cells fall, which is why it is decided here and not left to the mesh.
- `--cores`: the MPI ranks, 14 by default; 7 each runs two cases side by side.

A 2 mm case solves in about 20 minutes. `cases/` holds the generated cases and their results and is not
committed; the pictures and summaries the build page quotes are in `docs/lunchbox/cfd/`.

## What a result must pass before it is quoted

- **Settled:** each flow's drift over the last quarter of the run, in `summary.json`, under 1 %.
- **Mass balances:** air in at the grid plus every leak equals air out at the fans. `post.py` adds up the
  flow across a plane outside each face of the box (`inflow_by_face_L_s`) - that is how the wire hole's
  second opening, under the back wall, was found.
- **Every flow split by where it goes** - through the HEPA paper, beside its frame, over it - on planes
  clipped to each region, not averaged over a whole cut.
- **The sheet's pressure drop matches its own model** (10.1 Pa in the run, 9.2 by the floss coefficient at
  its mean speed), and **the total flow agrees with the lumped model** in `cfd.py network`.
