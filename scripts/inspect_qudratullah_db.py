import sqlite3

db_path = r"E:\Munajat App\munajat_e_maqbool_app\assets\quran_data\mushaf_layout_data\qudratullah-indopak-15-lines.db"

conn = sqlite3.connect(db_path)
c = conn.cursor()

# List all tables
c.execute("SELECT name FROM sqlite_master WHERE type='table'")
tables = c.fetchall()
print("ALL TABLES:", [t[0] for t in tables])

# Get schema for pages table
print("\n--- Schema for pages ---")
c.execute("PRAGMA table_info(pages)")
for col in c.fetchall():
    print(col)

# Get schema for info table
print("\n--- Schema for info ---")
c.execute("PRAGMA table_info(info)")
for col in c.fetchall():
    print(col)

# Sample data
print("\n--- Sample pages data ---")
c.execute("SELECT * FROM pages LIMIT 5")
for row in c.fetchall():
    print(row)

print("\n--- Sample info data ---")
c.execute("SELECT * FROM info")
for row in c.fetchall():
    print(row)

conn.close()
