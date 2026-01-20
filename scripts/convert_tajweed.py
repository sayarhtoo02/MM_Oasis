
import json
import re
import difflib
import os
import sys

# Tajweed rules extraction regex
TAG_REGEX = re.compile(r'<rule class=([^>]+)>(.*?)</rule>')

def remove_diacritics(text):
    # Range of Arabic diacritics/tashkeel
    return re.sub(r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u06E5\u06E6]', '', text)

def normalize_skeleton(text):
    # Remove diacritics first
    text = remove_diacritics(text)
    # Unify Alefs
    text = re.sub(r'[ٱأإآ]', 'ا', text)
    # Unify Ya/Alef Maqsura
    text = re.sub(r'[ى]', 'ي', text) 
    # Unify Taa Marbuta/Haa (optional, sometimes helpful)
    # text = re.sub(r'ة', 'ه', text)
    return text

def parse_tajweed_segments(tajweed_text):
    """
    Parses string like "<rule class=x>AB</rule>C"
    Returns list of {'text': 'AB', 'rule': 'x'}, {'text': 'C', 'rule': None}
    """
    segments = []
    last_pos = 0
    for match in TAG_REGEX.finditer(tajweed_text):
        # Text before tag
        if match.start() > last_pos:
            segments.append({'text': tajweed_text[last_pos:match.start()], 'rule': None})
        
        # Tag content
        rule_class = match.group(1)
        content = match.group(2)
        segments.append({'text': content, 'rule': rule_class})
        
        last_pos = match.end()
        
    # Remaining text
    if last_pos < len(tajweed_text):
        segments.append({'text': tajweed_text[last_pos:], 'rule': None})
        
    return segments

def get_char_analysis(text):
    """
    Analyzes text to map skeleton characters back to their full representation (including diacritics).
    Returns:
      chars: list of skeleton characters
      mappings: list of the original string part that corresponds to this skeleton char
      
    Example: Indopak "بِسۡ" -> skeleton "بس"
    mappings[0] (for 'ب') = "بِ"
    mappings[1] (for 'س') = "سۡ"
    """
    skeleton_chars = []
    full_parts = []
    
    current_part = ""
    for char in text:
        norm = normalize_skeleton(char)
        if norm:
            # This is a base letter
            if current_part:
                # Flush previous diacritics to the PREVIOUS letter if any, 
                # OR if this is the first letter, they are prefix diacritics (rare in Arabic, usually diacritics follow letter)
                # Actually, diacritics always follow the letter they modify in unicode order.
                pass
            
            # Start a new part
            skeleton_chars.append(norm)
            full_parts.append(char)
        else:
            # This is a diacritic, append to last base letter part
            if full_parts:
                full_parts[-1] += char
            else:
                # Diacritic at start? Should not happen usually, but handle just in case
                # Attach to 'next' logic or dummy? Let's attach to next if possible, or ignore.
                # Ideally, we wait for next char. But simpler: just carry over.
                # For robust mapping, let's keep it simple: strict skeleton.
                pass
                
    return skeleton_chars, full_parts

def process_word(uthmani_tajweed, indopak_text):
    # 1. Parse Uthmani into segments to know which letter has which rule
    segments = parse_tajweed_segments(uthmani_tajweed)
    
    # 2. Build Uthmani Skeleton with Rules
    uthmani_skeleton = [] # list of chars
    uthmani_rules = []    # list of rules corresponding to each char
    
    for seg in segments:
        rule = seg['text']
        s_chars, _ = get_char_analysis(seg['text'])
        for c in s_chars:
            uthmani_skeleton.append(c)
            uthmani_rules.append(seg['rule'])
            
    # 3. Build Indopak Skeleton and parts
    indopak_skel_chars, indopak_parts = get_char_analysis(indopak_text)
    
    # 4. Align Skeletons
    matcher = difflib.SequenceMatcher(None, uthmani_skeleton, indopak_skel_chars)
    
    # Create an array for rules on Indopak, default None
    indopak_rules = [None] * len(indopak_skel_chars)
    
    for tag, i1, i2, j1, j2 in matcher.get_opcodes():
        if tag == 'equal':
            # Map rules from Uthmani to Indopak
            for k in range(i2 - i1):
                # Ensure we don't go out of bounds (difflib guarantees ranges match length for 'equal')
                u_idx = i1 + k
                i_idx = j1 + k
                indopak_rules[i_idx] = uthmani_rules[u_idx]
        elif tag == 'replace':
            # Heuristic: if lengths match, just transfer. If not, maybe transfer to first?
            # 'replace' usually means spelling difference like Alef vs No-Alef
            # Let's try to fill as much as possible
            count = min(i2-i1, j2-j1)
            for k in range(count):
                indopak_rules[j1+k] = uthmani_rules[i1+k]
    
    # 5. Reconstruct Indopak with tags
    result = ""
    current_rule = None
    
    for i, part in enumerate(indopak_parts):
        rule = indopak_rules[i]
        
        # Check rule transition
        if rule != current_rule:
            # Close previous if exists
            if current_rule is not None:
                result += "</rule>"
            # Open new if exists
            if rule is not None:
                result += f"<rule class={rule}>"
            current_rule = rule
            
        result += part
        
    # Close final rule
    if current_rule is not None:
        result += "</rule>"
        
    return result

def main():
    input_path = 'assets/quran_data/quran_tajweed_api.json'
    output_path = 'assets/quran_data/quran_tajweed_indopak.json'
    
    if not os.path.exists(input_path):
        print(f"Error: {input_path} not found.")
        return

    print("Loading JSON...")
    with open(input_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
        
    print(f"Processing {len(data)} words...")
    
    processed_count = 0
    match_issues = 0
    
    new_data = []
    
    for item in data:
        # Create copy
        new_item = item.copy()
        
        u_text = item.get('text_tajweed', '')
        i_text = item.get('text_indopak', '')
        
        if u_text and i_text:
            try:
                # Generate converted text
                converted = process_word(u_text, i_text)
                new_item['text_tajweed_indopak'] = converted
                
                # Check for major mismatches (heuristic)
                # length diff > 50% ? 
                # ignoring for now, trusting the diff algo
                
            except Exception as e:
                print(f"Error processing {item.get('surah')}:{item.get('ayah')}:{item.get('word')} - {e}")
                new_item['text_tajweed_indopak'] = i_text # Fallback
                match_issues += 1
        else:
            new_item['text_tajweed_indopak'] = i_text
            
        new_data.append(new_item)
        processed_count += 1
        
        if processed_count % 5000 == 0:
            print(f"Processed {processed_count}...")
            
    print("Saving output...")
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(new_data, f, ensure_ascii=False, indent=None) # Compact save to save space
        
    print(f"Done. Saved to {output_path}")

if __name__ == "__main__":
    main()
