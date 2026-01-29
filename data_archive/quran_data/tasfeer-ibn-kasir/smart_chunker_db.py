import json
import os
import sqlite3

def smart_chunk_from_db(db_path, output_dir, max_chunk_size=15000, min_chunk_size=14000):
    """
    Smart chunker that reads from SQLite DB, separates empty items, and chunks non-empty items.
    
    Args:
        db_path (str): Path to the SQLite database file
        output_dir (str): Directory to write output chunk files
        max_chunk_size (int): Maximum characters per chunk
        min_chunk_size (int): Minimum characters per chunk
    """
    os.makedirs(output_dir, exist_ok=True)
    
    # Connect to database
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row  # Enable column access by name
    cursor = conn.cursor()
    
    # Get table name
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
    tables = cursor.fetchall()
    if not tables:
        print("No tables found in database")
        return
    
    print("Available tables:")
    for i, table in enumerate(tables):
        print(f"  {i+1}. {table[0]}")
    
    table_name = tables[0][0]  # Use first table by default
    print(f"Using table: {table_name}")
    
    # Count total items
    cursor.execute(f"SELECT COUNT(*) FROM {table_name}")
    total_count = cursor.fetchone()[0]
    print(f"Total items in database: {total_count}")
    
    # Count and save empty items
    cursor.execute(f"SELECT * FROM {table_name} WHERE text IS NULL OR TRIM(text) = ''")
    empty_rows = cursor.fetchall()
    
    if empty_rows:
        empty_items = [dict(row) for row in empty_rows]
        empty_path = os.path.join(output_dir, "empty_items.json")
        with open(empty_path, "w", encoding="utf-8") as f:
            json.dump(empty_items, f, ensure_ascii=False, indent=2)
        print(f"Saved {len(empty_items)} empty items to: empty_items.json")
    
    # Get non-empty items for chunking
    cursor.execute(f"SELECT * FROM {table_name} WHERE text IS NOT NULL AND TRIM(text) != '' ORDER BY ayah_key")
    
    chunks = []
    current_chunk = []
    current_size = 0
    
    while True:
        rows = cursor.fetchmany(100)  # Process in batches
        if not rows:
            break
            
        for row in rows:
            item = dict(row)
            item_json = json.dumps(item, ensure_ascii=False)
            item_size = len(item_json)
            
            # If single item is too large, put it in its own chunk
            if item_size > max_chunk_size:
                if current_chunk:
                    chunks.append(current_chunk)
                    current_chunk = []
                    current_size = 0
                
                chunks.append([item])
                print(f"Large item (ayah {item.get('ayah_key', 'unknown')}): {item_size:,} chars - separate chunk")
                continue
            
            # If adding this item would exceed max_chunk_size, start new chunk
            if current_size + item_size > max_chunk_size and current_chunk:
                chunks.append(current_chunk)
                current_chunk = []
                current_size = 0
            
            current_chunk.append(item)
            current_size += item_size
            
            # If reached good size, consider closing chunk
            if current_size >= min_chunk_size and len(current_chunk) >= 5:
                chunks.append(current_chunk)
                current_chunk = []
                current_size = 0
    
    # Add last chunk if it has items
    if current_chunk:
        chunks.append(current_chunk)
    
    conn.close()
    
    print(f"Created {len(chunks)} chunks for translation")
    
    # Save chunks
    for i, chunk in enumerate(chunks, 1):
        chunk_name = f"part_{i:03d}.json"
        chunk_path = os.path.join(output_dir, chunk_name)
        
        chunk_json = json.dumps(chunk, ensure_ascii=False, indent=2)
        chunk_size = len(chunk_json)
        
        with open(chunk_path, "w", encoding="utf-8") as f:
            f.write(chunk_json)
        
        # Show ayah range
        first_ayah = chunk[0].get('ayah_key', 'unknown')
        last_ayah = chunk[-1].get('ayah_key', 'unknown')
        ayah_range = f"{first_ayah}-{last_ayah}" if first_ayah != last_ayah else first_ayah
        
        print(f"Chunk {i:2d}: {chunk_name:<15} ({ayah_range:<15}) - {len(chunk):3d} items, {chunk_size:6,} chars")

if __name__ == "__main__":
    script_dir = os.path.dirname(os.path.abspath(__file__))
    db_path = r"E:\Munajat App\munajat_e_maqbool_app\assets\quran_data\en-tafisr-ibn-kathir.db"
    
    smart_chunk_from_db(
        db_path=db_path,
        output_dir=os.path.join(script_dir, "en-ibn-kasir"),
        max_chunk_size=15000,
        min_chunk_size=14000
    )