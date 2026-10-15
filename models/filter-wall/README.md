# The filter wall

The enclosure's left wall, printed, is the chamber's one filter unit: IKEA's STARKVIND particle filter over a bed
of carbon and the Deltas, standing on the floor and under the roof between the Lack's legs. Why it is built so, and
the air it moves, are in [docs/bentobox-scrubber.md](../../docs/bentobox-scrubber.md), under *One panel and one
carbon row* and *Which panel*.

**The first increment: the layout, to scale.** The wall's parts are drawn as plain shells with their openings, in
the pieces they print in, and checked to fit the bed. Nothing here is ready to print: the joints, the seals and the
parts inside are not drawn yet (see *Not drawn yet*).

![The filter wall from inside the chamber: the Lack's legs, floor and roof faint; the filter row on top, the
filter in the cassette's pocket, open to the chamber; the carbon row under it with the two outlets low](../../docs/diagrams/filter-wall/model-inside.png)

![The wall exploded: the ring's four corners and the carbon row's two trays out into the room, the cassette's four
corners and the filter in towards the chamber](../../docs/diagrams/filter-wall/model-exploded.png)

## The frame

Every part is drawn where it sits, in the wall's frame: **Y** along the wall from the front leg's inner face to
the back leg's, 450 mm; **Z** up from the floor, 460 mm to the roof; **X** across the wall, 0 at the Lack's edge and
**+ into the chamber**. The wall stands 50 mm in from the edge (the room on the floor and the roof, Q296) and 40 mm
out past it (D301, D303 a): its inner face at x = 50, its outer at x = -40. The printer moves right to clear it
(Alon, 15 Oct 2026: Q307), and the filter comes out into the chamber, so it wants some 45 mm in front of it.

## The parts

| Part | Pieces | Each, as it prints | What it is |
|---|---|---|---|
| The ring | 4 | 225 × 155 × 90 mm, 132 or 148 g | The filter row's frame: its top under the roof, its bottom on the carbon row, its ends at the legs, a skin on the room's side, and a flange in the cassette's land plane between each end and the cassette. Open over the plenum behind the cassette: the port down to the carbon. |
| The cassette | 4 | 195 × 153 × 50 mm, 46 g | The filter's frame: a pocket open to the chamber, and at its back a land as large as the row's inside, with a window, that the filter seals on. |
| The carbon row | 2 | 225 × 150 × 90 mm, 172 g | One tray each side of the middle, each its own airway: the port from above, the carbon, its floss, a Delta, and the clean air's plenum with its outlet low in the inner face. |

Every piece prints along the wall on the bed's X, on the face it is open away from - a carbon tray on its inner
face, a ring corner on its skin, a cassette corner on its land: no support. About **1.1 kg of ASA** in all, and
some 0.15 kg more in the carbon row's hatch still to come. scad-check sliced three, one of each kind, at the print
profile's two perimeters: a cassette corner, 3 h 57 m and 44 g; a low ring corner, 9 h 49 m and 125 g; and a
carbon tray, 14 h 23 m and 167 g. The walls are drawn four perimeters wide, so print them with four.

## The filter changes from inside, and the air seals it

Alon, 15 Oct 2026: *"the filter should be inserted/changed from the inside. one less thing to seal. also then the
airflow pulls it into the seal strengthening the seal."* The fans draw from under the carbon, so the plenum
behind the cassette's land is below the chamber's pressure, and the air presses the filter onto the land's seal.
Retainers at the inner face only hold it in place, and carry no seal. The ring is closed on the room's side, so
the filter row has no hatch to seal.

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

1. **How the pieces join**: flanges and screws into captive nuts at every seam, each seam sealed. The cassette's
   land is a 2 mm plate 195 × 153 per corner, and the seal is pressed on it: ribs behind it, so it does not bow.
2. **What the carbon row holds**: the carbon's mesh floor, the floss's frame, the fans' plate cut for four, the
   sensors' mounts, the outlet's louvre.
3. **The filter's retainers** at the inner face, and **the carbon row's hatch** on the room's side, through which
   the carbon and the floss change.
4. **The purge**: a servo's damper and the 100 mm collar for the duct to the window, in the back tray (D300 a). No
   servo is chosen.
5. **The seals and the fixing**: the land's seal and the wall's round its edge, TPU printed in lengths, since the
   runs are longer than the bed, and joined (Alon, 15 Oct 2026: D306 b); and how the wall fixes to the legs and
   lifts out (D291 a).
6. **The electronics' box**, on the outer face.
