import sqlite3

layout_path = r"E:\Munajat App\munajat_e_maqbool_app\assets\quran_data\mushaf_layout_data\qudratullah-indopak-15-lines.db"

conn = sqlite3.connect(layout_path)
c = conn.cursor()

print("=== Pages table schema ===")
c.execute("PRAGMA table_info(pages)")
for col in c.fetchall():
    print(col)

print("\n=== All lines from page 1 ===")
c.execute("SELECT * FROM pages WHERE page_number = 1")
rows = c.fetchall()
for row in rows:
    print(row)

print("\n=== All lines from page 2 ===")
c.execute("SELECT * FROM pages WHERE page_number = 2")
rows = c.fetchall()
for row in rows:
    print(row)

conn.close()
