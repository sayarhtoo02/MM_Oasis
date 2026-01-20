import sqlite3
import os

db_path = r"e:\Munajat App\munajat_e_maqbool_app\assets\quran_data\mushaf_layout_data\qudratullah-indopak-15-lines.db"
output_file = r"e:\Munajat App\munajat_e_maqbool_app\db_schema.txt"

if not os.path.exists(db_path):
    with open(output_file, 'w') as f:
        f.write(f"Error: Database not found at {db_path}")
    exit(1)

try:
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    with open(output_file, 'w', encoding='utf-8') as f:
        # List tables
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
        tables = cursor.fetchall()
        f.write(f"Tables found: {[t[0] for t in tables]}\n")

        for table_name in tables:
            table = table_name[0]
            f.write(f"\n--- Schema for table: {table} ---\n")
            cursor.execute(f"PRAGMA table_info({table})")
            columns = cursor.fetchall()
            for col in columns:
                f.write(f"  {col}\n")
            
            f.write(f"\n--- First row for table: {table} ---\n")
            cursor.execute(f"SELECT * FROM {table} LIMIT 1")
            row = cursor.fetchone()
            f.write(f"  {row}\n")

    conn.close()

except Exception as e:
    with open(output_file, 'w') as f:
        f.write(f"Error: {e}")
