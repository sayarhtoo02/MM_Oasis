#!/usr/bin/env python3
"""Explore remaining database files to add to consolidated DB"""
import sqlite3
from pathlib import Path

ASSETS = Path(__file__).parent.parent / "assets"

dbs = [
    ASSETS / "quran_data" / "quran_scripts" / "indopak-nastaleeq.db",
    ASSETS / "quran_data" / "quran_scripts" / "qpc-v4.db",
    ASSETS / "quran_data" / "mushaf_layout_data" / "qudratullah-indopak-15-lines.db",
]

for db_path in dbs:
    print(f"\n{'='*60}")
    print(f"DATABASE: {db_path.name}")
    print(f"SIZE: {db_path.stat().st_size / 1024:.1f} KB")
    print('='*60)
    
    conn = sqlite3.connect(str(db_path))
    c = conn.cursor()
    
    # Get tables
    c.execute("SELECT name FROM sqlite_master WHERE type='table'")
    tables = [r[0] for r in c.fetchall()]
    print(f"TABLES: {tables}")
    
    for table in tables:
        c.execute(f"PRAGMA table_info({table})")
        cols = [r[1] for r in c.fetchall()]
        c.execute(f"SELECT COUNT(*) FROM {table}")
        count = c.fetchone()[0]
        print(f"\n  {table} ({count} rows): {cols}")
        
        # Sample data
        c.execute(f"SELECT * FROM {table} LIMIT 2")
        for row in c.fetchall():
            print(f"    Sample: {row[:5]}...")
    
    conn.close()
