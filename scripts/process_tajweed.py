#!/usr/bin/env python3
"""
Tajweed Pre-processor for Quran Database

This script processes the indopak-nastaleeq.db SQLite database and adds
Tajweed color tags to each word. The tags are stored in a 'text_tajweed' column.

Format: "text_segment:rule_index|text_segment:rule_index|..."

Rule indices:
0 = LAFZATULLAH (green)
1 = izhar (cyan)
2 = ikhfaa (red)
3 = idghamWithGhunna (pink)
4 = iqlab (blue)
5 = qalqala (olive)
6 = idghamWithoutGhunna (grey)
7 = ghunna (orange)
8 = prolonging (purple)
9 = alefTafreeq (grey)
10 = hamzatulWasli (grey)
11 = none (default)
"""

import sqlite3
import re
import os
from pathlib import Path

# Tajweed Rule indices (matching the Dart enum order)
RULE_LAFZATULLAH = 0
RULE_IZHAR = 1
RULE_IKHFAA = 2
RULE_IDGHAM_WITH_GHUNNA = 3
RULE_IQLAB = 4
RULE_QALQALA = 5
RULE_IDGHAM_WITHOUT_GHUNNA = 6
RULE_GHUNNA = 7
RULE_PROLONGING = 8
RULE_ALEF_TAFREEQ = 9
RULE_HAMZATUL_WASLI = 10
RULE_NONE = 11

# Arabic Unicode constants
SMALL_HIGH_LETTERS = r'[\u06DA\u06D6\u06D7\u06D8\u06D9\u06DB\u06E2\u06ED]'
FATHA_KASRA_DAMMA_WITH_TANVIN = r'[\u064B\u064C\u064D\u08F0\u08F1\u08F2]'
NOON_SAKIN = r'\u0646\u0652'
MEEM_SAKIN = r'\u0645\u0652'
SUKOON = r'\u0652'
SHADDA = r'\u0651'

# Tajweed patterns (simplified for word-level processing)
PATTERNS = [
    # Ghunna (noon + shadda or meem + shadda)
    (re.compile(r'(\u0646\u0651|\u0645\u0651)'), RULE_GHUNNA),
    
    # Qalqala letters with sukoon
    (re.compile(r'([\u0642\u0637\u0628\u062C\u062F]\u0652)'), RULE_QALQALA),
    
    # Ikhfaa - noon sakin/tanween followed by ikhfaa letters
    (re.compile(r'(\u0646\u0652[\u062A\u062B\u062C\u062F\u0630\u0632\u0633\u0634\u0635\u0636\u0637\u0638\u0641\u0642\u0643])'), RULE_IKHFAA),
    (re.compile(r'(' + FATHA_KASRA_DAMMA_WITH_TANVIN + r'[\u062A\u062B\u062C\u062F\u0630\u0632\u0633\u0634\u0635\u0636\u0637\u0638\u0641\u0642\u0643])'), RULE_IKHFAA),
    
    # Iqlab - noon sakin/tanween followed by ba
    (re.compile(r'(\u0646\u0652\u0628)'), RULE_IQLAB),
    (re.compile(r'(' + FATHA_KASRA_DAMMA_WITH_TANVIN + r'\u0628)'), RULE_IQLAB),
    
    # Idgham with Ghunna - noon sakin/tanween followed by ya/noon/meem/waw
    (re.compile(r'(\u0646\u0652[\u064A\u0646\u0645\u0648])'), RULE_IDGHAM_WITH_GHUNNA),
    (re.compile(r'(' + FATHA_KASRA_DAMMA_WITH_TANVIN + r'[\u064A\u0646\u0645\u0648])'), RULE_IDGHAM_WITH_GHUNNA),
    
    # Idgham without Ghunna - noon sakin/tanween followed by lam/ra
    (re.compile(r'(\u0646\u0652[\u0644\u0631])'), RULE_IDGHAM_WITHOUT_GHUNNA),
    (re.compile(r'(' + FATHA_KASRA_DAMMA_WITH_TANVIN + r'[\u0644\u0631])'), RULE_IDGHAM_WITHOUT_GHUNNA),
    
    # Izhar - noon sakin/tanween followed by throat letters
    (re.compile(r'(\u0646\u0652[\u0621\u0623\u0625\u0627\u0647\u0639\u063A\u062D\u062E])'), RULE_IZHAR),
    (re.compile(r'(' + FATHA_KASRA_DAMMA_WITH_TANVIN + r'[\u0621\u0623\u0625\u0627\u0647\u0639\u063A\u062D\u062E])'), RULE_IZHAR),
    
    # Prolonging (Madd) - alif/waw/ya with specific vowels before
    (re.compile(r'(\u064E\u0627|\u064F\u0648|\u0650\u064A)'), RULE_PROLONGING),
    
    # Lafzatullah (Allah)
    (re.compile(r'(\u0627?\u0644\u0651?\u0644\u0651?\u0647)'), RULE_LAFZATULLAH),
]

def tokenize_word(text):
    """
    Tokenize a single word into Tajweed segments.
    Returns a list of (text_segment, rule_index) tuples.
    """
    if not text or not text.strip():
        return [(text, RULE_NONE)]
    
    # Find all matches and their positions
    matches = []
    for pattern, rule in PATTERNS:
        for match in pattern.finditer(text):
            matches.append({
                'start': match.start(),
                'end': match.end(),
                'text': match.group(1) if match.groups() else match.group(),
                'rule': rule
            })
    
    if not matches:
        return [(text, RULE_NONE)]
    
    # Sort matches by start position, then by length (longer first)
    matches.sort(key=lambda m: (m['start'], -len(m['text'])))
    
    # Remove overlapping matches (keep the first/longer one)
    filtered = []
    last_end = 0
    for m in matches:
        if m['start'] >= last_end:
            filtered.append(m)
            last_end = m['end']
    
    # Build tokens from filtered matches
    tokens = []
    pos = 0
    for m in filtered:
        # Add non-rule text before this match
        if pos < m['start']:
            tokens.append((text[pos:m['start']], RULE_NONE))
        # Add the matched rule text
        tokens.append((m['text'], m['rule']))
        pos = m['end']
    
    # Add remaining text after last match
    if pos < len(text):
        tokens.append((text[pos:], RULE_NONE))
    
    return tokens if tokens else [(text, RULE_NONE)]

def serialize_tokens(tokens):
    """
    Serialize tokens to a string format: "text:rule|text:rule|..."
    """
    parts = []
    for text, rule in tokens:
        # Escape special characters
        safe_text = text.replace('|', '&#124;').replace(':', '&#58;')
        parts.append(f"{safe_text}:{rule}")
    return '|'.join(parts)

def process_database(db_path):
    """
    Process the database and add Tajweed tags to all words.
    """
    print(f"Opening database: {db_path}")
    
    if not os.path.exists(db_path):
        print(f"Error: Database file not found at {db_path}")
        return False
    
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    # Check if text_tajweed column exists
    cursor.execute("PRAGMA table_info(words)")
    columns = [col[1] for col in cursor.fetchall()]
    print(f"Existing columns: {columns}")
    
    if 'text_tajweed' not in columns:
        print("Adding text_tajweed column...")
        cursor.execute("ALTER TABLE words ADD COLUMN text_tajweed TEXT")
        conn.commit()
    else:
        print("text_tajweed column already exists. Updating...")
    
    # Get all words
    cursor.execute("SELECT id, text FROM words")
    words = cursor.fetchall()
    print(f"Total words to process: {len(words)}")
    
    # Process each word
    count = 0
    batch_size = 1000
    
    for word_id, text in words:
        if text:
            tokens = tokenize_word(text)
            serialized = serialize_tokens(tokens)
            cursor.execute(
                "UPDATE words SET text_tajweed = ? WHERE id = ?",
                (serialized, word_id)
            )
        
        count += 1
        if count % batch_size == 0:
            conn.commit()
            print(f"Processed {count} words...")
    
    conn.commit()
    conn.close()
    
    print(f"Finished processing {count} words.")
    print("Database updated successfully!")
    return True

def main():
    # Get the database path
    script_dir = Path(__file__).parent
    db_path = script_dir.parent / 'assets' / 'quran_data' / 'quran_scripts' / 'indopak-nastaleeq.db'
    
    # Also try from current working directory
    if not db_path.exists():
        db_path = Path('assets/quran_data/quran_scripts/indopak-nastaleeq.db')
    
    if not db_path.exists():
        print("Please provide the path to indopak-nastaleeq.db as an argument")
        print("Usage: python process_tajweed.py [path_to_db]")
        import sys
        if len(sys.argv) > 1:
            db_path = Path(sys.argv[1])
        else:
            return
    
    process_database(str(db_path))

if __name__ == '__main__':
    main()
