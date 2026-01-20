import json
import os
import re

# Paths
input_file_path = r'e:\Munajat App\munajat_e_maqbool_app\PyarayNabi.txt'
output_dir = r'e:\Munajat App\munajat_e_maqbool_app\sunnah collection'

def process_sunnah_data():
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    with open(input_file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Split content by markdown code blocks
    # Looking for ```json ... ```
    # Using regex to capture content between ```json and ```
    json_blocks = re.findall(r'```json(.*?)```', content, re.DOTALL)

    all_chapters = {}
    book_info = None

    print(f"Found {len(json_blocks)} JSON blocks.")

    for i, block in enumerate(json_blocks):
        try:
            # Clean up whitespace
            cleaned_block = block.strip()
            data = json.loads(cleaned_block)

            # Extract book_info if present (should be in the first block)
            if 'book_info' in data:
                print(f"Found book_info in block {i+1}")
                book_info = data['book_info']

            # Extract chapters
            if 'chapters' in data:
                print(f"Found {len(data['chapters'])} chapters in block {i+1}")
                for chapter in data['chapters']:
                    c_id = chapter['chapter_id']
                    # Overwrite if exists, assuming later blocks are corrections/updates
                    if c_id in all_chapters:
                        print(f"Overwriting Chapter {c_id} with newer version.")
                    all_chapters[c_id] = chapter

        except json.JSONDecodeError as e:
            print(f"Error decoding JSON in block {i+1}: {e}")
            # print(block[:100]) # Print start of block for debugging

    # Write book_info.json
    if book_info:
        book_info_path = os.path.join(output_dir, 'book_info.json')
        with open(book_info_path, 'w', encoding='utf-8') as f:
            json.dump(book_info, f, ensure_ascii=False, indent=2)
        print(f"Written book_info.json")

    # Write chapter files
    sorted_chapter_ids = sorted(all_chapters.keys())
    for c_id in sorted_chapter_ids:
        chapter = all_chapters[c_id]
        filename = f"chapter_{c_id}.json"
        file_path = os.path.join(output_dir, filename)
        
        # We wrap the chapter in the structure the user might expect or just the chapter itself.
        # User prompt: "make the structure .json format in a folder a chapter a file"
        # And user provided example:
        # { "book_info": ..., "chapters": [...] }
        # But since we are splitting, `book_info` is separate.
        # It's cleaner to just dump the chapter object.
        # However, to be extra safe and comprehensive, let's keep it simple: just the chapter object.
        # Unless I want to replicate the 'full structure' in every file (redundant).
        # Given "book data into .json file" (singular) vs "a file" per chapter.
        # I will stick to just the chapter content in the chapter file.
        
        with open(file_path, 'w', encoding='utf-8') as f:
            json.dump(chapter, f, ensure_ascii=False, indent=2)
        print(f"Written {filename}")

if __name__ == '__main__':
    process_sunnah_data()
