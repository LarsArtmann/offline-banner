#!/usr/bin/env python3
"""Count banner-yellow pixels in a PPM (P6) inside a physical row band.

Hue thresholds follow render-smoke's calibration doctrine: the raw
#f2f9e2 never survives the compositor transform, so a pixel qualifies
when r >= 200, g >= 170 and r - b >= 40.

Usage: band-count.py FILE ROW_LO ROW_HI  (rows are physical pixels)
"""
import sys


def main() -> None:
    if len(sys.argv) != 4:
        raise SystemExit(__doc__)
    path, lo, hi = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
    with open(path, "rb") as f:
        data = f.read()
    fields: list[bytes] = []
    pos = 0
    while len(fields) < 4:
        nl = data.index(b"\n", pos)
        chunk = data[pos:nl]
        pos = nl + 1
        if chunk.startswith(b"#"):
            continue
        fields.extend(chunk.split())
    if fields[0] != b"P6":
        raise SystemExit(f"not a binary ppm: {fields[0]!r}")
    width, height = int(fields[1]), int(fields[2])
    raw = data[pos:]
    count = 0
    row_bytes = width * 3
    for y in range(max(0, lo), min(hi, height)):
        row = raw[y * row_bytes : (y + 1) * row_bytes]
        for x in range(width):
            o = x * 3
            r, g, b = row[o], row[o + 1], row[o + 2]
            if r >= 200 and g >= 170 and r - b >= 40:
                count += 1
    print(count)


if __name__ == "__main__":
    main()
