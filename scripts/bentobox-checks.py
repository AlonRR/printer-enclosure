#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
# SPDX-License-Identifier: MPL-2.0
# /// script
# requires-python = ">=3.11"
# ///
"""The BentoBox remix's fit checks, against the original STLs. From the repository's root:

  uv run scripts/bentobox-checks.py fits       every fit check in models/bentobox/bentobox-assembly.scad
  uv run scripts/bentobox-checks.py controls   each check's positive control: one thing broken on purpose,
                                               which its check must catch
  uv run scripts/bentobox-checks.py all        both
  uv run scripts/bentobox-checks.py figures [--write]
                                               every picture in docs/bentobox/, each render's output read
                                               for errors - rendered aside, or over docs/ with --write

A fit check intersects two parts that may touch but must not overlap: OpenSCAD must write nothing, or a
solid of no volume. The originals must be in models/bentobox/original/ (its README says where from); a
missing one makes an import fail, which OpenSCAD reports only as a WARNING - so every render's output is
read, never only its exit code. OPENSCAD should name a build with the Manifold backend (the nightly).
Exit status: 0 everything as expected, 1 anything else.

The same checks as scripts/lunchbox-checks.py, for the other box; the two are kept apart so that each
reads on its own.
"""
import sys
import tempfile
import uuid
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "scad-tools" / "scripts"))
from scadtools import DEGENERATE, defines, describe, parallel, problems, render, stl_stats  # noqa: E402

ASSEMBLY = "models/bentobox/bentobox-assembly.scad"
BACKEND = ["--backend=manifold"]

# The joints as the originals have them - magnets, tongue and groove - are checked with sealed=false; the model's
# default is the sealed stack, whose joints are the check_seal_ ones.
UNSEALED = [("sealed", "false")]
FITS = [("check_section_carbon", UNSEALED), ("check_section_fans", UNSEALED), ("check_magnets_top", UNSEALED),
        ("check_magnets_bottom", UNSEALED), ("check_air", []),
        ("check_ring_holder", []), ("check_ring_opening", []), ("check_wedges_paper", []),
        ("check_ring_paper", []), ("check_caps_strips", []),
        ("check_auto_fans_base", []), ("check_auto_plate", []), ("check_auto_nuts", []), ("check_auto_nut_ways", []),
        ("check_auto_screws", []), ("check_auto_wires", []), ("check_auto_air", []),
        ("check_seal_j1", []), ("check_seal_j2", []), ("check_seal_j3", []), ("check_seal_beads", []),
        ("check_seal_screws", []), ("check_seal_nuts", []), ("check_seal_nut_ways", []), ("check_seal_access", [])]

# Each control breaks ONE side of its check's relationship - the section's feature against the original's
# fixed mesh, or against a probe built from the original's measurements - never both, so that the check
# could only pass by not looking. None may trip one of the model's asserts instead: that would prove the
# assert, not the check.
CONTROLS = [
    ("check_section_carbon", UNSEALED + [("tongue_h", "2.5")], "the section's tongue made taller than the housing's groove is deep"),
    ("check_section_fans", UNSEALED + [("groove_h", "1.2")], "the section's groove made shallower than the fan case's tongue is tall"),
    ("check_magnets_top", UNSEALED + [("mag_xy", "[23.5, 52.5]")], "the section's magnet holes moved 1 mm off the housing's"),
    ("check_magnets_bottom", UNSEALED + [("mag_xy", "[23.5, 52.5]")], "the same, against the fan case's"),
    ("check_air", [("in_w", "30")], "the section's inside narrowed into the openings' path"),
    ("check_ring_holder", [("ring_play", "-0.3")], "the ring made wider than the holder's pocket"),
    ("check_ring_opening", [("ring_beads", "6")], "the ring's walls thickened over the ledge's opening"),
    # The wedges' width is derived; overriding it moves the wedges and leaves the paper, drawn from its own values.
    ("check_wedges_paper", [("wedge_w", "4")], "the caps' wedges made wider than the paper's channels"),
    ("check_wedges_paper", [("tooth_w", "4")], "the caps' teeth from below made wider than theirs"),
    ("check_ring_paper", [("ring_strip_h", "12")], "the ring's strips made taller than the channel beside each flap"),
    ("check_caps_strips", [("strip_notch", "-0.3")], "the caps' teeth not cut back for the strips"),
    ("check_auto_fans_base", [("auto_fans_dz", "-30.5")], "the Auto's fan section set 0.5 mm down into its base"),
    ("check_auto_plate", [("plate_t", "3")], "the plate made 0.5 mm thicker than its recess is deep"),
    ("check_auto_plate", [("lobe_play", "-0.3")], "the base's pockets made smaller than the plate's lobes"),
    ("check_auto_nuts", [("nut_fit", "-0.3")], "the nuts' slots and pockets made narrower than a nut"),
    ("check_auto_nut_ways", [("nut_slot_out", "1")], "the plate's nut slots cut only 1 mm past their screws: no way in"),
    ("check_auto_nut_ways", [("pull_way", "9")], "the fans' nut pockets stopped in the Auto's bosses at the end walls"),
    ("check_auto_screws", [("screw_shift", "[1, 0]")], "the screws moved 1 mm off their holes"),
    ("check_auto_wires", [("wire_shift", "1.5")], "the wires moved 1.5 mm off the tube"),
    ("check_auto_air", [("post_clear_air", "false")], "the fan screws' posts left round, under the fans' openings"),
    # The sealed joints. collar_play narrows the upper parts' chamfers, not the collars; bead_side the grooves,
    # not the beads; bracket_h reaches the carbon housing's top brackets down over the section's screws.
    ("check_seal_j1", [("collar_play", "-0.4")], "the section's chamfer cut back less than the fan section's collar"),
    ("check_seal_j2", [("collar_play", "-0.4")], "the carbon housing's chamfer, against the section's collar"),
    ("check_seal_j3", [("collar_play", "-0.4")], "the HEPA holder's chamfer, against the carbon housing's collar"),
    ("check_seal_beads", [("bead_side", "-0.35")], "the grooves made narrower than the beads"),
    ("check_seal_screws", [("screw_shift", "[1, 0]")], "the joints' screws moved 1 mm off their holes"),
    ("check_seal_nuts", [("nut_fit", "-0.3")], "the joints' nut slots made narrower and lower than a nut"),
    ("check_seal_nut_ways", [("nut_slot_out", "1")], "the joints' nut slots cut short of the tabs' ends"),
    ("check_seal_access", [("bracket_h", "80")], "the carbon housing's brackets reaching down over the section's screws"),
    # A missing original makes every intersection empty, which reads as a pass: its import's WARNING must fail it.
    ("check_section_carbon", UNSEALED + [("carbon_stl", '"original/missing.stl"')], "the housing's STL missing - must be reported, not passed"),
    ("check_ring_holder", [("hepa_stl", '"original/missing.stl"')], "the holder's STL missing - must be reported, not passed"),
    ("check_auto_fans_base", [("auto_base_stl", '"original/missing.stl"')], "the Auto base's STL missing - must be reported, not passed"),
]
MISSING = "Can't open import file"

# The checks hold parts that meet face to face 0.01 mm apart (bentobox-assembly.scad, `sep`), so a good fit
# leaves NOTHING; DUST is only float noise.
DUST = 1e-3   # mm3


def run(view, settings, tmp):
    out = Path(tmp) / f"{view}-{uuid.uuid4().hex[:8]}.stl"
    _, log = render(out, ASSEMBLY, BACKEND + defines([("view", f'"{view}"'), *settings]))
    stats = stl_stats(out) if out.exists() else None
    return stats, problems(log, allowed=[DEGENERATE]), log


def fits():
    with tempfile.TemporaryDirectory() as tmp:
        results = parallel(lambda c: run(c[0], c[1], tmp), FITS)
    failed = 0
    for (view, settings), (stats, bad, _) in zip(FITS, results):
        label = f"{view} {' '.join(f'{k}={v}' for k, v in settings)}"
        if bad:
            verdict, failed = "FAIL  " + "; ".join(bad)[:200], failed + 1
        elif stats is None:
            verdict = "ok    empty"
        elif abs(stats["volume"]) < DUST:
            verdict = f"ok    dust ({stats['volume']:.5f} mm3)"
        else:
            verdict, failed = f"FAIL  {stats['volume']:.3f} mm3 overlap, in {describe(stats)}", failed + 1
        print(f"{label:40} {verdict}")
    print(f"fits: {len(FITS) - failed} of {len(FITS)} as they must be")
    return failed == 0


def controls():
    with tempfile.TemporaryDirectory() as tmp:
        results = parallel(lambda c: run(c[0], c[1], tmp), CONTROLS)
    failed = 0
    for (view, settings, what), (stats, bad, _) in zip(CONTROLS, results):
        if "missing" in what:
            caught = any(MISSING in b for b in bad)
            verdict = "ok    reported: " + MISSING if caught else "BLIND the missing file passed"
            failed += not caught
        elif bad:
            verdict, failed = "FAIL  " + "; ".join(bad)[:200], failed + 1
        elif stats is None or abs(stats["volume"]) < DUST:
            verdict, failed = "BLIND nothing found", failed + 1
        else:
            verdict = f"ok    caught, {stats['volume']:.3f} mm3"
        print(f"{view:22} {what:70} {verdict}")
    print(f"controls: {len(CONTROLS) - failed} of {len(CONTROLS)} caught")
    return failed == 0


# Every picture in docs/bentobox/: the view it shows, and the camera and settings it is rendered with.
FIGURES = {
    "exploded": [("view", '"exploded"')], "cut": [("view", '"cut"'), ("cut_x", "0")],
    "section-top": [("view", '"section"')], "section-bottom": [("view", '"section"'), ("axes_cam", "[235, 0, 30]")],
    "paper-frame": [("view", '"frame"'), ("explode", "25")], "paper-cap": [("view", '"cap"')],
    "paper-cut": [("view", '"paper_cut"')], "auto-bottom": [("view", '"bottom"'), ("explode", "28"), ("axes_cam", "[50, 0, 215]")],
    "joints": [("view", '"joints"'), ("explode", "22")],
}
CAMERAS = {
    "exploded": ["--imgsize=1200,1900", "--viewall", "--autocenter", "--camera=0,0,0,70,0,320,0"],
    "cut": ["--imgsize=1200,1900", "--projection=o", "--viewall", "--autocenter", "--camera=0,0,0,0,0,0,0"],
    "section-top": ["--imgsize=1400,900", "--viewall", "--autocenter", "--camera=0,0,0,55,0,30,0"],
    "section-bottom": ["--imgsize=1400,900", "--viewall", "--autocenter", "--camera=0,0,0,235,0,30,0"],
    "paper-frame": ["--imgsize=1400,1100", "--viewall", "--autocenter", "--camera=0,0,0,55,0,30,0"],
    "paper-cap": ["--imgsize=1200,800", "--viewall", "--autocenter", "--camera=0,0,0,55,0,30,0"],
    "paper-cut": ["--imgsize=1800,560", "--projection=o", "--camera=-8,11,0,0,0,0,118"],
    "auto-bottom": ["--imgsize=1400,1300", "--viewall", "--autocenter", "--camera=0,0,0,50,0,215,0"],
    "joints": ["--imgsize=1300,1800", "--viewall", "--autocenter", "--camera=0,0,0,62,0,30,0"],
}


def figures(write, names):
    """Each picture rendered to PNG - into a scratch folder, or over docs/bentobox/ with --write. A failed
    assert or import during a PNG export still exits 0 and writes a picture of nothing, so the output is read."""
    target = Path(__file__).resolve().parent.parent / "docs" / "bentobox"
    chosen = names or list(FIGURES)
    with tempfile.TemporaryDirectory() as tmp:
        folder = target if write else Path(tmp)
        folder.mkdir(parents=True, exist_ok=True)

        def one(name):
            out = folder / f"{name}.png"
            _, log = render(out, ASSEMBLY, ["--colorscheme=Tomorrow", *CAMERAS[name], *defines(FIGURES[name])])
            return out.exists(), problems(log) + [l for l in log.splitlines() if "Assertion" in l]

        results = parallel(one, chosen)
    failed = 0
    for name, (made, bad) in zip(chosen, results):
        verdict = "ok" if made and not bad else "FAIL  " + ("; ".join(bad) or "no picture")[:200]
        failed += verdict != "ok"
        print(f"{name:15} {verdict}{'  -> docs/bentobox/' + name + '.png' if write and verdict == 'ok' else ''}")
    print(f"figures: {len(chosen) - failed} of {len(chosen)} rendered clean")
    return failed == 0


if __name__ == "__main__":
    what = sys.argv[1] if len(sys.argv) > 1 else "all"
    if what == "figures":
        args = sys.argv[2:]
        sys.exit(0 if figures("--write" in args, [a for a in args if a != "--write"]) else 1)
    if what not in ("fits", "controls", "all"):
        sys.exit(__doc__)
    ok = True
    if what in ("fits", "all"):
        ok &= fits()
    if what in ("controls", "all"):
        ok &= controls()
    sys.exit(0 if ok else 1)
