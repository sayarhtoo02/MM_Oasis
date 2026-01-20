#!/usr/bin/env python3
"""
Fast Tajweed Pre-processor - Fixed patterns based on actual database analysis
Based on fcat97/tajweedApi with fixes for Indopak database
"""

import sqlite3
import re
import sys
from pathlib import Path

# Rule indices
GHUNNA, QALQALA, IKHFAA, IDGHAM_G, IDGHAM_NG, IQLAB, NONE = range(7)

# ========== CHARACTERS ==========

IQFAA_LETTERS = 'تثجدذزسشصضطظفقكک'
QALQALA_LETTERS = 'قطبجد'
ALIF = 'ا'
MEEM = 'م'
NOON = 'ن'
BAA = 'ب'
HARAKAT = 'َُِ'
TANWEEN = 'ًٌٍ'
TASHDEED = 'ّ'
MADDAH = 'ٓ'
SUPERSCRIPT_ALIF = 'ٰ'
SUBSCRIPT_ALIF = 'ٖ'
INVERTED_DAMMA = 'ٗ'
SUKUN = 'ْۡ'
# Small meem marks for Iqlab (U+06E2 and U+06ED)
MEEM_ISOLATED = 'ۭۢ'
IDGHAM_WITH_GHUNNA = 'یىومن'
IDGHAM_WITHOUT_GHUNNA = 'رل'

# PUA range (font-specific ligatures that might appear)
# U+F500-U+F700 range seems to be used in this database

# ========== PATTERNS ==========

def get_harakat():
    return f'[{HARAKAT}{TANWEEN}{SUPERSCRIPT_ALIF}{SUBSCRIPT_ALIF}{INVERTED_DAMMA}]?'

def get_noon_sakin():
    # noon + sukun, OR any letter + tashdeed? + tanween + alif?
    return f'({NOON}[{SUKUN}]|\\w?{TASHDEED}?[{TANWEEN}]{ALIF}?)'

# Pattern 1: Gunnah - Noon/Meem + Shadda
PATTERN_GUNNAH = f'([{NOON}{MEEM}]{TASHDEED}{get_harakat()}{MADDAH}?)'

# Pattern 2: Qalqalah - qalqala letter + sukun
PATTERN_QALQALA = f'([{QALQALA_LETTERS}][{SUKUN}])'

# Pattern 3: Ikhfaa - noon_sakin/tanween + ikhfaa_letter
# Allow any characters between (for PUA fonts)
PATTERN_IKHFAA = f'{get_noon_sakin()}.{{0,3}}[{IQFAA_LETTERS}]'

# Pattern 4: Iqlab - FIXED: tanween/noon_sakin followed by small meem mark
# The small meem appears AFTER tanween in this database: ٌۢ (tanween + small meem)
PATTERN_IQLAB = f'([{TANWEEN}].{{0,2}}[{MEEM_ISOLATED}]|{NOON}[{SUKUN}].{{0,2}}[{MEEM_ISOLATED}])'

# Pattern 5: Idgham WITH Ghunna
PATTERN_IDGHAM_G = f'{get_noon_sakin()}.{{0,3}}[{IDGHAM_WITH_GHUNNA}]{TASHDEED}?[{HARAKAT}{TANWEEN}{SUPERSCRIPT_ALIF}{SUBSCRIPT_ALIF}{INVERTED_DAMMA}]'

# Pattern 6: Idgham WITHOUT Ghunna
PATTERN_IDGHAM_NG = f'{get_noon_sakin()}.{{0,3}}[{IDGHAM_WITHOUT_GHUNNA}]{TASHDEED}?{get_harakat()}'

# Compile patterns
PATTERNS = [
    (re.compile(PATTERN_IQLAB, re.UNICODE), IQLAB),      # Check Iqlab first (small meem)
    (re.compile(PATTERN_GUNNAH, re.UNICODE), GHUNNA),
    (re.compile(PATTERN_QALQALA, re.UNICODE), QALQALA),
    (re.compile(PATTERN_IDGHAM_G, re.UNICODE), IDGHAM_G),
    (re.compile(PATTERN_IDGHAM_NG, re.UNICODE), IDGHAM_NG),
    (re.compile(PATTERN_IKHFAA, re.UNICODE), IKHFAA),
]

def tokenize(text):
    if not text:
        return [(text, NONE)]
    
    matches = []
    for pat, rule in PATTERNS:
        for m in pat.finditer(text):
            matches.append((m.start(), m.end(), m.group(), rule))
    
    if not matches:
        return [(text, NONE)]
    
    # Sort by position, longer matches first
    matches.sort(key=lambda x: (x[0], -(x[1]-x[0])))
    
    # Remove overlaps
    filtered = []
    last_end = 0
    for s, e, t, r in matches:
        if s >= last_end:
            filtered.append((s, e, t, r))
            last_end = e
    
    # Build tokens
    tokens = []
    pos = 0
    for s, e, t, r in filtered:
        if pos < s:
            tokens.append((text[pos:s], NONE))
        tokens.append((t, r))
        pos = e
    if pos < len(text):
        tokens.append((text[pos:], NONE))
    
    return tokens or [(text, NONE)]

def serialize(tokens):
    return '|'.join(f"{t.replace('|','&#124;').replace(':','&#58;')}:{r}" for t, r in tokens)

def main():
    db_path = sys.argv[1] if len(sys.argv) > 1 else 'assets/quran_data/quran_scripts/indopak-nastaleeq.db'
    
    if not Path(db_path).exists():
        print(f"Error: {db_path} not found")
        return
    
    print(f"Processing {db_path}...")
    print("Patterns:")
    print(f"  Iqlab: {PATTERN_IQLAB}")
    print(f"  Gunnah: {PATTERN_GUNNAH}")
    print(f"  Qalqala: {PATTERN_QALQALA}")
    
    conn = sqlite3.connect(db_path)
    conn.execute("PRAGMA journal_mode=WAL")
    conn.execute("PRAGMA synchronous=NORMAL")
    cur = conn.cursor()
    
    cur.execute("PRAGMA table_info(words)")
    if 'text_tajweed' not in [c[1] for c in cur.fetchall()]:
        cur.execute("ALTER TABLE words ADD COLUMN text_tajweed TEXT")
    
    cur.execute("SELECT id, text FROM words")
    words = cur.fetchall()
    total = len(words)
    print(f"\nTotal words: {total}")
    
    batch = []
    stats = {i: 0 for i in range(7)}
    
    for i, (wid, text) in enumerate(words):
        tokens = tokenize(text) if text else [(text, NONE)]
        batch.append((serialize(tokens), wid))
        for _, r in tokens:
            stats[r] += 1
        
        if len(batch) >= 5000:
            cur.executemany("UPDATE words SET text_tajweed=? WHERE id=?", batch)
            conn.commit()
            batch = []
            print(f"  {i+1}/{total} ({100*(i+1)//total}%)")
    
    if batch:
        cur.executemany("UPDATE words SET text_tajweed=? WHERE id=?", batch)
        conn.commit()
    
    conn.close()
    
    print(f"\nDone! Processed {total} words.")
    print("\nStatistics:")
    names = ["Ghunna", "Qalqala", "Ikhfaa", "Idgham+G", "Idgham-G", "Iqlab", "None"]
    for i, n in enumerate(names):
        print(f"  {n}: {stats[i]}")

if __name__ == '__main__':
    main()
