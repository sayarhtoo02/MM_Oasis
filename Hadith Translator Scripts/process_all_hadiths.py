import os
import glob
import argparse
from hadith_translation_manager import extract_text_from_json, run_translation, create_burmese_json, API_KEYS as HARDCODED_KEYS

def process_all(hadits_dir, keys_file):
    # Find all JSON files (English/Arabic source)
    search_pattern = os.path.join(hadits_dir, "*.json")
    files = glob.glob(search_pattern)
    
    # Filter out already translated files (my-*.json) to avoid re-processing
    files = [f for f in files if not os.path.basename(f).startswith("my-")]

    if not files:
        print(f"No files found matching {search_pattern}")
        return

    print(f"Found {len(files)} files to process: {[os.path.basename(f) for f in files]}")
    
    # Load keys
    keys = []
    if os.path.exists(keys_file):
        with open(keys_file, 'r') as f:
            keys = [line.strip() for line in f if line.strip() and not line.strip().startswith("#")]
            
    if not keys:
        print(f"No valid keys found in {keys_file}. Checking hardcoded keys...")
        keys = [k for k in HARDCODED_KEYS if k and not k.startswith("YOUR_API_KEY")]
        
    if not keys:
        print("Error: No API keys found in file or script.")
        return
        
    print(f"Loaded {len(keys)} API keys.")

    for json_file in files:
        base_name = os.path.basename(json_file)
        # Create output name: bukhari.json -> my-bukhari.json
        new_name = "my-" + base_name
        output_json = os.path.join(hadits_dir, new_name)
        
        print(f"\n--- Processing {base_name} -> {new_name} ---")
        
        # Intermediate files
        temp_txt = os.path.join(hadits_dir, base_name.replace(".json", "_extracted.txt"))
        trans_jsonl = os.path.join(hadits_dir, base_name.replace(".json", "_translated.jsonl"))
        
        # 1. Extract
        print("1. Extracting text...")
        if extract_text_from_json(json_file, temp_txt):
            
            # 2. Translate
            print("2. Translating (Resume capable)...")
            run_translation(temp_txt, trans_jsonl, keys)
            
            # 3. Merge
            print("3. Merging into JSON...")
            create_burmese_json(json_file, trans_jsonl, output_json)
            
            print(f"Done processing {base_name}")
            
            # Cleanup temp files?
            # os.remove(temp_txt)
            # os.remove(trans_txt)
        else:
            print(f"Skipping {base_name} due to extraction error.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Batch translate Hadith files")
    parser.add_argument("--dir", default=".", help="Directory containing hadith JSON files")
    parser.add_argument("--keys", default="api_keys.txt", help="Path to API keys file")
    
    args = parser.parse_args()
    
    process_all(args.dir, args.keys)
