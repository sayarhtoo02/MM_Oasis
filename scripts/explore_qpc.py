#!/usr/bin/env python3
"""Explore the qpc-v4.db database structure"""

import sqlite3

db_path = 'assets/quran_data/quran_scripts/qpc-v4.db'
conn = sqlite3.connect(db_path)
cur = conn.cursor()

# Get all tables
cur.execute("SELECT name FROM sqlite_master WHERE type='table'")
tables = [t[0] for t in cur.fetchall()]
print("Tables:", tables)

# Explore each table structure
for table in tables:
    print(f"\n=== {table} ===")
    cur.execute(f"PRAGMA table_info({table})")
    columns = cur.fetchall()
    print("Columns:", [(c[1], c[2]) for c in columns])
    
    cur.execute(f"SELECT * FROM {table} LIMIT 5")
    rows = cur.fetchall()
    print("Sample rows:")
    for row in rows:
        print(f"  {row}")

conn.close()
