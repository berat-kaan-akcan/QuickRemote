#!/usr/bin/env python3
"""Packs PNG files into one .ico (PNG-compressed entries, Windows Vista+).

Usage: pack_ico.py OUT.ico IN-16.png IN-32.png ...
"""
import struct
import sys


def png_size(data: bytes) -> tuple[int, int]:
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError("not a PNG")
    return struct.unpack(">II", data[16:24])


def main() -> None:
    out, inputs = sys.argv[1], sys.argv[2:]
    images = [open(path, "rb").read() for path in inputs]
    header = struct.pack("<HHH", 0, 1, len(images))
    offset = len(header) + 16 * len(images)
    entries, blobs = b"", b""
    for data in images:
        w, h = png_size(data)
        # 0 stands for 256 in the one-byte width and height fields.
        entries += struct.pack("<BBBBHHII", w % 256, h % 256, 0, 0, 1, 32, len(data), offset)
        blobs += data
        offset += len(data)
    with open(out, "wb") as f:
        f.write(header + entries + blobs)


if __name__ == "__main__":
    main()
