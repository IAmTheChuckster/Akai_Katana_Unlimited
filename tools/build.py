#!/usr/bin/env python3
"""Build a patched Akai Katana u4 from your own dump.

usage: build.py <original u4> <goldpatch.bin> <output u4>

The original u4 must be the 2010/8/13 MASTER VER. (CRC 613fd380).
No ROM data is stored in this repository.
"""
import sys, struct, zlib

src, patchbin, dst = sys.argv[1:4]
d = bytearray(open(src, 'rb').read())
crc = zlib.crc32(d) & 0xffffffff
if crc != 0x613fd380:
    sys.exit('unexpected u4 CRC %08x (want 613fd380)' % crc)
# u4 is stored word-swapped relative to the SH-3's big-endian view
be = bytearray(len(d)); be[0::2] = d[1::2]; be[1::2] = d[0::2]
patch = open(patchbin, 'rb').read()
OFF = 0x3F0000                                   # free (0xFF) space in u4
assert be[OFF:OFF + len(patch)] == b'\xff' * len(patch), 'target area not free'
assert be[0x1D4:0x1D8] == bytes.fromhex('0c1de164'), 'unexpected boot literal'
be[OFF:OFF + len(patch)] = patch
be[0x1D4:0x1D8] = struct.pack('>I', 0xA03F0000)  # boot calls our hook before 0x0C1DE164
out = bytearray(len(be)); out[0::2] = be[1::2]; out[1::2] = be[0::2]
open(dst, 'wb').write(out)
outcrc = zlib.crc32(out) & 0xffffffff
print('written %s crc32 %08x' % (dst, outcrc))
if outcrc != 0x200a35a3:
    print('warning: expected 200a35a3 for the released patch')
