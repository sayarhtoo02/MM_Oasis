import sqlite3
import os

db_path = r"e:\Munajat App\munajat_e_maqbool_app\assets\quran_data\mushaf_layout_data\qudratullah-indopak-15-lines.db"

if not os.path.exists(db_path):
    print(f"Error: Database not found at {db_path}")
    exit(1)

try:
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # List tables
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
    tables = cursor.fetchall()
    print("Tables found:", [t[0] for t in tables])

    for table_name in tables:
        table = table_name[0]
        print(f"\n--- Schema for table: {table} ---")
        cursor.execute(f"PRAGMA table_info({table})")
        columns = cursor.fetchall()
        for col in columns:
            print(col)
        
        print(f"\n--- Sample data for table: {table} (Limit 5) ---")
        cursor.execute(f"SELECT * FROM {table} LIMIT 5")
        rows = cursor.fetchall()
        for row in rows:
            print(row)

    conn.close()

except sqlite3.Error as e:
    print(f"SQLite error: {e}")
except Exception as e:
    print(f"Error: {e}")
