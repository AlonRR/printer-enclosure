# The BentoBox remix's model

Laid out as scad-tools' [project layout](https://github.com/AlonRR/scad-tools/blob/main/docs/project-layout.md)
says (Alon, 11 Oct 2026). What the remix is, how to print and assemble it and what was measured are on the
[build page](../../docs/bentobox-scrubber.md); this page is the files.

```
bentobox.scad          the model: includes the rest in order and draws what `draw` names. Render this one
bentobox.params.scad   every value set - what to draw, the assembled views' settings and the checks' switches too
vitamins/              the bought parts, each in its file: their own numbers, measured or by their standards
  fans.scad, fan-plug.scad (and the plug's model, for the checks), wire.scad, usb-c-trigger.scad (and the board's
  model), fasteners.scad, magnets.scad, hepa-cartridge.scad, hepa-paper.scad, carbon.scad
lib/helpers.scad       the modules and functions more than one part uses; they set no values and draw nothing alone
bentobox.layout.scad   the values more than one part reads; draws nothing
parts/                 the printed parts, each file its own values beside its geometry
  originals.scad       ThrutheFrame's and the Auto's STLs in the box's frame - never printed
  section.scad         the section: the original joint's version, and the sealed one
  joints.scad          the sealed joints: the outline with its tabs, brackets, collar, chamfer, bead; sealed_part()
  paper-frame.scad     the glue frame for your own HEPA paper, and the shelved clamp
  bottom.scad          the base, the bay's tray, the fan section
  carbon.scad, hepa.scad, cover.scad, cmag.scad, grommet.scad
  fan-mate.scad        the fans' plug mate - on hold, not to print, until the fan connector is settled
  samples.scad         the samples and the sample plates
  print.scad           every part as it prints: print_part(), whose names are draw's
assembly/
  stack.scad           the parts together: where each stands, and the drawings - stack, exploded, cut, the bottom,
                       the joints, the paper's frames. Render them to an image, never to an STL
  figures.scad         the build page's pictures: a drawing file that includes the model and adds the xyz arrows,
                       so no printed part loads axes.scad; scripts/checks/bentobox-checks.py renders it
checks/
  fits.scad            what the fit checks read: screws, nuts, beads, probes, drivers, and their own numbers
  guards.scad          the asserts that stop a render whose geometry is impossible
  report.scad          the warnings - builds, but compromised - and the echoes each part prints
  air.scad             the airflow simulation's view of the stack: a drawing file of its own, which includes the
                       model with draw = "none"; sim/bentobox-cfd/cfd.py renders it
original/              the originals' STLs, not in git: its README says where they come from
.check/                the part files scripts/tools/part-files.sh writes, and what scad-check.sh leaves - ignored
```

- **The include order is the value order.** OpenSCAD reads top-level values in order through the included files,
  and a value read before it is set is `undef`. The entry includes each file after every file whose values it
  reads; modules and functions can sit anywhere. A render shows no warnings.
- **An `import()` reads its path from the file it is written in.** The originals are imported in
  `parts/originals.scad`, so `orig_dir` is `../original/`.
- **Only the entry draws.** Its `draw` menu: a printed part's name draws it as it prints; the assembled views
  (`stack`, `exploded`, `cut`, `section_fig`, `cmag`, `frame`, `glue`, `clamp_print`, `paper_cut`, `glue_cut`,
  `bottom`, `joints`, `grommet_fig`, `fan_mate_fig`); the checks' views (`check_...`); and `none`, for a file that
  includes the model to draw its own. The checks script and the figures set it with `-D draw=...`. The two
  drawing files that include the model - `assembly/figures.scad` and `checks/air.scad` - draw their own on top.
- **Each printed part's own file** - the one scad-tools' `scad-check.sh` and `printables.py` take - is written by
  `sh scripts/tools/part-files.sh` into `.check/`; `scripts/tools/bentobox-print.sh` runs it, and builds there.
- **The module names are the old files'** (`carbon_sealed()`, `auto_base()`, `sealed_part()`): the checks script and
  the build page name them.

What stays where, and why:

- **The originals' measurements stay in the params**, in their own group, MEASURED: they are not bought parts but
  the model the remix redraws.
- **The derived values the joints and the bottom share stay in the layout** - the screws and nuts, the stack's
  heights, the joints' outline and tabs - since several parts read them. The values only one part reads are in its
  file: the fan mate's, the grommet's, the C-MAG's, the paper frame's, the bay's USB-C pocket.
- **The archived LunchBox stays in `archive/lunchbox/`**, as the repository's CLAUDE.md asks, rather than at the
  paths it had; and the airflow simulations stay in `sim/`, a project of their own.

Moved from four files - the params, the layout, the model and the assembly - on 11 Oct 2026 by a script that placed
every line of them in exactly one of these, but for the old includes, the menus merged into `draw`, and
`draw_model`, gone. Checked unchanged against them: all 25 parts and the airflow view both ways, by volume, area and
box under Manifold (whose facets vary from one render to the next); every part's echoes; the 44 fits' and 62
controls' lines; the airflow view's numbers; `pleat.py`'s clamp numbers; and the 13 pictures, pixel for pixel
against the old files rendered in the same run, auto-bottom's patch excepted, which varies as much between two
renders of the old files.
