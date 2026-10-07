# The scrubber — LunchBox, remixed

The chamber's recirculating filter is GekoPrime's [LunchBox](https://www.printables.com/model/468166):
air comes in through the grid on the front, passes HEPA paper and a bed of carbon pellets, goes down a
channel at the back, and the fans underneath blow it out at the front. It takes three 40 mm fans; this
build runs two 40 × 40 × 20 mm Delta EFB0412VHD, 12 V, with a tach wire each.

The remix adds four things and leaves the originals as they are, apart from tabs:

![The stack pulled apart: lid, its gasket, the body, a gasket, the insert, a gasket, the fan section with the blank in its middle bay](lunchbox/exploded.png)

| | What it does | File |
|---|---|---|
| **Insert** | A section between the body and the fan section, holding a flat filter sheet that stops carbon dust reaching the fans. Its top is the fan section's lip and its bottom the body's groove, so it drops into any LunchBox. | [`lunchbox-insert.scad`](../models/lunchbox/lunchbox-insert.scad), or [`lunchbox-insert-plain.scad`](../models/lunchbox/lunchbox-insert-plain.scad) without tabs |
| **Gaskets** | TPU. A ring for the lid. For each joint at the fans, a sheet that is solid under the HEPA paper and over the fans — the paper's bottom edge sits on it, and the fans get air only through the carbon — and open behind, where the air goes down. | [`lunchbox-gasket-lid.scad`](../models/lunchbox/lunchbox-gasket-lid.scad), [`lunchbox-gasket-fans.scad`](../models/lunchbox/lunchbox-gasket-fans.scad) |
| **Blank** | Closes the fan section's middle bay: two fans, one in each outer bay. | [`lunchbox-blank.scad`](../models/lunchbox/lunchbox-blank.scad) |
| **Tabs** | Two on each short end of the fan joint, clamped by an M3 screw into a nut that slides into a slot. Added to the original body and fan section. The lid needs none: its own two screws clamp its gasket. | [`lunchbox-body.scad`](../models/lunchbox/lunchbox-body.scad), [`lunchbox-fans.scad`](../models/lunchbox/lunchbox-fans.scad) |

**Not printed yet.** Every fit is checked against the original's STLs (see *Checking it*), not yet
against printed parts.

## The insert

![The insert from above: solid at the front, the cavity at the back with the grid, the lip round it, the tabs at the ends](lunchbox/insert-top.png)

The front of it is solid: it takes the place of what held the HEPA paper and the fans down. The back is
open, under the body's channel. The sheet lies on a grid at the bottom of that cavity, with 5 mm of air
above it, so the air coming down the 14 mm channel spreads forward over the whole sheet: 28 cm² of filter,
where the channel's own opening is 16 cm².

![A section through the stack at the middle bay: the air comes down the channel at the back, through the insert's sheet, onto the fan section's curved floor and forward into the fans](lunchbox/section.png)

**The sheet:** polyester filter floss, about 5 mm thick loose, cut to **115 × 25 mm** — a little over the
cavity, so it seals at its edges. It is there for carbon dust, which is coarse; it needs to be open, not
fine. Flat HEPA paper would be the wrong thing here: unpleated, it would choke the fans. Change the sheet
when it turns grey.

![The insert from below: the groove the fan section's lip seats in, the grid](lunchbox/insert-bottom.png)

## Printing

Every part's file draws it in the pose it prints in. No supports, no brim: the tabs that face down while
printing stand on a 45° support of their own, and the nut slots' roofs are short bridges.

| Part | Material | Count | Time | Filament |
|---|---|---|---|---|
| Insert | ASA | 1 | 2 h 24 m | 26 g |
| Gasket, fans | TPU 95A | 2 with the insert, 1 without | 1 h 2 m | 6 g |
| Gasket, lid | TPU 95A | 1 | 8 m | 1 g |
| Blank | ASA | 1 | 1 h 6 m | 9 g |
| Body, with tabs | ASA | 1 | 13 h 19 m | 126 g |
| Fan section, with tabs | ASA | 1 | 4 h 13 m | 45 g |

Times and weights are PrusaSlicer's, at 0.2 mm with the house profile `0.2mm QUALITY @MK3 - no skirt, no
brim, no crossing perimeter`, as [`scad-check.sh`](https://github.com/AlonRR/scad-tools) slices them.
Print the lid, `filter_lid_110x74x21.stl`, and the HEPA frame, `furnace_filter.stl`, as they come.

## Hardware

| Quantity | Item |
|---|---|
| 4 | M3 × 30 socket head cap screw — the fan joint, through the insert |
| 4 | M3 hex nut, ISO 4032 |
| 2 | M3 × 20 screw — the lid's own two, into the body's 3 mm holes |
| 2 | 40 × 40 × 20 mm 12 V fan |
| 1 | polyester filter floss, 115 × 25 mm |

Without the insert, the fan joint takes M3 × 16 instead. The lid's screws go 9–12 mm into the body's
bosses through the lid and its gasket; the holes are at least 12.5 mm deep.

## Putting it together

1. **Fan section:** a fan in each outer bay, blowing out of the front, and the blank in the middle bay,
   its closed face at the front. The wires leave by the opening in the floor's back right corner, as you
   face the front, which runs out under the end wall. Slide a nut into each of its four tabs.
2. **A fans gasket** on its rim, the ears over the tabs.
3. **The insert,** lip up, and the sheet on its grid.
4. **The second fans gasket** on the insert.
5. **The body,** with the HEPA paper in its frame pushed up into the holder from below. Screw the stack
   together with the four M3 × 30, down through the body's tabs and the insert into the nuts.
6. **Carbon** in from the top, through the funnel.
7. **The lid:** its gasket on the rim, the lid, and its two M3 × 20.

## Checking it

The model's rules are asserts and warnings in [`lunchbox.layout.scad`](../models/lunchbox/lunchbox.layout.scad).
The fits are checked against the original's STLs, which have to be in
[`models/lunchbox/original/`](../models/lunchbox/original/):

```sh
OPENSCAD="<the OpenSCAD nightly>" uv run scripts/lunchbox-checks.py all
```

It intersects every pair of parts that meet — the insert with the body, the insert with the fan section,
the blank with its bay, each gasket with what passes through it, the fan joint's tabs — and the air's
way through the insert and into the plenum. Each must come out empty. Every check has a positive control,
something broken on purpose that it must catch, and the run fails if one passes unnoticed. The body is
an 8 MB mesh, so it needs the nightly, whose Manifold backend does in seconds what the 2021.01 release
does in hours.

[`lunchbox.params.scad`](../models/lunchbox/lunchbox.params.scad) holds the original's dimensions, measured
by sectioning its STLs, and every setting of the remix.

## Credit and licence

LunchBox is © GekoPrime, under [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/). The remix
— the models in [`models/lunchbox/`](../models/lunchbox/) and the pictures in [`lunchbox/`](lunchbox/) — is
under CC BY-SA 4.0 too.
