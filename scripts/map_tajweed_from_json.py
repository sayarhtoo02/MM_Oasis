#!/usr/bin/env python3
"""
Map Tajweed annotations from cpfair/quran-tajweed to our Indopak database
Uses ayah-level mapping since word boundaries may differ
"""

import sqlite3
import json
import sys
from collections import defaultdict

# Rule name to index mapping
RULE_MAP = {
    'ghunnah': 0,
    'qalqalah': 1,
    'ikhfa': 2,
    'ikhfa_shafawi': 2,  # Same color as ikhfaa
    'idghaam_ghunnah': 3,
    'idghaam_shafawi': 3,  # Same color
    'idghaam_no_ghunnah': 4,
    'idghaam_mutajanisayn': 4,
    'idghaam_mutaqaribayn': 4,
    'iqlab': 5,
    'madd_2': 6,
    'madd_246': 6,
    'madd_6': 6,
    'madd_munfasil': 6,
    'madd_muttasil': 6,
    'hamzat_wasl': 7,
    'lam_shamsiyyah': 8,
    'silent': 9,
}
RULE_NONE = 10

def load_tajweed_data(json_path):
    """Load and index tajweed annotations by surah:ayah"""
    with open(json_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    # Index by (surah, ayah)
    indexed = {}
    for entry in data:
        key = (entry['surah'], entry['ayah'])
        indexed[key] = entry['annotations']
    
    return indexed

def build_ayah_text(conn, surah, ayah):
    """Build full ayah text from words and track word boundaries"""
    cur = conn.cursor()
    cur.execute("""
        SELECT id, word, text FROM words 
        WHERE surah = ? AND ayah = ? 
        ORDER BY word
    """, (surah, ayah))
    
    words = cur.fetchall()
    
    # Track word boundaries in the combined text
    boundaries = []  # (start, end, word_id, text)
    pos = 0
    
    for word_id, word_num, text in words:
        if text:
            start = pos
            end = pos + len(text)
            boundaries.append((start, end, word_id, text))
            pos = end + 1  # +1 for space
    
    return boundaries

def apply_annotations_to_words(boundaries, annotations):
    """Apply ayah-level annotations to individual words"""
    word_tags = {}  # word_id -> list of (char_start, char_end, rule)
    
    for ann in annotations:
        rule_name = ann['rule']
        if rule_name not in RULE_MAP:
            continue
        
        rule_idx = RULE_MAP[rule_name]
        ann_start = ann['start']
        ann_end = ann['end']
        
        # Find which words this annotation overlaps with
        for word_start, word_end, word_id, word_text in boundaries:
            # Check for overlap
            overlap_start = max(ann_start, word_start)
            overlap_end = min(ann_end, word_end)
            
            if overlap_start < overlap_end:
                # Convert to word-relative positions
                local_start = overlap_start - word_start
                local_end = overlap_end - word_start
                
                if word_id not in word_tags:
                    word_tags[word_id] = []
                word_tags[word_id].append((local_start, local_end, rule_idx))
    
    return word_tags

def serialize_word_tags(text, tags):
    """Serialize tags into our format: text:rule|text:rule"""
    if not tags:
        return f"{text.replace('|','&#124;').replace(':','&#58;')}:{RULE_NONE}"
    
    # Sort tags by position
    tags.sort(key=lambda t: t[0])
    
    # Remove overlaps
    filtered = []
    last_end = 0
    for start, end, rule in tags:
        if start >= last_end:
            filtered.append((start, end, rule))
            last_end = end
    
    # Build tokens
    parts = []
    pos = 0
    for start, end, rule in filtered:
        if pos < start:
            chunk = text[pos:start]
            parts.append(f"{chunk.replace('|','&#124;').replace(':','&#58;')}:{RULE_NONE}")
        chunk = text[start:end]
        parts.append(f"{chunk.replace('|','&#124;').replace(':','&#58;')}:{rule}")
        pos = end
    
    if pos < len(text):
        chunk = text[pos:]
        parts.append(f"{chunk.replace('|','&#124;').replace(':','&#58;')}:{RULE_NONE}")
    
    return '|'.join(parts) if parts else f"{text.replace('|','&#124;').replace(':','&#58;')}:{RULE_NONE}"

def main():
    db_path = sys.argv[1] if len(sys.argv) > 1 else 'assets/quran_data/quran_scripts/indopak-nastaleeq.db'
    json_path = 'temp_quran_tajweed/output/tajweed.hafs.uthmani-pause-sajdah.json'
    
    print(f"Loading Tajweed data from {json_path}...")
    tajweed_data = load_tajweed_data(json_path)
    print(f"Loaded annotations for {len(tajweed_data)} ayahs")
    
    print(f"\nOpening database {db_path}...")
    conn = sqlite3.connect(db_path)
    conn.execute("PRAGMA journal_mode=WAL")
    cur = conn.cursor()
    
    # Ensure column exists
    cur.execute("PRAGMA table_info(words)")
    if 'text_tajweed' not in [c[1] for c in cur.fetchall()]:
        cur.execute("ALTER TABLE words ADD COLUMN text_tajweed TEXT")
    
    # Get all unique (surah, ayah) combinations
    cur.execute("SELECT DISTINCT surah, ayah FROM words ORDER BY surah, ayah")
    ayahs = cur.fetchall()
    print(f"Total ayahs in database: {len(ayahs)}")
    
    # Process each ayah
    stats = defaultdict(int)
    updates = []
    
    for i, (surah, ayah) in enumerate(ayahs):
        # Get word boundaries
        boundaries = build_ayah_text(conn, surah, ayah)
        
        # Get annotations for this ayah
        annotations = tajweed_data.get((surah, ayah), [])
        
        # Apply annotations to words
        word_tags = apply_annotations_to_words(boundaries, annotations)
        
        # Serialize each word
        for word_start, word_end, word_id, text in boundaries:
            tags = word_tags.get(word_id, [])
            serialized = serialize_word_tags(text, tags)
            updates.append((serialized, word_id))
            
            # Count rules
            if tags:
                for _, _, rule in tags:
                    stats[rule] += 1
            else:
                stats[RULE_NONE] += 1
        
        if (i + 1) % 500 == 0:
            print(f"  Processed {i+1}/{len(ayahs)} ayahs...")
            cur.executemany("UPDATE words SET text_tajweed=? WHERE id=?", updates)
            conn.commit()
            updates = []
    
    # Final batch
    if updates:
        cur.executemany("UPDATE words SET text_tajweed=? WHERE id=?", updates)
        conn.commit()
    
    conn.close()
    
    print(f"\nDone!")
    print("\nStatistics:")
    names = {0: "Ghunna", 1: "Qalqala", 2: "Ikhfaa", 3: "Idgham+G", 4: "Idgham-G",
             5: "Iqlab", 6: "Madd", 7: "Hamzat Wasl", 8: "Lam Shams", 9: "Silent", 10: "None"}
    for rule, count in sorted(stats.items()):
        print(f"  {names.get(rule, rule)}: {count}")

if __name__ == '__main__':
    main()
