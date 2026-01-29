import json
import os

def collect_empty_items(source_dir):
    """Collect all items with empty text fields"""
    empty_items = []
    
    files = sorted([f for f in os.listdir(source_dir) if f.startswith('part_') and f.endswith('.json')])
    
    for filename in files:
        filepath = os.path.join(source_dir, filename)
        with open(filepath, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        for item in data:
            if item.get('text', '').strip() == '':
                empty_items.append({
                    'file': filename,
                    'ayah_key': item.get('ayah_key', 'unknown')
                })
    
    print(f"Found {len(empty_items)} items with empty text fields:")
    for item in empty_items:
        print(f"  {item['file']}: {item['ayah_key']}")
    
    return empty_items

if __name__ == "__main__":
    source_dir = r"e:\Munajat App\munajat_e_maqbool_app\assets\quran_data\tasfeer-ibn-kasir\en-ibn-kasir"
    collect_empty_items(source_dir)