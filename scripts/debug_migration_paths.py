
import sqlite3
from pathlib import Path
import os

ASSETS_DIR = Path("assets").absolute()
ARCHIVE_DIR = Path("data_archive").absolute()

def check_indopak():
    print("-" * 50)
    print("Checking IndoPak DB Paths:")
    
    path1 = ASSETS_DIR / "quran_data" / "quran_scripts" / "indopak-nastaleeq.db"
    path2 = ARCHIVE_DIR / "quran_data" / "quran_scripts" / "indopak-nastaleeq.db"
    
    print(f"Path 1 (Assets): {path1} | Exists: {path1.exists()}")
    print(f"Path 2 (Archive): {path2} | Exists: {path2.exists()}")
    
    valid_path = path1 if path1.exists() else (path2 if path2.exists() else None)
    
    if valid_path:
        print(f"Valid DB found at: {valid_path}")
        try:
            conn = sqlite3.connect(str(valid_path))
            cursor = conn.cursor()
            cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
            tables = [r[0] for r in cursor.fetchall()]
            print(f"Tables in source DB: {tables}")
            
            if 'words' in tables:
                cursor.execute("SELECT COUNT(*) FROM words")
                count = cursor.fetchone()[0]
                print(f"Count in 'words' table: {count}")
            conn.close()
        except Exception as e:
            print(f"Error connecting to source DB: {e}")
    else:
        print("❌ NO VALID INDOPAK DB FOUND")

def check_dua_dirs():
    print("-" * 50)
    print("Checking Dua Directories:")
    
    path1 = ASSETS_DIR / "dua_data"
    path2 = ARCHIVE_DIR / "dua_data"
    
    print(f"Path 1 (Assets): {path1} | Exists: {path1.exists()}")
    print(f"Path 2 (Archive): {path2} | Exists: {path2.exists()}")
    
    base_dir = path1 if path1.exists() else (path2 if path2.exists() else None)
    
    if base_dir:
         print(f"Base dir: {base_dir}")
         dhikr_dir = base_dir / "dua-dhikr"
         print(f"Dhikr dir: {dhikr_dir} | Exists: {dhikr_dir.exists()}")
         if dhikr_dir.exists():
             for child in dhikr_dir.iterdir():
                 if child.is_dir():
                     json_files = list(child.glob("*.json"))
                     print(f"  Category: {child.name} | JSON Files: {len(json_files)}")

if __name__ == "__main__":
    print(f"CWD: {os.getcwd()}")
    check_indopak()
    check_dua_dirs()
