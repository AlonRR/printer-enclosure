# The LunchBox remix - archived

GekoPrime's [LunchBox](https://www.printables.com/model/468166), remixed for two 40 x 40 x 20 mm fans: a
carbon-dust insert, TPU gaskets, a blank for the middle fan bay, and M3 tabs on the originals. Weighed against
the BentoBox from 7 Oct 2026; **archived 8 Oct 2026, not built** - the chamber's scrubber is the
[BentoBox remix](../../docs/bentobox-scrubber.md).

Everything keeps the repository's own layout under this folder, and still works:

| | |
|---|---|
| [`docs/lunchbox-scrubber.md`](docs/lunchbox-scrubber.md), [`docs/lunchbox/`](docs/lunchbox/) | the build page and its pictures |
| [`models/lunchbox/`](models/lunchbox/) | the models; the originals go in `models/lunchbox/original/` (its README says where from) |
| [`scripts/lunchbox-checks.py`](scripts/lunchbox-checks.py) | the fit checks and their positive controls |
| [`sim/lunchbox-cfd/`](sim/lunchbox-cfd/README.md) | the airflow simulation; the BentoBox's lumped model reads its own from here |

From the repository's root, with `OPENSCAD` set to an OpenSCAD nightly:

```sh
uv run archive/lunchbox/scripts/lunchbox-checks.py all
```

The models are CC-BY-SA-4.0, as the LunchBox is; the scripts and the simulation MPL-2.0.
