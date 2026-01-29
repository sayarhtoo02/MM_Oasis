import sqlite3
import os

db_path = 'assets/oasismm.db'
if not os.path.exists(db_path):
    print(f"Error: {db_path} not found")
    exit(1)

conn = sqlite3.connect(db_path)
c = conn.cursor()

print("--- Hadith Data Verification ---")

# Overall counts
c.execute("SELECT COUNT(*) FROM hadiths")
total = c.fetchone()[0]
print(f"Total Hadiths: {total}")

# Arabic counts
c.execute("SELECT COUNT(*) FROM hadiths WHERE text_arabic IS NOT NULL AND text_arabic != ''")
arabic = c.fetchone()[0]
print(f"Hadiths with Arabic: {arabic}")

# English counts
c.execute("SELECT COUNT(*) FROM hadiths WHERE text_english IS NOT NULL AND text_english != ''")
english = c.fetchone()[0]
print(f"Hadiths with English: {english}")

# Myanmar counts
c.execute("SELECT COUNT(*) FROM hadiths WHERE text_myanmar IS NOT NULL AND text_myanmar != ''")
myanmar = c.fetchone()[0]
print(f"Hadiths with Myanmar: {myanmar}")

# Book-wise English/Myanmar check
print("\n--- Book-wise Detail ---")
c.execute("""
    SELECT b.book_key, 
           COUNT(*) as total,
           SUM(CASE WHEN text_english IS NOT NULL AND text_english != '' THEN 1 ELSE 0 END) as english,
           SUM(CASE WHEN text_myanmar IS NOT NULL AND text_myanmar != '' THEN 1 ELSE 0 END) as myanmar
    FROM hadith_books b
    JOIN hadiths h ON b.id = h.book_id
    GROUP BY b.id
""")
rows = c.fetchall()
for r in rows:
    print(f"Book: {r[0]:10} | Total: {r[1]:6} | English: {r[2]:6} | Myanmar: {r[3]:6}")

conn.close()
