#!/usr/bin/env python3
"""Debug script to find actual Tajweed patterns in the database"""

import sqlite3
import sys

db_path = sys.argv[1] if len(sys.argv) > 1 else 'assets/quran_data/quran_scripts/indopak-nastaleeq.db'

conn = sqlite3.connect(db_path)
cur = conn.cursor()
cur.execute("SELECT id, text, surah, ayah FROM words WHERE text LIKE '%ب%' LIMIT 200")

print("=== SEARCHING FOR IQLAB (Noon/Tanween before Baa) ===")
print("Looking for small meem marks: ۢ (U+06E2) or ۭ (U+06ED)")
print()

# Characters
NOON = 'ن'
BAA = 'ب'
TANWEEN = 'ًٌٍ'
SUKUN = 'ْۡ'
MEEM_MARKS = 'ۭۢ'

iqlab_examples = []
idgham_r_examples = []
idgham_l_examples = []

cur.execute("SELECT id, text, surah, ayah FROM words")
words = cur.fetchall()

for wid, text, surah, ayah in words:
    if not text:
        continue
    
    # Check for Iqlab patterns
    for i, c in enumerate(text):
        # Check if current char is small meem
        if c in MEEM_MARKS:
            iqlab_examples.append((wid, text, surah, ayah, f"Found small meem at pos {i}"))
            continue
        
        # Check for noon+sukun followed by baa
        if c == NOON and i+1 < len(text) and text[i+1] in SUKUN:
            rest = text[i+2:]
            if BAA in rest[:3]:  # Check next few chars
                iqlab_examples.append((wid, text, surah, ayah, f"noon+sukun near baa"))
        
        # Check for tanween near baa
        if c in TANWEEN:
            rest = text[i+1:]
            if BAA in rest[:3]:
                iqlab_examples.append((wid, text, surah, ayah, f"tanween near baa"))
    
    # Check for Idgham patterns (noon+sukun before ر or ل)
    if NOON in text:
        for i, c in enumerate(text):
            if c == NOON and i+1 < len(text) and text[i+1] in SUKUN:
                rest = text[i+2:]
                if rest and rest[0] == 'ر':
                    idgham_r_examples.append((wid, text, surah, ayah))
                if rest and rest[0] == 'ل':
                    idgham_l_examples.append((wid, text, surah, ayah))

print(f"Found {len(iqlab_examples)} potential Iqlab words")
for w in iqlab_examples[:20]:
    print(f"  {w[2]}:{w[3]} - {w[1]} - {w[4]}")
    # Show codepoints
    codepoints = ' '.join([f'U+{ord(c):04X}' for c in w[1]])
    print(f"       [{codepoints}]")

print(f"\n=== IDGHAM WITHOUT GHUNNA (noon+sukun before ر) ===")
print(f"Found {len(idgham_r_examples)} examples")
for w in idgham_r_examples[:10]:
    print(f"  {w[2]}:{w[3]} - {w[1]}")
    codepoints = ' '.join([f'U+{ord(c):04X}' for c in w[1]])
    print(f"       [{codepoints}]")

print(f"\n=== IDGHAM WITHOUT GHUNNA (noon+sukun before ل) ===")
print(f"Found {len(idgham_l_examples)} examples")
for w in idgham_l_examples[:10]:
    print(f"  {w[2]}:{w[3]} - {w[1]}")
    codepoints = ' '.join([f'U+{ord(c):04X}' for c in w[1]])
    print(f"       [{codepoints}]")

conn.close()
