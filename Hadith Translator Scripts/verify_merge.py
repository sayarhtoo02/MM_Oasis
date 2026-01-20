from hadith_translation_manager import create_burmese_json
import json
import os

original_json = "db/test_run/test_bukhari.json"
translated_jsonl = "db/test_run/test_bukhari_translated.jsonl"
output_json = "db/test_run/my-test_bukhari.json"

if create_burmese_json(original_json, translated_jsonl, output_json):
    print("Merge successful.")
    with open(output_json, "r", encoding="utf-8") as f:
        data = json.load(f)
        print("--- Merged Content (First Hadith) ---")
        burmese = data['hadiths'][0].get('burmese', {})
        print(f"Narrator: {burmese.get('narrator', 'MISSING')}")
        print(f"Text: {burmese.get('text', 'MISSING')}")
        
        print("--- Merged Content (Second Hadith) ---")
        burmese = data['hadiths'][1].get('burmese', {})
        print(f"Narrator: {burmese.get('narrator', 'MISSING')}")
        print(f"Text: {burmese.get('text', 'MISSING')}")
else:
    print("Merge failed.")
