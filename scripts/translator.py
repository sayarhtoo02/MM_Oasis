import json
import os

source_dir = r"e:\Munajat App\munajat_e_maqbool_app\assets\quran_data\tasfeer-ibn-kasir\en-ibn-kasir"
target_dir = r"e:\Munajat App\munajat_e_maqbool_app\assets\quran_data\tasfeer-ibn-kasir\my-ibn-kasir"

files = sorted([f for f in os.listdir(source_dir) if f.startswith('part_') and f.endswith('.json')])

print(f"Found {len(files)} files to translate")
print(f"First: {files[0]}, Last: {files[-1]}")
print("\nReady to translate. Please provide translations one by one.")
