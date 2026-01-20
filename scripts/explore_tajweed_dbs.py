#!/usr/bin/env python3
"""Explore all Tajweed databases"""

import sqlite3
import os

tajweed_dbs = [
    'assets/quran_data/tajweed/ayah-lemma.db',
    'assets/quran_data/tajweed/ayah-root.db',
    'assets/quran_data/tajweed/ayah-stem.db',
    'assets/quran_data/tajweed/word-lemma.db',
    'assets/quran_data/tajweed/word-root.db',
    'assets/quran_data/tajweed/word-stem.db',
]

for db_path in tajweed_dbs:
    if not os.path.exists(db_path):
        print(f"\n{db_path}: NOT FOUND")
        continue
        
    print(f"\n{'='*60}")
    print(f"DATABASE: {db_path}")
    print('='*60)
    
    conn = sqlite3.connect(db_path)
    cur = conn.cursor()
    
    cur.execute("SELECT name FROM sqlite_master WHERE type='table'")
    tables = [t[0] for t in cur.fetchall()]
    print(f"Tables: {tables}")
    
    for table in tables:
        print(f"\n--- {table} ---")
        cur.execute(f"PRAGMA table_info({table})")
        columns = cur.fetchall()
        print(f"Columns: {[(c[1], c[2]) for c in columns]}")
        
        cur.execute(f"SELECT * FROM {table} LIMIT 3")
        rows = cur.fetchall()
        for row in rows:
            print(f"  {row}")
    
    conn.close()
