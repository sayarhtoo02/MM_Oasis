import json
import os

def count_empty_items(source_dir):
    """Count and save empty items to a file"""
    empty_items = []
    total_items = 0
    
    files = sorted([f for f in os.listdir(source_dir) if f.startswith('part_') and f.endswith('.json')])
    
    for filename in files:
        filepath = os.path.join(source_dir, filename)
        with open(filepath, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        total_items += len(data)
        
        for item in data:
            if item.get('text', '').strip() == '':
                empty_items.append({
                    'file': filename,
                    'ayah_key': item.get('ayah_key', 'unknown')
                })
    
    # Save to file
    with open('empty_items.json', 'w', encoding='utf-8') as f:
        json.dump(empty_items, f, ensure_ascii=False, indent=2)
    
    print(f"Total items: {total_items}")
    print(f"Empty items: {len(empty_items)}")
    print(f"Percentage empty: {len(empty_items)/total_items*100:.1f}%")
    print(f"Items to translate: {total_items - len(empty_items)}")
    print(f"Empty items saved to: empty_items.json")

if __name__ == "__main__":
    source_dir = r"e:\Munajat App\munajat_e_maqbool_app\assets\quran_data\tasfeer-ibn-kasir\en-ibn-kasir"
    count_empty_items(source_dir)