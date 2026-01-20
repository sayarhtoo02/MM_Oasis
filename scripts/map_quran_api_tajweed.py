#!/usr/bin/env python3
"""
Apply Tajweed rules from Quran.com API to Indopak database
Character-level mapping: Only tagged letters get colored
"""

import sqlite3
import json
import re
import os

# Tajweed rule mapping
RULE_MAP = {
    'ghunnah': 0,
    'qalaqah': 1,
    'ikhafa': 2,
    'ikhafa_shafawi': 2,
    'idgham_ghunnah': 3,
    'idgham_shafawi': 3,
    'idgham_no_ghunnah': 4,
    'idgham_mutajanisayn': 4,
    'idgham_mutaqaribayn': 4,
    'iqlab': 5,
    'madda_normal': 6,
    'madda_permissible': 6,
    'madda_obligatory_mottasel': 6,
    'madda_obligatory_monfasel': 6,
    'ham_wasl': 7,
    'laam_shamsiyah': 8,
    'slnt': 9,
}
RULE_NONE = 11

def parse_tajweed_segments(tajweed_text):
    """
    Parse Tajweed HTML tags and return list of (text, rule_index) segments
    This preserves character-level information
    """
    if not tajweed_text:
        return []
    
    # Pattern: <rule class=NAME>TEXT</rule>
    segments = []
    last_end = 0
    
    for match in re.finditer(r'<rule class=([a-z_]+)>(.*?)</rule>', tajweed_text, re.DOTALL):
        # Plain text before this tag
        if match.start() > last_end:
            plain = tajweed_text[last_end:match.start()]
            if plain:
                segments.append((plain, RULE_NONE))
        
        # Tagged text
        rule_class = match.group(1)
        rule_text = match.group(2)
        rule_idx = RULE_MAP.get(rule_class, RULE_NONE)
        if rule_text:
            segments.append((rule_text, rule_idx))
        
        last_end = match.end()
    
    # Remaining text after last tag
    if last_end < len(tajweed_text):
        remaining = tajweed_text[last_end:]
        if remaining:
            segments.append((remaining, RULE_NONE))
    
    return segments

def map_to_indopak(indopak_text, api_segments):
    """
    Map API segments to Indopak text
    Returns properly formatted segments using Indopak characters
    """
    if not indopak_text:
        return []
    
    if not api_segments:
        return [(indopak_text, RULE_NONE)]
    
    # Calculate character proportions
    api_chars = sum(len(seg[0]) for seg in api_segments)
    indopak_len = len(indopak_text)
    
    if api_chars == 0:
        return [(indopak_text, RULE_NONE)]
    
    result = []
    indopak_pos = 0
    
    for api_text, rule in api_segments:
        seg_len = len(api_text)
        # Calculate proportional length in Indopak
        proportion = seg_len / api_chars
        indopak_seg_len = round(proportion * indopak_len)
        
        # Ensure we don't go past the end
        if indopak_pos + indopak_seg_len > indopak_len:
            indopak_seg_len = indopak_len - indopak_pos
        
        # Ensure at least 1 character for non-empty segments
        if seg_len > 0 and indopak_seg_len == 0 and indopak_pos < indopak_len:
            indopak_seg_len = 1
        
        if indopak_seg_len > 0:
            indopak_segment = indopak_text[indopak_pos:indopak_pos + indopak_seg_len]
            result.append((indopak_segment, rule))
            indopak_pos += indopak_seg_len
    
    # Handle any remaining characters
    if indopak_pos < indopak_len:
        result.append((indopak_text[indopak_pos:], RULE_NONE))
    
    return result if result else [(indopak_text, RULE_NONE)]

def serialize_segments(segments):
    """Serialize segments to format: text:rule|text:rule"""
    parts = []
    for text, rule in segments:
        safe_text = text.replace('|', '&#124;').replace(':', '&#58;')
        parts.append(f"{safe_text}:{rule}")
    return '|'.join(parts)

def main():
    json_path = 'quran_tajweed_api.json'
    db_path = 'assets/quran_data/quran_scripts/indopak-nastaleeq.db'
    
    print(f"Loading API data...")
    with open(json_path, 'r', encoding='utf-8') as f:
        api_data = json.load(f)
    
    # Index by (surah, ayah, word)
    api_index = {(w['surah'], w['ayah'], w['word']): w for w in api_data}
    print(f"Loaded {len(api_index)} words")
    
    print(f"Opening database...")
    conn = sqlite3.connect(db_path)
    conn.execute("PRAGMA journal_mode=WAL")
    cur = conn.cursor()
    
    cur.execute("PRAGMA table_info(words)")
    if 'text_tajweed' not in [c[1] for c in cur.fetchall()]:
        cur.execute("ALTER TABLE words ADD COLUMN text_tajweed TEXT")
    
    cur.execute("SELECT id, surah, ayah, word, text FROM words")
    db_words = cur.fetchall()
    print(f"Database has {len(db_words)} words")
    
    stats = {i: 0 for i in range(12)}
    updates = []
    count = 0
    
    for word_id, surah, ayah, word_num, indopak_text in db_words:
        api_word = api_index.get((surah, ayah, word_num))
        
        if api_word and api_word.get('text_tajweed'):
            # Parse API tags
            api_segments = parse_tajweed_segments(api_word['text_tajweed'])
            # Map to Indopak text
            segments = map_to_indopak(indopak_text, api_segments)
        else:
            segments = [(indopak_text, RULE_NONE)] if indopak_text else [('', RULE_NONE)]
        
        serialized = serialize_segments(segments)
        updates.append((serialized, word_id))
        
        for _, rule in segments:
            stats[rule] += 1
        
        count += 1
        if len(updates) >= 5000:
            cur.executemany("UPDATE words SET text_tajweed=? WHERE id=?", updates)
            conn.commit()
            print(f"  {count} words...")
            updates = []
    
    if updates:
        cur.executemany("UPDATE words SET text_tajweed=? WHERE id=?", updates)
        conn.commit()
    
    conn.close()
    
    print(f"\nDone! {count} words processed")
    print("\nStatistics:")
    names = {0: "Ghunna", 1: "Qalqala", 2: "Ikhfa", 3: "Idgham+G", 4: "Idgham-G",
             5: "Iqlab", 6: "Madd", 7: "Hamzat Wasl", 8: "Lam Shams", 9: "Silent", 11: "None"}
    for i, name in names.items():
        if stats.get(i, 0) > 0:
            print(f"  {name}: {stats[i]}")

if __name__ == '__main__':
    main()
