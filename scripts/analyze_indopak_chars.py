#!/usr/bin/env python3
"""
Analyze Indopak script characters to understand the Unicode encoding
This will help us create accurate Tajweed rules for Indopak script.
"""

import sqlite3
import os
from collections import Counter

def analyze_characters(db_path):
    """Analyze all unique characters in the database."""
    print(f"Opening database: {db_path}")
    
    if not os.path.exists(db_path):
        print(f"Error: Database file not found at {db_path}")
        return
    
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    # Get sample words
    cursor.execute("SELECT id, text FROM words LIMIT 100")
    sample_words = cursor.fetchall()
    
    print("\n=== SAMPLE WORDS ===")
    for word_id, text in sample_words[:20]:
        # Show the text and its Unicode codepoints
        codepoints = ' '.join([f'U+{ord(c):04X}' for c in text])
        print(f"ID {word_id}: {text}")
        print(f"   Codepoints: {codepoints}")
        print()
    
    # Count all characters
    cursor.execute("SELECT text FROM words")
    all_words = cursor.fetchall()
    
    char_counter = Counter()
    for (text,) in all_words:
        if text:
            for char in text:
                char_counter[char] += 1
    
    print("\n=== ALL UNIQUE CHARACTERS (sorted by frequency) ===")
    for char, count in char_counter.most_common():
        codepoint = f'U+{ord(char):04X}'
        char_name = get_char_name(char)
        print(f"'{char}' ({codepoint}) - {char_name}: {count} occurrences")
    
    # Identify diacritical marks (harakat)
    print("\n=== DIACRITICAL MARKS ===")
    diacritics = []
    for char in char_counter:
        code = ord(char)
        # Arabic diacritics range
        if 0x064B <= code <= 0x065F or 0x0670 <= code <= 0x0672:
            diacritics.append((char, code, char_counter[char]))
    
    for char, code, count in sorted(diacritics, key=lambda x: x[1]):
        print(f"'{char}' (U+{code:04X}): {count}")
    
    # Identify letters
    print("\n=== ARABIC LETTERS ===")
    letters = []
    for char in char_counter:
        code = ord(char)
        # Arabic letters range
        if 0x0621 <= code <= 0x064A:
            letters.append((char, code, char_counter[char]))
    
    for char, code, count in sorted(letters, key=lambda x: x[1]):
        print(f"'{char}' (U+{code:04X}): {count}")
    
    conn.close()

def get_char_name(char):
    """Get character name if available."""
    import unicodedata
    try:
        return unicodedata.name(char)
    except ValueError:
        return "UNKNOWN"

if __name__ == '__main__':
    import sys
    if len(sys.argv) > 1:
        db_path = sys.argv[1]
    else:
        db_path = 'assets/quran_data/quran_scripts/indopak-nastaleeq.db'
    
    analyze_characters(db_path)
