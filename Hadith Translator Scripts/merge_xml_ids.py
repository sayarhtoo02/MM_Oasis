import json
import os
import re
import xml.etree.ElementTree as ET

TARGET_FILE = 'db/by_book/the_9_books/my-muslim.json'
XML_FILE = 'Muslim.xml'

def remove_tashkeel(text):
    tashkeel = re.compile(r'[\u0617-\u061A\u064B-\u0652]')
    return tashkeel.sub('', text)

def normalize_text(text):
    if not text:
        return ""
    text = remove_tashkeel(text)
    # Remove non-alphanumeric characters (keep Arabic letters)
    text = re.sub(r'[^\w\s\u0600-\u06FF]', ' ', text)
    return ' '.join(text.split())

def parse_xml_hadiths(xml_path):
    print(f"Parsing {xml_path}...")
    tree = ET.parse(xml_path)
    root = tree.getroot()
    
    hadiths = []
    
    for hadith_elem in root.findall('.//hadith'):
        # Extract Reference (Sunnah ID)
        sunnah_id = None
        for ref in hadith_elem.findall('.//reference'):
            if ref.find('code').text == 'Reference':
                parts = ref.findall('.//part')
                if parts:
                    val = parts[0].text
                    # User requested to ignore suffix and take the integer part
                    # suffix = ref.find('suffix').text
                    # if suffix:
                    #     val += suffix
                    
                    if val.isdigit():
                        sunnah_id = int(val)
                    else:
                        # Try to extract leading digits if mixed
                        match = re.match(r'^(\d+)', val)
                        if match:
                            sunnah_id = int(match.group(1))
                        else:
                            sunnah_id = val
                break
        
        if sunnah_id is None:
            continue
            
        # Extract In-Book Reference
        book_num = None
        hadith_num = None
        
        for ref in hadith_elem.findall('.//reference'):
            if ref.find('code').text == 'In-Book':
                parts = ref.findall('.//part')
                if len(parts) >= 2:
                    book_num = parts[0].text
                    hadith_num = parts[1].text
                break
                
        if book_num and hadith_num:
            hadiths.append({
                'id': sunnah_id,
                'book_num': int(book_num) if book_num.isdigit() else book_num,
                'hadith_num': int(hadith_num) if hadith_num.isdigit() else hadith_num
            })
        
    print(f"Parsed {len(hadiths)} hadiths from XML.")
    return hadiths

def merge_xml():
    if not os.path.exists(TARGET_FILE):
        print(f"Target file not found: {TARGET_FILE}")
        return
    if not os.path.exists(XML_FILE):
        print(f"XML file not found: {XML_FILE}")
        return

    # Load Target
    print("Loading target file...")
    with open(TARGET_FILE, 'r', encoding='utf-8') as f:
        target_data = json.load(f)

    # Parse XML
    xml_hadiths = parse_xml_hadiths(XML_FILE)
    
    # Debug: Print some keys from XML
    print("Sample XML keys (Book, Hadith):")
    xml_keys = list(lookup_map.keys())
    for k in xml_keys[:10]:
        print(f"  {k}")
        
    # Match
    print("Matching...")
    matched_count = 0
    already_matched = 0
    newly_matched = 0
    
    unmatched_keys = []
    
    for hadith in target_data.get('hadiths', []):
        # We check if we can improve or add Sunnah ID
        # Even if it has one, we might want to verify or overwrite?
        # For now, let's prioritize filling missing ones.
        
        chapter_id = hadith.get('chapterId')
        id_in_book = hadith.get('idInBook')
        
        if chapter_id is None or id_in_book is None:
            continue
            
        key = (chapter_id, id_in_book)
        
        if key in lookup_map:
            new_id = lookup_map[key]
            
            # Always update to ensure we get the integer version
            if 'sunnahHadithId' not in hadith or hadith['sunnahHadithId'] != new_id:
                hadith['sunnahHadithId'] = new_id
                newly_matched += 1
            else:
                already_matched += 1
        else:
            if len(unmatched_keys) < 10:
                unmatched_keys.append(key)
            pass
            
    print(f"Sample unmatched keys from target: {unmatched_keys}")
            
    print(f"Already matched (verified): {already_matched}")
    print(f"Newly matched: {newly_matched}")
    
    # Calculate total coverage
    total_hadiths = len(target_data['hadiths'])
    total_with_id = sum(1 for h in target_data['hadiths'] if 'sunnahHadithId' in h)
    print(f"Total hadiths with Sunnah ID: {total_with_id}/{total_hadiths} ({total_with_id/total_hadiths*100:.1f}%)")
    
    if newly_matched > 0:
        print(f"Saving updated {TARGET_FILE}...")
        with open(TARGET_FILE, 'w', encoding='utf-8') as f:
            json.dump(target_data, f, ensure_ascii=False, indent=4)
        print("Done.")
    else:
        print("No new matches found.")

if __name__ == "__main__":
    merge_xml()
