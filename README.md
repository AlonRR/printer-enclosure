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
[`docs/chamber-airflow.md`](docs/chamber-airflow.md) is the filter and extraction build.

## What is where

| | |
|---|---|
| [`docs/chamber-sensor.md`](docs/chamber-sensor.md), [`docs/chamber-sensor/`](docs/chamber-sensor/) | the record and the decisions: sensors, the node, boards, WiFi, the SuperMini antenna, measurements, heating and airflow, the build order |
| [`docs/chamber-airflow.md`](docs/chamber-airflow.md) | the two-fan filter and extraction plan |
| [`firmware/chamber-c3.yaml`](firmware/chamber-c3.yaml) | the chamber node in service |
| [`firmware/chamber-baseline.yaml`](firmware/chamber-baseline.yaml), [`scripts/chamber-log.py`](scripts/chamber-log.py), [`data/chamber-baseline.csv`](data/chamber-baseline.csv) | the first enclosure test, steps 1 and 2 of the build order, and its data |
| `firmware/chamber-*-espnow.yaml`, `chamber-sensor-mini1.yaml`, [`espnow-c/`](firmware/espnow-c/), [`espnow-rssi/`](firmware/espnow-rssi/), [`scripts/chamber-serial-log.py`](scripts/chamber-serial-log.py) | the ESP-NOW attempt: ESPHome's component would not pass a packet, so it was tested in plain ESP-IDF |
| [`firmware/secrets.yaml.example`](firmware/secrets.yaml.example) | copy to `firmware/secrets.yaml`, which is gitignored, and fill in |

## Related

- [**air-quality-monitor**](https://github.com/AlonRR/air-quality-monitor) — the particle and VOC/NOx
  monitor that hangs outside the enclosure. It is planned to take over the chamber node's job, with the
  fume fans' control on pins it already reserves.
- [**3d-printing-toolkit**](https://github.com/AlonRR/3d-printing-toolkit) — the printer's profiles,
  design rules and running notes. This repository was split out of it, with its history, in October
  2026.

## Licence

Code — `firmware/` and `scripts/` — is MPL-2.0; everything else, the docs, the data and this README, is
CC-BY-4.0. Every file states its own licence, following [REUSE](https://reuse.software/): an
`SPDX-License-Identifier` header, or an entry in `REUSE.toml`. Full texts are in [`LICENSES/`](LICENSES/).

_Parts of this repository were drafted with the help of an LLM agent; reviewed and verified locally._
