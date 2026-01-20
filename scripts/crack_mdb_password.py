#!/usr/bin/env python3
"""
Recover Access MDB password - improved version
"""

import struct
import os

def recover_jet4_password(mdb_path):
    """
    Recover password from Jet 4.0 (Access 2000+) MDB files.
    """
    print(f"Analyzing: {mdb_path}")
    print(f"Size: {os.path.getsize(mdb_path):,} bytes")
    
    with open(mdb_path, 'rb') as f:
        header = f.read(256)
    
    # Print header for analysis
    print(f"Header bytes 0x40-0x60: {header[0x40:0x60].hex()}")
    
    # Jet 4.0 password location and XOR key
    # The password is stored at offset 0x42 (66)
    # XOR key from Jet 4.0 specification
    jet4_xor = bytes([
        0x86, 0xfb, 0xec, 0x37, 0x5d, 0x44, 0x9c, 0xfa,
        0xc6, 0x5e, 0x28, 0xe6, 0x13, 0xb6, 0x8a, 0x60,
        0x54, 0x94, 0x3b, 0x49
    ])
    
    # Alternative XOR key (from some tools)
    jet4_xor_alt = bytes([
        0x6a, 0xba, 0x5f, 0xc1, 0x96, 0x28, 0xc7, 0x60,
        0x8f, 0x5a, 0x47, 0x5b, 0xfc, 0x58, 0x2d, 0xaa,
        0x32, 0xbd, 0x7e, 0x2e
    ])
    
    # Another common key
    jet4_xor_v2 = bytes([
        0xa1, 0xec, 0x7a, 0x9c, 0xe1, 0x28, 0x34, 0x8a,
        0x73, 0x7b, 0xd2, 0x30, 0x9b, 0x36, 0x5a, 0x60,
        0x0a, 0x8a, 0x7e, 0x2e
    ])
    
    # Password offset in header
    pwd_offset = 0x42
    pwd_data = header[pwd_offset:pwd_offset+40]
    
    print(f"\nPassword region bytes: {pwd_data.hex()}")
    
    # Try different XOR keys
    for name, xor_key in [('key1', jet4_xor), ('key2', jet4_xor_alt), ('key3', jet4_xor_v2)]:
        password = ''
        for i in range(0, min(20, len(pwd_data)), 2):
            # Unicode decoding (password stored as UTF-16LE)
            low = pwd_data[i] ^ xor_key[i % len(xor_key)]
            high = pwd_data[i+1] ^ xor_key[(i+1) % len(xor_key)] if i+1 < len(pwd_data) else 0
            
            char_code = low | (high << 8)
            if char_code == 0:
                break
            if 32 <= char_code < 127:
                password += chr(char_code)
            else:
                password += f'\\x{char_code:04x}'
        
        print(f"  {name}: '{password}'")
    
    # Try simple byte XOR
    print("\nSimple byte XOR attempts:")
    for xor_val in [0, 0x86, 0x6a, 0xa1, 0xff]:
        result = ''.join(chr(b ^ xor_val) if 32 <= (b ^ xor_val) < 127 else '.' for b in pwd_data[:20])
        print(f"  XOR 0x{xor_val:02x}: {result}")

# Test
mdb_path = 'Tj_Ajmi.mdb'
if os.path.exists(mdb_path):
    recover_jet4_password(mdb_path)
else:
    print(f"File not found: {mdb_path}")
