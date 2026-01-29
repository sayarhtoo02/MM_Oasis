import sqlite3
import os

src_path = 'data_archive/quran_data/mushaf_layout_data/qudratullah-indopak-15-lines.db'
dest_path = 'assets/oasismm.db'

print(f"Checking {src_path}...")
if os.path.exists(src_path):
    src = sqlite3.connect(src_path)
    c = src.cursor()
    c.execute('SELECT name FROM sqlite_master WHERE type="table"')
    print(f"Source Tables: {c.fetchall()}")
    src.close()
else:
    print("Source not found")

print(f"Checking {dest_path}...")
if os.path.exists(dest_path):
    dest = sqlite3.connect(dest_path)
    c = dest.cursor()
    c.execute('SELECT name FROM sqlite_master WHERE type="table" AND name="mashaf_pages"')
    if c.fetchone():
        c.execute('SELECT COUNT(*) FROM mashaf_pages')
        print(f"Mashaf Pages Count: {c.fetchone()[0]}")
    else:
        print("Table mashaf_pages not found")
    dest.close()
else:
    print("Destination not found")
