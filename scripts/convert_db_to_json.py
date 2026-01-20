import sqlite3
import json
import os

# Paths to the databases
words_db_path = r"e:\Munajat App\munajat_e_maqbool_app\assets\quran_data\quran_scripts\indopak.db"
layout_db_path = r"e:\Munajat App\munajat_e_maqbool_app\assets\quran_data\mushaf_layout_data\qudratullah-indopak-15-lines.db"
output_json_path = r"e:\Munajat App\munajat_e_maqbool_app\assets\quran_data\quran_scripts\indopak_full.json"

if not os.path.exists(words_db_path) or not os.path.exists(layout_db_path):
    print("Error: One or both database files not found.")
    exit(1)

try:
    # Connect to databases
    conn_words = sqlite3.connect(words_db_path)
    cursor_words = conn_words.cursor()

    conn_layout = sqlite3.connect(layout_db_path)
    cursor_layout = conn_layout.cursor()

    # Get Info
    cursor_layout.execute("SELECT * FROM info")
    info_row = cursor_layout.fetchone()
    cursor_layout.execute("PRAGMA table_info(info)")
    info_cols = [col[1] for col in cursor_layout.fetchall()]
    info_data = dict(zip(info_cols, info_row)) if info_row else {}
    
    print(f"Info loaded: {info_data}")

    # Get Pages
    print("Loading pages...")
    cursor_layout.execute("SELECT * FROM pages ORDER BY page_number ASC, line_number ASC")
    pages_rows = cursor_layout.fetchall()
    cursor_layout.execute("PRAGMA table_info(pages)")
    pages_cols = [col[1] for col in cursor_layout.fetchall()]
    
    # Get Words
    print("Loading words...")
    cursor_words.execute("SELECT * FROM words ORDER BY id ASC")
    words_rows = cursor_words.fetchall()
    cursor_words.execute("PRAGMA table_info(words)")
    words_cols = [col[1] for col in cursor_words.fetchall()]
    
    # Index words by ID for fast lookup
    words_map = {}
    for row in words_rows:
        word_dict = dict(zip(words_cols, row))
        words_map[word_dict['id']] = word_dict

    # Construct the full structure
    full_data = {
        "info": info_data,
        "pages": []
    }

    current_page_num = -1
    current_page_data = None

    for row in pages_rows:
        page_dict = dict(zip(pages_cols, row))
        page_num = page_dict['page_number']
        
        if page_num != current_page_num:
            if current_page_data:
                full_data["pages"].append(current_page_data)
            current_page_data = {
                "page_number": page_num,
                "lines": []
            }
            current_page_num = page_num
        
        # Process Line
        first_word_id_raw = page_dict['first_word_id']
        last_word_id_raw = page_dict['last_word_id']
        
        line_words = []
        
        # Handle cases where IDs are empty strings or None
        if isinstance(first_word_id_raw, int) and isinstance(last_word_id_raw, int):
            for word_id in range(first_word_id_raw, last_word_id_raw + 1):
                if word_id in words_map:
                    line_words.append(words_map[word_id])
        
        line_data = {
            "line_number": page_dict['line_number'],
            "line_type": page_dict.get('line_type', 'text'),
            "is_centered": page_dict.get('is_centered', 0) == 1,
            "surah_number": page_dict.get('surah_number'),
            "words": line_words
        }
        current_page_data["lines"].append(line_data)

    if current_page_data:
        full_data["pages"].append(current_page_data)

    # Write to JSON
    print(f"Writing to {output_json_path}...")
    with open(output_json_path, 'w', encoding='utf-8') as f:
        json.dump(full_data, f, ensure_ascii=False, indent=2)

    print("Conversion complete.")
    conn_words.close()
    conn_layout.close()

except Exception as e:
    print(f"Error: {e}")
    import traceback
    traceback.print_exc()
