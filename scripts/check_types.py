import sqlite3

# Check pages table schema and data types
layout_path = r"E:\Munajat App\munajat_e_maqbool_app\assets\quran_data\mushaf_layout_data\qudratullah-indopak-15-lines.db"
conn = sqlite3.connect(layout_path)
c = conn.cursor()

print("=== pages schema ===")
c.execute("PRAGMA table_info(pages)")
for col in c.fetchall():
    print(col)

print("\n=== Sample pages data with types ===")
c.execute("SELECT * FROM pages WHERE page_number = 1")
rows = c.fetchall()
for row in rows:
    print(f"Row: {row}")
    print(f"Types: {[type(x).__name__ for x in row]}")
    print()

conn.close()
