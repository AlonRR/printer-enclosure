#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
# SPDX-License-Identifier: MPL-2.0
# /// script
# requires-python = ">=3.11"
# ///
"""The LunchBox remix's fit checks, against the original STLs. From the repository's root:

  uv run scripts/lunchbox-checks.py fits       every fit check in models/lunchbox/lunchbox-assembly.scad
  uv run scripts/lunchbox-checks.py controls   each check's positive control: one thing broken on purpose,
                                               which its check must catch
  uv run scripts/lunchbox-checks.py all        both
  uv run scripts/lunchbox-checks.py figures [--write]
                                               every picture in docs/lunchbox/, each render's output read
                                               for errors - rendered aside, or over docs/ with --write

A fit check intersects two parts that may touch but must not overlap: OpenSCAD must write nothing, or a
solid of no volume. The originals must be in models/lunchbox/original/ (its README says where from); a
missing one makes an import fail, which OpenSCAD reports only as a WARNING - so every render's output is
read, never only its exit code.

The originals' body is an 8 MB mesh: OPENSCAD should name a build with the Manifold backend (the nightly),
which this script asks for. Exit status: 0 everything as expected, 1 anything else.
"""
import sys
import tempfile
import uuid
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "scad-tools" / "scripts"))
from scadtools import DEGENERATE, defines, describe, parallel, problems, render, stl_stats  # noqa: E402

ASSEMBLY = "models/lunchbox/lunchbox-assembly.scad"
BACKEND = ["--backend=manifold"]

# Each fit check, both with the insert's tabs and without, where the tabs take part.
FITS = [("check_insert_body", [("tabbed", "true")]), ("check_insert_body", [("tabbed", "false"), ("insert_tabs", "false")]),
        ("check_insert_fans", [("tabbed", "true")]), ("check_insert_fans", [("tabbed", "false"), ("insert_tabs", "false")]),
        ("check_blank", []), ("check_gasket_fans", []), ("check_gasket_insert", []), ("check_gasket_lid", []),
        ("check_tabs_fans", []), ("check_air_insert", []), ("check_air_plenum", [])]

# Each control breaks ONE side of its check's relationship - a modelled feature against the original's
# fixed mesh, or against a probe built from the original's measurements - never both, so that the check
# could only pass by not looking. None may trip one of the model's asserts instead: that would prove the
# assert, not the check.
CONTROLS = [
    ("check_insert_body", [("groove_h", "2.5")], "the insert's lip made taller than the body's groove is deep"),
    ("check_insert_fans", [("groove_h", "1.5")], "the insert's groove made shallower than the fans' lip is tall"),
    ("check_blank", [("blank_fit", "-0.4")], "the blank made deeper than the bay, into the curved floor"),
    ("check_gasket_fans", [("gasket_open_y0", "32")], "the fans' gasket left over the front of the lip"),
    ("check_gasket_insert", [("gasket_open_y0", "32")], "the same gasket against the insert's lip"),
    ("check_gasket_lid", [("gasket_hx", "59.5")], "the lid's gasket ring made wider, onto the lid's plug"),
    ("check_tabs_fans", [("fans_tab_z0", "-5")], "the fan section's tabs raised 1 mm, into the body's"),
    ("check_air_insert", [("cav_y1", "50")], "the insert's cavity cut short of the channel's back"),
    ("check_air_plenum", [("probe_h", "30")], "the probe sent down to the plenum's curved floor"),
    # A missing original makes every intersection empty, which reads as a pass: its import's WARNING must fail it.
    ("check_insert_body", [("body_stl", '"original/missing.stl"')], "the body's STL missing - must be reported, not passed"),
]
MISSING = "Can't open import file"


# The checks hold parts that meet face to face 0.01 mm apart (lunchbox-assembly.scad, `sep`), so a good fit
# leaves NOTHING. Judging touching faces by volume instead failed both ways: the Manifold backend's floats
# turned the lid's plug against the body's wall into 0.027 mm3 of "overlap", and judging by thickness let a
# real 4.8 mm3 collision hide in 6000 mm2 of face contact. DUST is only float noise.
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
        print(f"{label:62} {verdict}")
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
        print(f"{view:20} {what:66} {verdict}")
    print(f"controls: {len(CONTROLS) - failed} of {len(CONTROLS)} caught")
    return failed == 0


# Every picture in docs/lunchbox/: the view it shows, and the camera and settings it is rendered with.
FIGURES = {
    "exploded": [("view", '"exploded"'), ("explode", "35")], "section": [("view", '"section"')],
    "insert-top": [("view", '"insert"')], "insert-bottom": [("view", '"insert"'), ("axes_cam", "[230, 0, 30]")],
}
CAMERAS = {
    "exploded": ["--imgsize=1400,1600", "--viewall", "--autocenter", "--camera=0,0,0,65,0,330,0"],
    "section": ["--imgsize=1500,1900", "--projection=o", "--viewall", "--autocenter", "--camera=0,0,0,0,0,0,0"],
    "insert-top": ["--imgsize=1400,900", "--viewall", "--autocenter", "--camera=0,0,0,50,0,30,0"],
    "insert-bottom": ["--imgsize=1400,900", "--viewall", "--autocenter", "--camera=0,0,0,230,0,30,0"],
}


def figures(write, names):
    """Each picture rendered to PNG - into a scratch folder, or over docs/lunchbox/ with --write. A failed
    assert or import during a PNG export still exits 0 and writes a picture of nothing, so the output is read."""
    target = Path(__file__).resolve().parent.parent / "docs" / "lunchbox"
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
        print(f"{name:15} {verdict}{'  -> docs/lunchbox/' + name + '.png' if write and verdict == 'ok' else ''}")
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
