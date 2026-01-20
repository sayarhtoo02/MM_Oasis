import json
import os
import google.generativeai as genai
from concurrent.futures import ThreadPoolExecutor, as_completed
import time
from datetime import datetime
import threading

API_KEYS = [
    "AIzaSyAKkH4TZ10-23Hpym45owbDbkKesvgoZ-0",
    "AIzaSyCcEepv_6TIUlGZcliz4qT5aB9kJgLrOyY",
    "AIzaSyBHByOLVzTrc48YmrxGO3I-IRdtgFZWrko",
    "AIzaSyAr7xpGLjjVaRBQb5v6M4fuJQSdebUI0tU",
    "AIzaSyBKyVWDQl4wBnXOqTBmdwU51IY0iB5vuN8",
    "AIzaSyB9nQ62jc3UbdrW2cKt-I-w_As4NKKXX0w",
    "AIzaSyCo0NHknRiqeQs_O4lDFCmmXUMaopK3oTU",
    "AIzaSyDpg7X-rOuaa6mzCKDzDPoHu3I1r0dXtHA",
    "AIzaSyC31rlgwdjwsMrHHrqSmCOo7wDNVN8vinM",
    "AIzaSyCNZI7he81KAbRiQXGWWbBRoVY6xqTj89Q"
]

failed_keys = set()
suspended_keys = {}  # Track temporarily suspended keys with cooldown time
key_lock = threading.Lock()

# Free API limits control
REQUESTS_PER_MINUTE = 4   # Ultra conservative: 4 RPM for 10 RPM limit
REQUESTS_PER_DAY = 250    # Gemini free tier: 250 RPD (actual limit)
api_usage = {}  # Track usage per key
last_request_time = {}  # Track last request time per key
usage_lock = threading.Lock()

source_dir = r"e:\Munajat App\munajat_e_maqbool_app\assets\quran_data\tasfeer-ibn-kasir\en-ibn-kasir"
target_dir = r"e:\Munajat App\munajat_e_maqbool_app\assets\quran_data\tasfeer-ibn-kasir\my-ibn-kasir"
progress_file = r"e:\Munajat App\munajat_e_maqbool_app\translation_progress.txt"
log_file = r"e:\Munajat App\munajat_e_maqbool_app\translation_log.txt"

SYSTEM_PROMPT = """You are a precise translator. Translate ONLY the English text to Burmese. Do NOT add any extra content, explanations, or commentary.

Rules:
1. Translate ONLY English text where lang="en" appears
2. Keep ALL Arabic text (lang="ar") unchanged
3. Keep ALL other language tags (es, sd, bs, fy, etc.) unchanged - do NOT translate them
4. Keep ALL HTML tags, attributes, and structure exactly as they are
5. Change ONLY lang="en" to lang="my" and class="en" to class="my"
6. Keep HTML entities (&amp;, &quot;, etc.) unchanged
7. Do NOT add new paragraphs, sections, or explanations
8. Translate word-for-word, sentence-for-sentence - nothing more
9. Return ONLY the translated HTML, no extra text

IMPORTANT: Your output must have the SAME structure and length as the input. Do not expand or add content.

EXAMPLE:
Input:
<div lang="en" class="en "><h2>The Meaning of Al Fatiha &amp; its Various Names</h2></div><p lang="en" class="en ">This Surah is called Al-Fatihah, that is, the Opener of the Book.</p><p class="ar qpc-hafs" lang="ar">الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ</p>

Output:
<div lang="my" class="my "><h2>အလ်ဖာတီဟာ၏ အဓိပ္ပါယ်နှင့် ၎င်း၏ အမည်အမျိုးမျိုး</h2></div><p lang="my" class="my ">ဤဆူရာကို အလ်ဖာတီဟာဟု ခေါ်သည်၊ ဆိုလိုသည်မှာ ကျမ်း၏ အဖွင့်ဖြစ်သည်။</p><p class="ar qpc-hafs" lang="ar">الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ</p>"""

def get_last_completed():
    if os.path.exists(progress_file):
        with open(progress_file, 'r') as f:
            return f.read().strip()
    return None

def save_progress(filename):
    with open(progress_file, 'w') as f:
        f.write(filename)

def translate_file(filename, api_key, retry=3):
    source_path = os.path.join(source_dir, filename)
    target_path = os.path.join(target_dir, filename)
    
    print(f"[DEBUG] Processing: {filename}")
    print(f"[DEBUG] Source: {source_path}")
    print(f"[DEBUG] Target: {target_path}")
    
    if os.path.exists(target_path):
        print(f"[DEBUG] Target file already exists, skipping: {filename}")
        return f"SKIP: {filename}"
    
    with key_lock:
        if api_key in failed_keys:
            print(f"[DEBUG] API key disabled for: {filename}")
            return f"[{datetime.now().strftime('%H:%M:%S')}] SKIP: {filename} (API key disabled)"
        
        # Check if key is suspended and if cooldown period has passed
        if api_key in suspended_keys:
            if time.time() < suspended_keys[api_key]:
                remaining = int(suspended_keys[api_key] - time.time())
                print(f"[DEBUG] API key {api_key[-8:]} still suspended for {remaining}s")
                return f"[{datetime.now().strftime('%H:%M:%S')}] SKIP: {filename} (API key suspended {remaining}s)"
            else:
                # Cooldown period passed, reactivate the key
                del suspended_keys[api_key]
                print(f"[DEBUG] API key {api_key[-8:]} reactivated after cooldown")
    
    # Check daily usage limit
    with usage_lock:
        today = datetime.now().strftime('%Y-%m-%d')
        if api_key not in api_usage:
            api_usage[api_key] = {'date': today, 'count': 0}
        elif api_usage[api_key]['date'] != today:
            api_usage[api_key] = {'date': today, 'count': 0}
        
        if api_usage[api_key]['count'] >= REQUESTS_PER_DAY:
            print(f"[DEBUG] Daily limit reached for key: {api_key[-8:]}")
            return f"[{datetime.now().strftime('%H:%M:%S')}] SKIP: {filename} (Daily limit reached)"
    
    for attempt in range(retry):
        try:
            genai.configure(api_key=api_key)
            model = genai.GenerativeModel('gemini-2.5-flash')
            
            with open(source_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
            
            print(f"[DEBUG] Loaded {len(data)} items from {filename}")
            
            # Collect all items with text for batch translation
            items_to_translate = []
            for i, item in enumerate(data):
                if 'text' in item and item['text'].strip():
                    items_to_translate.append((i, item))
                elif 'text' in item and not item['text'].strip():
                    print(f"[DEBUG] Item {i+1} has empty text field, skipping - ayah: {item.get('ayah_key', 'unknown')}")
                else:
                    print(f"[DEBUG] Item {i+1} has no text field, skipping")
            
            if items_to_translate:
                print(f"[DEBUG] Translating {len(items_to_translate)} items in one API call")
                
                # Combine all items into one prompt
                combined_content = ""
                for i, (idx, item) in enumerate(items_to_translate):
                    combined_content += f"<!-- ITEM {i+1} START -->\n{item['text']}\n<!-- ITEM {i+1} END -->\n\n"
                
                full_prompt = f"{SYSTEM_PROMPT}\n\nTranslate ONLY the English text in this HTML content. Keep the ITEM markers intact:\n\n{combined_content}\n\nReturn the translated HTML with lang='en' changed to lang='my' and class='en' changed to class='my'. Keep all other languages unchanged."
                
                # Ensure minimum 15 seconds between requests for this API key
                wait_time = 0
                with usage_lock:
                    current_time = time.time()
                    if api_key in last_request_time:
                        time_since_last = current_time - last_request_time[api_key]
                        if time_since_last < 15:
                            wait_time = 15 - time_since_last
                
                # Sleep OUTSIDE the lock to avoid blocking other threads
                if wait_time > 0:
                    print(f"[DEBUG] API key {api_key[-8:]} waiting {wait_time:.1f}s before next request")
                    time.sleep(wait_time)
                
                with usage_lock:
                    # Track API usage - ONE call for entire file
                    api_usage[api_key]['count'] += 1
                    print(f"[DEBUG] API usage for key {api_key[-8:]}: {api_usage[api_key]['count']}/{REQUESTS_PER_DAY}")
                    
                    # Check if approaching daily limit
                    if api_usage[api_key]['count'] >= REQUESTS_PER_DAY - 10:
                        print(f"[WARNING] API key {api_key[-8:]} approaching daily limit ({api_usage[api_key]['count']}/{REQUESTS_PER_DAY})")
                
                print(f"[API_CALL] Making API request #{api_usage[api_key]['count']} for key {api_key[-8:]} - File: {filename}")
                response = model.generate_content(full_prompt)
                print(f"[API_SUCCESS] Request #{api_usage[api_key]['count']} completed successfully for {filename}")
                
                # Update last request time AFTER successful request
                with usage_lock:
                    last_request_time[api_key] = time.time()
                
                response_text = response.text.strip()
                
                # Clean up response if it has markdown formatting
                if '```html' in response_text:
                    response_text = response_text.split('```html')[1].split('```')[0].strip()
                elif '```' in response_text:
                    response_text = response_text.split('```')[1].split('```')[0].strip()
                
                # Split response back into individual items
                import re
                item_pattern = r'<!-- ITEM (\d+) START -->\s*(.*?)\s*<!-- ITEM \1 END -->'
                matches = re.findall(item_pattern, response_text, re.DOTALL)
                
                # Update items with translated content
                for i, (idx, item) in enumerate(items_to_translate):
                    if i < len(matches):
                        item['text'] = matches[i][1].strip()
                        print(f"[DEBUG] Successfully translated item {idx+1}")
                    else:
                        print(f"[DEBUG] Warning: No translation found for item {idx+1}")
                
                print(f"[DEBUG] Completed batch translation of {len(items_to_translate)} items")
            
            # Ensure target directory exists
            os.makedirs(target_dir, exist_ok=True)
            
            with open(target_path, 'w', encoding='utf-8') as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
            
            print(f"[DEBUG] Saved translated file: {target_path}")
            save_progress(filename)
            return f"[{datetime.now().strftime('%H:%M:%S')}] DONE: {filename}"
        except Exception as e:
            error_msg = str(e)
            print(f"[API_ERROR] Exception in attempt {attempt+1} for {filename}: {error_msg}")
            print(f"[API_ERROR] This was a FAILED API request for key {api_key[-8:]}")
            if '429' in error_msg or 'quota' in error_msg.lower() or 'rate limit' in error_msg.lower():
                # Extract retry delay from error message if available
                retry_delay = 300  # Default 5 minutes
                if 'retry in' in error_msg:
                    try:
                        import re
                        match = re.search(r'retry in ([0-9.]+)s', error_msg)
                        if match:
                            retry_delay = max(int(float(match.group(1))), 60)  # Min 1 minute
                    except:
                        pass
                
                # Check if this is daily quota exhaustion (permanent) or rate limit (temporary)
                if ('daily' in error_msg.lower() or 
                    'GenerateRequestsPerDayPerProjectPerModel' in error_msg or
                    api_usage.get(api_key, {}).get('count', 0) >= REQUESTS_PER_DAY):
                    with key_lock:
                        failed_keys.add(api_key)
                    print(f"[DEBUG] API key {api_key[-8:]} daily quota exhausted - disabled permanently")
                    return f"[{datetime.now().strftime('%H:%M:%S')}] ERROR: {filename} - API key daily quota exhausted"
                else:
                    # Temporary suspension for rate limiting
                    cooldown_until = time.time() + retry_delay
                    with key_lock:
                        suspended_keys[api_key] = cooldown_until
                    print(f"[DEBUG] API key {api_key[-8:]} suspended for {retry_delay} seconds (rate limit)")
                    return f"[{datetime.now().strftime('%H:%M:%S')}] ERROR: {filename} - API key suspended ({retry_delay}s)"
            if attempt < retry - 1:
                # Ensure minimum 15 seconds between retry attempts for same API key
                wait_time = 5  # Default wait
                with usage_lock:
                    if api_key in last_request_time:
                        time_since_last = time.time() - last_request_time[api_key]
                        if time_since_last < 15:
                            wait_time = 15 - time_since_last
                        else:
                            wait_time = 0  # No wait needed
                
                # Sleep OUTSIDE the lock
                if wait_time > 0:
                    print(f"[DEBUG] Retrying in {wait_time:.1f} seconds... (attempt {attempt+2}/{retry})")
                    time.sleep(wait_time)
                else:
                    print(f"[DEBUG] Retrying immediately... (attempt {attempt+2}/{retry})")
                print(f"[RETRY_ATTEMPT] About to retry attempt {attempt+2} for {filename} with key {api_key[-8:]}")
                continue
            return f"[{datetime.now().strftime('%H:%M:%S')}] ERROR: {filename} - {error_msg}"
    return f"[{datetime.now().strftime('%H:%M:%S')}] FAILED: {filename}"

print(f"[DEBUG] Source directory: {source_dir}")
print(f"[DEBUG] Target directory: {target_dir}")
print(f"[DEBUG] Checking if directories exist...")
print(f"[DEBUG] Source exists: {os.path.exists(source_dir)}")
print(f"[DEBUG] Target exists: {os.path.exists(target_dir)}")

if not os.path.exists(source_dir):
    print(f"[ERROR] Source directory does not exist: {source_dir}")
    exit(1)

all_files = os.listdir(source_dir)
print(f"[DEBUG] All files in source: {len(all_files)} files")

files = sorted([f for f in all_files if f.startswith('part_') and f.endswith('.json') and f != 'empty_items.json'])
print(f"[DEBUG] Filtered part_ files: {len(files)} files")

# Check how many files are already translated
if os.path.exists(target_dir):
    translated_files = [f for f in os.listdir(target_dir) if f.startswith('part_') and f.endswith('.json')]
else:
    translated_files = []

total_files = len(files)
finished_count = len(translated_files)
remaining_count = total_files - finished_count

print(f"\n{'='*50}")
print(f"TRANSLATION STATUS:")
print(f"Total files: {total_files}")
print(f"Finished: {finished_count} ({finished_count/total_files*100:.1f}%)")
print(f"Remaining: {remaining_count} ({remaining_count/total_files*100:.1f}%)")
print(f"{'='*50}\n")

last_completed = get_last_completed()
print(f"[DEBUG] Last completed: {last_completed}")

if last_completed:
    try:
        start_idx = files.index(last_completed) + 1
        files = files[start_idx:]
        print(f"Resuming from {files[0] if files else 'END'}")
    except ValueError:
        print(f"[DEBUG] Last completed file not found in current file list")
        pass

print(f"Files to process in this session: {len(files)}")
print(f"Using {len(API_KEYS)} API keys")
print(f"Started at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")

# Initialize log file
with open(log_file, 'a', encoding='utf-8') as f:
    f.write(f"\n{'='*50}\n")
    f.write(f"Translation started: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
    f.write(f"Files to translate: {len(files)}\n")
    f.write(f"{'='*50}\n")

completed = 0
file_queue = list(files)
failed_queue = []  # Track failed files for retry
queue_lock = threading.Lock()

with ThreadPoolExecutor(max_workers=len(API_KEYS)) as executor:
    futures = {}
    
    # Submit initial batch - each key has its own rate limit
    for api_key in API_KEYS:
        with queue_lock:
            if file_queue:
                filename = file_queue.pop(0)
                future = executor.submit(translate_file, filename, api_key)
                futures[future] = (filename, api_key)
    
    # Process results and submit new work immediately
    while futures:
        for future in as_completed(futures):
            result = future.result()
            filename, api_key = futures.pop(future)
            completed += 1
            
            print(f"[{completed}/{len(files)}] {result}")
            
            # Log result
            with open(log_file, 'a', encoding='utf-8') as f:
                f.write(f"[{completed}/{len(files)}] {result}\n")
            
            # If failed (not quota/suspension issue), add to retry queue
            if "ERROR" in result and "quota" not in result.lower() and "suspended" not in result.lower():
                with queue_lock:
                    failed_queue.append(filename)
            
            # Thread-safe: Get next file and submit immediately
            with queue_lock:
                if file_queue:
                    # Check if this API key is still available (not suspended/failed)
                    current_time = time.time()
                    key_available = (api_key not in failed_keys and 
                                   (api_key not in suspended_keys or current_time >= suspended_keys.get(api_key, 0)))
                    
                    if key_available:
                        next_file = file_queue.pop(0)
                        new_future = executor.submit(translate_file, next_file, api_key)
                        futures[new_future] = (next_file, api_key)
                    else:
                        print(f"[DEBUG] API key {api_key[-8:]} not available, checking other keys...")
                        
                        for other_key in API_KEYS:
                            if (other_key not in failed_keys and 
                                (other_key not in suspended_keys or current_time >= suspended_keys.get(other_key, 0))):
                                next_file = file_queue.pop(0)
                                new_future = executor.submit(translate_file, next_file, other_key)
                                futures[new_future] = (next_file, other_key)
                                print(f"[DEBUG] Assigned {next_file} to available key {other_key[-8:]}")
                                break
                        else:
                            print(f"[DEBUG] No available API keys, waiting for cooldown...")
            
            break

# Retry failed files
if failed_queue:
    print(f"\n{'='*50}")
    print(f"Retrying {len(failed_queue)} failed files...")
    with open(log_file, 'a', encoding='utf-8') as f:
        f.write(f"\nRetrying {len(failed_queue)} failed files...\n")
    
    file_queue = failed_queue
    failed_queue = []
    
    with ThreadPoolExecutor(max_workers=len(API_KEYS)) as executor:
        futures = {}
        
        # Get available keys (not failed and not suspended)
        current_time = time.time()
        available_keys = []
        for key in API_KEYS:
            if key not in failed_keys:
                if key not in suspended_keys or current_time >= suspended_keys[key]:
                    available_keys.append(key)
                    # Clean up expired suspensions
                    if key in suspended_keys and current_time >= suspended_keys[key]:
                        with key_lock:
                            if key in suspended_keys:
                                del suspended_keys[key]
        
        print(f"[DEBUG] Available API keys for retry: {len(available_keys)}/{len(API_KEYS)}")
        
        for api_key in available_keys:
            with queue_lock:
                if file_queue:
                    filename = file_queue.pop(0)
                    future = executor.submit(translate_file, filename, api_key)
                    futures[future] = (filename, api_key)
        
        while futures:
            for future in as_completed(futures):
                result = future.result()
                filename, api_key = futures.pop(future)
                completed += 1
                
                print(f"[RETRY] {result}")
                
                with open(log_file, 'a', encoding='utf-8') as f:
                    f.write(f"[RETRY] {result}\n")
                
                # Check for available keys and assign work
                current_time = time.time()
                with queue_lock:
                    if file_queue:
                        # Find an available key
                        for check_key in available_keys:
                            if (check_key not in failed_keys and 
                                (check_key not in suspended_keys or current_time >= suspended_keys.get(check_key, 0))):
                                next_file = file_queue.pop(0)
                                new_future = executor.submit(translate_file, next_file, check_key)
                                futures[new_future] = (next_file, check_key)
                                break
                
                break

print(f"\nCompleted at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
print("Translation complete!")

# Final log entry
with open(log_file, 'a', encoding='utf-8') as f:
    f.write(f"\nCompleted at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
    f.write(f"Translation complete!\n")
    if failed_queue:
        f.write(f"\nFailed files remaining: {len(failed_queue)}\n")
        for failed_file in failed_queue:
            f.write(f"  - {failed_file}\n")