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
