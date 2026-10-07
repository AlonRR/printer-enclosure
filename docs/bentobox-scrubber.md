# The other scrubber — BentoBox v2.0, with the C-MAG

ThrutheFrame's [BentoBox v2.0](https://www.printables.com/model/272525) is the other filter weighed for the
chamber, against the [LunchBox](lunchbox-scrubber.md). It is a stack of parts, each held to the next by four
magnets and a tongue in a groove. Air comes in through the cover on top and passes a HEPA cartridge. Then it
goes through the C-MAG, a cartridge that holds the carbon pellets in three thin trays, one above the
other. Two 40 mm fans in the fan case pull it down and blow it into the duct, which turns it out of one long
side, at the floor. It is built for the two Delta EFB0412VHD this build has, 40 × 40 × 20 mm.

![The stack pulled apart: the cover, the HEPA holder, the carbon housing with the C-MAG in it, the section, the fan case, the duct](bentobox/exploded.png)

**It needs bought HEPA:** an 80 × 40 × 15 mm cartridge, which rests on a ledge in its holder. The HEPA paper
this build already has is pleated 20 mm deep and does not fit.

The remix adds one part, and changes nothing of the original:

| | What it does | File |
|---|---|---|
| **Section** | Goes between the carbon housing and the fan case, holding a flat filter sheet that stops carbon dust reaching the fans. Its top is the fan case's tongue and its bottom the housing's groove, with the same magnets, so it drops into any BentoBox v2.0 stack. | [`bentobox-section.scad`](../models/bentobox/bentobox-section.scad) |

**Not printed yet.** Every fit is checked against the original's STLs (see *Checking it*), not yet against
printed parts.

## The C-MAG

The carbon goes in the C-MAG, not loose in the housing. The C-MAG is two halves that close on four grills.
Lying open, the grills stand across it and make three trays; the user guide says to fill each to a line
moulded inside it, 9 mm deep. Closed and stood on end in the housing, each tray's pellets fall onto the grill
below them and spread over the whole of the C-MAG's inside. That makes three layers, each about **5.35 mm
deep, one above the other**: about 55 cm³ of carbon in all. The LunchBox's bed holds 150 cm³.

**Filled to the top instead**, the C-MAG holds 222 cm³, and the airflow simulation says that costs a
seventh of the flow (see *The air through it*). The author fills it thin for the airflow; here the HEPA
cartridge, not the carbon, is what holds the air back.

The grills are solid plates in their STL; the slicer settings in the author's project turn them into a
honeycomb (the project's plate 3). Print them from the project, not from the STL alone.

## The section

![The section from above: the grid at its bottom, the tongue round its top, a magnet hole at each corner](bentobox/section-top.png)

The sheet lies on a grid at the section's bottom, with 5 mm of air above it. The carbon housing's floor has
an opening over each fan only, and that air spreads over the whole sheet before it goes through. Below the
grid is the fan case, with 11 mm of air above the fans.

**The sheet:** polyester filter floss, about 5 mm thick loose, cut to **42 × 102 mm**: a little over the
section's inside, 40.8 × 100.8, so it seals at its edges on the ledge round the grid. It is there for carbon
dust, which is coarse, so it needs to be open, not fine. Change it when it turns grey.

![The section from below: the groove the fan case's tongue seats in, the magnet holes, the grid](bentobox/section-bottom.png)

**Magnets:** eight more, 4 × 2 mm like the rest, four in each face. Set the top four's poles as the fan
case's top has them, and the bottom four's as the carbon housing's bottom: the section then meets each
neighbour the way the two of them met.

The groove is 1 mm from each magnet hole, and so it is in every BentoBox part. The section copies that
joint rather than changing it.

## Printing

Every part prints as the author's project lays it out; the section prints as its file draws it, bottom
down. No supports, no brim.

| Part | Material | Count | Time | Filament |
|---|---|---|---|---|
| Section | ASA | 1 | 1 h 43 m | 16 g |

Time and weight are PrusaSlicer's, at 0.2 mm with the house profile `0.2mm QUALITY @MK3 - no skirt, no
brim, no crossing perimeter`, as [`scad-check.sh`](https://github.com/AlonRR/scad-tools) slices them.

## The air through it

An airflow simulation of the whole stack, standing on the chamber's floor with the chamber's air round it:
OpenFOAM, the two Deltas on their published curve, the filters as resistances, on the same assumptions
as [the LunchBox's](lunchbox-scrubber.md#the-air-through-it). How it is built and every assumption in it:
[`sim/bentobox-cfd/`](../sim/bentobox-cfd/README.md). The HEPA cartridge's grade is not known, and it sets
the flow more than anything else: the numbers are for a mid-grade one.

![A cut across the box through a fan: the air comes in at the cover, goes down through the HEPA cartridge and the C-MAG's trays, through the fan, and the duct turns it out along the floor](bentobox/cfd/side-fan.png)

| | As designed | With the section | Section, trays full |
|---|---|---|---|
| Air through the filters | 0.69 L/s | 0.68 L/s | 0.58 L/s |
| ...by the lumped model | 0.68 L/s | 0.65 L/s | 0.57 L/s |
| The HEPA cartridge takes | 91 Pa | 87 Pa | 74 Pa |
| The C-MAG takes | 6 Pa | 6 Pa | 20 Pa |
| The section's sheet takes | | 4 Pa | 3 Pa |
| Time the air spends in the carbon | 81 ms | 83 ms | 387 ms |
| The chamber's 180 L through it every | 4.4 min | 4.5 min | 5.2 min |

- **The HEPA cartridge sets the flow.** It takes about nine tenths of what the fans can give. Its paper sees
  only the 78 × 37 mm opening of its ledge, where the LunchBox's paper sees 70 cm², more than twice as
  much. So the BentoBox moves about half the LunchBox's air (1.3 to 1.5 L/s with its leaks sealed), and
  turns the chamber over every 4.5 minutes where the LunchBox does it every 2 to 2.5.
- **The section costs little**: 1.5 % of the flow in the simulation, 4 % by the lumped model. The two
  differ by about as much as the meshes of two cases do. Its sheet is evenly loaded, 0.14 m/s on average,
  except over the grid's two long ribs.

  ![The section's sheet from above: evenly loaded but for two strips over the grid's long ribs](bentobox/cfd/sheet.png)
- **Filling the C-MAG's trays full costs a seventh of the flow and quadruples the carbon**: 222 cm³ instead
  of 55, more than the LunchBox's 150, and the air spends nearly five times as long in it. The carbon is
  not what limits this box's flow, so carbon here is cheap.
- **No leaks.** The air in at the cover and out at the duct agree to within 2 %, and to 1 % on every plane
  between them, and nothing gets round the C-MAG. Unlike the LunchBox, there is nothing to seal.
- **None of its own air comes back in.** The duct throws the fans' air out along the floor, and the inlet
  is on top, 23 cm above it: in the air modelled round the box, none of it gets back there. A real
  chamber's walls turn it, so take it as a sign, not a number, as on the LunchBox's page.

  ![The fans' air, followed: it runs out along the floor and none of it rises to the cover](bentobox/cfd/tracer.png)

![Paths from the cover: down through the HEPA and the C-MAG, round the fans' hubs, out of the duct](bentobox/cfd/streamlines.png)

## How long the carbon lasts

An estimate, from [`scripts/carbon-life.py`](../scripts/carbon-life.py), which says where each number comes
from:

- **The carbon** is AP4-60: 4 mm pellets of steam-activated coal, so acid-free in the sense the BentoBox's
  author asks for. Its data sheet gives 450 kg/m³, and how much benzene it holds at four concentrations; an
  isotherm fitted to those, and carried over to styrene, says how much it holds at a chamber's concentration.
- **The fumes** from ASA: 0.5 to 3.5 mg of VOCs an hour of printing, 1.5 in the middle. UL's consolidated
  chamber tests put three quarters of all printers' totals under 1 mg/h and the worst cases, ASA among them,
  over 3. On a Prusa i3, ASA gave off under a quarter of ABS's styrene.
- **The chamber**: every fume goes through the carbon, which sits at 45 °C during an ASA print.

A scrubber keeps the chamber's air clean enough that the carbon only ever sees tens to hundreds of
micrograms of styrene a cubic metre, and there it takes up only 3 to 7 % of its own weight - not the 20 to
40 % a data sheet shows at high concentrations. The BentoBox moves less air, so its chamber runs about twice
as concentrated, and each gram of its carbon holds a little more.

| | Carbon | ASA print hours until it is spent | Range, 3.5 to 0.5 mg/h |
|---|---|---|---|
| LunchBox | 150 cm³, 68 g | about 1,850 | 1,000 to 3,900 |
| BentoBox, the C-MAG filled to its line | 55 cm³, 25 g | about 850 | 460 to 1,800 |
| BentoBox, its trays filled full | 222 cm³, 100 g | about 3,500 | 1,900 to 7,500 |

"Spent" is the carbon in equilibrium with the chamber's air. It lets more through well before then, so
change it sooner: when the smell comes back during a print. Damp air shortens it too - the carbon sits at
room humidity between prints - and whatever the extraction carries out lengthens it.

The lighter fumes, ASA's acrylonitrile among them, stick to plain carbon poorly, and either box lets some
of them through from the start. The HEPA is not what wears out: printing gives off particles by the
billion, but they weigh micrograms.

## Checking it

The model's rules are asserts and warnings in [`bentobox.layout.scad`](../models/bentobox/bentobox.layout.scad).
The fits are checked against the original's STLs, which have to be in
[`models/bentobox/original/`](../models/bentobox/original/):

```sh
OPENSCAD="<the OpenSCAD nightly>" uv run scripts/bentobox-checks.py all
```

It intersects the section with the carbon housing above it and the fan case below it, puts a magnet across
each joint through both parts' holes, and runs the air's way from the housing's floor openings down through
the section. Each must come out empty. Every check has a positive control, something broken on purpose that
it must catch, and the run fails if one passes unnoticed: 5 fits and 6 controls.

[`bentobox.params.scad`](../models/bentobox/bentobox.params.scad) holds the original's dimensions, measured
by sectioning its STLs, and every setting of the section.

## Credit and licence

BentoBox v2.0 is © ThrutheFrame, under [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/).
The remix — the models in [`models/bentobox/`](../models/bentobox/) and the pictures in [`bentobox/`](bentobox/)
— is under CC BY-NC-SA 4.0 too: free to use and share, not for sale.
