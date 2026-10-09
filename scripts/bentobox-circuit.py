#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
# SPDX-License-Identifier: MPL-2.0
# /// script
# requires-python = ">=3.11"
# dependencies = ["schemdraw>=0.19", "matplotlib>=3.8"]
# ///
"""The BentoBox bay's circuit, drawn from this file into docs/bentobox/circuit.png:

  uv run scripts/bentobox-circuit.py

The pins are firmware/bentobox.yaml's; change one there and here together. Every +12 V, +5 V, 3V3 and ground
symbol is one net, and each tag joins the wire with the same name, so the drawing needs no long wires.
Every element takes the direction of the one before it, so each box and each part says its own.
"""
from pathlib import Path

import schemdraw
import schemdraw.elements as elm

OUT = Path(__file__).resolve().parent.parent / "docs" / "bentobox" / "circuit.png"
schemdraw.use("matplotlib")


def pin(name, side, slot, anchor):
    return elm.IcPin(name=name, side=side, slot=slot, anchorname=anchor)


def box(text, size, pins, fontsize=10):
    return elm.Ic(size=size, pins=pins).right().label(text, loc="center", fontsize=fontsize)


with schemdraw.Drawing(show=False) as d:
    d.config(fontsize=10, unit=2.2)

    # ---- power in: the USB-C trigger asks the charger for 12 V; the step-down makes the SuperMini's 5 V
    usb = box("USB-C PD\ntrigger, 12 V", (5.2, 1.8), [pin("12 V", "right", "2/2", "v"), pin("GND", "right", "1/2", "g")])
    d += usb.anchor("center").at((0, 1.0))
    d += elm.Line().at(usb.v).right(0.8)
    d += elm.Vdd().theta(0).label("+12 V")
    d += elm.Line().at(usb.g).right(0.8)
    d += elm.Ground().theta(0)

    buck = box("MP1584EN\nstep-down, 5 V", (5.0, 1.8), [
        pin("IN+", "left", "2/2", "ip"), pin("IN−", "left", "1/2", "im"),
        pin("OUT+", "right", "2/2", "op"), pin("OUT−", "right", "1/2", "om")])
    d += buck.anchor("center").at((0.4, -4.0))
    d += elm.Line().at(buck.ip).left(0.8)
    d += elm.Vdd().theta(0).label("+12 V")
    d += elm.Line().at(buck.im).left(0.8)
    d += elm.Ground().theta(0)
    d += elm.Line().at(buck.op).right(0.8)
    d += elm.Vdd().theta(0).label("+5 V")
    d += elm.Line().at(buck.om).right(0.8)
    d += elm.Ground().theta(0)

    # ---- the fans, in parallel on one low-side switch: their reds joined, and their blacks, in the fan section
    x1, x2, xd, top, bot = 9.0, 13.0, 18.4, 3.2, -2.6
    d += elm.Label().at((x1 - 1.2, top + 1.9)).label(
        "Fans: 2 × Delta EFB0412VHD-F00, 12 V 0.12 A each", loc="right", fontsize=9)
    d += elm.Line().at((x1, top)).right(xd - x1)
    d += elm.Vdd().at(((x1 + x2) / 2, top)).theta(0).label("+12 V")
    for i, (x, side) in enumerate(((x1, "left"), (x2, "right"))):
        f = box(f"Fan {i + 1}", (2.6, 3.0), [
            pin("red", "top", "1/1", "p"), pin("black", "bottom", "1/1", "n"), pin("", side, "2/3", "t")])
        d += f.anchor("p").at((x, top))
        d += elm.Line().at(f.n).down(f.n[1] - bot)
        d += elm.Line().at(f.t).theta(180 if side == "left" else 0).length(1.0).label("blue", fontsize=8)
        d += elm.Tag().theta(180 if side == "left" else 0).label(f"TACH {i + 1}", fontsize=9)
    d += elm.Line().at((x1, bot)).right(xd - x1)
    # flyback: band to +12 V
    d += elm.Schottky().at((xd, bot)).up().toy(top).label("1N5819\nflyback", loc="bottom", ofst=0.2, fontsize=9)
    xq = (x1 + x2) / 2
    d += elm.Dot().at((xq, bot))
    d += elm.Line().at((xq, bot)).down(0.8)
    q = elm.NFet().right().anchor("drain").label("IRLZ44N", loc="left", ofst=0.3, fontsize=9)
    d += q
    d += elm.Ground().at(q.source).theta(0)
    d += elm.Line().at(q.gate).right(0.5)
    d += (gate := elm.Dot())
    d += elm.Resistor().right().label("100 Ω")
    d += elm.Tag().right().label("GPIO10", fontsize=9)
    d += elm.Resistor().at(gate.center).down().label("10 kΩ", loc="bottom")
    d += elm.Ground().theta(0)

    # ---- the SuperMini: 5 V in, the switch's gate, each fan's tach through a Schottky, the outlet's I2C
    mini = box("ESP32-C3\nSuperMini", (5.0, 6.6), [
        pin("3V3", "left", "6/6", "v33"), pin("5V", "left", "5/6", "v5"), pin("GND", "left", "4/6", "g"),
        pin("GPIO10", "right", "6/6", "g10"), pin("GPIO3", "right", "5/6", "g3"), pin("GPIO4", "right", "4/6", "g4"),
        pin("GPIO5 SDA", "right", "3/6", "sda"), pin("GPIO6 SCL", "right", "2/6", "scl"),
        pin("GPIO8", "right", "1/6", "led")], fontsize=11)
    d += mini.anchor("center").at((26.0, 0.4))
    d += elm.Line().at(mini.v33).left(0.6)
    d += elm.Vdd().theta(0).label("3V3")
    d += elm.Line().at(mini.v5).left(1.8)
    d += elm.Vdd().theta(0).label("+5 V")
    d += elm.Line().at(mini.g).left(1.0)
    d += elm.Ground().theta(0)
    d += elm.Line().at(mini.g10).right(0.6)
    d += elm.Tag().right().label("GPIO10", fontsize=9)
    for a, n in ((mini.g3, 1), (mini.g4, 2)):
        # band towards the fan: the fan can pull the pin low, and nothing comes back when the switch is off
        d += elm.Schottky().at(a).right().label("1N5819", loc="top", fontsize=8)
        d += elm.Tag().right().label(f"TACH {n}", fontsize=9)
    run = 5.4
    d += elm.Line().at(mini.sda).right(run)
    sens = box("outlet sensor(s), D112:\nSGP41 (3V3), maybe\nSPS30 (5 V)", (5.2, 2.6), [
        pin("SDA", "left", "2/2", "sda"), pin("SCL", "left", "1/2", "scl")], fontsize=9)
    d += sens.anchor("sda").at((mini.sda[0] + run, mini.sda[1]))
    d += elm.Wire("-|").at(mini.scl).to(sens.scl)
    d += elm.Line().at(mini.led).right(0.6)
    d += elm.Label().label("the onboard LED, active-low", loc="right", fontsize=8)

    d += elm.Label().at((-2.2, -8.0)).label(
        "Four leads come down through the grommet: +12 V, the fans' joined blacks to the drain, TACH 1 and TACH 2 "
        "(D154). The tach pins use the C3's internal pull-ups.", loc="right", fontsize=9)
    d += elm.Label().at((-2.2, -8.7)).label(
        "Power the bay with the SuperMini's own USB-C unplugged: its 5V pin is the USB bus. Update it over the air.",
        loc="right", fontsize=9)
    d.save(str(OUT), dpi=140)

print("wrote", OUT.relative_to(OUT.parent.parent.parent))
