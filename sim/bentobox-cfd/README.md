# Airflow through the BentoBox v2.0 scrubber

An OpenFOAM simulation of the air through [BentoBox v2.0 with its C-MAG](../../docs/bentobox-scrubber.md),
with and without the remix's carbon-dust section, built from the OpenSCAD model the section is printed from.
Beside it is a lumped model of the same physics, which also prints the LunchBox's on the same assumptions.
It is built the way [`archive/lunchbox/sim/lunchbox-cfd/`](../../archive/lunchbox/sim/lunchbox-cfd/README.md) is, and that README's setup and checks
apply here unchanged. This one says what differs. What it found is on the build page.

## What is modelled

- **The geometry** is `models/bentobox/bentobox-cfd.scad`: the stack from the duct to the cover, the C-MAG
  standing in its housing, the two fans' frames and hubs, and the section if it is in. It stands on the
  chamber's floor with the chamber's air round it. The model also echoes every zone, so the case cannot
  disagree with it. Its header lists what is left out or closed, and why: the C-MAG's grills, the cover's
  pattern, and the C-MAG's 0.4 mm clearance.
- **The mesh** is castellated: 2 mm inside the box, or 1 mm with `--fine`; 2 mm round the cover and in front
  of the duct's outlet; 4 mm beyond.
- **Steady, incompressible, k-omega SST** (`simpleFoam`), air at 20 °C.
- **The filters are porous zones** (Darcy-Forchheimer), the LunchBox's media value for value, except:
  - **HEPA cartridge**, 80 × 40 × 15 mm, bought: 380 Pa at 1 m/s through its face. That is the LunchBox's
    300 Pa for a 19 mm pleated pack, scaled to 15 mm pleats, which hold 15/19 of the media. ⚠️ An
    assumption: its grade is not known, and it decides the flow more than anything else.
  - **The C-MAG's carbon**: three trays, each a 5.35 mm layer of 4 mm pellets standing on its grill. Filled
    lying open to the line moulded inside it, a tray's pellets spread over the whole of the C-MAG's inside
    once it stands. The Ergun equation, 40 % voids, as for the LunchBox. A bed one or two pellets deep packs
    looser than that, and `cfd.py network` shows 50 % beside it. Three thin layers resist exactly as one
    layer of their total depth would, so the model cannot see any benefit claimed for thin layers.
  - **The section's sheet**: filter floss, as in the LunchBox's insert.
- **The fans**: the same two Delta EFB0412VHD on their published curve, standing on the fan case's floor,
  blowing down.
- **A tracer** held at 1 in the fans, as for the LunchBox.

## Running it

From the repository's root, with `OPENSCAD` set to an OpenSCAD nightly and the originals in
`models/bentobox/original/`:

```sh
uv run --project sim/bentobox-cfd sim/bentobox-cfd/cfd.py network          # the lumped model, beside the LunchBox's
uv run --project sim/bentobox-cfd sim/bentobox-cfd/cfd.py case [--plain] [--fine] [--cores 7]
#   ... then the wsl.exe command it prints: meshes and solves in WSL, copies the results back
uv run --project sim/bentobox-cfd sim/bentobox-cfd/post.py section [--out docs/bentobox/cfd]
```

`--plain` is the stack as designed, without the section. A 2 mm case is about 380,000 cells; a 1 mm one,
`--fine`, 1.5 million, and it runs 2500 iterations.

## A porous zone's thickness is the mesh's, unless it is made not to be

A zone is the cells whose centres fall inside its box. A 15 mm HEPA zone on a 2 mm mesh therefore came out
16 mm thick in one case and 14 mm in the other, because the section raises everything above it by 13 mm
and moves the zone against the mesh. Its pressure drop moved by the same ±7 %, more than the section
itself costs. `cfd.py` now snaps every porous zone to the mesh's planes through it, and scales its
coefficients by the true thickness over the meshed one. `zones.json` in each case records the factors.

The LunchBox's case predates this. On its 2 mm mesh, its 19 mm HEPA zone is 18 mm thick, about 5 % light.
Its 1 mm check meshes it exactly.

## What a result must pass before it is quoted

The LunchBox's list, and:
- **Settled, read on the filters' side.** Here the flow creeps up to its value for a long time, because the
  HEPA cartridge takes nearly all the fans' pressure: at 1000 iterations it still moved 2.5 % over the last
  quarter, so a case runs 2000. Judge the drift on the planes the filtered air crosses - the cover, under
  the HEPA, the housing's floor, the sheet. The fan floor's and the duct's planes sit in the fans' wake and
  swing by 2 to 3 % however long it runs.
- **Nothing round the C-MAG**: `round_cmag_L_s` in `summary.json`, the flow down the band between the
  C-MAG's inside and the housing's outside, must be nil, since the model closes it.
- **Every flow plane agrees**: the cover, under the HEPA, the housing's floor, the fan case's floor and the
  duct's outlet carry the same air, unless `inflow_by_face_L_s` names where the difference goes in or out.
  That one sums a closed box 3 mm round the scrubber; it is a coarse locator, closing to a few per cent.
- **The mesh check**: the section's case on the 1 mm mesh, 1.50 million cells, 2500 iterations, 2 h 23 min
  on 14 cores (`summary-section-fine.json` in `docs/bentobox/cfd/`). The filtered flow comes out 3.5 % lower
  than on 2 mm, 0.653 L/s at the cover instead of 0.676, and equal to the lumped model's 0.654 within
  0.2 %; it drifted under 0.1 % over the last quarter on every filter-side plane, and those planes and the
  fan case's floor agree to 0.05 %. The duct's plane reads 1.5 % low, in the fans' wake as before.
- **A measuring plane must miss the cells' centres as well as their faces**: a face is caught when the
  line between its two cells' centres crosses the plane, so a plane through a row of centres catches two
  rows of faces, or part of them. The 1 mm run's plane through the sheet sat on its cells' centres, at
  90.5 mm, and read 0.90 L/s of the 0.65 that passes it; re-measured afterwards at 90.75 mm it reads the
  inlet's flow exactly, and the summary carries that value and says so. `off_grid()` now nudges a plane
  off both. A 2 mm case written again therefore has its planes under the HEPA and through the sheet a
  fraction of a millimetre from where the committed results measured them; the results stand.

## One pleat of your own paper: how many pleats the clamp should hold

[`pleat.py`](pleat.py) answers D143: how many pleats of the pre-folded HEPA paper the clamp should hold across
its 40.3 mm. More pleats put more paper in the air's way, so each square millimetre of it passes less air; but
the channels between the pleats narrow, and near each fold the two sheets touch, so that paper passes little.

```sh
uv run --project sim/bentobox-cfd sim/bentobox-cfd/pleat.py lumped     # the same, worked out by hand
uv run --project sim/bentobox-cfd sim/bentobox-cfd/pleat.py cases      # one case per count, grade and velocity
#   ... then the wsl.exe command it prints (from Git Bash, with MSYS_NO_PATHCONV=1): every case, 14 at a time.
#   The whole sweep takes about an hour: start it detached inside WSL (setsid nohup bash <cases>/run_pleats.sh
#   <cases> 14 &), not under a watcher that may end first. It runs the cases in list.txt, so a stopped sweep
#   resumes with a list of the cases that have no results/ yet.
uv run --project sim/bentobox-cfd sim/bentobox-cfd/pleat.py results --out docs/bentobox/cfd
```

- **The geometry** is half a pitch of the pack, 2-D, between symmetry planes through a top fold and a bottom
  fold, with 5 mm of air above and below; the paper's thickness, depth and the clamp's width come from the
  model. The paper is a porous band, its middle straight from fold to fold. Near a fold, where the band from
  each side overlaps, it is solid paper: a sharp fold of real paper is pressed shut there too.
- **The mesh** is 0.02 × 0.05 mm, about 20 cells across the paper. The band is the cells whose centres fall in
  it, and its coefficient is scaled by its true thickness over the meshed one, as the box's zones are. Before a
  case is written, a flood fill checks that no air gets from top to bottom without crossing paper; topoSet's
  count of the band's cells must equal the script's.
- **Laminar** `simpleFoam`: the channels' Reynolds number is under 100.
- **The paper's grade is not known**: HomeBox has it as "HEPA-grade", the fibre not stated. Three are run,
  100, 200 and 300 Pa across the flat paper at 5.33 cm/s, the velocity HEPA media are rated at; 300 is about
  a glass-fibre H13.
- **Each count** from 8 to 26, at three face velocities, 0.1, 0.2 and 0.35 m/s; the drop is fitted as
  a v + b v² and put into `cfd.py`'s lumped model of the box in place of the cartridge, over the n pleats'
  face between the clamp's wedges. The clamp builds up to 18 pleats: at 19 its half wedges come out under 3 mm.
- **The carbon** is compared the same way: the C-MAG filled to its line or full, or no C-MAG, the housing's
  whole inside filled to a depth on a grid, by the Ergun equation as for the box; its life by
  `scripts/carbon-life.py` at its middle emission.

A case's drop must have settled - its inlet pressure moving under 0.05 % over the last fifth of its
iterations; each case runs 800 - and the air in at the top must equal the air out at the bottom to 0.1 %. Left to
SIMPLE's residual control, the dense pleats' cases stopped after 80 to 120 iterations with their drop still moving
by up to 0.3 %, so none is stopped by residuals. The mesh check runs three counts again on half the cells' size.
