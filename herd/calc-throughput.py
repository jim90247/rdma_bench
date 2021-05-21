#!/usr/bin/env python3
import re
from argparse import ArgumentParser
from collections import defaultdict
from pprint import pprint
from statistics import median

# example_str = "main: Worker 1: 6605767.48 IOPS. Avg per-port postlist = 17.81. HERD lookup fail rate = 0.0085"

pattern = re.compile(
    r'^main: Worker (?P<worker_id>\d+): (?P<iops>\d+(\.\d+)?) IOPS. Avg per-port postlist = (?P<postlist>\d+(\.\d+)?)')


def parse_line(line: str):
    m = pattern.match(line)
    return m.groupdict() if m is not None else None


def main(args):
    with open(args.log) as f:
        lines = f.read().splitlines()
    worker_stats = defaultdict(lambda: defaultdict(list))
    for line in lines:
        stats = parse_line(line)
        if stats is None:
            continue
        for stat in ('iops', 'postlist'):
            worker_stats[stats['worker_id']][stat].append(float(stats[stat]))

    worker_stats_median = {}
    for worker_id, stats in worker_stats.items():
        worker_stats_median[worker_id] = {name: median(values) for name, values in stats.items()}
    pprint(worker_stats_median)

    median_total = defaultdict(lambda: 0)
    for worker_id, stats in worker_stats_median.items():
        for name, value in stats.items():
            median_total[name] += value
    pprint(dict(median_total))


if __name__ == '__main__':
    parser = ArgumentParser()
    parser.add_argument("log")
    args = parser.parse_args()

    main(args)
