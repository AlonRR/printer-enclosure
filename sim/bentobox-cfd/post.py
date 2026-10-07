#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
# SPDX-License-Identifier: MPL-2.0
"""Pictures and numbers from a solved BentoBox case. From the repository's root:

  uv run --project sim/bentobox-cfd sim/bentobox-cfd/post.py <case name> [--out docs/bentobox/cfd]

Reads sim/bentobox-cfd/cases/<name>/results (what run_case.sh copies back) and writes, into --out (default
the case's own results/pictures):

  side-long.png     a cut along the box at X = 0, through both fans: speed, and where the air goes
  side-fan.png      a cut across it through a fan, the duct's outlet on the left
  hepa.png          the speed down through the HEPA cartridge, seen from above
  carbon.png        the same through the C-MAG's middle tray
  sheet.png         the same through the section's filter sheet (with the section)
  streamlines.png   the air's paths from the cover to the duct's outlet
  tracer.png        how much of the air at each point came straight out of the fans
  summary.json      flows, pressures, and the same physics from cfd.py's lumped model

Every number is read from the case's own output; nothing here is typed in. The same pictures and checks as
sim/lunchbox-cfd/post.py, for this box's shape: here the air goes down, in at the top and out at the floor.
"""
import argparse
import json
import sys
from pathlib import Path

import numpy as np
import pyvista as pv

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import cfd  # noqa: E402

pv.OFF_SCREEN = True
MM = 1000.0
FACES = ("inlet", "outlet", "belowHepa", "carbonFloor", "fanFloor", "sheetFace")


def rows(path):
    return [l.split() for l in Path(path).read_text().splitlines() if l.strip() and not l.startswith("#")]


def series(path, column=-1):
    return np.array([[float(r[0]), float(r[column].strip("()"))] for r in rows(path)])


def post_numbers(res, nums):
    pp = res / "postProcessing"
    out = {}

    def one(fo, fname):
        hits = sorted((pp / fo).glob(f"*/{fname}"))
        return hits[-1] if hits else None

    for f in FACES:
        p = one(f"flowThrough_{f}", "surfaceFieldValue.dat")
        if p:
            s = series(p)
            out[f"flow_{f}_L_s"] = abs(s[-1, 1]) * 1000
            tail = s[len(s) * 3 // 4:, 1]
            out[f"flow_{f}_drift_pct"] = float(100 * (tail.max() - tail.min()) / max(abs(s[-1, 1]), 1e-12))
        t = one(f"tracer_{f}", "surfaceFieldValue.dat")
        if t:
            out[f"tracer_{f}"] = float(rows(t)[-1][-1])
    for z in ("hepa", "carbon1", "carbon2", "carbon3", "sheet"):
        p = one(f"pressureIn_{z}", "volFieldValue.dat")
        if p:
            out[f"p_avg_{z}_Pa"] = float(rows(p)[-1][-1]) * cfd.AIR["rho"]
    probes = json.loads((res.parent / "probes.json").read_text())
    pfile = one("probes", "p")
    if pfile:
        vals = rows(pfile)[-1][1:]
        out["probes_p_Pa"] = {name: float(v) * cfd.AIR["rho"] for name, v in zip(probes, vals)}
    for i in (1, 2):
        props = res / "uniform" / f"fan{i}Properties"
        if props.exists():
            q = [l for l in props.read_text().splitlines() if l.strip().startswith("flow_rate")]
            out[f"fan{i}_L_s"] = float(q[0].split()[1].rstrip(";")) * 1000 if q else float("nan")
    q_net, p_net = cfd.network(with_section=bool(nums["sheet"]), layer_t=nums["carbon_layer"] / 1000)
    out["network_L_s"] = q_net * 1000
    out["network_fan_Pa"] = p_net
    log = (res / "log.simpleFoam").read_text(errors="replace")
    its = [l for l in log.splitlines() if l.startswith("Time = ")]
    out["iterations"] = int(float(its[-1].split()[-1])) if its else 0
    out["converged"] = "SIMPLE solution converged" in log
    return out


def load(res):
    vtus = sorted((res / "VTK").rglob("internal.vtu"))
    if not vtus:
        sys.exit(f"no internal.vtu under {res / 'VTK'}")
    grid = pv.read(vtus[-1])
    grid.points *= MM                                # metres -> mm, the model's frame
    grid = grid.cell_data_to_point_data() if "U" not in grid.point_data else grid
    grid["speed"] = np.linalg.norm(grid["U"], axis=1)
    walls = [pv.read(p) for p in sorted((res / "VTK").rglob("bentobox.vtp"))]
    wall = walls[-1] if walls else None
    if wall is not None:
        wall.points *= MM
    return grid, wall


def shot(plotter, path, view, zoom=1.0):
    getattr(plotter, f"view_{view}")()
    plotter.camera.zoom(zoom)
    plotter.screenshot(str(path))
    plotter.close()


def bar(title):
    return {"title": title, "vertical": True, "position_x": 0.86, "position_y": 0.15, "height": 0.7,
            "title_font_size": 16, "label_font_size": 14, "fmt": "%.2f"}


def side(grid, normal, at, path, vmax, title, view, size):
    """A cut through the stack: speed on a log scale, and in-plane arrows on a coarse sample of it."""
    origin = (at, 0, 0) if normal == "x" else (0, at, 0)
    cut = grid.slice(normal=normal, origin=origin)
    p = pv.Plotter(off_screen=True, window_size=size)
    p.set_background("white")
    # A log scale: the air through the filters moves at a tenth of the fans' jet, and on a linear scale
    # every filter reads as the same dark colour.
    cut["speed"] = np.clip(cut["speed"], 0.01, None)
    p.add_mesh(cut, scalars="speed", cmap="viridis", clim=(0.01, vmax), log_scale=True,
               scalar_bar_args={**bar("speed, m/s"), "fmt": "%.2g"})
    centres = cut.cell_centers()
    pick = np.arange(0, centres.n_points, max(1, centres.n_points // 600))
    pts = pv.PolyData(centres.points[pick])
    vec = np.asarray(centres["U"])[pick].copy()
    vec[:, 0 if normal == "x" else 1] = 0
    pts["inplane"] = vec
    # Arrows grow with the square root of speed, so a slow filter's arrows still show which way it flows.
    pts["len"] = np.sqrt(np.linalg.norm(vec, axis=1) / max(vmax, 1e-9))
    p.add_mesh(pts.glyph(orient="inplane", scale="len", factor=7.0, geom=pv.Arrow()), color="white", opacity=0.95)
    p.add_text(title, font_size=12, color="black")
    shot(p, path, view, 1.2)


def face(grid, z, path, title, box):
    """The flow down through a filter: a cut at its middle, inside its own box only - the statistics are of
    the filter, never of the whole plane the cut lies in."""
    cut = grid.slice(normal="z", origin=(0, 0, z)).clip_box(box, invert=False)
    cut["through"] = -cut["U"][:, 2]
    p = pv.Plotter(off_screen=True, window_size=(900, 1500))
    p.set_background("white")
    p.add_mesh(cut, scalars="through", cmap="viridis", scalar_bar_args=bar("m/s down through it"))
    p.add_text(title, font_size=12, color="black")
    shot(p, path, "xy", 1.3)
    vals = cut["through"]
    vals = vals[np.isfinite(vals) & (np.abs(vals) > 1e-6)]
    return {"mean": float(vals.mean()), "min": float(vals.min()), "max": float(vals.max()),
            "cov": float(vals.std() / vals.mean()) if vals.mean() else float("nan")}


def through_box(grid, normal, origin, box, component):
    """Flow through a plane, inside a box only: L/s, signed along the axis."""
    cut = grid.slice(normal=normal, origin=origin).clip_box(box, invert=False)
    if cut.n_points == 0:
        return 0.0
    cut["un"] = cut["U"][:, component]
    return cut.integrate_data()["un"][0] * 1e-6 * 1000


def by_face(grid, nums):
    """Where air crosses into the box: the net flow inwards, L/s, across a plane 3 mm outside each face - in
    clear air, not the castellated mesh's ragged edge, where 0.6 mm off the wall the sums missed by 10 %.
    The -X face is split at the duct's top: the duct's outlet below, the rest of the box above. Only the top
    should take air in, and only the duct should give it out; anything else is a leak, or an outlet nobody
    meant. A coarse locator: the flow planes inside the box are the balance."""
    x0, x1, y0, y1, z0, z1 = nums["box"]
    duct_top = nums["fans_z"]
    o = 3.0
    # A closed box round the scrubber, o outside it everywhere - beyond the duct's mounting tab at -Y too.
    X0, X1, Y0, Y1, Z1 = x0 - o, x1 + o, y0 - 12 - o, y1 + o, z1 + o
    return {
        "top": -through_box(grid, "z", (0, 0, Z1), (X0, X1, Y0, Y1, Z1 - 1, Z1 + 1), 2),
        "minus_x_duct": through_box(grid, "x", (X0, 0, 0), (X0 - 1, X0 + 1, Y0, Y1, z0, duct_top), 0),
        "minus_x_above": through_box(grid, "x", (X0, 0, 0), (X0 - 1, X0 + 1, Y0, Y1, duct_top, Z1), 0),
        "plus_x": -through_box(grid, "x", (X1, 0, 0), (X1 - 1, X1 + 1, Y0, Y1, z0, Z1), 0),
        "minus_y": through_box(grid, "y", (0, Y0, 0), (X0, X1, Y0 - 1, Y0 + 1, z0, Z1), 1),
        "plus_y": -through_box(grid, "y", (0, Y1, 0), (X0, X1, Y1 - 1, Y1 + 1, z0, Z1), 1),
    }


def streamlines(grid, wall, nums, path, vmax):
    ix = nums["inlet"]
    # Seeded just under the cover's window and followed forwards only: each line is one parcel's way from the
    # cover to the outlet, not the chamber's air drifting about.
    seeds = pv.Plane(center=(0, 0, ix[4] - 3), direction=(0, 0, 1), i_size=ix[1] - ix[0] - 4,
                     j_size=ix[3] - ix[2] - 6, i_resolution=5, j_resolution=14)
    lines = grid.streamlines_from_source(seeds, vectors="U", max_length=2000.0, initial_step_length=0.5,
                                         integration_direction="forward", max_steps=60000)
    p = pv.Plotter(off_screen=True, window_size=(1200, 1600))
    p.set_background("white")
    if wall is not None:
        p.add_mesh(wall, color="lightgray", opacity=0.12)
    if lines.n_points:
        lines["speed"] = np.linalg.norm(lines["U"], axis=1)   # a streamline carries U, not what was derived from it
        p.add_mesh(lines.tube(radius=0.35), scalars="speed", cmap="viridis", clim=(0, vmax),
                   scalar_bar_args=bar("speed, m/s"))
    p.add_axes()
    p.add_text("From the cover: through the HEPA, the C-MAG and the fans, out of the duct", font_size=12, color="black")
    p.camera_position = [(-330, -300, 260), (0, 0, 110), (0, 0, 1)]
    p.screenshot(str(path))
    p.close()


def tracer(grid, y, path):
    cut = grid.slice(normal="y", origin=(0, y, 0))
    p = pv.Plotter(off_screen=True, window_size=(1100, 1500))
    p.set_background("white")
    p.add_mesh(cut, scalars="s", cmap="magma", clim=(0, 1), scalar_bar_args=bar("from the fans"))
    p.add_text("Air just out of the fans, and where it goes", font_size=12, color="black")
    shot(p, path, "xz", 1.1)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("name")
    ap.add_argument("--out")
    a = ap.parse_args()
    case = HERE / "cases" / a.name
    res = case / "results"
    nums = json.loads((case / "numbers.json").read_text())
    out = Path(a.out) if a.out else res / "pictures"
    out.mkdir(parents=True, exist_ok=True)
    summary = post_numbers(res, nums)
    grid, wall = load(res)
    vmax = float(np.percentile(grid["speed"], 99.5))
    fy = nums["fans"][0][1]
    side(grid, "x", 0.0, out / "side-long.png", vmax, "Cut along the box at x = 0, through both fans",
         "yz", (1100, 1600))
    side(grid, "y", fy, out / "side-fan.png", vmax, f"Cut across at y = {fy:g} mm, through a fan: the outlet on the left",
         "xz", (1100, 1600))
    h = nums["hepa"]
    summary["hepa_face"] = face(grid, (h[4] + h[5]) / 2, out / "hepa.png", "Down through the HEPA cartridge, from above",
                                (h[0], h[1], h[2], h[3], h[4], h[5]))
    c = nums["carbon"][1]
    summary["carbon_face"] = face(grid, (c[4] + c[5]) / 2, out / "carbon.png", "Down through the C-MAG's middle tray, from above",
                                  (c[0], c[1], c[2], c[3], c[4] - 1, c[5] + 1))
    if nums["sheet"]:
        s = nums["sheet"]
        summary["sheet_face"] = face(grid, (s[4] + s[5]) / 2, out / "sheet.png", "Down through the section's sheet, from above",
                                     (s[0], s[1], s[2], s[3], s[4] - 1, s[5] + 1))
    summary["inflow_by_face_L_s"] = by_face(grid, nums)
    # Round the C-MAG: down the band between its inside and the housing's, at its middle. It is closed in the
    # model (bentobox-cfd.scad), so anything here is a modelling error.
    cm = nums["cmag_in"]
    zc = (nums["carbon"][0][4] + nums["carbon"][2][5]) / 2
    band = sum(through_box(grid, "z", (0, 0, zc), b, 2) for b in (
        (-26.4, -cm[0] / 2, -56.4, 56.4, zc - 1, zc + 1), (cm[0] / 2, 26.4, -56.4, 56.4, zc - 1, zc + 1),
        (-cm[0] / 2, cm[0] / 2, -56.4, -cm[1] / 2, zc - 1, zc + 1), (-cm[0] / 2, cm[0] / 2, cm[1] / 2, 56.4, zc - 1, zc + 1)))
    summary["round_cmag_L_s"] = -band
    if "flow_inlet_L_s" in summary and "flow_fanFloor_L_s" in summary:
        summary["not_through_cover_L_s"] = summary["flow_fanFloor_L_s"] - summary["flow_inlet_L_s"]
    bed = sum((b[1] - b[0]) * (b[3] - b[2]) * nums["carbon_layer"] for b in nums["carbon"]) * 1e-3   # cm3
    q = summary.get("flow_belowHepa_L_s", float("nan"))
    summary["carbon_bed_cm3"] = bed
    summary["carbon_contact_ms"] = bed / q if q else float("nan")      # cm3 / (L/s) = ms
    streamlines(grid, wall, nums, out / "streamlines.png", vmax)
    tracer(grid, fy, out / "tracer.png")
    summary["speed_p99_5"] = vmax
    (out / "summary.json").write_text(json.dumps(summary, indent=1), encoding="utf-8")
    print(json.dumps(summary, indent=1))


if __name__ == "__main__":
    main()
