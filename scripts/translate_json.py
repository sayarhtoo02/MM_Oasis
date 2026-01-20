import json
from bs4 import BeautifulSoup

def translate_text_to_burmese(text):
    # Placeholder for actual translation.
    # In a real scenario, this would call a translation API (e.g., Google Translate API).
    # For now, we'll just prepend "[Translated to Burmese]" to the text.
    return f"[Translated to Burmese] {text}"

def translate_html_content(html_content):
    soup = BeautifulSoup(html_content, 'html.parser')

    # Translate text within <h2> tags
    for h2_tag in soup.find_all('h2'):
        if h2_tag.get('lang') == 'en' or not h2_tag.get('lang'): # Translate if lang="en" or no lang attribute
            h2_tag.string = translate_text_to_burmese(h2_tag.get_text())

    # Translate text within <p> tags
    for p_tag in soup.find_all('p'):
        if p_tag.get('lang') == 'en' or not p_tag.get('lang'): # Translate if lang="en" or no lang attribute
            # Iterate through contents to handle <span> tags within <p>
            for content in p_tag.contents:
                if content.name == 'span' and 'gray' in content.get('class', []):
                    # Preserve content inside <span class="gray"> tags, but translate if it's English
                    # For now, we'll assume content inside gray spans is also English and needs translation
                    content.string = translate_text_to_burmese(content.get_text())
                elif isinstance(content, str):
                    # Translate plain text directly within <p>
                    translated_string = translate_text_to_burmese(content)
                    content.replace_with(translated_string)
            # After processing children, if the p_tag itself has lang="en" and still has untranslated text,
            # it means it was direct text content, which should have been handled above.
            # This part is mostly for safety, in case some text was missed.
            if p_tag.get('lang') == 'en' and p_tag.get_text(strip=True) and not p_tag.find('span', class_='gray'):
                p_tag.string = translate_text_to_burmese(p_tag.get_text())


    return str(soup)

def process_json_file(input_filepath, output_filepath):
    with open(input_filepath, 'r', encoding='utf-8') as f:
        data = json.load(f)

    translated_data = []
    for entry in data:
        if "text" in entry and entry["text"]:
            entry["text"] = translate_html_content(entry["text"])
        translated_data.append(entry)

    with open(output_filepath, 'w', encoding='utf-8') as f:
        json.dump(translated_data, f, ensure_ascii=False, indent=2)

if __name__ == "__main__":
    input_file = 'assets/quran_data/tasfeer-ibn-kasir/en-ibn-kasir/part_001.json'
    output_file = 'assets/quran_data/tasfeer-ibn-kasir/my-ibn-kasir/part_001.json'
    
    # Create the output directory if it doesn't exist
    import os
    output_dir = os.path.dirname(output_file)
    os.makedirs(output_dir, exist_ok=True)

    process_json_file(input_file, output_file)
    print(f"Translation process completed. Translated file saved to {output_file}")
