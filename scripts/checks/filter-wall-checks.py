#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
# SPDX-License-Identifier: MPL-2.0
# /// script
# requires-python = ">=3.11"
# ///
"""The filter wall's checks (models/filter-wall/). From the repository's root:

  uv run scripts/checks/filter-wall-checks.py         the echo, every printed part, the controls and the figures

- the model's echo with nothing drawn: no OpenSCAD error or warning, and its own warnings counted;
- every printed part, exported as it prints: one closed body, inside the bed's 250 x 210 x 210 and standing on it,
  and its mass from its volume;
- the controls: settings that must break a guard - a split past the bed, a pocket smaller than the filter - each
  refused with the guard's own message, so a clean run means the guards can fail;
- the figures in docs/diagrams/filter-wall/, each render's output read for errors.

OPENSCAD names the binary; the nightly's Manifold renders a part in seconds. The part files it writes go in
models/filter-wall/.check/, which git ignores.
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scad-tools" / "scripts"))
from scadtools import mesh_problems, parallel, problems, render, stl_stats

MODEL = ROOT / "models" / "filter-wall"
ENTRY = "models/filter-wall/filter-wall.scad"
CHECK = MODEL / ".check"
FIGURES = ROOT / "docs" / "diagrams" / "filter-wall"
BED = (250, 210, 210)
DENSITY = 1.07  # g/cm3, ASA
CONTROLS = [
    ("split_y=300", "past the bed"),
    ("clearance=-1", "larger than its pocket"),
    ("starkvind=[385,290,40]", "outgrows the cassette"),
    ("starkvind=[370,290,46]", "too thick"),
]
VIEWS = {  # the picture, what it draws, and the camera's angles - the arrows' labels turn to face them
    "model-inside": ("wall", "75,0,90", "1600,1500"),
    "model-outside": ("outside", "70,0,235", "1600,1400"),
    "model-exploded": ("exploded", "62,0,215", "1800,1400"),
}


def parts():
    echo = CHECK / "nothing.echo"
    code, log = render(echo, ENTRY, ["-D", 'draw=""'])
    text = echo.read_text() if echo.exists() else ""
    names = re.findall(r'ECHO: "part (\w+):', text)
    return code, log, text, names


def part_file(name):
    f = CHECK / f"filter-wall-{name.replace('_', '-')}.scad"
    f.write_text("// SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz\n// SPDX-License-Identifier: CC-BY-4.0\n\n"
                 f"// Written by scripts/checks/filter-wall-checks.py: the filter wall's {name}, as it prints.\n"
                 f'include <../filter-wall.scad>\ndraw = "{name}";\n')
    return f


def check_part(name):
    stl = CHECK / f"filter-wall-{name.replace('_', '-')}.stl"
    code, log = render(stl, str(part_file(name).relative_to(ROOT)), [])
    if code != 0 or problems(log):
        return name, [f"render: exit {code}; " + "; ".join(problems(log))[:300]], None
    s = stl_stats(stl)
    bad = [f"mesh: {k} {v}" for k, v in mesh_problems(stl).items()]
    size = [h - lo for h, lo in zip(s["hi"], s["lo"])]
    if any(sz > b + 1e-6 for sz, b in zip(size, BED)) or abs(s["lo"][2]) > 1e-3:
        bad.append(f"as it prints {[round(x, 2) for x in size]} from z {s['lo'][2]:.3f}: not on the bed's {BED}")
    return name, bad, s


def control(setting):
    """An .echo export can exit 0 with the failed assert's ERROR inside the file, not in the log: read both."""
    d, needle = setting
    out = CHECK / f"control-{re.sub(r'[^a-z0-9]+', '-', d)}.echo"
    out.unlink(missing_ok=True)
    code, log = render(out, ENTRY, ["-D", 'draw=""', "-D", d])
    said = log + (out.read_text() if out.exists() else "")
    return d, (code != 0 or "ERROR" in said) and needle in said


def figure(view):
    name, (draw, angles, size) = view
    out = FIGURES / f"{name}.png"
    args = [f"--imgsize={size}", "--viewall", "--autocenter", f"--camera=0,0,0,{angles},0"]
    code, log = render(out, ENTRY, ["-D", f'draw="{draw}"', "-D", f"cam=[{angles}]", *args])
    return name, code == 0 and out.exists() and not problems(log), problems(log)


def main():
    CHECK.mkdir(exist_ok=True)
    FIGURES.mkdir(parents=True, exist_ok=True)
    failed = 0
    code, log, text, names = parts()
    own = re.search(r"warnings : (\w+)", text)
    ok = code == 0 and not problems(log) and "ERROR" not in text and names
    print(f"{'ok' if ok else 'FAIL'}  echo, nothing drawn: {len(names)} printed parts named; the model's warnings: "
          f"{own.group(1) if own else '?'}")
    failed += not ok
    results = parallel(check_part, names)
    grams = 0.0
    for name, bad, s in results:
        if s:
            grams += s["volume"] / 1000 * DENSITY
        print(f"{'ok' if not bad else 'FAIL'}  {name}: " + ("; ".join(bad) if bad else
              f"{s['hi'][0] - s['lo'][0]:.1f} x {s['hi'][1] - s['lo'][1]:.1f} x {s['hi'][2] - s['lo'][2]:.1f} mm, "
              f"{s['volume'] / 1000 * DENSITY:.0f} g"))
        failed += bool(bad)
    good = sum(1 for _, bad, _ in results if not bad)
    print(f"parts: {good} of {len(results)} clean; {grams:.0f} g of ASA in all")
    caught = parallel(control, CONTROLS)
    for d, hit in caught:
        print(f"{'ok' if hit else 'FAIL'}  control {d}: {'refused, by its guard' if hit else 'NOT refused'}")
    failed += sum(1 for _, hit in caught if not hit)
    print(f"controls: {sum(1 for _, hit in caught if hit)} of {len(caught)} caught")
    for name, ok, probs in parallel(figure, list(VIEWS.items())):
        print(f"{'ok' if ok else 'FAIL'}  figure {name}.png" + ("" if ok else f": {probs}"))
        failed += not ok
    print("all clean" if not failed else f"{failed} failed")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
