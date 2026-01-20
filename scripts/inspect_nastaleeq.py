import sqlite3

db_path = r"E:\Munajat App\munajat_e_maqbool_app\assets\quran_data\quran_scripts\indopak-nastaleeq.db"

conn = sqlite3.connect(db_path)
c = conn.cursor()

print("=== Tables ===")
c.execute("SELECT name FROM sqlite_master WHERE type='table'")
tables = c.fetchall()
for table in tables:
    print(f"Table: {table[0]}")

for table in tables:
    table_name = table[0]
    print(f"\n=== {table_name} Schema ===")
    c.execute(f"PRAGMA table_info({table_name})")
    for col in c.fetchall():
        print(col)
    
    print(f"\n=== {table_name} Sample Data (5 rows) ===")
    c.execute(f"SELECT * FROM {table_name} LIMIT 5")
    for row in c.fetchall():
        print(row)

conn.close()
