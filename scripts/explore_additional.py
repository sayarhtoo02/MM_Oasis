"""Explore additional database structures"""
import sqlite3
import json
from pathlib import Path

ASSETS = Path("assets/quran_data")

def explore_db(db_path, name):
    print(f"\n=== {name} ===")
    print(f"Path: {db_path}")
    try:
        conn = sqlite3.connect(str(db_path))
        c = conn.cursor()
        c.execute("SELECT name FROM sqlite_master WHERE type='table'")
        tables = [r[0] for r in c.fetchall()]
        print(f"Tables: {tables}")
        
        for table in tables[:3]:  # First 3 tables
            c.execute(f"PRAGMA table_info({table})")
            cols = [r[1] for r in c.fetchall()]
            c.execute(f"SELECT COUNT(*) FROM {table}")
            count = c.fetchone()[0]
            print(f"  {table}: {count} rows, columns: {cols}")
            
            # Sample row
            c.execute(f"SELECT * FROM {table} LIMIT 1")
            row = c.fetchone()
            if row:
                print(f"    Sample: {str(row)[:200]}...")
        conn.close()
    except Exception as e:
        print(f"Error: {e}")

def explore_folder(folder_path, name):
    print(f"\n=== {name} ===")
    print(f"Path: {folder_path}")
    folder = Path(folder_path)
    if folder.exists():
        files = list(folder.iterdir())[:5]
        print(f"Total files: {len(list(folder.iterdir()))}")
        for f in files:
            print(f"  {f.name}")
            if f.suffix == '.json':
                try:
                    with open(f, 'r', encoding='utf-8') as jf:
                        data = json.load(jf)
                    if isinstance(data, list):
                        print(f"    List with {len(data)} items")
                    elif isinstance(data, dict):
                        print(f"    Dict with keys: {list(data.keys())[:5]}")
                except Exception as e:
                    print(f"    Error: {e}")

# Explore DBs
explore_db(ASSETS / "en-tafisr-ibn-kathir.db", "English Ibn Kathir Tafseer DB")
explore_db(ASSETS / "quran_scripts" / "indopak-nastaleeq.db", "IndoPak Nastaleeq DB")
explore_db(ASSETS / "quran_scripts" / "qpc-v4.db", "QPC v4 DB")

# Explore folders
explore_folder(ASSETS / "tasfeer-ibn-kasir" / "my-ibn-kasir", "Myanmar Ibn Kasir Tafseer")
explore_folder(ASSETS / "tasfeer-ibn-kasir" / "en-ibn-kasir", "English Ibn Kasir Tafseer")
