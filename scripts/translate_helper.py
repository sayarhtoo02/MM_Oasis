import json
import os
import sys

def get_file_list(directory):
    files = [f for f in os.listdir(directory) if f.startswith('part_') and f.endswith('.json')]
    return sorted(files)

def read_json(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        return json.load(f)

def write_json(filepath, data):
    with open(filepath, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

if __name__ == "__main__":
    source_dir = r"e:\Munajat App\munajat_e_maqbool_app\assets\quran_data\tasfeer-ibn-kasir\en-ibn-kasir"
    files = get_file_list(source_dir)
    print(f"Total files: {len(files)}")
    print(f"First file: {files[0]}")
    print(f"Last file: {files[-1]}")
