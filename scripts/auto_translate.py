import json
import os
import re
from deep_translator import GoogleTranslator

source_dir = r"e:\Munajat App\munajat_e_maqbool_app\assets\quran_data\tasfeer-ibn-kasir\en-ibn-kasir"
target_dir = r"e:\Munajat App\munajat_e_maqbool_app\assets\quran_data\tasfeer-ibn-kasir\my-ibn-kasir"

translator = GoogleTranslator(source='en', target='my')

def translate_html_content(html_text):
    parts = re.split(r'(<[^>]+>)', html_text)
    result = []
    for part in parts:
        if part.startswith('<'):
            if 'lang="en"' in part:
                part = part.replace('lang="en"', 'lang="my"')
            if 'class="en' in part:
                part = part.replace('class="en', 'class="my')
            result.append(part)
        elif part.strip() and not re.match(r'^[\u0600-\u06FF\s]+$', part):
            try:
                translated = translator.translate(part)
                result.append(translated)
            except:
                result.append(part)
        else:
            result.append(part)
    return ''.join(result)

files = sorted([f for f in os.listdir(source_dir) if f.startswith('part_') and f.endswith('.json')])

for i, filename in enumerate(files, 1):
    source_path = os.path.join(source_dir, filename)
    target_path = os.path.join(target_dir, filename)
    
    with open(source_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    for item in data:
        if 'text' in item:
            item['text'] = translate_html_content(item['text'])
    
    with open(target_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print(f"Translated {i}/{len(files)}: {filename}")
