# Printer enclosure — chamber air and airflow

The Prusa MK3S+ prints in a Lack enclosure. Closing it up is what lets ASA print well, and this repository
is how that is done safely: knowing what the air in the chamber, the printer's electronics bay and the
room actually does, and then moving that air — a filter recirculating it during a print, plus a small
extraction that keeps the chamber slightly below room pressure, so every leak flows inward.

It is step 5 of [ASA print quality](https://github.com/AlonRR/3d-printing-toolkit/blob/main/docs/asa-print-quality.md)
in the [3D-printing toolkit](https://github.com/AlonRR/3d-printing-toolkit), the last and largest item
there.

## Where it stands

- **Measuring:** in service since 11 Sep 2026 — [`firmware/chamber-c3.yaml`](firmware/chamber-c3.yaml),
  an ESP32-C3 with an AHT20 and a BMP280 in the chamber air, on ESPHome over MQTT.
- **The enclosure has been closed for every print since 19 Sep 2026.** An ASA print reached 45–46 °C
  on bed heat alone, inside ASA's 40–60 °C band.
- **Not done yet:** the electronics bay's reading with the box closed during an ASA print — the open
  number that matters most — and the fans with their interlock.

[`docs/chamber-sensor.md`](docs/chamber-sensor.md) is the full status and the index to the topic pages;
[`docs/chamber-airflow.md`](docs/chamber-airflow.md) is the filter and extraction build, and
[`docs/bentobox-scrubber.md`](docs/bentobox-scrubber.md) the filter itself: ThrutheFrame's BentoBox v2.0,
remixed, with a carbon-dust section, sealed joints, the BentoBox Auto's bottom and a screwed clamp for the build's own
HEPA paper. The LunchBox remix it was weighed against is archived in [`archive/lunchbox/`](archive/lunchbox/).

## What is where

| | |
|---|---|
| [`docs/chamber-sensor.md`](docs/chamber-sensor.md), [`docs/chamber-sensor/`](docs/chamber-sensor/) | the record and the decisions: sensors, the node, boards, WiFi, the SuperMini antenna, measurements, heating and airflow, the build order |
| [`docs/chamber-airflow.md`](docs/chamber-airflow.md) | the two-fan filter and extraction plan |
| [`docs/bentobox-scrubber.md`](docs/bentobox-scrubber.md), [`models/bentobox/`](models/bentobox/), [`scripts/bentobox-checks.py`](scripts/bentobox-checks.py), [`scripts/bentobox-auto-stl.py`](scripts/bentobox-auto-stl.py) | the filter: BentoBox v2.0 with its carbon magazine, a carbon-dust section for it, sealed joints, a screwed clamp for the build's own HEPA paper, the BentoBox Auto's bottom with nuts for its heat-set inserts, and its fit checks |
| [`sim/`](sim/) | the filter's airflow simulation, OpenFOAM, from its model |
| [`archive/lunchbox/`](archive/lunchbox/) | archived 8 Oct 2026, not built: the LunchBox remix it was weighed against - its parts, build page, fit checks and airflow simulation, as they were, and still working |
| [`scad-tools/`](https://github.com/AlonRR/scad-tools) | the shared OpenSCAD tools, a git submodule: `scad-check.sh`, and the xyz arrows the pictures use |
| [`firmware/chamber-c3.yaml`](firmware/chamber-c3.yaml) | the chamber node in service |
| [`firmware/bentobox.yaml`](firmware/bentobox.yaml), [`scripts/bentobox-circuit.py`](scripts/bentobox-circuit.py) | the filter's controller in the base's bay: the fans' switch and tach, over MQTT; and its circuit, drawn |
| [`firmware/chamber-baseline.yaml`](firmware/chamber-baseline.yaml), [`scripts/chamber-log.py`](scripts/chamber-log.py), [`data/chamber-baseline.csv`](data/chamber-baseline.csv) | the first enclosure test, steps 1 and 2 of the build order, and its data |
| `firmware/chamber-*-espnow.yaml`, `chamber-sensor-mini1.yaml`, [`espnow-c/`](firmware/espnow-c/), [`espnow-rssi/`](firmware/espnow-rssi/), [`scripts/chamber-serial-log.py`](scripts/chamber-serial-log.py) | the ESP-NOW attempt: ESPHome's component would not pass a packet, so it was tested in plain ESP-IDF |
| [`firmware/secrets.yaml.example`](firmware/secrets.yaml.example) | copy to `firmware/secrets.yaml`, which is gitignored, and fill in |

**The models need the [`scad-tools`](https://github.com/AlonRR/scad-tools) submodule.** Clone with it:

```sh
git clone --recursive https://github.com/AlonRR/printer-enclosure
```

A ZIP from GitHub comes without it: from the unpacked folder, fetch the version this repository is pinned
to. In PowerShell:

```powershell
$pin = (Invoke-RestMethod https://api.github.com/repos/AlonRR/printer-enclosure/contents/scad-tools).sha
Invoke-WebRequest "https://github.com/AlonRR/scad-tools/archive/$pin.zip" -OutFile scad-tools.zip
Remove-Item -Recurse -ErrorAction SilentlyContinue scad-tools
Expand-Archive scad-tools.zip . ; Rename-Item "scad-tools-$pin" scad-tools ; Remove-Item scad-tools.zip
```

or in a POSIX shell:

```sh
pin=$(curl -s https://api.github.com/repos/AlonRR/printer-enclosure/contents/scad-tools | sed -n 's/.*"sha": *"\([0-9a-f]*\)".*/\1/p')
rm -rf scad-tools && mkdir scad-tools && curl -sL "https://github.com/AlonRR/scad-tools/archive/$pin.tar.gz" | tar xz --strip-components=1 -C scad-tools
```

## Related

- [**air-quality-monitor**](https://github.com/AlonRR/air-quality-monitor) — the particle and VOC/NOx
  monitor that hangs outside the enclosure. It is planned to take over the chamber node's job, with the
  fume fans' control on pins it already reserves.
- [**3d-printing-toolkit**](https://github.com/AlonRR/3d-printing-toolkit) — the printer's profiles,
  design rules and running notes. This repository was split out of it, with its history, in October
  2026.

## Licence

Code — `firmware/`, `scripts/` and `sim/`, and the archive's — is MPL-2.0. The LunchBox remix —
`archive/lunchbox/models/lunchbox/` and its pictures in `archive/lunchbox/docs/lunchbox/` — is CC-BY-SA-4.0, as the [LunchBox](https://www.printables.com/model/468166) it builds
on is. The BentoBox remix — `models/bentobox/` and its pictures in `docs/bentobox/` — is
CC-BY-NC-SA-4.0, as [BentoBox v2.0](https://www.printables.com/model/272525) is, and the
[BentoBox Auto](https://makerworld.com/en/models/1882240) its bottom comes from. Everything else, the docs, the data and this README, is CC-BY-4.0. Every file states its own
licence, following [REUSE](https://reuse.software/): an `SPDX-License-Identifier` header, or an entry in
`REUSE.toml`. Full texts are in [`LICENSES/`](LICENSES/).

_Parts of this repository were drafted with the help of an LLM agent; reviewed and verified locally._
