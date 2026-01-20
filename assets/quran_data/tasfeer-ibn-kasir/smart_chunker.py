import json
import os

def smart_chunk_json(input_path, output_dir, max_chunk_size=50000, min_chunk_size=5000):
    """
    Smart chunker that separates empty items and chunks only non-empty items for translation.
    
    Args:
        input_path (str): Path to the large JSON file
        output_dir (str): Directory to write output chunk files
        max_chunk_size (int): Maximum characters per chunk (for large content items)
        min_chunk_size (int): Minimum characters per chunk (to batch small items)
    """
    os.makedirs(output_dir, exist_ok=True)
    
    # Load the data
    with open(input_path, "r", encoding="utf-8") as f:
        data = json.load(f)
    
    print(f"Total items to process: {len(data)}")
    
    # Separate empty and non-empty items
    empty_items = []
    non_empty_items = []
    
    for item in data:
        if item.get('text', '').strip() == '':
            empty_items.append(item)
        else:
            non_empty_items.append(item)
    
    print(f"Empty items: {len(empty_items)}")
    print(f"Non-empty items: {len(non_empty_items)}")
    
    # Save empty items to separate file
    if empty_items:
        empty_path = os.path.join(output_dir, "empty_items.json")
        with open(empty_path, "w", encoding="utf-8") as f:
            json.dump(empty_items, f, ensure_ascii=False, indent=2)
        print(f"Saved {len(empty_items)} empty items to: empty_items.json")
    
    # Process only non-empty items for chunking
    data = non_empty_items
    
    chunks = []
    current_chunk = []
    current_size = 0
    
    for item in data:
        # Calculate the size of this item
        item_json = json.dumps(item, ensure_ascii=False)
        item_size = len(item_json)
        
        # If this single item is very large, put it in its own chunk
        if item_size > max_chunk_size:
            # Save current chunk if it has items
            if current_chunk:
                chunks.append(current_chunk)
                current_chunk = []
                current_size = 0
            
            # Create a chunk with just this large item
            chunks.append([item])
            print(f"Large item (ayah {item.get('ayah_key', 'unknown')}): {item_size:,} chars - separate chunk")
            continue
        
        # If adding this item would exceed max_chunk_size, start a new chunk
        if current_size + item_size > max_chunk_size and current_chunk:
            chunks.append(current_chunk)
            current_chunk = []
            current_size = 0
        
        # Add item to current chunk
        current_chunk.append(item)
        current_size += item_size
        
        # If we've reached a good size and have multiple items, consider closing chunk
        if current_size >= min_chunk_size and len(current_chunk) >= 5:
            chunks.append(current_chunk)
            current_chunk = []
            current_size = 0
    
    # Add the last chunk if it has items
    if current_chunk:
        chunks.append(current_chunk)
    
    print(f"Created {len(chunks)} chunks for translation")
    
    # Save chunks with part_ naming for compatibility with gemini_translate.py
    for i, chunk in enumerate(chunks, 1):
        # Use part_ naming that gemini_translate.py expects
        chunk_name = f"part_{i:03d}.json"
        
        chunk_path = os.path.join(output_dir, chunk_name)
        
        # Calculate chunk stats
        chunk_json = json.dumps(chunk, ensure_ascii=False, indent=2)
        chunk_size = len(chunk_json)
        
        with open(chunk_path, "w", encoding="utf-8") as f:
            f.write(chunk_json)
        
        # Show ayah range for reference
        first_ayah = chunk[0].get('ayah_key', 'unknown')
        last_ayah = chunk[-1].get('ayah_key', 'unknown')
        ayah_range = f"{first_ayah}-{last_ayah}" if first_ayah != last_ayah else first_ayah
        
        print(f"Chunk {i:2d}: {chunk_name:<15} ({ayah_range:<15}) - {len(chunk):3d} items, {chunk_size:6,} chars")

if __name__ == "__main__":
    # Get the directory where this script is located
    script_dir = os.path.dirname(os.path.abspath(__file__))
    
    # Smart chunking with optimized sizes
    smart_chunk_json(
        input_path=os.path.join(script_dir, "tafseer_ibn_kasir.json"),
        output_dir=os.path.join(script_dir, "en-ibn-kasir"),
        max_chunk_size=15000,  # 50KB max per chunk (good for API calls)
        min_chunk_size=14000    # 5KB min to batch small items
    )