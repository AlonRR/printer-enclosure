# The filter wall

The enclosure's left wall, printed, is the chamber's one filter unit: IKEA's STARKVIND particle filter over a bed
of carbon and the Deltas, standing on the floor and under the roof between the Lack's legs. Why it is built so, and
the air it moves, are in [docs/bentobox-scrubber.md](../../docs/bentobox-scrubber.md), under *One panel and one
carbon row* and *Which panel*.

**The first increment: the layout, to scale.** The wall's parts are drawn as plain shells with their openings, in
the pieces they print in, and checked to fit the bed. Nothing here is ready to print: the joints, the seals and the
parts inside are not drawn yet (see *Not drawn yet*).

![The filter wall from inside the chamber: the Lack's legs, floor and roof faint; the filter row on top, the
cassette's land round the filter; the carbon row under it with the two outlets low](../../docs/diagrams/filter-wall/model-inside.png)

![The wall exploded: the ring's four corners and the carbon row's two trays out into the room, the cassette's four
corners and the filter in towards the chamber](../../docs/diagrams/filter-wall/model-exploded.png)

## The frame

Every part is drawn where it sits, in the wall's frame: **Y** along the wall from the front leg's inner face to
the back leg's, 450 mm; **Z** up from the floor, 460 mm to the roof; **X** across the wall, 0 at the Lack's edge and
**+ into the chamber**. The wall stands 50 mm in from the edge (the room on the floor and the roof, Q296) and 40 mm
out past it (D301, D303 a): its inner face at x = 50, its outer at x = -40.

## The parts

| Part | Pieces | Each, as it prints | What it is |
|---|---|---|---|
| The ring | 4 | 225 × 155 × 90 mm, 58 or 75 g | The filter row's frame: its top under the roof, its bottom on the carbon row, its ends at the legs, a flange between each end and the cassette. Open towards the room, and over the plenum behind the cassette: the port down to the carbon. |
| The cassette | 4 | 195 × 153 × 50 mm, 46 g | The filter's frame: a land as large as the row's inside, with a window the filter seals on, and the pocket's walls round the filter. |
| The carbon row | 2 | 225 × 150 × 90 mm, 172 g | One tray each side of the middle, each its own airway: the port from above, the carbon, its floss, a Delta, and the clean air's plenum with its outlet low in the inner face. |

Every piece prints on its inner face, along the wall on the bed's X: no support. About **0.8 kg of ASA** in all,
and about 0.45 kg more in the hatches still to come. scad-check sliced two at the print profile's two perimeters:
a cassette corner, 3 h 42 m, and a carbon tray, 14 h 23 m. The walls are drawn four perimeters wide, so print them
with four.

## The filter: measure it before the cassette is printed

IKEA lists the STARKVIND particle filter at 37 × 29 × 4 cm, in whole centimetres, with a PET frame and
polypropylene media. It says nothing of the frame's rim, which face takes the air, or how it seats (ikea.com, read
15 Oct 2026). So every number in [vitamins/starkvind.scad](vitamins/starkvind.scad) is `<<CONFIRM>>`, and:

- **The rows, the ring and the carbon trays do not move with the filter.** The filter row's height, the cassette's
  outline and its depth are set in the params, so a measured filter changes only the cassette's pocket and window.
- **The rows take a filter up to 378 × 294 mm, and 41 mm thick**, at a clearance of 4 mm a side. Past that, a guard
  stops the render and says which way it outgrew.
- **Five numbers settle the cassette:** the filter's outside length, height and thickness; its frame's rim on the
  face, where the media starts; and which face the arrow on its frame, if any, marks as taking the air.

## The files

Laid out as [scad-tools' project layout](../../scad-tools/docs/project-layout.md): render
[`filter-wall.scad`](filter-wall.scad); every value set is in
[`filter-wall.params.scad`](filter-wall.params.scad), and `draw` there names what is drawn - `wall`, `outside`,
`exploded`, or a printed piece by name.

| File | Holds |
|---|---|
| `vitamins/` | The bought parts' own numbers: the Lack, STARKVIND, the Deltas, the SPS30 and SGP41 (their numbers the BentoBox's, measured there) |
| `filter-wall.layout.scad` | The values more than one part reads, and each printed piece's box |
| `parts/` | The ring, the cassette, the carbon trays; `print.scad` turns each piece to the bed |
| `assembly/wall.scad` | The wall in the Lack, exploded, and the xyz arrows |
| `checks/` | The guards (asserts) and the report (echoes, the mass, the warnings) |

`uv run scripts/checks/filter-wall-checks.py` renders the echo, exports every piece as it prints and checks it is
one closed body on the bed, runs four controls that must each be refused by its guard, and draws the figures in
[docs/diagrams/filter-wall/](../../docs/diagrams/filter-wall/).

## Not drawn yet

In the order they come:

1. **How the pieces join**: flanges and screws into captive nuts at every seam, each seam sealed.
2. **What the carbon row holds**: the carbon's mesh floor, the floss's frame, the fans' plate cut for four, the
   sensors' mounts, the outlet's louvre.
3. **The hatches** on the room's side, through which the filter and the carbon change, and the filter's retainers.
4. **The purge**: a servo's damper and the 100 mm collar for the duct to the window, in the back tray (D300 a). No
   servo is chosen.
5. **The seals and the fixing**: the land's seal and the wall's round its edge - foam tape, or TPU printed in
   lengths, since the runs are longer than the bed - and how the wall fixes to the legs and lifts out (D291 a).
6. **The electronics' box**, on the outer face.
