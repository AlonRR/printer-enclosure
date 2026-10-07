#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
# SPDX-License-Identifier: MPL-2.0
"""Pictures and numbers from a solved LunchBox case. From the repository's root:

  uv run --project sim/lunchbox-cfd sim/lunchbox-cfd/post.py <case name> [--out docs/lunchbox/cfd]

Reads sim/lunchbox-cfd/cases/<name>/results (what run_case.sh copies back) and writes, into --out (default
the case's own results/pictures):

  side-fan.png      a cut through the stack at one fan: speed, and where the air goes
  side-middle.png   the same through the middle bay, behind the blank
  hepa.png          the speed through the HEPA paper, seen from the front
  sheet.png         the speed down through the insert's filter sheet, seen from above (with the insert)
  streamlines.png   the air's paths from the grid to the fans and out
  tracer.png        how much of the air at each point came straight out of the fans
  summary.json      flows, pressures, and the same physics from cfd.py's lumped model

Every number is read from the case's own output; nothing here is typed in.
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


def last_value(path, column=-1):
    rows = [l.split() for l in Path(path).read_text().splitlines() if l.strip() and not l.startswith("#")]
    return float(rows[-1][column].strip("()")) if rows else float("nan")


def series(path, column=-1):
    rows = [l.split() for l in Path(path).read_text().splitlines() if l.strip() and not l.startswith("#")]
    return np.array([[float(r[0]), float(r[column].strip("()"))] for r in rows])


def post_numbers(res, nums):
    pp = res / "postProcessing"
    out = {}

    def one(fo, fname):
        hits = sorted((pp / fo).glob(f"*/{fname}"))
        return hits[-1] if hits else None

    for f in ("inlet", "outlet", "sheetFace"):
        p = one(f"flowThrough_{f}", "surfaceFieldValue.dat")
        if p:
            s = series(p)
            out[f"flow_{f}_L_s"] = abs(s[-1, 1]) * 1000
            tail = s[len(s) * 3 // 4:, 1]
            out[f"flow_{f}_drift_pct"] = float(100 * (tail.max() - tail.min()) / max(abs(s[-1, 1]), 1e-12))
        t = one(f"tracer_{f}", "surfaceFieldValue.dat")
        if t:
            out[f"tracer_{f}"] = last_value(t)
    for z in ("hepa", "carbon", "sheet"):
        p = one(f"pressureIn_{z}", "volFieldValue.dat")
        if p:
            out[f"p_avg_{z}_Pa"] = last_value(p) * cfd.AIR["rho"]
    probes = json.loads((res.parent / "probes.json").read_text())
    pfile = one("probes", "p")
    if pfile:
        vals = [l.split() for l in pfile.read_text().splitlines() if l.strip() and not l.startswith("#")][-1][1:]
        out["probes_p_Pa"] = {name: float(v) * cfd.AIR["rho"] for name, v in zip(probes, vals)}
    for i in (1, 2):
        props = res / "uniform" / f"fan{i}Properties"
        if props.exists():
            txt = props.read_text()
            q = [l for l in txt.splitlines() if l.strip().startswith("flow_rate")]
            out[f"fan{i}_L_s"] = float(q[0].split()[1].rstrip(";")) * 1000 if q else float("nan")
    q_net, p_net = cfd.network(with_insert=bool(nums["sheet"]))
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
    walls = [pv.read(p) for p in sorted((res / "VTK").rglob("lunchbox.vtp"))]
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


def side(grid, x, path, vmax, title):
    cut = grid.slice(normal="x", origin=(x, 0, 0))
    p = pv.Plotter(off_screen=True, window_size=(900, 1500))
    p.set_background("white")
    # A log scale: the air through the filters moves at a tenth of the fans' jet, and on a linear scale
    # every filter reads as the same dark colour.
    cut["speed"] = np.clip(cut["speed"], 0.01, None)
    p.add_mesh(cut, scalars="speed", cmap="viridis", clim=(0.01, vmax), log_scale=True,
               scalar_bar_args={**bar("speed, m/s"), "fmt": "%.2g"})
    # In-plane direction: arrows on a coarse sample of the cut, length by speed.
    centres = cut.cell_centers()
    pick = np.arange(0, centres.n_points, max(1, centres.n_points // 500))
    pts = pv.PolyData(centres.points[pick])
    vec = np.asarray(centres["U"])[pick].copy()
    vec[:, 0] = 0
    pts["inplane"] = vec
    pts["len"] = np.linalg.norm(vec, axis=1)
    # Arrows grow with the square root of speed, so a slow filter's arrows still show which way it flows.
    pts["len"] = np.sqrt(pts["len"] / max(vmax, 1e-9))
    arrows = pts.glyph(orient="inplane", scale="len", factor=7.0, geom=pv.Arrow())
    p.add_mesh(arrows, color="white", opacity=0.95)
    p.add_text(title, font_size=12, color="black")
    shot(p, path, "yz", 1.25)


def face(grid, normal, origin, component, path, title, view, clim, box):
    """The flow through a filter's face: a cut at its middle, inside its own box only - the statistics are
    of the filter, never of the whole plane the cut lies in."""
    cut = grid.slice(normal=normal, origin=origin).clip_box(box, invert=False)
    cut["through"] = cut["U"][:, component] * (-1 if normal in ("z",) else 1)
    p = pv.Plotter(off_screen=True, window_size=(1400, 900))
    p.set_background("white")
    p.add_mesh(cut, scalars="through", cmap="viridis", clim=clim, scalar_bar_args=bar("m/s through it"))
    p.add_text(title, font_size=12, color="black")
    shot(p, path, view, 1.3)
    vals = cut["through"]
    vals = vals[np.isfinite(vals) & (np.abs(vals) > 1e-6)]
    return {"mean": float(vals.mean()), "min": float(vals.min()), "max": float(vals.max()),
            "cov": float(vals.std() / vals.mean()) if vals.mean() else float("nan")}


def streamlines(grid, wall, nums, path, vmax):
    ix0, ix1, iz0, iz1 = nums["inlet"]
    # Seeded just inside the grid, between it and the HEPA frame, and followed forwards only: each line is
    # one parcel's way from the grid to the fans and out, not the chamber's air drifting about.
    h = nums["hepa"]
    seeds = pv.Plane(center=(0, (nums["box"][2] + h[2]) / 2 + 1, (h[4] + h[5]) / 2), direction=(0, 1, 0),
                     i_size=h[1] - h[0] - 6, j_size=h[5] - h[4] - 6, i_resolution=12, j_resolution=7)
    lines = grid.streamlines_from_source(seeds, vectors="U", max_length=1500.0, initial_step_length=0.5,
                                         integration_direction="forward", max_steps=40000)
    p = pv.Plotter(off_screen=True, window_size=(1400, 1400))
    p.set_background("white")
    if wall is not None:
        p.add_mesh(wall, color="lightgray", opacity=0.12)
    if lines.n_points:
        lines["speed"] = np.linalg.norm(lines["U"], axis=1)   # a streamline carries U, not what was derived from it
        p.add_mesh(lines.tube(radius=0.35), scalars="speed", cmap="viridis", clim=(0, vmax),
                   scalar_bar_args=bar("speed, m/s"))
    p.add_axes()
    p.add_text("From the grid: through the HEPA and the carbon, down the back, out through the fans",
               font_size=12, color="black")
    p.camera_position = [(260, -320, 230), (0, 30, 30), (0, 0, 1)]
    p.screenshot(str(path))
    p.close()


def wire_leak(grid, nums):
    """Flow in through the fan section's wire channel - 12.7 mm wide, 2 mm tall, under its +x end wall into
    the plenum: a cut across the wall at x = 60, over the channel's height and depth, integrated."""
    z0 = nums["floor_z"]
    cut = grid.slice(normal="x", origin=(60.0, 0, 0)).clip_box((-1e3, 1e3, 38, 60, z0 - 1, z0 + 4), invert=False)
    if cut.n_points == 0:
        return 0.0
    cut["ux"] = cut["U"][:, 0]
    flux = cut.integrate_data()["ux"][0] * 1e-6        # m/s x mm2 -> m3/s
    return -flux * 1000                                 # L/s, positive inward (towards -x)


def through_box(grid, normal, origin, box, component):
    """Flow through a plane, inside a box only: L/s, signed along the axis."""
    cut = grid.slice(normal=normal, origin=origin).clip_box(box, invert=False)
    if cut.n_points == 0:
        return 0.0
    cut["un"] = cut["U"][:, component]
    return cut.integrate_data()["un"][0] * 1e-6 * 1000


def hepa_flow(grid, nums):
    """Across the HEPA frame's mid-plane: through the paper inside the frame, and round it - beside the frame,
    between it and the body's side walls, and over its top. The holder is the body's whole inside, 120 mm
    wide; the frame is 109.4, so the sides are open unless something fills them."""
    h = nums["hepa"]
    y = (h[2] + h[3]) / 2
    yb = (h[2] - 1, h[3] + 1)
    wall = nums["carbon"][1]                      # the body's inner side wall, x = +/-60
    return {
        "paper": through_box(grid, "y", (0, y, 0), (h[0], h[1], *yb, h[4], h[5]), 1),
        "beside": (through_box(grid, "y", (0, y, 0), (h[1], wall, *yb, 0, 80), 1)
                   + through_box(grid, "y", (0, y, 0), (-wall, h[0], *yb, 0, 80), 1)),
        "over": through_box(grid, "y", (0, y, 0), (h[0], h[1], *yb, h[5], 80), 1),
    }


def by_face(grid, nums):
    """Where air crosses into the box: the net flow inwards, L/s, across a plane 0.6 mm outside each face,
    the front split into the grid, the band between the grid and the fans, and the fans. Anything but
    the grid going in, and the fans going out, is a leak."""
    x0, x1, y0, y1, z0, z1 = nums["box"]
    rim, top = nums["fans_rim"], nums["body_top"]
    o = 0.6
    return {
        "front_grid": through_box(grid, "y", (0, y0 - o, 0), (x0, x1, y0 - o - 1, y0 - o + 1, 0, top), 1),
        "front_joints": through_box(grid, "y", (0, y0 - o, 0), (x0, x1, y0 - o - 1, y0 - o + 1, rim, 0), 1),
        "front_fans": through_box(grid, "y", (0, y0 - o, 0), (x0, x1, y0 - o - 1, y0 - o + 1, z0, rim), 1),
        "end_plus_x": -through_box(grid, "x", (x1 + o, 0, 0), (x1 + o - 1, x1 + o + 1, y0, y1, z0, z1), 0),
        "end_minus_x": through_box(grid, "x", (x0 - o, 0, 0), (x0 - o - 1, x0 - o + 1, y0, y1, z0, z1), 0),
        "back": -through_box(grid, "y", (0, y1 + o, 0), (x0, x1, y1 + o - 1, y1 + o + 1, z0, z1), 1),
        "top": -through_box(grid, "z", (0, 0, z1 + o), (x0, x1, y0, y1, z1 + o - 1, z1 + o + 1), 2),
    }


def tracer(grid, x, path):
    cut = grid.slice(normal="x", origin=(x, 0, 0))
    p = pv.Plotter(off_screen=True, window_size=(900, 1500))
    p.set_background("white")
    p.add_mesh(cut, scalars="s", cmap="magma", clim=(0, 1), scalar_bar_args=bar("from the fans"))
    p.add_text("Air just out of the fans, and where it goes", font_size=12, color="black")
    shot(p, path, "yz", 1.25)


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
    fx = nums["fans"][0][0]
    side(grid, fx, out / "side-fan.png", vmax, f"Cut at x = {fx:g} mm, through a fan: front on the left")
    side(grid, 0.0, out / "side-middle.png", vmax, "Cut at x = 0, through the middle bay and its blank")
    h = nums["hepa"]
    side_x = nums["carbon"][1]                    # the body's inner side walls, +/-
    summary["hepa_face"] = face(grid, "y", (0, (h[2] + h[3]) / 2, 0), 1, out / "hepa.png",
                                "Through the HEPA holder, seen from the front: the paper, and the gaps beside it",
                                "xz", None, (-side_x, side_x, h[2] - 1, h[3] + 1, 0, 80))
    if nums["sheet"]:
        s = nums["sheet"]
        summary["sheet_face"] = face(grid, "z", (0, 0, (s[4] + s[5]) / 2), 2, out / "sheet.png",
                                     "Down through the insert's sheet, seen from above", "xy", None,
                                     (s[0], s[1], s[2], s[3], s[4] - 1, s[5] + 1))
    summary["wire_channel_in_L_s"] = wire_leak(grid, nums)
    summary["inflow_by_face_L_s"] = by_face(grid, nums)
    hf = hepa_flow(grid, nums)
    summary["hepa_paper_L_s"], summary["hepa_beside_frame_L_s"], summary["hepa_over_frame_L_s"] = hf["paper"], hf["beside"], hf["over"]
    if "flow_inlet_L_s" in summary and "flow_outlet_L_s" in summary:
        summary["not_through_grid_L_s"] = summary["flow_outlet_L_s"] - summary["flow_inlet_L_s"]
    streamlines(grid, wall, nums, out / "streamlines.png", vmax)
    tracer(grid, fx, out / "tracer.png")
    summary["speed_p99_5"] = vmax
    (out / "summary.json").write_text(json.dumps(summary, indent=1), encoding="utf-8")
    print(json.dumps(summary, indent=1))


if __name__ == "__main__":
    main()
