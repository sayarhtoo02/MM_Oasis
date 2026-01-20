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
    """
    Remove Arabic diacritics (tashkeel) from text for better matching.
    """
    if not text:
        return ""
    # Arabic diacritics unicode range
    tashkeel = re.compile(r'[\u0617-\u061A\u064B-\u0652]')
    return tashkeel.sub('', text)

def normalize_text(text):
    """
    Normalize text by removing tashkeel, punctuation, and extra whitespace.
    """
    if not text:
        return ""
    text = remove_tashkeel(text)
    # Remove non-alphanumeric characters (keep Arabic letters)
    # This is a simple regex, might need refinement
    text = re.sub(r'[^\w\s\u0600-\u06FF]', ' ', text)
    return ' '.join(text.split())

def extract_sunnah_id(reference):
    """
    Extract the ID from a Sunnah.com reference URL.
    Example: "https://sunnah.com/tirmidhi:13" -> 13
    Example: "https://sunnah.com/muslim:8a" -> "8a"
    """
    if not reference:
        return None
    # Match :number or :number[letter]
    match = re.search(r':(\d+[a-z]*)$', reference)
    if match:
        val = match.group(1)
        # Return int if possible, else string
        if val.isdigit():
            return int(val)
        return val
    return None

def merge_book(target_filename):
    if target_filename not in BOOK_MAPPING:
        print(f"Skipping {target_filename}: No corresponding dataset found.")
        return

    dataset_filename = BOOK_MAPPING[target_filename]
    dataset_path = os.path.join(DATASET_DIR, dataset_filename)
    target_path = os.path.join(TARGET_DIR, target_filename)

    if not os.path.exists(dataset_path):
        print(f"Dataset file not found: {dataset_path}")
        return
    if not os.path.exists(target_path):
        print(f"Target file not found: {target_path}")
        return

    print(f"Processing {target_filename} using {dataset_filename}...")

    # Load Dataset (Source)
    print("  Loading source dataset...")
    with open(dataset_path, 'r', encoding='utf-8') as f:
        source_data = json.load(f)

    # Build Lookup Dictionary
    # We'll use normalized Arabic text as the key
    print("  Building lookup index...")
    lookup_map = {}
    
    # Also keep track of "Chapter:Hadith" mapping if Arabic text fails?
    # For now let's try Arabic text.
    
    for item in source_data:
        arabic_text = item.get('Arabic_Text', '')
        reference = item.get('Reference', '')
        
        if not arabic_text or not reference:
            continue
            
        sunnah_id = extract_sunnah_id(reference)
        if sunnah_id is None:
            continue
            
        norm_text = normalize_text(arabic_text)
        # Store the info we want to transfer
        lookup_map[norm_text] = {
            'id': sunnah_id,
            'grade': item.get('Grade', '').strip(),
            'chapter_title_arabic': item.get('Chapter_Title_Arabic', '').strip(),
            'chapter_title_english': item.get('Chapter_Title_English', '').strip()
        }

    print(f"  Indexed {len(lookup_map)} hadiths from source.")

    # Load Target File
    print("  Loading target file...")
    with open(target_path, 'r', encoding='utf-8') as f:
        target_data = json.load(f)

    # Update Target Data
    print("  Matching and updating...")
    matched_count = 0
    total_count = len(target_data.get('hadiths', []))
    
    for hadith in target_data.get('hadiths', []):
        arabic = hadith.get('arabic', '')
        norm_arabic = normalize_text(arabic)
        
        if norm_arabic in lookup_map:
            source_info = lookup_map[norm_arabic]
            
            # Update fields
            hadith['sunnahHadithId'] = source_info['id']
            
            # Add new fields if they exist in source
            if source_info['grade']:
                hadith['grade'] = source_info['grade']
            
            # For chapter titles, we might want to store them in the hadith object 
            # or check if we should update the chapter object? 
            # The user asked for "chapter title arabic. chapter title english" to be added.
            # Since the structure separates chapters, adding them to the hadith object 
            # might be redundant but it's what was requested.
            if source_info['chapter_title_arabic']:
                hadith['chapterTitleArabic'] = source_info['chapter_title_arabic']
            if source_info['chapter_title_english']:
                hadith['chapterTitleEnglish'] = source_info['chapter_title_english']
                
            matched_count += 1
        else:
            # Fallback: Try matching by English text? 
            # Arabic is usually more reliable if normalized correctly.
            # Let's just log it for now.
            pass

    print(f"  Matched {matched_count}/{total_count} hadiths ({matched_count/total_count*100:.1f}%) via text match.")

    # Second Pass: Gap Filling
    # If we have a sequence like: Match(10), ???, Match(12), the missing one is likely 11.
    # We can also just assume sequential order if the text match failed but the position is logical.
    
    # Build a map of ID -> Source Info for easy lookup by ID
    id_to_info = {}
    for info in lookup_map.values():
        id_to_info[info['id']] = info

    filled_count = 0
    hadiths = target_data.get('hadiths', [])
    
    for i in range(len(hadiths)):
        if 'sunnahHadithId' in hadiths[i]:
            continue
            
        # Look at previous hadith
        prev_id = None
        if i > 0 and 'sunnahHadithId' in hadiths[i-1]:
            prev_id = hadiths[i-1]['sunnahHadithId']
            
        # Look at next hadith (to verify sequence if possible, but strictly next ID is a good guess)
        # For now, let's just try (prev_id + 1)
        
        if prev_id is not None and isinstance(prev_id, int):
            candidate_id = prev_id + 1
            
            # Check if this candidate ID exists in our source data
            if candidate_id in id_to_info:
                # Assign it!
                source_info = id_to_info[candidate_id]
                hadiths[i]['sunnahHadithId'] = candidate_id
                
                if source_info['grade']:
                    hadiths[i]['grade'] = source_info['grade']
                if source_info['chapter_title_arabic']:
                    hadiths[i]['chapterTitleArabic'] = source_info['chapter_title_arabic']
                if source_info['chapter_title_english']:
                    hadiths[i]['chapterTitleEnglish'] = source_info['chapter_title_english']
                
                filled_count += 1
                
    total_matched = matched_count + filled_count
    print(f"  Filled {filled_count} gaps. Total matched: {total_matched}/{total_count} ({total_matched/total_count*100:.1f}%)")

    # Save updated file
    print(f"  Saving updated {target_filename}...")
    with open(target_path, 'w', encoding='utf-8') as f:
        json.dump(target_data, f, ensure_ascii=False, indent=4)
    print("  Done.")


def main():
    if len(sys.argv) > 1:
        # Process specific file
        target_file = sys.argv[1]
        if os.path.basename(target_file) in BOOK_MAPPING:
            merge_book(os.path.basename(target_file))
        else:
            print(f"Unknown file or no mapping for: {target_file}")
            print("Available mappings:")
            for k in BOOK_MAPPING.keys():
                print(f"  {k}")
    else:
        # Process all known books
        for target_file in BOOK_MAPPING.keys():
            merge_book(target_file)

if __name__ == "__main__":
    main()
