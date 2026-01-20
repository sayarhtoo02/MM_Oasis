#!/usr/bin/env python3
"""Check qpc-v4.db for Tajweed data"""

import sqlite3

db_path = 'assets/quran_data/quran_scripts/qpc-v4.db'
conn = sqlite3.connect(db_path)
cur = conn.cursor()

# Get total count
cur.execute("SELECT COUNT(*) FROM words")
total = cur.fetchone()[0]
print(f"Total words: {total}")

# Get sample from different surahs
print("\n=== Sample words with codepoints ===")
cur.execute("SELECT id, surah, ayah, word, text FROM words WHERE surah = 2 AND ayah <= 10")
rows = cur.fetchall()

for row in rows[:20]:
    wid, surah, ayah, word, text = row
    codepoints = ' '.join([f'U+{ord(c):04X}' for c in text])
    print(f"{surah}:{ayah}:{word} - '{text}' = [{codepoints}]")

# Check if there are any Uthmani style characters
print("\n=== Character frequency ===")
cur.execute("SELECT text FROM words")
all_words = cur.fetchall()

from collections import Counter
char_count = Counter()
for (text,) in all_words:
    if text:
        for c in text:
            char_count[c] += 1

print("Top 50 characters:")
for char, count in char_count.most_common(50):
    print(f"  '{char}' (U+{ord(char):04X}): {count}")

conn.close()
