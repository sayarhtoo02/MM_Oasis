import json
import os
import time
import threading
import queue
import re
import concurrent.futures
from itertools import cycle
from google import genai
from google.genai import types

# --- Configuration ---
# Keys will be loaded from file
DEFAULT_MODEL = "gemini-2.0-flash-exp"

# --- Logging ---
LOG_FILE = "tafseer_translation_log.txt"
log_lock = threading.Lock()

def log(message):
    with log_lock:
        timestamp = time.strftime('%Y-%m-%d %H:%M:%S')
        entry = f"{timestamp} - {message}"
        print(entry)
        with open(LOG_FILE, "a", encoding="utf-8") as f:
            f.write(entry + "\n")

# --- Extraction ---
def extract_text_from_json(json_path, output_txt_path):
    """Extracts text from the Tafseer JSON file to a JSONL file."""
    log(f"Extracted text from {json_path}...")
    try:
        with open(json_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        count = 0
        with open(output_txt_path, 'w', encoding='utf-8') as f:
            for key, content in data.items():
                if isinstance(content, dict):
                    text = content.get('text', '')
                else:
                    text = str(content)

                if not text:
                    continue

                item = {
                    "id": key,
                    "text": text.strip()
                }
                
                f.write(json.dumps(item, ensure_ascii=False) + "\n")
                count += 1
        
        log(f"Extracted {count} tafseer items to {output_txt_path}")
        return True
        
    except Exception as e:
        log(f"Error extracting text: {e}")
        return False

# --- Helper Functions ---
def split_text_smart(text, max_chunk_size=8000):
    """Splits text into chunks at safe boundaries (</p>, \n, .)."""
    if len(text) <= max_chunk_size:
        return [text]
    
    chunks = []
    current_chunk = ""
    
    # Split by paragraphs first (most safe)
    paragraphs = re.split(r'(</p>)', text) # Keep delimiter
    
    # Re-group paragraphs
    temp_paragraphs = []
    for i in range(0, len(paragraphs), 2):
        p = paragraphs[i]
        tag = paragraphs[i+1] if i+1 < len(paragraphs) else ""
        temp_paragraphs.append(p + tag)
        
    for p in temp_paragraphs:
        if len(current_chunk) + len(p) > max_chunk_size:
            if current_chunk:
                chunks.append(current_chunk)
                current_chunk = ""
            
            # If a single paragraph is HUGE, split by sentences
            if len(p) > max_chunk_size:
                sentences = re.split(r'(\. )', p)
                for s in sentences:
                    if len(current_chunk) + len(s) > max_chunk_size:
                        if current_chunk: chunks.append(current_chunk)
                        current_chunk = s
                    else:
                        current_chunk += s
            else:
                current_chunk = p
        else:
            current_chunk += p
            
    if current_chunk:
        chunks.append(current_chunk)
        
    return chunks

def parse_delimiter_response(response_text):
    """Parses the custom delimiter format."""
    pattern = r"<<<ID:\s*(.*?)>>>\s*(.*?)\s*<<<END>>>"
    matches = re.findall(pattern, response_text, re.DOTALL)
    return [{"id": m[0].strip(), "text": m[1].strip()} for m in matches]

# --- Translation Logic ---
def translate_batch_delimiter(batch_items, api_key, model_name=DEFAULT_MODEL):
    """Translates a batch using the delimiter format."""
    if not batch_items:
        return []

    # Prepare batch prompt
    prompt_parts = ["Translate the following English Tafseer items into Burmese.\nPRESERVE ALL HTML TAGS.\nUse the format:\n<<<ID: item_id>>>\nTranslation...\n<<<END>>>\n"]
    
    for item in batch_items:
        prompt_parts.append(f"<<<ID: {item['id']}>>>\n{item['text']}\n<<<END>>>")
    
    prompt = "\n".join(prompt_parts)

    try:
        client = genai.Client(api_key=api_key, http_options={'timeout': 600000})
        
        response = client.models.generate_content(
            model=model_name,
            contents=prompt,
            config=types.GenerateContentConfig(
                max_output_tokens=8192,
                temperature=1
            )
        )
        
        if response and response.text:
            return parse_delimiter_response(response.text)
        else:
            return None
    except Exception as e:
        raise e

def worker_thread(input_queue, progress_file_path, api_key, lock):
    # Mega-Batch Configuration
    MAX_BATCH_CHARS = 5000  # Matched to Hadith Script (Safer)
    MAX_BATCH_ITEMS = 20     # Matched to Hadith Script
    LARGE_ITEM_THRESHOLD = 4000 
    CHUNK_SIZE = 4000        
    REQUEST_SLEEP = 15       # Increased to 15s (Safer)
    
    log(f"Worker started for key ...{api_key[-4:]}")

    while not input_queue.empty():
        batch = []
        current_batch_chars = 0
        is_large_item_mode = False
        large_item_chunks = []
        large_item_id = ""
        
        # --- Batch Collection ---
        try:
            try:
                first_item = input_queue.get_nowait()
            except queue.Empty:
                break

            # Check if it's a LARGE item
            if len(first_item['text']) > LARGE_ITEM_THRESHOLD:
                is_large_item_mode = True
                large_item_id = first_item['id']
                log(f"Processing Large Item {large_item_id} ({len(first_item['text'])} chars) on key ...{api_key[-4:]}...")
                
                # Split into chunks
                raw_chunks = split_text_smart(first_item['text'], max_chunk_size=CHUNK_SIZE)
                
                for i, chunk in enumerate(raw_chunks):
                    large_item_chunks.append({
                        "id": f"{large_item_id}_chunk_{i}", 
                        "text": chunk
                    })
                batch = large_item_chunks
            else:
                # Normal Batching
                batch.append(first_item)
                current_batch_chars += len(first_item['text'])
                
                while len(batch) < MAX_BATCH_ITEMS:
                    try:
                        if input_queue.empty(): break
                        
                        item = input_queue.get_nowait()
                        
                        if len(item['text']) > LARGE_ITEM_THRESHOLD:
                            input_queue.put(item) 
                            break
                            
                        item_chars = len(item['text'])
                        if current_batch_chars + item_chars > MAX_BATCH_CHARS:
                            input_queue.put(item) 
                            break
                        
                        batch.append(item)
                        current_batch_chars += item_chars
                    except queue.Empty:
                        break
        except Exception as e:
            log(f"Error in batch collection: {e}")
            break
            
        if not batch:
            break

        # --- Translation ---
        try:
            translations = translate_batch_delimiter(batch, api_key)
            
            # Rate Limit Sleep per key
            time.sleep(REQUEST_SLEEP)
            
            if translations:
                # Success! Write to file.
                with lock:
                    with open(progress_file_path, "a", encoding="utf-8") as f:
                        if is_large_item_mode:
                            # Reassemble large item
                            # Check if all chunks are present
                            chunk_ids = set(c['id'] for c in batch)
                            trans_ids = set(t['id'] for t in translations)
                            
                            if chunk_ids.issubset(trans_ids):
                                sorted_trans = sorted(translations, key=lambda x: int(x['id'].split('_chunk_')[1]))
                                full_translation = "".join([t['text'] for t in sorted_trans])
                                
                                entry = json.dumps({
                                    "index": large_item_id,
                                    "original": {"id": large_item_id}, 
                                    "translated": {"text": full_translation}
                                }, ensure_ascii=False)
                                f.write(entry + "\n")
                                log(f"Translated Large Item {large_item_id} successfully.")
                            else:
                                log(f"Large Item {large_item_id} failed: Missing chunks. Retrying...")
                                # Put back original large item
                                full_text = "".join([c['text'] for c in batch])
                                input_queue.put({"id": large_item_id, "text": full_text})

                        else:
                            # Normal batch
                            trans_map = {t['id']: t['text'] for t in translations}
                            for item in batch:
                                if item['id'] in trans_map:
                                    entry = json.dumps({
                                        "index": item['id'],
                                        "original": item,
                                        "translated": {"text": trans_map[item['id']]}
                                    }, ensure_ascii=False)
                                    f.write(entry + "\n")
                                else:
                                    log(f"Missing translation for {item['id']}. Re-queueing...")
                                    input_queue.put(item) # CRITICAL: Put missing items back!
            else:
                raise Exception("Empty response")

        except Exception as e:
            error_str = str(e).lower()
            if "quota" in error_str or "429" in error_str or "resource_exhausted" in error_str:
                log(f"Quota exceeded for key ...{api_key[-4:]}. Pausing 60s.")
                time.sleep(60) 
                
                # Put items back
                if is_large_item_mode:
                     full_text = "".join([c['text'] for c in batch])
                     input_queue.put({"id": large_item_id, "text": full_text})
                else:
                    for item in batch: input_queue.put(item)
            else:
                log(f"Batch failed on key ...{api_key[-4:]}: {e}. Retrying...")
                # Put back
                if is_large_item_mode:
                     full_text = "".join([c['text'] for c in batch])
                     input_queue.put({"id": large_item_id, "text": full_text})
                else:
                    for item in batch: input_queue.put(item)
                time.sleep(2)

def run_translation(input_txt_path, output_jsonl_path, api_keys):
    if not api_keys:
        log("No API keys provided!")
        return

    items = []
    if os.path.exists(input_txt_path):
        with open(input_txt_path, 'r', encoding='utf-8') as f:
            for line in f:
                if line.strip():
                    try: items.append(json.loads(line))
                    except: pass
    
    completed_indices = set()
    if os.path.exists(output_jsonl_path):
        with open(output_jsonl_path, 'r', encoding='utf-8') as f:
            for line in f:
                if line.strip():
                    try:
                        data = json.loads(line)
                        completed_indices.add(data['index'])
                    except: pass
    
    log(f"Total Items: {len(items)}. Already translated: {len(completed_indices)}.")

    q = queue.Queue()
    skipped_refs = 0
    for item in items:
        if item['id'] not in completed_indices:
            # Check for reference-only items (e.g., "99:2", "2:148")
            text = item['text'].strip()
            # Regex: Start, digits, colon, digits, optional range (-digits), End. Length check < 20.
            if len(text) < 20 and re.match(r'^\d+:\d+(-\d+)?$', text):
                skipped_refs += 1
                continue
                
            q.put(item)
            
    if skipped_refs > 0:
        log(f"Skipped {skipped_refs} items that were just verse references (e.g. '99:2').")

    if q.empty():
        log("All items already translated!")
        return

    lock = threading.Lock()
    
    # MULTI-THREADED MEGA-BATCHING
    # Launch one thread per API key
    log(f"Starting {len(api_keys)} Worker Threads (One per API Key)...")
    
    threads = []
    for key in api_keys:
        t = threading.Thread(target=worker_thread, args=(q, output_jsonl_path, key, lock))
        t.start()
        threads.append(t)
        time.sleep(2) # Stagger start to prevent burst quota hits
        
    for t in threads:
        t.join()
        
    log("Translation finished.")

# --- Merge ---
def create_burmese_json(original_json_path, translated_jsonl_path, output_json_path):
    log(f"Merging translations into {output_json_path}...")
    
    try:
        with open(original_json_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
            
        translations_map = {}
        if os.path.exists(translated_jsonl_path):
            with open(translated_jsonl_path, 'r', encoding='utf-8') as f:
                for line in f:
                    if line.strip():
                        try:
                            entry = json.loads(line)
                            translations_map[entry['index']] = entry['translated']['text']
                        except: pass
        
        success_count = 0
        
        for key, content in data.items():
            if key in translations_map:
                if isinstance(content, dict):
                    content['burmese'] = translations_map[key]
                success_count += 1
            
        with open(output_json_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=4)
            
        log(f"Successfully created {output_json_path}. Translated {success_count} items.")
        return True
        
    except Exception as e:
        log(f"Error merging JSON: {e}")
        return False

if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="Tafseer Translation Tool")
    parser.add_argument("--action", choices=["extract", "translate", "merge", "all"], required=True)
    parser.add_argument("--input", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--keys", help="Path to API keys file")
    parser.add_argument("--original", help="Original JSON file (required for merge)")
    
    args = parser.parse_args()
    
    if args.action == "extract":
        extract_text_from_json(args.input, args.output)
        
    elif args.action == "translate":
        if not args.keys: exit(1)
        with open(args.keys, 'r') as f:
            keys = [line.strip() for line in f if line.strip()]
        run_translation(args.input, args.output, keys)
        
    elif args.action == "merge":
        if not args.original: exit(1)
        create_burmese_json(args.original, args.input, args.output)
        
    elif args.action == "all":
        if not args.keys: exit(1)
        
        json_file = args.input
        base_name = os.path.splitext(json_file)[0]
        txt_file = base_name + "_extracted.jsonl"
        trans_jsonl = base_name + "_translated.jsonl"
        final_json = args.output
        
        with open(args.keys, 'r') as f:
            keys = [line.strip() for line in f if line.strip()]
            
        if extract_text_from_json(json_file, txt_file):
            run_translation(txt_file, trans_jsonl, keys)
            create_burmese_json(json_file, trans_jsonl, final_json)
