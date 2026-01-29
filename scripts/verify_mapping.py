import sqlite3
import os

src_path = 'data_archive/quran_data/mushaf_layout_data/qudratullah-indopak-15-lines.db'
dest_path = 'assets/oasismm.db'

print(f"Checking mapping...")
src = sqlite3.connect(src_path)
c_src = src.cursor()
c_src.execute('SELECT first_word_id, line_number, page_number FROM pages WHERE line_type="ayah" LIMIT 5')
source_rows = c_src.fetchall()
src.close()

dest = sqlite3.connect(dest_path)
c_dest = dest.cursor()

for fwid, line, page in source_rows:
    if fwid:
        c_dest.execute('SELECT surah, ayah, word, text FROM indopak_words WHERE id=?', (fwid,))
        result = c_dest.fetchone()
        print(f"Source Fwid {fwid} (Page {page}, Line {line}) -> Dest: {result}")
    else:
        print(f"Source Page {page}, Line {line} -> No first_word_id")

dest.close()
