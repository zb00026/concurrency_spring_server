"""
Load tester for highreq-api (no external dependencies beyond `requests`).

Uses multiprocessing + threads so it can push thousands of requests/second
from one machine. For serious 5k+ RPS testing, prefer k6 (loadtest/k6.js).

Usage:
    python loadtest.py --url http://localhost:8080/api/v1/users/1 \
        --connections 300 --duration 30
"""
import argparse
import multiprocessing as mp
import statistics
import threading
import time

import requests


def worker(url: str, duration: int, results: mp.Queue, stop_flag: mp.Value):
    session = requests.Session()
    adapter = requests.adapters.HTTPAdapter(
        pool_connections=10, pool_maxsize=10, max_retries=0)
    session.mount("http://", adapter)
    lat = []
    errors = 0
    deadline = time.monotonic() + duration
    while time.monotonic() < deadline and not stop_flag.value:
        t0 = time.monotonic()
        try:
            r = session.get(url, timeout=5)
            if r.status_code != 200:
                errors += 1
        except Exception:
            errors += 1
        lat.append((time.monotonic() - t0) * 1000.0)
    results.put((lat, errors))


def percentile(sorted_vals, p: float) -> float:
    if not sorted_vals:
        return 0.0
    k = (len(sorted_vals) - 1) * p
    f = int(k)
    c = min(f + 1, len(sorted_vals) - 1)
    return sorted_vals[f] + (sorted_vals[c] - sorted_vals[f]) * (k - f)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--url", default="http://localhost:8080/api/v1/users/1")
    ap.add_argument("--connections", type=int, default=300,
                    help="concurrent connections (threads)")
    ap.add_argument("--duration", type=int, default=30, help="seconds")
    ap.add_argument("--processes", type=int,
                    default=max(2, (mp.cpu_count() or 4) - 2))
    args = ap.parse_args()

    print(f"Warming up: GET {args.url}")
    requests.get(args.url, timeout=5).raise_for_status()

    mgr = mp.Manager()
    results = mgr.Queue()
    stop_flag = mgr.Value("i", 0)
    threads_per_proc = max(1, args.connections // args.processes)

    print(f"Starting load test: {args.processes} processes x "
          f"{threads_per_proc} threads = {args.processes * threads_per_proc} "
          f"connections for {args.duration}s ...")
    t0 = time.monotonic()
    procs = []
    for _ in range(args.processes):
        for _ in range(threads_per_proc):
            p = mp.Process(target=worker,
                           args=(args.url, args.duration, results, stop_flag))
            p.start()
            procs.append(p)
    for p in procs:
        p.join()
    wall = time.monotonic() - t0

    all_lat, total_errors, total_req = [], 0, 0
    for _ in procs:
        lat, errors = results.get()
        all_lat.extend(lat)
        total_errors += errors
    total_req = len(all_lat)
    all_lat.sort()

    rps = total_req / wall
    print("\n===== RESULTS =====")
    print(f"Total requests : {total_req:,}")
    print(f"Wall time      : {wall:.1f} s")
    print(f"Throughput     : {rps:,.0f} req/s")
    print(f"Errors         : {total_errors} ({100*total_errors/max(total_req,1):.2f}%)")
    if all_lat:
        print(f"Latency  p50   : {percentile(all_lat, 0.50):.1f} ms")
        print(f"Latency  p95   : {percentile(all_lat, 0.95):.1f} ms")
        print(f"Latency  p99   : {percentile(all_lat, 0.99):.1f} ms")
        print(f"Latency  max   : {all_lat[-1]:.1f} ms")
        print(f"Latency  mean  : {statistics.mean(all_lat):.1f} ms")


if __name__ == "__main__":
    main()
