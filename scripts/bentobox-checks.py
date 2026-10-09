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

The same checks as archive/lunchbox/scripts/lunchbox-checks.py, for the archived box; the two are kept apart so that each
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
# The C-MAG stands in a housing of the original's height: its fit in the housing is checked with carbon = "cmag".
CMAG = [("carbon", '"cmag"')]
FITS = [("check_section_carbon", UNSEALED), ("check_section_fans", UNSEALED), ("check_magnets_top", UNSEALED),
        ("check_magnets_bottom", UNSEALED), ("check_air", []),
        ("check_clamp_holder", []), ("check_cover_holder", []), ("check_cover_magnets", []),
        ("check_cmag_housing", CMAG), ("check_cmag_halves", []), ("check_cmag_magnets", []), ("check_cmag_grills", []), ("check_clamp_frames", []), ("check_clamp_paper", []),
        ("check_clamp_opening", []), ("check_clamp_screws", []), ("check_clamp_nuts", []), ("check_clamp_nut_ways", []),
        ("check_auto_fans_base", []), ("check_auto_tray", []), ("check_tray_slot_walls", []), ("check_usb_board", []),
        ("check_grommet_halves", []), ("check_grommet_hole", []), ("check_auto_nuts", []), ("check_auto_nut_ways", []),
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
    ("check_clamp_holder", [("clamp_play", "-0.3")], "the clamp made wider than the holder's pocket"),
    ("check_clamp_frames", [("clamp_slot", "-0.4")], "the wedges and teeth made to meet through the paper's slot"),
    ("check_clamp_opening", [("rim_in", "-13")], "the lower frame's rim made to reach in over the air's way down"),
    ("check_clamp_screws", [("screw_shift", "[1, 0]")], "the clamp's screws moved 1 mm off their holes"),
    ("check_clamp_nuts", [("pull_fit", "-0.25")], "the clamp's nut seats made narrower than a nut"),
    ("check_clamp_nut_ways", [("clamp_way", "1")], "the clamp's nut ways stopped short of the lower frame's bottom"),
    # The wedges' width is derived; overriding it moves the wedges and leaves the paper, drawn from its own values.
    ("check_clamp_paper", [("wedge_w", "4")], "the clamp's wedges made wider than the paper's channels"),
    ("check_clamp_paper", [("tooth_w", "4")], "the clamp's teeth made wider than theirs"),
    ("check_clamp_paper", [("flap_off", "0")], "the half wedges' faces moved in onto the flaps' middles"),
    ("check_auto_fans_base", [("fans_drop", "0.5")], "the fan section set 0.5 mm down into its base"),
    ("check_auto_tray", [("tray_top", "14.3")], "the tray made 0.3 mm taller than the bay's roof"),
    ("check_tray_slot_walls", [("tray_screw_y", "51.4")], "the tray's screws moved 1 mm in, their slots' backs under the end walls' fillets"),
    ("check_usb_board", [("usb_shift", "[0, -1, 0]")], "the USB-C board moved 1 mm out, into the wall in front of it"),
    ("check_usb_board", [("usb_notch_w", "8.5")], "the socket's notch made narrower than the socket"),
    ("check_usb_board", [("usb_notch_r", "1.2")], "the socket's notch made lower than the socket"),
    ("check_grommet_halves", [("grommet_play", "-0.2")], "the grommet's key slot made smaller than its key"),
    ("check_grommet_hole", [("grommet_groove", "0.3")], "the floor's groove made shallower than the grommet's lip"),
    ("check_auto_nuts", [("nut_fit", "-0.3")], "the nuts' slots and pockets made narrower than a nut"),
    ("check_auto_nut_ways", [("tray_slot_past", "-3")], "the tray's nut slots stopped 3 mm inside the end faces: no way in"),
    ("check_auto_nut_ways", [("pull_rise", "3")], "the fans' nut pockets started 3 mm up their posts' undersides: no way in"),
    ("check_auto_nuts", [("pull_fit", "-0.25")], "the fans' nut seats made narrower than a nut"),
    ("check_auto_screws", [("screw_shift", "[1, 0]")], "the screws moved 1 mm off their holes"),
    ("check_auto_wires", [("wire_shift", "1.5")], "the wires moved 1.5 mm off the tube"),
    ("check_auto_air", [("post_clear_air", "false")], "the fan screws' posts left round, under the fans' openings"),
    # The sealed joints. collar_play narrows the upper parts' chamfers, not the collars; bead_side the grooves,
    # not the beads. The top joint's tabs back at the corners stand over the lower joints' screws; a short blade
    # brings the driver's handle down against the HEPA holder.
    ("check_seal_j1", [("collar_play", "-0.4")], "the section's chamfer cut back less than the fan section's collar"),
    ("check_seal_j2", [("collar_play", "-0.4")], "the carbon housing's chamfer, against the section's collar"),
    ("check_seal_j3", [("collar_play", "-0.4")], "the HEPA holder's chamfer, against the carbon housing's collar"),
    ("check_seal_beads", [("bead_side", "-0.35")], "the grooves made narrower than the beads"),
    ("check_seal_screws", [("screw_shift", "[1, 0]")], "the joints' screws moved 1 mm off their holes"),
    ("check_seal_nuts", [("nut_fit", "-0.3")], "the joints' nut slots made narrower and lower than a nut"),
    ("check_seal_nut_ways", [("nut_slot_out", "1")], "the joints' nut slots cut short of the tabs' ends"),
    ("check_seal_access", [("top_tabs", '"corners"')], "the top joint's tabs back at the corners, over the lower screws' heads"),
    ("check_seal_access", [("driver", "[4, 30, 30]")], "a 30 mm blade: the driver's handle down against the HEPA holder"),
    # A missing original makes every intersection empty, which reads as a pass: its import's WARNING must fail it.
    ("check_section_carbon", UNSEALED + [("carbon_stl", '"original/missing.stl"')], "the housing's STL missing - must be reported, not passed"),
    ("check_cover_holder", [("hepa_in_grow", "-0.5")], "the HEPA holder's inside made narrower than the cover's plug"),
    # The cover is drawn from the same mag_xy as the holder: moving it would move both. The cover is moved instead.
    ("check_cover_magnets", [("cover_shift", "[0, 0.5]")], "the cover moved 0.5 mm along, its magnet holes off the holder's"),
    ("check_cmag_housing", CMAG + [("cmag_shift", "[0.5, 0, 0]")], "the C-MAG moved 0.5 mm across, into the housing's wall"),
    # Both halves are cut from one body at cmag_split, and their magnets' holes share cmag_boss: the lid is moved.
    ("check_cmag_halves", [("cmag_lid_move", "[0, 0, -0.3]")], "the lid set 0.3 mm down into the tray"),
    ("check_cmag_magnets", [("cmag_lid_move", "[0.5, 0, 0]")], "the lid moved 0.5 mm along, its magnet holes off the tray's"),
    ("check_cmag_grills", [("cmag_grill_t", "1.7")], "the grills made thicker than their slots"),
    ("check_section_fans", UNSEALED + [("auto_fans_stl", '"original/missing.stl"')], "the Auto fan section's STL missing - must be reported, not passed"),
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
    "paper-frame": [("view", '"frame"'), ("explode", "25")], "clamp-print": [("view", '"clamp_print"')],
    "paper-cut": [("view", '"paper_cut"')], "auto-bottom": [("view", '"bottom"'), ("explode", "28"), ("axes_cam", "[50, 0, 215]")],
    "joints": [("view", '"joints"'), ("explode", "22")],
}
CAMERAS = {
    "exploded": ["--imgsize=1200,1900", "--viewall", "--autocenter", "--camera=0,0,0,70,0,320,0"],
    "cut": ["--imgsize=1200,1900", "--projection=o", "--viewall", "--autocenter", "--camera=0,0,0,0,0,0,0"],
    "section-top": ["--imgsize=1400,900", "--viewall", "--autocenter", "--camera=0,0,0,55,0,30,0"],
    "section-bottom": ["--imgsize=1400,900", "--viewall", "--autocenter", "--camera=0,0,0,235,0,30,0"],
    "paper-frame": ["--imgsize=1400,1100", "--viewall", "--autocenter", "--camera=0,0,0,55,0,30,0"],
    "clamp-print": ["--imgsize=1400,900", "--viewall", "--autocenter", "--camera=0,0,0,55,0,25,0"],
    "paper-cut": ["--imgsize=1800,600", "--projection=o", "--camera=-12,11,0,0,0,0,125"],
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
