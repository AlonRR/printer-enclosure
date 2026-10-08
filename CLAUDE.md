# Printer enclosure — brief for an agent working here

The Prusa MK3S+'s Lack enclosure: the chamber's sensors and firmware, the airflow plan, and the filter that
recirculates the chamber's air. [README.md](README.md) is the map; read the doc for the part you touch
before changing it.

## Archived: the LunchBox - `archive/lunchbox/`

GekoPrime's LunchBox (CC BY-SA 4.0), remixed for two 40 x 40 x 20 fans. Archived 8 Oct 2026, not built: Alon
chose the BentoBox remix (Q90). Its models, build page, checks and airflow case keep the repository's layout
under `archive/lunchbox/` and still run; don't change it. When a scad-tools bump touches what it uses
(`axes.scad`), run `uv run archive/lunchbox/scripts/lunchbox-checks.py all` with `OPENSCAD` set to the
nightly. [archive/lunchbox/README.md](archive/lunchbox/README.md) says what is there.

## Every model

- **The original STLs are not in git.** Each model's `original/README.md` names the files and their page.
  Without them only the parts drawn from scratch build; everything else fails loudly.
- `<box>.params.scad` holds every value set - the original's, measured by sectioning its STLs and tagged so,
  and the remix's. `<box>.layout.scad` derives the rest and holds the rules as asserts and warnings.
  `<box>.scad` draws the parts in the box's frame; each `<box>-<part>.scad` pins one part in its printing
  pose. `<box>-assembly.scad` holds the views and the fit checks.
- Report results with their totals ("12 of 12"). A new fit check gets a positive control in the same change:
  one that breaks one side of the fit, trips no assert, and must be caught.
- To measure an original again: `uv run scad-tools/scripts/stl-inspect.py` (sections, bounds, the 3MF's
  print orientation).

## The BentoBox - `models/bentobox/`

ThrutheFrame's BentoBox v2.0 (CC BY-NC-SA 4.0) with its C-MAG carbon magazine: the chamber's filter, the
remix the build will print (Q90, 8 Oct 2026). [docs/bentobox-scrubber.md](docs/bentobox-scrubber.md) is its
page. The originals are not in git (`original/README.md`), every value is in `bentobox.params.scad`, and
**before calling a change done**, with `OPENSCAD` set to an OpenSCAD nightly (its Manifold backend handles
the large meshes in seconds; under the 2021.01 release every control reads BLIND):

```sh
uv run scripts/bentobox-checks.py all              # every fit empty, every positive control caught
uv run scripts/bentobox-checks.py figures --write  # the pictures in docs/bentobox/, if a view changed
sh scad-tools/scripts/scad-check.sh models/bentobox/bentobox-<part>.scad
```

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
- **Other sessions work in scad-tools, and may work here.** Never edit scad-tools' own clone: change it in a
  worktree of its own on a branch, and land it by fast-forward. Before writing to any repo, look at its
  `git status` and newest commits; if another session is in it, work in a temporary clone or worktree on a
  branch, and fast-forward `main` only if it has not moved. Move the `scad-tools/` pin only to a commit that
  is already on GitHub, so that a GitHub clone of this repo still builds.
