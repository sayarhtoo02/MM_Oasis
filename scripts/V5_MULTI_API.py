import google.generativeai as genai
import time
import os
import sys
import threading
import concurrent.futures
import queue
from itertools import cycle
from PyQt5.QtWidgets import (QApplication, QMainWindow, QLabel, QVBoxLayout, QHBoxLayout,
                             QWidget, QPushButton, QLineEdit, QFileDialog, QTextEdit,
                             QMessageBox, QPlainTextEdit)
from PyQt5.QtCore import Qt, QObject, pyqtSignal

# --- Configuration ---
LOG_FILE = "debug_log.txt"
# Approximate token count using character count. Adjust based on model and language.
# Start conservatively. Adjust if you get errors about context length.
MAX_CHARS_TARGET = 8000  # Target character count per chunk (approximates token limit)
OVERLAP_CHARS = 100       # Character overlap between chunks for context
API_REQUEST_DELAY_MS = 50 # Small delay between submitting requests
MAX_CHUNK_RETRIES = 3     # Max attempts for a single chunk across different keys
DEFAULT_MODEL = "gemini-2.0-flash" # Or "gemini-1.5-flash-latest"

# --- Debugging log function ---
log_lock = threading.Lock()

def debug_log(message):
    with log_lock:
        try:
            with open(LOG_FILE, "a", encoding="utf-8") as file:
                timestamp = time.strftime('%Y-%m-%d %H:%M:%S')
                thread_name = threading.current_thread().name
                log_entry = f"{timestamp} [{thread_name}] - {message}\n"
                file.write(log_entry)
                print(log_entry, end='')
        except Exception as e:
            print(f"Error writing to log file: {e}")

# --- Helper Functions ---

def split_text_intelligently(text, max_chars_target=MAX_CHARS_TARGET, overlap_chars=OVERLAP_CHARS):
    """
    Splits text into deterministic chunks, prioritizing paragraph and sentence boundaries
    (including Urdu sentence terminator '۔').

    Args:
        text (str): The full text to split.
        max_chars_target (int): The target maximum number of characters per chunk.
        overlap_chars (int): The number of characters to overlap between chunks.

    Returns:
        list[str]: A list of text chunks.
    """
    chunks = []
    current_pos = 0
    text_length = len(text)
    sentence_terminators = {'.', '?', '!', '۔'} # Include Urdu full stop
    paragraph_separator = "\n\n"

    debug_log(f"Splitting text (length {text_length}) intelligently. Target chars: {max_chars_target}, Overlap: {overlap_chars}")

    while current_pos < text_length:
        # Determine the ideal end position
        end_pos = min(current_pos + max_chars_target, text_length)
        split_pos = end_pos

        # If not at the end of the text, try to find a better split point backwards
        if end_pos < text_length:
            # Define a reasonable search window backwards from end_pos
            search_start_pos = max(current_pos, end_pos - overlap_chars * 2) # Search back up to 2x overlap

            # 1. Prioritize finding the last paragraph separator
            last_para_break = text.rfind(paragraph_separator, search_start_pos, end_pos)
            if last_para_break != -1:
                # Split *after* the paragraph break
                split_pos = last_para_break + len(paragraph_separator)
                # debug_log(f"  Found paragraph break at: {split_pos}")
            else:
                # 2. If no paragraph break, find the last sentence terminator
                best_sentence_end = -1
                for term in sentence_terminators:
                    term_pos = text.rfind(term, search_start_pos, end_pos)
                    if term_pos > best_sentence_end:
                        best_sentence_end = term_pos

                if best_sentence_end != -1:
                    # Split *after* the terminator
                    split_pos = best_sentence_end + 1
                    # debug_log(f"  Found sentence break at: {split_pos}")
                else:
                    # 3. If no sentence break, find the last space
                    last_space = text.rfind(' ', search_start_pos, end_pos)
                    if last_space != -1:
                        # Split *after* the space
                        split_pos = last_space + 1
                        # debug_log(f"  Found space break at: {split_pos}")
                    # else: If no space found, split_pos remains end_pos (cut at max chars)

            # Ensure split_pos doesn't go backward from current_pos in weird cases
            split_pos = max(split_pos, current_pos + 1) # Must advance at least 1 char if not end

        # Extract the chunk
        chunk = text[current_pos:split_pos]

        # Add the chunk if it's not just whitespace
        if chunk.strip():
            chunks.append(chunk)
            # debug_log(f"  Added chunk {len(chunks)}: Pos {current_pos}-{split_pos} (Length {len(chunk)})")
        # else:
            # debug_log(f"  Skipped empty chunk at Pos {current_pos}-{split_pos}")

        # Check if we've reached the end
        if split_pos >= text_length:
            break

        # Determine the start of the next chunk with overlap
        next_start_pos = max(0, split_pos - overlap_chars) # Ensure overlap doesn't go before 0
        current_pos = max(current_pos + 1, next_start_pos) # Ensure current_pos advances

        # Safety check for potential infinite loops if overlap logic fails
        if current_pos >= split_pos and current_pos < text_length:
             debug_log(f"Warning: Potential stall detected. Forcing advance. current_pos={current_pos}, split_pos={split_pos}")
             current_pos = split_pos

    debug_log(f"Intelligent splitting resulted in {len(chunks)} chunks.")
    return chunks

# --- Translation Function (and other helpers remain largely the same) ---

def translate_text_with_key(text_chunk, api_key, chunk_index, model_name=DEFAULT_MODEL):
    """Translates a single chunk using a specific API key."""
    if not isinstance(api_key, str) or not api_key.strip():
         debug_log(f"❌ Invalid API Key object passed for chunk {chunk_index+1} (Type: {type(api_key)}).")
         return "⚠️ Error (Invalid Key Object)"

    prompt = f"""Translate the following text into Burmese language. Ensure the translation is natural, fluent, and contextually accurate. Preserve the original meaning and tone as much as possible. Do not add any extra explanation, comments, or introductory phrases. Only provide the Burmese translation.

Original Text:
---
{text_chunk}
---

Burmese Translation:"""
    retries = 0
    max_retries_per_call = 2

    while retries < max_retries_per_call:
        try:
            genai.configure(api_key=api_key)
            model = genai.GenerativeModel(model_name)
            safety_settings = [
                {"category": "HARM_CATEGORY_HARASSMENT", "threshold": "BLOCK_NONE"},
                {"category": "HARM_CATEGORY_HATE_SPEECH", "threshold": "BLOCK_NONE"},
                {"category": "HARM_CATEGORY_SEXUALLY_EXPLICIT", "threshold": "BLOCK_NONE"},
                {"category": "HARM_CATEGORY_DANGEROUS_CONTENT", "threshold": "BLOCK_NONE"},
            ]
            response = model.generate_content(prompt, safety_settings=safety_settings)

            if response and hasattr(response, 'text') and response.text.strip():
                 return response.text.strip()
            elif response and response.prompt_feedback and response.prompt_feedback.block_reason:
                 reason = response.prompt_feedback.block_reason
                 details = response.prompt_feedback.safety_ratings if hasattr(response.prompt_feedback, 'safety_ratings') else 'N/A'
                 debug_log(f"❌ Chunk {chunk_index+1} blocked using key ...{api_key[-4:]}. Reason: {reason}, Details: {details}")
                 return f"⚠️ Not Translated (Blocked: {reason})"
            else:
                 finish_reason = "Unknown"
                 if response and hasattr(response, 'candidates') and response.candidates:
                     candidate = response.candidates[0]
                     if hasattr(candidate, 'finish_reason'):
                        finish_reason = candidate.finish_reason
                 debug_log(f"⚠️ Empty/invalid response chunk {chunk_index+1} key ...{api_key[-4:]}. Finish: {finish_reason}. Resp: {response}")
                 if finish_reason == 'MAX_TOKENS': return "⚠️ Error (Input Too Long?)"
                 return f"⚠️ Not Translated (Invalid/Empty: {finish_reason})"

        except Exception as e:
            error_str = str(e).lower()
            key_short = api_key[-4:] if len(api_key) >= 4 else api_key
            debug_log(f"❌ Error chunk {chunk_index+1} key ...{key_short} (Try {retries+1}): {type(e).__name__} - {e}")
            retries += 1
            if "api key not valid" in error_str or "permission denied" in error_str: return "⚠️ Error (Invalid Key)"
            elif "quota" in error_str or "resource has been exhausted" in error_str: return "⚠️ Error (Quota)"
            elif "rate limit" in error_str:
                 time.sleep(10 * (retries + 1)); continue
            elif "internal server error" in error_str or "service unavailable" in error_str:
                 time.sleep(15 * (retries + 1)); continue
            elif "deadline exceeded" in error_str:
                 time.sleep(5 * (retries+1)); continue
            elif "model requires billing enabled" in error_str: return "⚠️ Error (Billing Required)"
            else:
                time.sleep(5 * (retries + 1)); continue

    debug_log(f"❌ Failed call chunk {chunk_index+1} key ...{api_key[-4:]} after {max_retries_per_call} attempts.")
    return "⚠️ Not Translated (Failed Call)"

# --- File Operations ---
def read_file(file_path):
    try:
        with open(file_path, "r", encoding="utf-8") as file:
            return file.read()
    except FileNotFoundError:
        debug_log(f"❌ Error: Input file not found at {file_path}")
        return None
    except Exception as e:
        debug_log(f"❌ Error reading file {file_path}: {e}")
        return None

def save_chunk(text, output_path):
    try:
        os.makedirs(os.path.dirname(output_path), exist_ok=True)
        with open(output_path, "w", encoding="utf-8") as file:
            file.write(text)
    except Exception as e:
        debug_log(f"❌ Error saving chunk {os.path.basename(output_path)}: {e}")

# --- Worker Object for Threading and Signals ---
class TranslationWorker(QObject):
    progress_signal = pyqtSignal(str)
    chunk_done_signal = pyqtSignal(int, str) # chunk_index, result_text_or_error
    finished_signal = pyqtSignal(str) # Final status message

    def __init__(self, input_file, api_keys_text, output_dir):
        super().__init__()
        self.input_file = input_file
        self.api_keys = [key.strip() for key in api_keys_text.splitlines() if key.strip()]
        self.output_dir = output_dir
        self.is_cancelled = False
        self.chunks = []
        self.results = {} # Use dict for potentially sparse results if needed later
        self.failed_chunks_queue = queue.Queue() # Queue for (chunk_index, chunk_text, attempts)
        self.active_keys = set(self.api_keys)
        self.key_status = {key: {'status': 'active', 'wait_until': 0} for key in self.api_keys}
        self.key_cycler = cycle(self.api_keys)
        self.max_concurrent_workers = len(self.api_keys)
        self.total_chunks = 0
        self.processed_chunks_count = 0
        self.processing_lock = threading.Lock()

    def cancel(self):
        self.is_cancelled = True
        self.progress_signal.emit("🛑 Translation cancellation requested...")
        debug_log("🛑 Cancellation requested by user.")

    def run(self):
        start_time = time.time()
        debug_log("🚀 Worker thread started.")
        if not self.api_keys:
            self.finished_signal.emit("❌ Error: No valid API keys provided.")
            return

        self.progress_signal.emit(f"🔑 Initializing with {len(self.api_keys)} API keys.")
        self.progress_signal.emit("🔍 Reading input file...")
        text = read_file(self.input_file)
        if text is None:
            self.finished_signal.emit(f"❌ Error: Could not read input file: {self.input_file}")
            return

        self.progress_signal.emit(f"🧩 Splitting text intelligently (Target ~{MAX_CHARS_TARGET} chars)...")
        # *** Use the new intelligent chunking function ***
        self.chunks = split_text_intelligently(text, MAX_CHARS_TARGET, OVERLAP_CHARS)
        self.total_chunks = len(self.chunks)
        # Initialize results as a list, matching the fix from the previous error message
        self.results = [""] * self.total_chunks

        if not self.chunks:
             self.finished_signal.emit("❌ Error: No text chunks generated. Check input file or chunking params.")
             return

        try:
            os.makedirs(self.output_dir, exist_ok=True)
            self.progress_signal.emit(f"📂 Output directory: {self.output_dir}")
        except Exception as e:
            self.finished_signal.emit(f"❌ Error creating output directory '{self.output_dir}': {e}")
            return

        self.progress_signal.emit(f"📊 Total chunks generated: {self.total_chunks}")

        # --- Check existing chunks and populate queue ---
        initial_queue_fill_count = 0
        skipped_count = 0
        for i, chunk_text in enumerate(self.chunks):
             chunk_filename = os.path.join(self.output_dir, f"translated_chunk_{i+1}.txt")
             if os.path.exists(chunk_filename):
                 try:
                     with open(chunk_filename, "r", encoding="utf-8") as f:
                         content = f.read()
                         if content.strip() and not content.startswith("⚠️"):
                             self.results[i] = content # Store existing valid translation
                             with self.processing_lock:
                                 self.processed_chunks_count += 1
                             skipped_count += 1
                         else:
                              debug_log(f"Re-queueing chunk {i+1} due to previous error/empty: {os.path.basename(chunk_filename)}")
                              self.failed_chunks_queue.put((i, chunk_text, 0))
                              initial_queue_fill_count += 1
                 except Exception as e:
                     debug_log(f"Error reading existing chunk {i+1} ({os.path.basename(chunk_filename)}): {e}. Re-queueing.")
                     self.failed_chunks_queue.put((i, chunk_text, 0))
                     initial_queue_fill_count += 1
             else:
                 self.failed_chunks_queue.put((i, chunk_text, 0))
                 initial_queue_fill_count += 1

        self.progress_signal.emit(f"⏭️ Found {skipped_count} already translated chunks.")
        self.progress_signal.emit(f"📥 Added {initial_queue_fill_count} chunks to the processing queue.")

        if self.processed_chunks_count == self.total_chunks and initial_queue_fill_count == 0 :
            self.progress_signal.emit("✅ All chunks were already translated.")
            self.assemble_final_output(start_time) # Still assemble the final output
            return

        # --- Main processing loop ---
        with concurrent.futures.ThreadPoolExecutor(max_workers=self.max_concurrent_workers, thread_name_prefix="Translator") as executor:
            futures = {} # {future: (chunk_index, api_key, attempts)}

            while self.processed_chunks_count < self.total_chunks and not self.is_cancelled:
                # --- Assign tasks ---
                while not self.failed_chunks_queue.empty() and len(futures) < len(self.active_keys) :
                    if self.is_cancelled: break
                    chunk_index, chunk_text, attempts = self.failed_chunks_queue.get_nowait()

                    if attempts >= MAX_CHUNK_RETRIES:
                         self.progress_signal.emit(f"❌ Chunk {chunk_index+1} failed after {attempts} attempts. Skipping.")
                         self.results[chunk_index] = f"⚠️ Permanently Failed (Chunk {chunk_index+1})"
                         save_chunk(self.results[chunk_index], os.path.join(self.output_dir, f"translated_chunk_{chunk_index+1}.txt"))
                         with self.processing_lock: self.processed_chunks_count += 1
                         continue

                    # --- Find suitable key ---
                    assigned_key = None
                    keys_checked_in_cycle = 0
                    max_keys_to_check = len(self.api_keys) * 2

                    while keys_checked_in_cycle < max_keys_to_check and not self.is_cancelled:
                        potential_key = next(self.key_cycler)
                        keys_checked_in_cycle += 1
                        if potential_key not in self.active_keys: continue
                        if self.key_status[potential_key]['wait_until'] > time.time(): continue
                        assigned_key = potential_key; break

                    if assigned_key:
                        future = executor.submit(translate_text_with_key, chunk_text, assigned_key, chunk_index)
                        futures[future] = (chunk_index, assigned_key, attempts + 1)
                        time.sleep(API_REQUEST_DELAY_MS / 1000.0)
                    elif not self.is_cancelled:
                         self.failed_chunks_queue.put((chunk_index, chunk_text, attempts))
                         time.sleep(1 if futures else 5) # Wait longer if nothing is running

                # --- Process completed futures ---
                if not futures:
                     if self.failed_chunks_queue.empty() and self.processed_chunks_count < self.total_chunks:
                         # Check if stuck due to waiting keys or no active keys left
                         if not self.active_keys:
                             debug_log("Error: No active keys left.")
                             self.progress_signal.emit("❌ No active API keys left. Stopping.")
                             self.cancel()
                         else:
                             all_waiting = all(self.key_status[k]['wait_until'] > time.time() for k in self.active_keys)
                             if all_waiting: time.sleep(10) # All keys might be on quota hold
                             else: time.sleep(2) # General wait
                     elif self.failed_chunks_queue.empty() and self.processed_chunks_count == self.total_chunks:
                         break # All done
                     continue

                done, _ = concurrent.futures.wait(futures.keys(), timeout=1.0, return_when=concurrent.futures.FIRST_COMPLETED)

                for future in done:
                    if self.is_cancelled: break
                    chunk_index, api_key, attempt_num = futures.pop(future)
                    key_short = api_key[-4:] if len(api_key) >= 4 else api_key

                    try:
                        result = future.result()
                        current_chunk_text = self.chunks[chunk_index] # Get original text for re-queueing

                        if isinstance(result, str) and not result.startswith("⚠️"):
                             self.results[chunk_index] = result
                             save_chunk(result, os.path.join(self.output_dir, f"translated_chunk_{chunk_index+1}.txt"))
                             self.progress_signal.emit(f"✅ Chunk {chunk_index+1}/{self.total_chunks} OK (Key ...{key_short}, Try {attempt_num})")
                             with self.processing_lock: self.processed_chunks_count += 1
                        elif result == "⚠️ Error (Invalid Key)":
                             self.progress_signal.emit(f"❌ Invalid key ...{key_short}. Disabling & re-queueing chunk {chunk_index+1}.")
                             self.active_keys.discard(api_key)
                             self.key_status[api_key]['status'] = 'invalid'
                             self.failed_chunks_queue.put((chunk_index, current_chunk_text, attempt_num - 1)) # Retry with same attempt count
                             if not self.active_keys: self.cancel(); self.progress_signal.emit("❌ All keys failed!")
                        elif result == "⚠️ Error (Quota)":
                             self.progress_signal.emit(f"🚦 Quota error key ...{key_short}. Re-queueing chunk {chunk_index+1} & pausing key.")
                             self.key_status[api_key]['wait_until'] = time.time() + 300
                             self.failed_chunks_queue.put((chunk_index, current_chunk_text, attempt_num - 1)) # Retry with same attempt count
                        elif result == "⚠️ Error (Billing Required)":
                             self.progress_signal.emit(f"💰 Billing key ...{key_short}. Disabling & re-queueing chunk {chunk_index+1}.")
                             self.active_keys.discard(api_key)
                             self.key_status[api_key]['status'] = 'billing_error'
                             self.failed_chunks_queue.put((chunk_index, current_chunk_text, attempt_num - 1)) # Retry with same attempt count
                        elif result.startswith("⚠️ Not Translated (Blocked"):
                             self.progress_signal.emit(f"🛡️ Chunk {chunk_index+1} blocked by safety (Key ...{key_short}). Saving error.")
                             self.results[chunk_index] = result
                             save_chunk(result, os.path.join(self.output_dir, f"translated_chunk_{chunk_index+1}.txt"))
                             with self.processing_lock: self.processed_chunks_count += 1
                        elif result == "⚠️ Error (Input Too Long?)":
                             self.progress_signal.emit(f"📏 Chunk {chunk_index+1} too long? (Key ...{key_short}). Saving error.")
                             self.results[chunk_index] = result
                             save_chunk(result, os.path.join(self.output_dir, f"translated_chunk_{chunk_index+1}.txt"))
                             with self.processing_lock: self.processed_chunks_count += 1
                        else: # General failure for this attempt
                             self.progress_signal.emit(f"⚠️ Chunk {chunk_index+1} failed Try {attempt_num} (Key ...{key_short}: {result}). Re-queueing.")
                             self.failed_chunks_queue.put((chunk_index, current_chunk_text, attempt_num)) # Re-queue with incremented attempt

                    except Exception as exc:
                        self.progress_signal.emit(f"‼️ System error chunk {chunk_index+1} (Key ...{key_short}): {exc}")
                        debug_log(f"‼️ System error future chunk {chunk_index+1}: {exc}")
                        current_chunk_text = self.chunks[chunk_index] # Get original text
                        self.failed_chunks_queue.put((chunk_index, current_chunk_text, attempt_num)) # Re-queue

        # --- Final Check and Output Assembly ---
        if self.is_cancelled:
            self.finished_signal.emit("🛑 Translation process cancelled by user.")
        elif self.processed_chunks_count == self.total_chunks:
            self.progress_signal.emit(" assembling final output...")
            self.assemble_final_output(start_time)
        else:
             processed = self.processed_chunks_count
             total = self.total_chunks
             remaining = self.failed_chunks_queue.qsize()
             final_msg = f"⚠️ Finished unexpectedly. Processed {processed}/{total}. ({remaining} left in queue?). Check logs."
             self.finished_signal.emit(final_msg); debug_log(final_msg)

        active_key_count = len(self.active_keys)
        debug_log(f"🏁 Worker thread finished. Active keys remaining: {active_key_count}")


    def assemble_final_output(self, start_time):
        """Assembles the final translated text from processed chunks."""
        self.progress_signal.emit("💾 Assembling final translated text...")
        final_output = []
        success_count = 0
        fail_count = 0
        skipped_or_failed_indices = []

        for i in range(self.total_chunks):
            # *** Access results as list using index ***
            result_text = self.results[i] if i < len(self.results) else ""
            original_chunk_text = self.chunks[i] if i < len(self.chunks) else f"[Original Chunk {i+1} Missing]"

            if result_text and not result_text.startswith("⚠️"):
                final_output.append(result_text)
                success_count += 1
            else:
                fail_count += 1
                skipped_or_failed_indices.append(i + 1)
                fail_reason = result_text if result_text else "Missing Translation"
                final_output.append(f"\n--- FAILED CHUNK {i+1} ---\nReason: {fail_reason}\n--- ORIGINAL TEXT ---\n{original_chunk_text}\n--- END FAILED CHUNK ---\n")

        base_input_name = os.path.splitext(os.path.basename(self.input_file))[0]
        full_output_file = os.path.join(self.output_dir, f"{base_input_name}_translated_full_combined.txt")

        try:
            full_text = "\n\n".join(final_output)
            with open(full_output_file, "w", encoding="utf-8") as f: f.write(full_text)
            end_time = time.time()
            duration = end_time - start_time
            duration_str = time.strftime("%H:%M:%S", time.gmtime(duration))
            summary_msg = f"✅ Translation completed in {duration_str}. {success_count}/{self.total_chunks} chunks successful."
            if fail_count > 0: summary_msg += f" {fail_count} failed (Indices: {skipped_or_failed_indices})."
            summary_msg += f"\nFull output saved to:\n{full_output_file}"
            self.finished_signal.emit(summary_msg)
            debug_log(f"🎉 Translation completed! Output: {full_output_file}")
        except Exception as e:
             error_msg = f"✅ Tasks finished, but failed to save combined file '{os.path.basename(full_output_file)}': {e}"
             self.finished_signal.emit(error_msg); debug_log(f"❌ {error_msg}")

# --- PyQt5 UI class (Unchanged from previous version - except window title) ---
class TranslatorApp(QMainWindow):
    def __init__(self):
        super().__init__()
        # Updated window title to reflect the new version/feature
        self.setWindowTitle("Multi-Key Text Translator (v5 - Intelligent Chunking)")
        self.setGeometry(100, 100, 900, 700) # Keep window size
        self.setStyleSheet("""
            QMainWindow { background-color: #f0f0f0; }
            QLabel { font-size: 14px; padding-bottom: 5px; }
            QLineEdit, QPlainTextEdit, QTextEdit {
                background-color: white;
                border: 1px solid #ccc;
                border-radius: 4px;
                padding: 8px;
                font-size: 13px;
            }
            QPlainTextEdit#ApiKeys { font-family: Consolas, monospace; }
            QPushButton {
                background-color: #007bff; /* Blue */
                color: white;
                padding: 10px 15px;
                border: none;
                border-radius: 4px;
                font-size: 14px;
                font-weight: bold;
            }
            QPushButton:hover { background-color: #0056b3; }
            QPushButton:disabled { background-color: #cccccc; color: #666666;}
            QPushButton#CancelButton { background-color: #dc3545; /* Red */ }
            QPushButton#CancelButton:hover { background-color: #c82333; }
            QPushButton#CancelButton:disabled { background-color: #f8d7da; color: #721c24; }
            QTextEdit#ProgressText {
                background-color: #e9ecef; /* Lighter grey */
                border-radius: 5px;
                padding: 10px;
                font-family: Consolas, 'Courier New', monospace;
                font-size: 12px;
                color: #343a40; /* Darker text */
                line-height: 1.4;
            }
        """)

        self.translation_thread = None
        self.worker = None

        self.initUI()
        self.load_api_keys_from_file() # Attempt to load keys on startup

    def initUI(self):
        self.central_widget = QWidget()
        self.setCentralWidget(self.central_widget)
        self.layout = QVBoxLayout(self.central_widget)

        # --- API Keys Section ---
        self.api_keys_layout = QHBoxLayout()
        self.api_keys_label = QLabel("API Keys (one per line):")
        self.load_keys_button = QPushButton("Load from File")
        self.load_keys_button.clicked.connect(self.load_api_keys_from_file_dialog)
        self.save_keys_button = QPushButton("Save to File")
        self.save_keys_button.clicked.connect(self.save_api_keys_to_file_dialog)
        self.api_keys_layout.addWidget(self.api_keys_label)
        self.api_keys_layout.addStretch()
        self.api_keys_layout.addWidget(self.load_keys_button)
        self.api_keys_layout.addWidget(self.save_keys_button)

        self.api_keys_input = QPlainTextEdit()
        self.api_keys_input.setObjectName("ApiKeys")
        self.api_keys_input.setPlaceholderText("Enter your Google AI API keys here, one key per line.\nOr use 'Load from File'.")
        self.api_keys_input.setFixedHeight(120)

        # --- File Selection Section ---
        self.file_layout = QHBoxLayout()
        self.label_input = QLabel("Input Text File:")
        self.input_file_display = QLineEdit()
        self.input_file_display.setPlaceholderText("Select a .txt file to translate...")
        self.input_file_display.setReadOnly(False) # Allow pasting path
        self.browse_button = QPushButton("Browse...")
        self.browse_button.clicked.connect(self.browse_file)
        self.file_layout.addWidget(self.label_input)
        self.file_layout.addWidget(self.input_file_display, 1) # Allow input to stretch
        self.file_layout.addWidget(self.browse_button)

        # --- Progress Section ---
        self.label_progress = QLabel("Progress Log:")
        self.progress_text = QTextEdit()
        self.progress_text.setObjectName("ProgressText")
        self.progress_text.setReadOnly(True)

        # --- Action Buttons Section ---
        self.button_layout = QHBoxLayout()
        self.start_button = QPushButton("Start Translation")
        self.start_button.clicked.connect(self.start_translation)
        self.cancel_button = QPushButton("Cancel")
        self.cancel_button.setObjectName("CancelButton")
        self.cancel_button.clicked.connect(self.cancel_translation)
        self.cancel_button.setEnabled(False)
        self.button_layout.addStretch()
        self.button_layout.addWidget(self.start_button)
        self.button_layout.addWidget(self.cancel_button)
        self.button_layout.addStretch()


        # Add widgets to main layout
        self.layout.addLayout(self.api_keys_layout)
        self.layout.addWidget(self.api_keys_input)
        self.layout.addLayout(self.file_layout)
        self.layout.addWidget(self.label_progress)
        self.layout.addWidget(self.progress_text, 1) # Give progress log more space
        self.layout.addLayout(self.button_layout)

    # --- File Dialog and Key Management Methods ---
    def browse_file(self):
        filename, _ = QFileDialog.getOpenFileName(self, "Select Input Text File", "", "Text Files (*.txt);;All Files (*)")
        if filename:
            self.input_file_display.setText(filename)

    def load_api_keys_from_file(self, filename="api_keys.txt"):
         # Default filename for automatic loading
         if os.path.exists(filename):
             try:
                 with open(filename, "r", encoding="utf-8") as f: # Specify encoding
                     keys = f.read().strip()
                     self.api_keys_input.setPlainText(keys)
                     # Avoid appending progress on initial auto-load unless explicitly needed
                     # self.append_progress(f"🔑 Loaded API keys from {filename}")
                     debug_log(f"Auto-loaded API keys from {filename}")
             except Exception as e:
                 self.show_message("Error Loading Keys", f"Could not read keys from {filename}:\n{e}", level="warning")
                 debug_log(f"Error loading keys from {filename}: {e}")
         else:
             debug_log(f"Note: Default key file '{filename}' not found on startup.")


    def load_api_keys_from_file_dialog(self):
        filename, _ = QFileDialog.getOpenFileName(self, "Load API Keys", "", "Text Files (*.txt);;All Files (*)")
        if filename:
             try:
                 with open(filename, "r", encoding="utf-8") as f: # Specify encoding
                     keys = f.read().strip()
                     self.api_keys_input.setPlainText(keys)
                     self.append_progress(f"🔑 Loaded API keys from {os.path.basename(filename)}")
                     debug_log(f"Loaded API keys from {filename}")
             except Exception as e:
                 self.show_message("Error Loading Keys", f"Could not read keys from {filename}:\n{e}", level="warning")
                 debug_log(f"Error loading keys from {filename}: {e}")

    def save_api_keys_to_file_dialog(self):
         keys_text = self.api_keys_input.toPlainText().strip()
         if not keys_text:
             self.show_message("No Keys", "There are no API keys entered to save.", level="warning")
             return

         filename, _ = QFileDialog.getSaveFileName(self, "Save API Keys", "api_keys.txt", "Text Files (*.txt);;All Files (*)")
         if filename:
             try:
                 with open(filename, "w", encoding="utf-8") as f: # Specify encoding
                     f.write(keys_text + "\n") # Add newline for consistency
                 self.append_progress(f"💾 Saved API keys to {os.path.basename(filename)}")
                 debug_log(f"Saved API keys to {filename}")
             except Exception as e:
                 self.show_message("Error Saving Keys", f"Could not save keys to {filename}:\n{e}", level="error")
                 debug_log(f"Error saving keys to {filename}: {e}")


    # --- GUI Update and Control Methods ---
    def append_progress(self, message):
        """Appends messages to the progress log (thread-safe)."""
        self.progress_text.append(message)
        self.progress_text.verticalScrollBar().setValue(self.progress_text.verticalScrollBar().maximum()) # Auto-scroll

    def update_chunk_status(self, chunk_index, status_text):
         """Placeholder for potential future detailed status display."""
         pass # Logging is sufficient for now

    def show_message(self, title, message, level="info"):
        """Shows a message box."""
        msgBox = QMessageBox(self)
        msgBox.setWindowTitle(title)
        msgBox.setText(message)
        if level == "info":
            msgBox.setIcon(QMessageBox.Information)
        elif level == "warning":
            msgBox.setIcon(QMessageBox.Warning)
        elif level == "error":
             msgBox.setIcon(QMessageBox.Critical)
        msgBox.setStandardButtons(QMessageBox.Ok)
        msgBox.exec_()

    def set_controls_enabled(self, enabled):
        """Enables/disables controls during translation."""
        self.start_button.setEnabled(enabled)
        self.browse_button.setEnabled(enabled)
        self.input_file_display.setEnabled(enabled)
        self.api_keys_input.setEnabled(enabled)
        self.load_keys_button.setEnabled(enabled)
        self.save_keys_button.setEnabled(enabled)
        # Handle cancel button state
        self.cancel_button.setEnabled(not enabled) # Enable cancel only when running
        if enabled:
            self.cancel_button.setText("Cancel") # Reset cancel button text


    def translation_finished(self, final_message):
        """Called when the worker thread finishes or is cancelled."""
        # Ensure controls are re-enabled and thread references are cleared
        self.set_controls_enabled(True)
        self.translation_thread = None
        self.worker = None
        # Log the first line of the final message
        self.append_progress(f"🏁 {final_message.splitlines()[0]}")
        debug_log(f"Translation finished signal received: {final_message.splitlines()[0]}")


        # Show appropriate message box based on result
        if "✅" in final_message:
            self.show_message("Translation Finished", final_message, level="info")
        elif "🛑" in final_message:
             self.show_message("Translation Cancelled", final_message, level="warning")
        elif "⚠️" in final_message or "❌" in final_message:
             # Use warning for partial success/errors/unexpected finish
             self.show_message("Translation Problem", final_message, level="warning")
        else: # Should not happen often
            self.show_message("Translation Status", final_message, level="info")


    def start_translation(self):
        if self.worker is not None:
            self.show_message("Already Running", "A translation process is already in progress.", level="warning")
            return

        input_file = self.input_file_display.text().strip()
        api_keys_text = self.api_keys_input.toPlainText().strip()

        if not input_file or not os.path.exists(input_file):
            self.show_message("Input Error", "Please select a valid input text file.", level="warning")
            return
        if not api_keys_text:
            self.show_message("Input Error", "Please enter at least one API key.", level="warning")
            return

        # Validate keys slightly
        api_keys = [key.strip() for key in api_keys_text.splitlines() if key.strip()]
        if not api_keys:
             self.show_message("Input Error", "No valid API keys found.", level="warning")
             return

        # Determine output directory based on input file name
        output_dir_name = os.path.splitext(os.path.basename(input_file))[0] + "_translated_chunks"
        output_dir = os.path.join(os.path.dirname(input_file), output_dir_name)

        # --- Prepare for translation ---
        self.progress_text.clear()
        self.append_progress(f"🚀 Initializing translation for: {os.path.basename(input_file)}")
        self.append_progress(f"   Output directory: {output_dir}")
        self.set_controls_enabled(False) # Disable controls, enable cancel

        # Create and start the worker thread using threading.Thread
        # Ensure the worker instance is created correctly
        try:
            self.worker = TranslationWorker(input_file, api_keys_text, output_dir)
            self.translation_thread = threading.Thread(target=self.worker.run, name="TranslationWorkerThread", daemon=True)

            # Connect signals (must be done before starting thread)
            self.worker.progress_signal.connect(self.append_progress)
            self.worker.chunk_done_signal.connect(self.update_chunk_status)
            self.worker.finished_signal.connect(self.translation_finished)

            # Start the background thread
            self.translation_thread.start()
            self.append_progress("⏳ Translation process started...")

        except Exception as e:
             # Catch potential errors during worker/thread initialization
             error_msg = f"Failed to initialize translation worker: {e}"
             self.append_progress(f"❌ {error_msg}")
             debug_log(f"Error during start_translation: {e}")
             self.show_message("Initialization Error", error_msg, level="error")
             self.set_controls_enabled(True) # Re-enable controls if failed to start
             self.worker = None
             self.translation_thread = None


    def cancel_translation(self):
        if self.worker:
            self.append_progress("✋ Sending cancellation request...")
            self.cancel_button.setEnabled(False) # Disable immediately
            self.cancel_button.setText("Cancelling...")
            self.worker.cancel() # Signal the worker to stop
            debug_log("Cancel button clicked, cancel signal sent to worker.")
        else:
             self.append_progress("❕ No active translation process to cancel.")
             debug_log("Cancel clicked but no worker found.")


    def closeEvent(self, event):
        """Handle closing the window while translation might be running."""
        if self.translation_thread and self.translation_thread.is_alive():
            reply = QMessageBox.question(self, 'Confirm Exit',
                                         "Translation is running. Exiting now will stop it.\nAre you sure you want to exit?",
                                         QMessageBox.Yes | QMessageBox.No, QMessageBox.No)
            if reply == QMessageBox.Yes:
                debug_log("User confirmed exit during active translation.")
                if self.worker:
                    self.worker.cancel() # Attempt graceful cancellation
                    debug_log("Cancel signal sent to worker during close event.")
                event.accept() # Allow window to close
            else:
                debug_log("User cancelled exit during active translation.")
                event.ignore() # Keep window open
        else:
            event.accept() # Close normally if no thread running


if __name__ == "__main__":
    # --- Initial Log Setup ---
    try:
        # Use 'a' to append, 'w' to overwrite each time
        with open(LOG_FILE, "a", encoding="utf-8") as f:
             f.write("\n" + "="*20 + "\n")
             f.write(f"{time.strftime('%Y-%m-%d %H:%M:%S')} - Application Started\n")
             f.write(f"--- Platform: {sys.platform}, Python: {sys.version.split()[0]} ---\n")
    except Exception as e:
        print(f"Could not write initial log entry to '{LOG_FILE}': {e}")

    app = QApplication(sys.argv)
    window = TranslatorApp()
    window.show()
    sys.exit(app.exec_())