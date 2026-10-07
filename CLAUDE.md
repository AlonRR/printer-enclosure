# Printer enclosure — brief for an agent working here

The Prusa MK3S+'s Lack enclosure: the chamber's sensors and firmware, the airflow plan, and the filter that
recirculates the chamber's air. [README.md](README.md) is the map; read the doc for the part you touch
before changing it.

## The LunchBox scrubber - `models/lunchbox/`

GekoPrime's LunchBox (CC BY-SA 4.0), remixed for two 40 x 40 x 20 fans: a carbon-dust insert, TPU gaskets,
a blank for the middle fan bay, and M3 tabs added to the originals.
[docs/lunchbox-scrubber.md](docs/lunchbox-scrubber.md) is the build page.

- **The original STLs are not in git.** `models/lunchbox/original/README.md` names the four files and their
  page. Without them only the insert, the gaskets and the blank build; everything else fails loudly.
- `lunchbox.params.scad` holds every value set - the original's, measured by sectioning its STLs and
  tagged so, and the remix's. `lunchbox.layout.scad` derives the rest and holds the rules as asserts and
  warnings. `lunchbox.scad` draws the parts in the box's frame; each `lunchbox-<part>.scad` pins one part
  in its printing pose. `lunchbox-assembly.scad` holds the views and the fit checks.
- **Before calling a change done**, with `OPENSCAD` set to an OpenSCAD nightly (its Manifold backend handles
  the 8 MB body in seconds):

  ```sh
  uv run scripts/lunchbox-checks.py all              # every fit empty, every positive control caught
  uv run scripts/lunchbox-checks.py figures --write  # the pictures in docs/lunchbox/, if a view changed
  sh scad-tools/scripts/scad-check.sh models/lunchbox/lunchbox-<part>.scad
  ```

  Report results with their totals ("12 of 12"). A new fit check gets a positive control in the same
  change: one that breaks one side of the fit, trips no assert, and must be caught.
- To measure the original again: `uv run scad-tools/scripts/stl-inspect.py` (sections, bounds, the 3MF's
  print orientation), from a scad-tools new enough to have it.

## The BentoBox - `models/bentobox/`

ThrutheFrame's BentoBox v2.0 (CC BY-NC-SA 4.0) with its C-MAG carbon magazine, weighed against the LunchBox
from 7 Oct 2026, and a carbon-dust section for it. [docs/bentobox-scrubber.md](docs/bentobox-scrubber.md) is
its page. It has the LunchBox's layout: the originals are not in git (`original/README.md`), every value is in
`bentobox.params.scad`, and `uv run scripts/bentobox-checks.py all` runs its fit checks and controls.

## The airflow simulations - `sim/`

One OpenFOAM case per box, built from its `*-cfd.scad`; each README says how to run it and what a result
must pass before it is quoted. The two are kept apart on purpose: changing one must not move the other's
published numbers. A porous zone must be snapped to the mesh (`sim/bentobox-cfd/README.md` says why).

## Rules for this repository

- Built for public release: no hostnames, private IPs, SSIDs, machine paths or procurement in any file.
- Commit subjects are `type(scope): summary`, at most 72 characters; `git commit -F <file>`.
- `REUSE.toml` and SPDX headers: every new file states its licence (`reuse lint` must pass). Each remix and
  its pictures carry the original's licence: the LunchBox's CC-BY-SA-4.0, the BentoBox's CC-BY-NC-SA-4.0.
  Code is MPL-2.0; other docs CC-BY-4.0.
- Pushes go to the `gitea` remote. The `github` remote is public: pushing there is the owner's call.
