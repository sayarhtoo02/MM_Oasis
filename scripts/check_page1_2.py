import sqlite3

layout_path = r"E:\Munajat App\munajat_e_maqbool_app\assets\quran_data\mushaf_layout_data\qudratullah-indopak-15-lines.db"
words_path = r"E:\Munajat App\munajat_e_maqbool_app\assets\quran_data\quran_scripts\indopak.db"

conn_layout = sqlite3.connect(layout_path)
conn_words = sqlite3.connect(words_path)
c_layout = conn_layout.cursor()
c_words = conn_words.cursor()

print("=== Pages 1 and 2 data ===")
for page_num in [1, 2, 3]:
    print(f"\n--- Page {page_num} ---")
    c_layout.execute("SELECT * FROM pages WHERE page_number = ?", (page_num,))
    rows = c_layout.fetchall()
    for row in rows:
        print(f"Row: {row}")
        print(f"Types: {[type(x).__name__ for x in row]}")
        
        # Check if first_word_id and last_word_id exist in words table
        first_word_id = row[4]  # assuming column index
        last_word_id = row[5]
        print(f"first_word_id: {first_word_id}, last_word_id: {last_word_id}")
        
        if first_word_id and last_word_id:
            try:
                first_id = int(first_word_id) if isinstance(first_word_id, str) else first_word_id
                last_id = int(last_word_id) if isinstance(last_word_id, str) else last_word_id
                c_words.execute("SELECT COUNT(*) FROM words WHERE id >= ? AND id <= ?", (first_id, last_id))
                count = c_words.fetchone()[0]
                print(f"Words found: {count}")
            except Exception as e:
                print(f"Error checking words: {e}")
        print()

conn_layout.close()
conn_words.close()
