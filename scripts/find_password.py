#!/usr/bin/env python3
"""Search for password in EXE file"""

import re

exe_path = 'Quran DB/proQuran.exe'

print(f"Reading {exe_path}...")

with open(exe_path, 'rb') as f:
    data = f.read()

print(f"Size: {len(data):,} bytes")

# Look for connection strings
patterns = [
    (b'(?:Provider|Driver)[^;]*;[^;]*DBQ[^\"\']{0,200}', 'Connection strings'),
    (b'[Pp]assword[=:]([^\x00\r\n;\"\']{1,30})', 'Password fields'),
    (b'[Pp]wd[=:]([^\x00\r\n;\"\']{1,30})', 'PWD fields'),
    (b'mdb[;\"\'\\s]+[^\x00]{0,50}[Pp]', 'MDB with P'),
]

for pattern, name in patterns:
    print(f"\n=== {name} ===")
    matches = re.findall(pattern, data)
    for m in matches[:10]:
        try:
            print(f"  {m.decode('utf-8', errors='replace')}")
        except:
            print(f"  {m}")

# Look for specific strings near "mdb"
print("\n=== Strings containing 'mdb' ===")
# Find ASCII strings
strings = re.findall(b'[A-Za-z0-9_./\\\\:;= ]{10,100}\\.mdb[A-Za-z0-9_./\\\\:;= ]{0,100}', data, re.IGNORECASE)
for s in strings[:20]:
    print(f"  {s.decode('utf-8', errors='replace')}")

# Check for Unicode strings
print("\n=== Unicode strings with connection ===")
unicode_strings = re.findall(b'(?:P.r.o.v.i.d.e.r|D.r.i.v.e.r|D.B.Q|P.W.D|P.a.s.s.w.o.r.d)[^\x00]{2,200}', data)
for s in unicode_strings[:10]:
    # Decode as UTF-16
    try:
        decoded = s.decode('utf-16-le', errors='ignore')
        if len(decoded) > 5:
            print(f"  {decoded[:100]}")
    except:
        pass
