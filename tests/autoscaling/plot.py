"""Gráfica de autoescalado: réplicas del HPA vs. throughput y p95 de k6 en el tiempo (4.4.3).

Uso: python plot.py <k6-points.json> <hpa.csv> <salida.png> [<resumen.md>]
- k6-points.json: salida de `k6 run --out json=...` (una línea JSON por punto).
- hpa.csv: epoch,hpa,current_cpu,target_cpu,current_replicas,desired_replicas (lo escribe el workflow).
"""
import csv
import json
import statistics
import sys
from collections import defaultdict

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
from matplotlib.ticker import MaxNLocator  # noqa: E402
from datetime import datetime  # noqa: E402

BUCKET = 10  # segundos


def parse_time(text):
    return datetime.fromisoformat(text.replace("Z", "+00:00")).timestamp()


def load_k6(path):
    reqs, durs = defaultdict(int), defaultdict(list)
    with open(path, encoding="utf-8") as f:
        for line in f:
            p = json.loads(line)
            if p.get("type") != "Point":
                continue
            t = int(parse_time(p["data"]["time"]) // BUCKET * BUCKET)
            if p["metric"] == "http_reqs":
                reqs[t] += 1
            elif p["metric"] == "http_req_duration":
                durs[t].append(p["data"]["value"])
    return reqs, durs


def load_hpa(path):
    series = defaultdict(list)
    with open(path, encoding="utf-8") as f:
        for row in csv.DictReader(f):
            series[row["hpa"]].append((int(row["epoch"]), int(row["current_replicas"] or 0), int(row["current_cpu"] or 0)))
    return series


def p95(values):
    return statistics.quantiles(values, n=100)[94] if len(values) >= 2 else (values[0] if values else 0)


def main(points, hpa_csv, out_png, out_md=None):
    reqs, durs = load_k6(points)
    hpa = load_hpa(hpa_csv)
    t0 = min([*reqs.keys(), *[s[0][0] for s in hpa.values() if s]])

    fig, (ax1, ax2, ax3) = plt.subplots(3, 1, figsize=(11, 9), sharex=True)
    xs = sorted(reqs)
    ax1.plot([(x - t0) / 60 for x in xs], [reqs[x] / BUCKET for x in xs], color="#1f79aa")
    ax1.set_ylabel("req/s")
    ax1.set_title("Throughput (k6)")
    ax2.plot([(x - t0) / 60 for x in xs], [p95(durs[x]) for x in xs], color="#c2410c")
    ax2.set_ylabel("p95 ms")
    ax2.set_title("Latencia p95 por ventana de 10 s")
    # Estilos distintos: si dos HPA escalan igual, las líneas se superponen y deben seguir distinguiéndose.
    for (name, rows), style in zip(hpa.items(), ["-", "--", ":", "-."]):
        ax3.step([(r[0] - t0) / 60 for r in rows], [r[1] for r in rows], where="post", linestyle=style, linewidth=2, label=f"{name} (réplicas)")
    ax3.yaxis.set_major_locator(MaxNLocator(integer=True))
    ax3.set_ylabel("réplicas")
    ax3.set_xlabel("minutos desde el inicio")
    ax3.set_title("Réplicas por HPA")
    ax3.legend()
    for ax in (ax1, ax2, ax3):
        ax.grid(alpha=0.3)
    fig.tight_layout()
    fig.savefig(out_png, dpi=120)

    if out_md:
        lines = ["| HPA | réplicas máx. | primer escalado (min) | CPU máx. (%) |", "|---|---|---|---|"]
        for name, rows in hpa.items():
            first = next((r[0] for r in rows if r[1] > rows[0][1]), None)
            lines.append(f"| {name} | {max(r[1] for r in rows)} | {'-' if first is None else round((first - t0) / 60, 1)} | {max(r[2] for r in rows)} |")
        with open(out_md, "w", encoding="utf-8") as f:
            f.write("\n".join(lines) + "\n")


if __name__ == "__main__":
    main(*sys.argv[1:])
