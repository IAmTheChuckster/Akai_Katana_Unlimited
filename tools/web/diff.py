#!/usr/bin/env python3
"""Write the byte runs that turn the original u4 into the Gold u4 as JSON for gen.py.
usage: diff.py <original u4> <patched u4> > patch.json"""
import sys, json, base64
a = open(sys.argv[1], 'rb').read(); b = open(sys.argv[2], 'rb').read()
runs, i = [], 0
while i < len(a):
    if a[i] != b[i]:
        j = i
        while j < len(a) and (a[j] != b[j] or (j + 8 < len(a) and a[j:j + 8] != b[j:j + 8])): j += 1
        runs.append([i, base64.b64encode(b[i:j]).decode()]); i = j
    else:
        i += 1
json.dump(runs, sys.stdout)
