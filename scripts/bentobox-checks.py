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

FITS = [("check_section_carbon", []), ("check_section_fans", []), ("check_magnets_top", []),
        ("check_magnets_bottom", []), ("check_air", [])]

# Each control breaks ONE side of its check's relationship - the section's feature against the original's
# fixed mesh, or against a probe built from the original's measurements - never both, so that the check
# could only pass by not looking. None may trip one of the model's asserts instead: that would prove the
# assert, not the check.
CONTROLS = [
    ("check_section_carbon", [("tongue_h", "2.5")], "the section's tongue made taller than the housing's groove is deep"),
    ("check_section_fans", [("groove_h", "1.2")], "the section's groove made shallower than the fan case's tongue is tall"),
    ("check_magnets_top", [("mag_xy", "[23.5, 52.5]")], "the section's magnet holes moved 1 mm off the housing's"),
    ("check_magnets_bottom", [("mag_xy", "[23.5, 52.5]")], "the same, against the fan case's"),
    ("check_air", [("in_w", "30")], "the section's inside narrowed into the openings' path"),
    # A missing original makes every intersection empty, which reads as a pass: its import's WARNING must fail it.
    ("check_section_carbon", [("carbon_stl", '"original/missing.stl"')], "the housing's STL missing - must be reported, not passed"),
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
}
CAMERAS = {
    "exploded": ["--imgsize=1200,1900", "--viewall", "--autocenter", "--camera=0,0,0,70,0,320,0"],
    "cut": ["--imgsize=1200,1900", "--projection=o", "--viewall", "--autocenter", "--camera=0,0,0,0,0,0,0"],
    "section-top": ["--imgsize=1400,900", "--viewall", "--autocenter", "--camera=0,0,0,55,0,30,0"],
    "section-bottom": ["--imgsize=1400,900", "--viewall", "--autocenter", "--camera=0,0,0,235,0,30,0"],
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
