# Scripts

Each runs from the repository's root and finds it from its own path. The shared OpenSCAD tools - `scad-check.sh`,
`printables.py`, `scad-preview.sh`, `stl-inspect.py` - are [scad-tools'](https://github.com/AlonRR/scad-tools), in the
`scad-tools/` submodule. The airflow simulations are a project of their own, in [`sim/`](../sim/); the archived
LunchBox's scripts stay under [`archive/lunchbox/`](../archive/lunchbox/).

| Folder | What is in it |
|---|---|
| `checks/` | `bentobox-checks.py`: the BentoBox remix's fit checks, each with a positive control, and its pictures (`figures`); exits non-zero on a failure. `filter-wall-checks.py`: the filter wall's parts, each exported as it prints and checked on the bed, its guards' controls, and its figures |
| `analysis/` | `carbon-life.py`: how many print hours the carbon lasts, from its isotherm and the fumes' rates; `scrubber-sizing.py`: how large the HEPA's face and the carbon's bed must be for a flow, at each fan pressure; `candidates` and `wall` modes for bought filters and the filter wall |
| `figures/` | `bentobox-circuit.py`: the bay's circuit, drawn into `docs/diagrams/bentobox/`; `chimney-concept.py`: the chimney and its printed wall drawn to the enclosure, into `docs/diagrams/chimney/`; `filter-wall.py`: the filter wall's layout, into `docs/diagrams/filter-wall/` |
| `tools/` | `bentobox-print.sh`: every part built, checked and sliced; `bentobox-auto-stl.py`: the BentoBox Auto's STLs from its STEP; `chamber-log.py`, `chamber-serial-log.py`: the chamber sensor's readings logged from MQTT or its serial port |
