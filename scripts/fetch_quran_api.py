#!/usr/bin/env python3
"""
Fetch Tajweed data from Quran.com API - Full version
"""

import requests
import json
import time
import os

OUTPUT_FILE = 'quran_tajweed_api.json'

def fetch_chapter_words(chapter_num):
    """Fetch all words with Tajweed for a chapter"""
    url = f"https://api.qurancdn.com/api/qdc/verses/by_chapter/{chapter_num}"
    params = {
        'words': 'true',
        'word_fields': 'text_uthmani_tajweed,text_uthmani,text_indopak,location',
        'per_page': 300,
    }
    
    all_verses = []
    page = 1
    
    while True:
        params['page'] = page
        try:
            response = requests.get(url, params=params, timeout=30)
            
            if response.status_code != 200:
                print(f"Error {response.status_code} for chapter {chapter_num}")
                break
            
            data = response.json()
            verses = data.get('verses', [])
            
            if not verses:
                break
            
            all_verses.extend(verses)
            
            pagination = data.get('pagination', {})
            if page >= pagination.get('total_pages', 1):
                break
            
            page += 1
            time.sleep(0.1)
            
        except Exception as e:
            print(f"Error: {e}")
            break
    
    return all_verses

def main():
    print("Fetching Tajweed data from Quran.com API...")
    print("This will take a few minutes...\n")
    
    all_words = []
    
    for surah in range(1, 115):
        print(f"Fetching Surah {surah}/114...", end=' ')
        verses = fetch_chapter_words(surah)
        
        word_count = 0
        for verse in verses:
            for word in verse.get('words', []):
                if word.get('char_type_name') == 'word':
                    word_count += 1
                    all_words.append({
                        'surah': surah,
                        'ayah': verse.get('verse_number'),
                        'word': word.get('position'),
                        'text_uthmani': word.get('text_uthmani', ''),
                        'text_indopak': word.get('text_indopak', ''),
                        'text_tajweed': word.get('text_uthmani_tajweed', ''),
                    })
        
        print(f"{len(verses)} verses, {word_count} words")
        time.sleep(0.2)
    
    # Save to file
    print(f"\nSaving to {OUTPUT_FILE}...")
    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        json.dump(all_words, f, ensure_ascii=False, indent=2)
    
    print(f"Done! Total words: {len(all_words)}")
    
    # Show sample of Tajweed tags
    print("\n=== Sample Tajweed Tags ===")
    for word in all_words[:5]:
        print(f"{word['surah']}:{word['ayah']}:{word['word']}")
        print(f"  Text: {word['text_uthmani']}")
        print(f"  Tajweed: {word['text_tajweed'][:100]}...")

if __name__ == '__main__':
    main()
