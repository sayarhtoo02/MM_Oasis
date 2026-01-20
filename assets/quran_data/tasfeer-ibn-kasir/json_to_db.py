import json
import sqlite3
import os

def json_to_sqlite(json_path, db_path):
    """Convert JSON file to SQLite database for better performance"""
    
    # Load JSON data
    with open(json_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    # Create SQLite database
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    # Create table
    cursor.execute('''
        CREATE TABLE tafseer (
            ayah_key TEXT,
            group_ayah_key TEXT,
            from_ayah TEXT,
            to_ayah TEXT,
            ayah_keys TEXT,
            text TEXT
        )
    ''')
    
    # Insert data
    for item in data:
        cursor.execute('''
            INSERT INTO tafseer (ayah_key, group_ayah_key, from_ayah, to_ayah, ayah_keys, text)
            VALUES (?, ?, ?, ?, ?, ?)
        ''', (
            item.get('ayah_key', ''),
            item.get('group_ayah_key', ''),
            item.get('from_ayah', ''),
            item.get('to_ayah', ''),
            item.get('ayah_keys', ''),
            item.get('text', '')
        ))
    
    # Create index for better performance
    cursor.execute('CREATE INDEX idx_ayah_key ON tafseer(ayah_key)')
    cursor.execute('CREATE INDEX idx_text_empty ON tafseer(text)')
    
    conn.commit()
    conn.close()
    
    print(f"Converted {len(data)} items to SQLite database: {db_path}")

if __name__ == "__main__":
    script_dir = os.path.dirname(os.path.abspath(__file__))
    json_path = os.path.join(script_dir, "tafseer_ibn_kasir.json")
    db_path = os.path.join(script_dir, "tafseer_ibn_kasir.db")
    
    if os.path.exists(json_path):
        json_to_sqlite(json_path, db_path)
    else:
        print(f"JSON file not found: {json_path}")