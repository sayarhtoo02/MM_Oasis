import json
import os
import re
import sys

# Mapping from our internal filenames to the dataset filenames
BOOK_MAPPING = {
    "my-bukhari.json": "Sahih al-Bukhari.json",
    "my-muslim.json": "Sahih Muslim.json",
    "my-tirmidhi.json": "Jami` at-Tirmidhi.json",
    "my-abudawud.json": "Sunan Abi Dawud.json",
    "my-nasai.json": "Sunan an-Nasa'i.json",
    "my-ibnmajah.json": "Sunan Ibn Majah.json"
}

DATASET_DIR = "hadith_datasets"
TARGET_DIR = "db/by_book/the_9_books"

def remove_tashkeel(text):
    if not text:
        return ""
    tashkeel = re.compile(r'[\u0617-\u061A\u064B-\u0652]')
    return tashkeel.sub('', text)

def normalize_text(text):
    if not text:
        return ""
    text = remove_tashkeel(text)
    # Remove non-alphanumeric characters (keep Arabic letters)
    text = re.sub(r'[^\w\s\u0600-\u06FF]', ' ', text)
    return ' '.join(text.split())

def analyze_mismatches(target_filename):
    if target_filename not in BOOK_MAPPING:
        return

    dataset_filename = BOOK_MAPPING[target_filename]
    dataset_path = os.path.join(DATASET_DIR, dataset_filename)
    target_path = os.path.join(TARGET_DIR, target_filename)

    print(f"Analyzing {target_filename}...")

    # Load Source
    with open(dataset_path, 'r', encoding='utf-8') as f:
        source_data = json.load(f)
    
    source_texts = set()
    for item in source_data:
        arabic = item.get('Arabic_Text', '')
        if arabic:
            source_texts.add(normalize_text(arabic))
    
    print("\nSample Source Texts (First 3):")
    for i, item in enumerate(source_data[:3]):
        print(f"\n--- Source #{i+1} ---")
        print(normalize_text(item.get('Arabic_Text', '')))
        print("-" * 20)

    # Load Target
    with open(target_path, 'r', encoding='utf-8') as f:
        target_data = json.load(f)

    # Find Mismatches
    mismatches = []
    for hadith in target_data.get('hadiths', []):
        if 'sunnahHadithId' not in hadith:
            mismatches.append(hadith)

    print(f"  Found {len(mismatches)} unmatched hadiths.")
    
    if mismatches:
        print("\nSample Mismatches (First 3):")
        for i, h in enumerate(mismatches[:3]):
            print(f"\n--- Mismatch #{i+1} (ID: {h.get('id')}) ---")
            print(f"Arabic Text (Normalized):")
            print(normalize_text(h.get('arabic', '')))
            print("-" * 20)
            
            # Try to find a close match? (Optional)
            # This would require fuzzy matching which is slow, so we skip for now.

def main():
    if len(sys.argv) > 1:
        target_file = sys.argv[1]
        if os.path.basename(target_file) in BOOK_MAPPING:
            analyze_mismatches(os.path.basename(target_file))
    else:
        for target_file in BOOK_MAPPING.keys():
            analyze_mismatches(target_file)

if __name__ == "__main__":
    main()
