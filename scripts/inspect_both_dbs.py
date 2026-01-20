import sqlite3

# Check both databases

print("=== LAYOUT DATABASE ===")
layout_path = r"E:\Munajat App\munajat_e_maqbool_app\assets\quran_data\mushaf_layout_data\qudratullah-indopak-15-lines.db"
conn = sqlite3.connect(layout_path)
c = conn.cursor()

c.execute("SELECT name FROM sqlite_master WHERE type='table'")
print("Tables:", [t[0] for t in c.fetchall()])

print("\n--- pages schema ---")
c.execute("PRAGMA table_info(pages)")
for col in c.fetchall():
    print(col)

print("\n--- pages sample ---")
c.execute("SELECT * FROM pages LIMIT 3")
for row in c.fetchall():
    print(row)

print("\n--- info schema ---")
c.execute("PRAGMA table_info(info)")
for col in c.fetchall():
    print(col)

print("\n--- info data ---")
c.execute("SELECT * FROM info")
for row in c.fetchall():
    print(row)

conn.close()

print("\n\n=== WORDS DATABASE ===")
words_path = r"E:\Munajat App\munajat_e_maqbool_app\assets\quran_data\quran_scripts\indopak.db"
conn2 = sqlite3.connect(words_path)
c2 = conn2.cursor()

c2.execute("SELECT name FROM sqlite_master WHERE type='table'")
print("Tables:", [t[0] for t in c2.fetchall()])

print("\n--- words schema ---")
c2.execute("PRAGMA table_info(words)")
for col in c2.fetchall():
    print(col)

print("\n--- words sample ---")
c2.execute("SELECT * FROM words LIMIT 5")
for row in c2.fetchall():
    print(row)

conn2.close()
