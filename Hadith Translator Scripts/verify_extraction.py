from hadith_translation_manager import extract_text_from_json
import os
import json

test_file = "db/test_run/test_bukhari.json"
output_file = "db/test_run/test_bukhari_extracted.txt"

if extract_text_from_json(test_file, output_file):
    print("Extraction successful.")
    with open(output_file, "r", encoding="utf-8") as f:
        print("--- Extracted Content (First 2 lines) ---")
        for i, line in enumerate(f):
            if i >= 2: break
            data = json.loads(line)
            print(f"Item {data['id']}:")
            print(f"  Narrator: {data.get('narrator', 'MISSING')}")
            print(f"  Text: {data.get('text', 'MISSING')[:50]}...")
else:
    print("Extraction failed.")
