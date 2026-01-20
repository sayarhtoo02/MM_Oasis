import json
import os
import time
import threading
import queue
import concurrent.futures
from itertools import cycle
from google import genai
from google.genai import types

# --- Configuration ---
# You can add your API keys here or load them from a file
API_KEYS = [
    
]

DEFAULT_MODEL = "gemini-2.5-flash"

# --- Logging ---
LOG_FILE = "hadith_translation_log.txt"
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
    """Extracts text from the Hadith JSON file to a JSONL file, one hadith object per line."""
    log(f"Extracted text from {json_path}...")
    try:
        with open(json_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        hadiths = data.get('hadiths', [])
        count = 0
        with open(output_txt_path, 'w', encoding='utf-8') as f:
            for i, hadith in enumerate(hadiths):
                # Extract English narrator and text
                english_data = hadith.get('english', {})
                narrator = english_data.get('narrator', '')
                text = english_data.get('text', '')
                
                # Fallback if english object is missing but text exists at top level
                if not text and 'text' in hadith:
                    text = hadith['text']

                # Create a structured object
                item = {
                    "id": i,
                    "narrator": narrator.strip() if narrator else "",
                    "text": text.strip() if text else ""
                }
                
                # Write as JSON line
                f.write(json.dumps(item, ensure_ascii=False) + "\n")
                count += 1
        
        log(f"Extracted {count} hadiths to {output_txt_path}")
        return True
        
    except Exception as e:
        log(f"Error extracting text: {e}")
        return False

# --- Translation Logic ---
def translate_batch(batch_items, api_key, model_name=DEFAULT_MODEL):
    """Translates a batch of hadith objects.
    batch_items: list of dicts {"id": ..., "narrator": ..., "text": ...}
    """
    if not batch_items:
        return []

    # Prepare batch prompt
    numbered_texts = []
    for i, item in enumerate(batch_items):
        narrator = item.get('narrator', '')
        text = item.get('text', '')
        numbered_texts.append(f"Item {i+1}:\nNarrator: {narrator}\nText: {text}")
    
    joined_text = "\n\n".join(numbered_texts)

    prompt = f"""Translate the following {len(batch_items)} English Hadith items (Narrator and Text) into Burmese.
Return the result as a JSON list of objects, where each object has "narrator" and "text" fields containing the Burmese translation.
Ensure the translation is accurate, respectful, and uses appropriate religious terminology.
Do not add explanations. Output ONLY the JSON list.

Input Items:
{joined_text}

Example Output Format:
[
  {{"narrator": "Burmese Narrator 1", "text": "Burmese Text 1"}},
  {{"narrator": "Burmese Narrator 2", "text": "Burmese Text 2"}}
]
"""

    try:
        client = genai.Client(
            api_key=api_key,
            http_options={'timeout': 600000}
        )
        
        response = client.models.generate_content(
            model=model_name,
            contents=prompt,
            config=types.GenerateContentConfig(
                response_mime_type="application/json",
                temperature=1, 
                thinking_config=types.ThinkingConfig(
                    include_thoughts=False, 
                    thinking_budget=0
                )
            )
        )
        
        if response and response.text:
            try:
                translations = json.loads(response.text)
                if isinstance(translations, list) and len(translations) == len(batch_items):
                    return translations
                else:
                    log(f"Warning: Batch response length mismatch. Expected {len(batch_items)}, got {len(translations) if isinstance(translations, list) else 'invalid'}")
                    return None
            except json.JSONDecodeError:
                log("Error: Failed to decode JSON response from batch.")
                return None
        else:
            return None
    except Exception as e:
        # Pass exception up to be handled by caller (for 429 checks)
        raise e

def translate_with_fallback(batch, api_key, model_name=DEFAULT_MODEL, depth=0):
    """Tries to translate a batch. If JSON error occurs, splits and retries."""
    try:
        return translate_batch(batch, api_key, model_name)
    except Exception as e:
        # If it's a rate limit error, re-raise it immediately so we can switch keys/wait
        error_str = str(e).lower()
        if "quota" in error_str or "429" in error_str or "resource_exhausted" in error_str:
            raise e
        
        # If it's a JSON/Content error and we have depth, try splitting
        if depth < 2 and len(batch) > 1:
            log(f"Batch failed ({e}). Splitting into sub-batches (Depth {depth})...")
            mid = len(batch) // 2
            left = batch[:mid]
            right = batch[mid:]
            
            res_left = translate_with_fallback(left, api_key, model_name, depth + 1)
            res_right = translate_with_fallback(right, api_key, model_name, depth + 1)
            
            if res_left is not None and res_right is not None:
                return res_left + res_right
        
        # If we can't split or it's another error, return None (failure)
        log(f"Translation failed for batch of size {len(batch)}: {e}")
        return None

def worker_thread(input_queue, progress_file_path, api_key_cycle, active_keys, key_status, lock, progress_callback=None):
    # Smart Batching Configuration
    MAX_BATCH_CHARS = 10000  # Reduced to avoid complexity errors
    MAX_BATCH_ITEMS = 20    # Reduced to respect 10 RPM (higher utility per request, but safer JSON)
    KEY_COOLDOWN = 7        # Seconds to wait between requests for the SAME key (10 RPM = 1 req/6s)
    
    while not input_queue.empty():
        # --- Smart Batch Collection ---
        batch = []
        current_batch_chars = 0
        
        try:
            # 1. Get the first item
            try:
                first_item = input_queue.get_nowait()
                batch.append(first_item)
                current_batch_chars += len(first_item.get('narrator', '')) + len(first_item.get('text', ''))
            except queue.Empty:
                break 

            # 2. Try to fill the batch
            while len(batch) < MAX_BATCH_ITEMS:
                try:
                    item = input_queue.get_nowait()
                    item_chars = len(item.get('narrator', '')) + len(item.get('text', ''))
                    
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

        # Log batch stats
        # log(f"Processing batch: {len(batch)} items, {current_batch_chars} chars")

        # --- Key Selection & Rate Limiting ---
        current_key = None
        attempts = 0
        max_key_attempts = len(active_keys) * 3
        
        while attempts < max_key_attempts:
            key = next(api_key_cycle)
            
            # Check if key is globally active
            if key not in active_keys:
                continue
                
            # Check specific key status
            status = key_status[key]
            now = time.time()
            
            if status['wait_until'] <= now:
                # Check last used time for strict RPM enforcement
                last_used = status.get('last_used', 0)
                if now - last_used < KEY_COOLDOWN:
                    # Key is technically free but cooling down. 
                    # We could wait, or skip to next key. 
                    # Let's skip to try finding a ready key.
                    continue
                
                current_key = key
                break
            
            attempts += 1
            time.sleep(0.1) # Small yield
        
        if not current_key:
            # All keys busy or cooling down. Wait a bit and put batch back.
            time.sleep(2)
            for item in batch: input_queue.put(item)
            continue

        # Mark key as used NOW (optimistic)
        key_status[current_key]['last_used'] = time.time()

        try:
            # Use fallback logic
            translations = translate_with_fallback(batch, current_key)
            
            if translations:
                with lock:
                    with open(progress_file_path, "a", encoding="utf-8") as f:
                        for original_item, translated_item in zip(batch, translations):
                            entry = json.dumps({
                                "index": original_item['id'],
                                "original": original_item, 
                                "translated": translated_item
                            }, ensure_ascii=False)
                            f.write(entry + "\n")
                
                if progress_callback:
                    for _ in batch: progress_callback(0)
            else:
                raise Exception("Batch failed (returned None)")
                
        except Exception as e:
            error_str = str(e).lower()
            
            # Strict check for Invalid Key
            if "api key not valid" in error_str or "key invalid" in error_str:
                log(f"Invalid key ...{current_key[-4:]}. Removing.")
                if current_key in active_keys:
                    active_keys.remove(current_key)
                for item in batch: input_queue.put(item)
            
            # Quota or Rate Limit
            elif "quota" in error_str or "429" in error_str or "resource_exhausted" in error_str:
                log(f"Quota exceeded for key ...{current_key[-4:]}. Pausing for 60s.")
                key_status[current_key]['wait_until'] = time.time() + 60 
                for item in batch: input_queue.put(item)
            
            # Timeout / Server Error
            elif "504" in error_str or "timed out" in error_str or "500" in error_str or "503" in error_str:
                log(f"Server error ({error_str}) for key ...{current_key[-4:]}. Retrying batch...")
                time.sleep(2)
                for item in batch: input_queue.put(item)
            
            # Other errors
            else:
                log(f"Error translating batch starting index {batch[0]['id']}: {e}. Retrying...")
                for item in batch: input_queue.put(item)
                time.sleep(1)

def run_translation(input_txt_path, output_jsonl_path, api_keys):
    """Runs the translation process with resume capability."""
    if not api_keys:
        log("No API keys provided!")
        return

    # Read input source (JSONL)
    items = []
    if os.path.exists(input_txt_path):
        with open(input_txt_path, 'r', encoding='utf-8') as f:
            for line in f:
                if line.strip():
                    try:
                        items.append(json.loads(line))
                    except:
                        pass
    
    total_hadiths = len(items)
    
    # Load existing progress
    completed_indices = set()
    if os.path.exists(output_jsonl_path):
        log(f"Found existing progress file: {output_jsonl_path}")
        with open(output_jsonl_path, 'r', encoding='utf-8') as f:
            for line in f:
                if line.strip():
                    try:
                        data = json.loads(line)
                        completed_indices.add(data['index'])
                    except:
                        pass
    
    log(f"Total Hadiths: {total_hadiths}. Already translated: {len(completed_indices)}.")

    # Queue only missing items
    q = queue.Queue()
    queued_count = 0
    for item in items:
        if item['id'] not in completed_indices:
            q.put(item)
            queued_count += 1
            
    if queued_count == 0:
        log("All hadiths already translated!")
        return

    log(f"Queued {queued_count} items for translation.")

    # Key management
    active_keys = list(api_keys)
    key_cycle = cycle(active_keys)
    # Initialize status with last_used
    key_status = {k: {'wait_until': 0, 'last_used': 0} for k in active_keys}
    
    lock = threading.Lock()
    
    # Workers
    # Limit workers to avoid excessive contention if keys are few
    # If we have 24 keys, 24 workers is fine IF they respect the lock/sleep.
    # But too many threads just spin. Let's cap at 10 or len(keys).
    num_workers = len(api_keys)
    threads = []
    
    log(f"Starting {num_workers} worker threads...")
    
    for _ in range(num_workers):
        t = threading.Thread(target=worker_thread, args=(q, output_jsonl_path, key_cycle, active_keys, key_status, lock))
        t.start()
        threads.append(t)
        
    for t in threads:
        t.join()
        
    log("Translation batch finished.")


# --- Merge ---
def create_burmese_json(original_json_path, translated_jsonl_path, output_json_path):
    """Merges translations from JSONL into the final JSON."""
    log(f"Merging translations into {output_json_path}...")
    
    try:
        # Load original structure
        with open(original_json_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
            
        # Load translations into a map
        translations_map = {}
        if os.path.exists(translated_jsonl_path):
            with open(translated_jsonl_path, 'r', encoding='utf-8') as f:
                for line in f:
                    if line.strip():
                        try:
                            entry = json.loads(line)
                            translations_map[entry['index']] = entry['translated']
                        except:
                            pass
        
        hadiths = data.get('hadiths', [])
        success_count = 0
        
        for i, hadith in enumerate(hadiths):
            if i in translations_map:
                hadith['burmese'] = translations_map[i]
                success_count += 1
            else:
                # Keep original or mark as missing? 
                # Keeping original is safer for database integrity if translation fails
                # But user wants Burmese. Let's leave it as is (Arabic) if missing, 
                # so at least there is data.
                pass 
                
        # Update metadata
        if 'metadata' in data:
            data['metadata']['name'] = data['metadata'].get('name', '') + " (Burmese)"
            
        with open(output_json_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=4)
            
        log(f"Successfully created {output_json_path}. Translated {success_count}/{len(hadiths)} items.")
        return True
        
    except Exception as e:
        log(f"Error merging JSON: {e}")
        return False

# --- Main CLI ---
if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="Hadith Translation Tool")
    parser.add_argument("--action", choices=["extract", "translate", "merge", "all"], required=True, help="Action to perform")
    parser.add_argument("--input", required=True, help="Input JSON file (for extract/merge) or Text file (for translate)")
    parser.add_argument("--output", required=True, help="Output file path")
    parser.add_argument("--keys", help="Path to file containing API keys (one per line)")
    parser.add_argument("--original", help="Original JSON file (required for merge)")
    
    args = parser.parse_args()
    
    if args.action == "extract":
        extract_text_from_json(args.input, args.output)
        
    elif args.action == "translate":
        if not args.keys:
            print("Error: --keys argument required for translation")
            exit(1)
            
        with open(args.keys, 'r') as f:
            keys = [line.strip() for line in f if line.strip()]
            
        run_translation(args.input, args.output, keys)
        
    elif args.action == "merge":
        if not args.original:
            print("Error: --original argument required for merge")
            exit(1)
        create_burmese_json(args.original, args.input, args.output)
        
    elif args.action == "all":
        # Full pipeline
        if not args.keys:
            print("Error: --keys argument required for full pipeline")
            exit(1)
            
        json_file = args.input
        base_name = os.path.splitext(json_file)[0]
        txt_file = base_name + "_extracted.txt"
        trans_jsonl = base_name + "_translated.jsonl" # Corrected from trans_file
        final_json = args.output
        
        with open(args.keys, 'r') as f:
            keys = [line.strip() for line in f if line.strip()]
            
        if extract_text_from_json(json_file, txt_file):
            run_translation(txt_file, trans_jsonl, keys)
            create_burmese_json(json_file, trans_jsonl, final_json)
