#!/usr/bin/env python3
"""Write patch.py (stand-alone Python patcher) from patch.json.
usage: genpy.py <patch.json> <patched u4 CRC32 hex>"""
import sys, json, os
runs = json.load(open(sys.argv[1])); out = sys.argv[2].lower()
tpl = r'''#!/usr/bin/env python3
"""Akai Katana Unlimited patcher (Python 3, no extra modules needed).

usage:  python3 patch.py akatana.zip
        python3 patch.py u4

Writes akatanaultd.zip (full set with the patched u4) and u4_unlimited next to this script.
Your original files are not changed. No ROM data is included in this script."""
import sys, os, zlib, zipfile, base64
IN_CRC, OUT_CRC = 0x613fd380, 0x%s
RUNS = %r

def die(msg): sys.exit('error: ' + msg)
if len(sys.argv) != 2: die('usage: python3 patch.py akatana.zip   (or: python3 patch.py u4)')
src = sys.argv[1]; others = {}
if zipfile.is_zipfile(src):
    with zipfile.ZipFile(src) as z:
        names = {os.path.basename(n).lower(): n for n in z.namelist()}
        if 'u4' not in names: die('no u4 in ' + src)
        u4 = z.read(names['u4'])
        others = {k: z.read(v) for k, v in names.items() if k != 'u4' and k}
else:
    u4 = open(src, 'rb').read()
crc = zlib.crc32(u4) & 0xffffffff
if crc == OUT_CRC: die('this u4 is already patched')
if crc != IN_CRC: die('u4 CRC32 is %%08x, expected %%08x (2010/ 8/13 MASTER VER.)' %% (crc, IN_CRC))
d = bytearray(u4)
for off, b64 in RUNS:
    b = base64.b64decode(b64); d[off:off + len(b)] = b
if zlib.crc32(d) & 0xffffffff != OUT_CRC: die('patch check failed')
here = os.path.dirname(os.path.abspath(__file__))
open(os.path.join(here, 'u4_unlimited'), 'wb').write(d)
print('wrote u4_unlimited (CRC32 %%08x)' %% OUT_CRC)
if others:
    with zipfile.ZipFile(os.path.join(here, 'akatanaultd.zip'), 'w', zipfile.ZIP_DEFLATED) as z:
        for k, v in sorted(others.items()): z.writestr(k, v)
        z.writestr('u4', bytes(d))
    print('wrote akatanaultd.zip (u2, u23, u24 copied unchanged)')
'''
open(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'patch.py'), 'w').write(tpl % (out, runs))
