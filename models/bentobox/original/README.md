# The original BentoBox v2.0 files

The BentoBox models build on ThrutheFrame's **BentoBox v2.0**, which is not copied into this repository:
download it from its page, <https://www.printables.com/model/272525>, and put these files here, under the
names they download with:

| File | What it is |
|---|---|
| `fan duct BambuLab 20231017.stl` | the base the box stands on: it takes the fans' air and turns it out of one long side, at the floor |
| `fan case v1_28.stl` | the fan case: two 40 mm fans stand on its floor, blowing down into the duct |
| `carbon.stl` | the carbon housing the C-MAG stands in, with a floor that has an opening over each fan |
| `CMag Case 01 v5.stl`, `CMag Case 02 v5.stl` | the C-MAG, the carbon magazine: the two halves of a cartridge that holds the pellets in three thin trays |
| `hepa.stl` | the holder for an 80 × 40 × 15 mm HEPA cartridge, which rests on a ledge at its bottom |
| `cover_hemp.stl`, `cover_voronoi.stl` | the top cover, where the air comes in; two patterns, either one |
| `BentoBoxV2 20231017.3mf` | the author's project: how each part is printed, and the slicer settings that turn the C-MAG's grills into a honeycomb |

The parts were exported in place, in one frame: stacked, every one sits where it does in the assembled box.
`bentobox.layout.scad` maps that frame into the models' own.

The C-MAG's four grills (`net_infill x4.stl`) are not needed here. They are solid plates in the STL, and
only the slicer settings in the project make them a mesh.

BentoBox is © ThrutheFrame, under [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/).

## The bottom from the BentoBox Auto

The bottom the models use by default (`bottom = "auto"` in `bentobox.params.scad`) is from Strangwooduk's
**BentoBox Auto VOC Sensor system**, <https://makerworld.com/en/models/1882240>, a remix of ThrutheFrame's.
It comes as one STEP file: download it, put it here under the name it downloads with (`BentoBox+Auto.step`),
and write its parts as STLs, from the repository's root:

```sh
uv run scripts/bentobox-auto-stl.py
```

| File it writes | What it is |
|---|---|
| `bentobox-auto-base.stl` | the base, in place of the duct: the same duct with its floor raised over a bay for the electronics, and a tube down to the bay for the wires |
| `bentobox-auto-fans.stl` | its fan section: the fan case's top, with each fan screwed through the floor into the base, and a hole for the wires |
| `bentobox-auto-plate.stl` | the plate that closes the bay: not used, the remix's tray replaces it |

The STEP's fourth part, a spacer that holds a sensor between the HEPA holder and the carbon housing, is not
used. Its parts were not exported in place; `bentobox.params.scad` says where each one goes.

The BentoBox Auto is © Strangwooduk. MakerWorld lists it as BY-NC-SA, and as a remix of a
[CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/) work, it is under that licence too.
