#!/usr/bin/env python3
"""
OasisMM Database Migration Script
Creates a consolidated SQLite database from all JSON/TXT/DB assets.
Database: oasismm.db
"""

import sqlite3
import json
import os
import re
from pathlib import Path
from typing import Dict, List, Any

# Configuration
# Configuration
ASSETS_DIR = Path("assets").absolute()
ARCHIVE_DIR = Path("data_archive").absolute()
OUTPUT_DB = ASSETS_DIR / "oasismm.db"


def log(message: str):
    try:
        print(f"[OasisMM] {message}")
    except UnicodeEncodeError:
        print(f"[OasisMM] {message.encode('ascii', 'replace').decode('ascii')}")


def create_connection() -> sqlite3.Connection:
    """Create database connection with optimized settings"""
    if OUTPUT_DB.exists():
        try:
            OUTPUT_DB.unlink()
            log(f"Removed existing database")
        except Exception as e:
            log(f"Warning: Could not remove existing database: {e}")
            log("Attempting to continue by overwriting...")
    
    conn = sqlite3.connect(str(OUTPUT_DB))
    conn.execute("PRAGMA journal_mode=WAL")
    conn.execute("PRAGMA synchronous=NORMAL")
    conn.execute("PRAGMA cache_size=10000")
    conn.execute("PRAGMA temp_store=MEMORY")
    return conn

def create_schema(conn: sqlite3.Connection):
    """Create all database tables"""
    log("Creating database schema...")
    
    conn.executescript("""
    -- ============================================
    -- DROP EXISTING TABLES
    -- ============================================
    DROP TABLE IF EXISTS surahs;
    DROP TABLE IF EXISTS verses;
    DROP TABLE IF EXISTS translations;
    DROP TABLE IF EXISTS surah_info;
    DROP TABLE IF EXISTS quran_juz;
    DROP TABLE IF EXISTS quran_hizb;
    DROP TABLE IF EXISTS quran_ruku;
    DROP TABLE IF EXISTS quran_manzil;
    DROP TABLE IF EXISTS quran_rub;
    DROP TABLE IF EXISTS quran_sajda;
    DROP TABLE IF EXISTS quran_ayah_metadata;
    DROP TABLE IF EXISTS tafseer;
    DROP TABLE IF EXISTS hadith_books;
    DROP TABLE IF EXISTS hadith_chapters;
    DROP TABLE IF EXISTS hadiths;
    DROP TABLE IF EXISTS sunnah_book_info;
    DROP TABLE IF EXISTS sunnah_chapters;
    DROP TABLE IF EXISTS sunnah_items;
    DROP TABLE IF EXISTS allah_names;
    DROP TABLE IF EXISTS dua_categories;
    DROP TABLE IF EXISTS duas;
    DROP TABLE IF EXISTS munajat;
    DROP TABLE IF EXISTS indopak_glyphs;
    DROP TABLE IF EXISTS indopak_words;
    DROP TABLE IF EXISTS qpc_glyphs;
    DROP TABLE IF EXISTS mashaf_pages;
    DROP TABLE IF EXISTS _migration_info;
    DROP TABLE IF EXISTS verses_fts;
    DROP TABLE IF EXISTS translations_fts;

    -- ============================================
    -- QURAN TABLES
    -- ============================================
    
    CREATE TABLE surahs (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        name_transliteration TEXT,
        revelation_type TEXT,
        total_verses INTEGER
    );
    
    CREATE TABLE verses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        surah_id INTEGER NOT NULL,
        verse_number INTEGER NOT NULL,
        text_arabic TEXT NOT NULL,
        text_tajweed TEXT,
        text_tajweed_indopak TEXT,
        FOREIGN KEY (surah_id) REFERENCES surahs(id),
        UNIQUE(surah_id, verse_number)
    );
    
    CREATE TABLE translations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        surah_id INTEGER NOT NULL,
        verse_number INTEGER NOT NULL,
        translator_key TEXT NOT NULL,
        text TEXT NOT NULL,
        FOREIGN KEY (surah_id) REFERENCES surahs(id),
        UNIQUE(surah_id, verse_number, translator_key)
    );
    
    CREATE TABLE surah_info (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        surah_id INTEGER NOT NULL,
        language TEXT NOT NULL,
        content TEXT NOT NULL,
        FOREIGN KEY (surah_id) REFERENCES surahs(id),
        UNIQUE(surah_id, language)
    );
    
    -- ============================================
    -- QURAN METADATA TABLES
    -- ============================================
    
    CREATE TABLE quran_juz (
        id INTEGER PRIMARY KEY,
        start_surah INTEGER,
        start_verse INTEGER,
        end_surah INTEGER,
        end_verse INTEGER,
        data TEXT
    );
    
    CREATE TABLE quran_hizb (
        id INTEGER PRIMARY KEY,
        data TEXT
    );
    
    CREATE TABLE quran_ruku (
        id INTEGER PRIMARY KEY,
        data TEXT
    );
    
    CREATE TABLE quran_manzil (
        id INTEGER PRIMARY KEY,
        data TEXT
    );
    
    CREATE TABLE quran_rub (
        id INTEGER PRIMARY KEY,
        data TEXT
    );
    
    CREATE TABLE quran_sajda (
        id INTEGER PRIMARY KEY,
        surah_id INTEGER,
        verse_number INTEGER,
        sajda_type TEXT
    );
    
    CREATE TABLE quran_ayah_metadata (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        surah_id INTEGER,
        verse_number INTEGER,
        juz INTEGER,
        hizb INTEGER,
        rub INTEGER,
        page INTEGER,
        UNIQUE(surah_id, verse_number)
    );
    
    -- ============================================
    -- TAFSEER TABLES
    -- ============================================
    
    CREATE TABLE tafseer (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        surah_id INTEGER NOT NULL,
        verse_start INTEGER NOT NULL,
        verse_end INTEGER,
        language TEXT NOT NULL,
        source TEXT NOT NULL,
        text TEXT NOT NULL
    );
    
    CREATE INDEX idx_tafseer_surah ON tafseer(surah_id, verse_start);
    
    -- ============================================
    -- HADITH TABLES
    -- ============================================
    
    CREATE TABLE hadith_books (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        book_key TEXT UNIQUE NOT NULL,
        name_arabic TEXT,
        name_english TEXT,
        author_arabic TEXT,
        author_english TEXT,
        total_hadiths INTEGER
    );
    
    CREATE TABLE hadith_chapters (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        book_id INTEGER NOT NULL,
        chapter_number INTEGER,
        name_arabic TEXT,
        name_english TEXT,
        FOREIGN KEY (book_id) REFERENCES hadith_books(id)
    );
    
    CREATE TABLE hadiths (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        book_id INTEGER NOT NULL,
        chapter_id INTEGER,
        hadith_number TEXT,
        text_arabic TEXT,
        text_english TEXT,
        text_myanmar TEXT,
        narrator_english TEXT,
        narrator_myanmar TEXT,
        chapter_arabic TEXT,
        chapter_english TEXT,
        chapter_number TEXT,
        grade TEXT,
        reference TEXT,
        FOREIGN KEY (book_id) REFERENCES hadith_books(id),
        FOREIGN KEY (chapter_id) REFERENCES hadith_chapters(id)
    );
    
    CREATE INDEX idx_hadiths_book ON hadiths(book_id);
    CREATE INDEX idx_hadiths_chapter ON hadiths(chapter_id);
    
    -- ============================================
    -- SUNNAH COLLECTION TABLES
    -- ============================================
    
    CREATE TABLE sunnah_book_info (
        id INTEGER PRIMARY KEY,
        title TEXT,
        author TEXT,
        publisher TEXT,
        language TEXT,
        edition TEXT,
        contact_phone TEXT,
        contact_mobile TEXT,
        contact_email TEXT
    );
    
    CREATE TABLE sunnah_chapters (
        id INTEGER PRIMARY KEY,
        chapter_number INTEGER UNIQUE,
        title TEXT
    );
    
    CREATE TABLE sunnah_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        chapter_id INTEGER,
        item_number INTEGER,
        text TEXT,
        arabic_text TEXT,
        urdu_translation TEXT,
        references_json TEXT,
        FOREIGN KEY (chapter_id) REFERENCES sunnah_chapters(id)
    );
    
    -- ============================================
    -- 99 NAMES OF ALLAH
    -- ============================================
    
    CREATE TABLE allah_names (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        arabic TEXT NOT NULL,
        english TEXT NOT NULL,
        urdu_meaning TEXT,
        english_meaning TEXT,
        english_explanation TEXT
    );
    
    -- ============================================
    -- DUA & DHIKR TABLES
    -- ============================================
    
    CREATE TABLE dua_categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_key TEXT UNIQUE,
        name TEXT,
        description TEXT
    );
    
    CREATE TABLE duas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER,
        language TEXT,
        title TEXT,
        arabic_text TEXT,
        transliteration TEXT,
        translation TEXT,
        reference TEXT,
        benefits TEXT,
        repeat_count INTEGER DEFAULT 1,
        FOREIGN KEY (category_id) REFERENCES dua_categories(id)
    );
    
    -- ============================================
    -- MUNAJAT TABLE
    -- ============================================
    
    CREATE TABLE munajat (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT,
        title TEXT,
        arabic_text TEXT,
        transliteration TEXT,
        translation TEXT,
        reference TEXT,
        data_json TEXT
    );
    
    -- ============================================
    -- INDOPAK FONT GLYPHS
    -- ============================================
    
    CREATE TABLE indopak_glyphs (
        id INTEGER PRIMARY KEY,
        location TEXT,
        surah INTEGER,
        ayah INTEGER,
        word INTEGER,
        text_tajweed TEXT
    );
    
    CREATE INDEX idx_indopak_glyphs_location ON indopak_glyphs(surah, ayah);
    
    -- IndoPak words from indopak-nastaleeq.db
    CREATE TABLE indopak_words (
        id INTEGER PRIMARY KEY,
        surah INTEGER NOT NULL,
        ayah INTEGER NOT NULL,
        word INTEGER NOT NULL,
        text TEXT,
        char_type TEXT,
        text_tajweed TEXT
    );
    
    CREATE INDEX idx_indopak_words_location ON indopak_words(surah, ayah);
    
    -- QPC v4 glyphs from qpc-v4.db
    CREATE TABLE qpc_glyphs (
        id INTEGER PRIMARY KEY,
        surah INTEGER NOT NULL,
        ayah INTEGER NOT NULL,
        word INTEGER NOT NULL,
        page INTEGER,
        line INTEGER,
        text TEXT,
        glyph_code TEXT
    );
    
    CREATE INDEX idx_qpc_glyphs_location ON qpc_glyphs(surah, ayah);
    CREATE INDEX idx_qpc_glyphs_page ON qpc_glyphs(page, line);
    
    -- Mashaf layout from qudratullah-indopak-15-lines.db
    CREATE TABLE mashaf_pages (
        id INTEGER PRIMARY KEY,
        page_number INTEGER NOT NULL,
        surah INTEGER,
        ayah INTEGER,
        line INTEGER,
        x_position REAL,
        y_position REAL,
        width REAL,
        height REAL,
        data_json TEXT
    );
    
    CREATE INDEX idx_mashaf_pages_page ON mashaf_pages(page_number);
    CREATE INDEX idx_mashaf_pages_location ON mashaf_pages(surah, ayah);
    
    -- ============================================
    -- MIGRATION METADATA
    -- ============================================
    
    CREATE TABLE _migration_info (
        id INTEGER PRIMARY KEY,
        version INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        source_files TEXT
    );
    
    -- Full-Text Search for Quran
    CREATE VIRTUAL TABLE verses_fts USING fts5(
        text_arabic, 
        content='verses', 
        content_rowid='id'
    );
    
    CREATE VIRTUAL TABLE translations_fts USING fts5(
        text,
        content='translations',
        content_rowid='id'
    );
    """)
    
    log("Schema created successfully")

# ============================================
# MIGRATION FUNCTIONS
# ============================================

def get_asset_file(path_str: str) -> Path:
    """Get file path from assets or archive"""
    # Check assets first
    p = ASSETS_DIR / path_str
    if p.exists(): return p
    
    # Check archive
    p = ARCHIVE_DIR / path_str
    if p.exists(): return p
    
    return None

def migrate_quran_simple(conn: sqlite3.Connection):
    """Migrate quran-simple.json (Arabic text)"""
    file_path = get_asset_file("quran_data/quran-simple.json")
    if not file_path:
        log("Quran simple JSON not found in assets or archive, skipping...")
        return
    
    log(f"Migrating Quran simple from {file_path}...")
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    surah_count = 0
    verse_count = 0
    
    for surah in data:
        conn.execute("""
            INSERT OR REPLACE INTO surahs (id, name, name_transliteration, revelation_type, total_verses)
            VALUES (?, ?, ?, ?, ?)
        """, (surah['id'], surah['name'], surah.get('transliteration'), surah.get('type'), surah.get('total_verses')))
        surah_count += 1
        
        for verse in surah.get('verses', []):
            conn.execute("""
                INSERT OR REPLACE INTO verses (surah_id, verse_number, text_arabic)
                VALUES (?, ?, ?)
            """, (surah['id'], verse['id'], verse['text']))
            verse_count += 1
    
    conn.commit()
    log(f"  Migrated {surah_count} surahs, {verse_count} verses")

def migrate_tajweed(conn: sqlite3.Connection):
    """Migrate tajweed JSON files"""
    files = [
        ("quran_tajweed_api.json", "text_tajweed"),
        ("quran_tajweed_indopak.json", "text_tajweed_indopak")
    ]
    
    for filename, column in files:
        file_path = get_asset_file(f"quran_data/{filename}")
        if not file_path:
            log(f"Skipping: {filename} not found in assets or archive")
            continue
        
        log(f"Migrating {filename}...")
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        count = 0
        for surah in data:
            for verse in surah.get('verses', []):
                conn.execute(f"""
                    UPDATE verses SET {column} = ?
                    WHERE surah_id = ? AND verse_number = ?
                """, (verse.get('text', ''), surah['id'], verse['id']))
                count += 1
        
        conn.commit()
        log(f"  Updated {count} verses with tajweed")

def migrate_translations(conn: sqlite3.Connection):
    """Migrate Burmese translation TXT files"""
    translation_files = [
        ("mya-basein.txt", "mya-basein"),
        ("mya-ghazimohammadha.txt", "mya-ghazi"),
        ("mya-hashimtinmyint.txt", "mya-hashim"),
    ]
    
    for filename, translator_key in translation_files:
        file_path = get_asset_file(f"quran_data/{filename}")
        if not file_path:
            log(f"Skipping: {filename} not found")
            continue
        
        log(f"Migrating translation: {filename}...")
        count = 0
        
        with open(file_path, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                
                parts = line.split('|')
                if len(parts) >= 3:
                    surah_id = int(parts[0])
                    verse_number = int(parts[1])
                    text = '|'.join(parts[2:])  # Handle text that might contain |
                    
                    conn.execute("""
                        INSERT OR REPLACE INTO translations (surah_id, verse_number, translator_key, text)
                        VALUES (?, ?, ?, ?)
                    """, (surah_id, verse_number, translator_key, text))
                    count += 1
        
        conn.commit()
        log(f"  Migrated {count} translation verses")

def migrate_quran_metadata(conn: sqlite3.Connection):
    """Migrate Quran metadata JSON files"""
    metadata_files = [
        ("quran-metadata-juz.json", "quran_juz"),
        ("quran-metadata-hizb.json", "quran_hizb"),
        ("quran-metadata-ruku.json", "quran_ruku"),
        ("quran-metadata-manzil.json", "quran_manzil"),
        ("quran-metadata-rub.json", "quran_rub"),
    ]
    
    for filename, table_name in metadata_files:
        file_path = get_asset_file(f"quran_data/{filename}")
        if not file_path:
            log(f"Skipping: {filename} not found")
            continue
        
        log(f"Migrating {filename}...")
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        if isinstance(data, list):
            for i, item in enumerate(data, 1):
                conn.execute(f"""
                    INSERT INTO {table_name} (id, data) VALUES (?, ?)
                """, (i, json.dumps(item, ensure_ascii=False)))
        elif isinstance(data, dict):
            for key, value in data.items():
                conn.execute(f"""
                    INSERT INTO {table_name} (id, data) VALUES (?, ?)
                """, (int(key) if key.isdigit() else hash(key), json.dumps(value, ensure_ascii=False)))
        
        conn.commit()
        log(f"  Migrated {table_name}")
    
    # Migrate sajda positions
    sajda_file = get_asset_file("quran_data/quran-metadata-sajda.json")
    if sajda_file:
        log("Migrating sajda positions...")
        with open(sajda_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        for key, item in data.items():
            # Parse verse_key format "surah:verse"
            verse_key = item.get('verse_key', '')
            parts = verse_key.split(':')
            surah_id = int(parts[0]) if len(parts) >= 2 else None
            verse_number = int(parts[1]) if len(parts) >= 2 else None
            
            conn.execute("""
                INSERT INTO quran_sajda (id, surah_id, verse_number, sajda_type)
                VALUES (?, ?, ?, ?)
            """, (item.get('sajdah_number'), surah_id, verse_number, item.get('sajdah_type', 'optional')))
        conn.commit()
        log(f"  Migrated {len(data)} sajda positions")
    
    # Migrate ayah metadata
    ayah_file = get_asset_file("quran_data/quran-metadata-ayah.json")
    if ayah_file:
        log("Migrating ayah metadata...")
        with open(ayah_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        count = 0
        # Handle dictionary format with keys like "1", "2", etc.
        items = data.values() if isinstance(data, dict) else data
        for item in items:
            conn.execute("""
                INSERT OR REPLACE INTO quran_ayah_metadata 
                (surah_id, verse_number, juz, hizb, rub, page)
                VALUES (?, ?, ?, ?, ?, ?)
            """, (
                item.get('surah_number') or item.get('surah'), 
                item.get('ayah_number') or item.get('ayah'), 
                item.get('juz'), item.get('hizb'),
                item.get('rub'), item.get('page')
            ))
            count += 1
        conn.commit()
        log(f"  Migrated {count} ayah metadata records")

def migrate_surah_info(conn: sqlite3.Connection):
    """Migrate surah info JSON files"""
    info_files = [
        ("surah-info-ur.json", "ur"),
        ("suran-info-mm.json", "mm"),
    ]
    
    for filename, language in info_files:
        file_path = get_asset_file(f"quran_data/{filename}")
        if not file_path:
            log(f"Skipping: {filename} not found")
            continue
        
        log(f"Migrating surah info: {filename}...")
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        count = 0
        if isinstance(data, list):
            for item in data:
                surah_id = item.get('index') or item.get('id')
                if surah_id:
                    conn.execute("""
                        INSERT OR REPLACE INTO surah_info (surah_id, language, content)
                        VALUES (?, ?, ?)
                    """, (surah_id, language, json.dumps(item, ensure_ascii=False)))
                    count += 1
        elif isinstance(data, dict):
            for surah_id, content in data.items():
                conn.execute("""
                    INSERT OR REPLACE INTO surah_info (surah_id, language, content)
                    VALUES (?, ?, ?)
                """, (int(surah_id), language, json.dumps(content, ensure_ascii=False)))
                count += 1
        
        conn.commit()
        log(f"  Migrated {count} surah info records")

def migrate_hadith(conn: sqlite3.Connection):
    """Migrate Hadith JSON files"""
    hadith_dir = get_asset_file("hadits_data")
    if not hadith_dir:
        log("Hadith directory not found in assets or archive, skipping...")
        return
    
    book_mapping = {
        "bukhari": ("Sahih al-Bukhari", "صحيح البخاري"),
        "muslim": ("Sahih Muslim", "صحيح مسلم"),
        "tirmidhi": ("Jami at-Tirmidhi", "جامع الترمذي"),
        "abudawud": ("Sunan Abu Dawud", "سنن أبي داود"),
        "nasai": ("Sunan an-Nasa'i", "سنن النسائي"),
        "ibnmajah": ("Sunan Ibn Majah", "سنن ابن ماجه"),
        "malik": ("Muwatta Malik", "موطأ مالك"),
        "ahmed": ("Musnad Ahmad", "مسند أحمد"),
        "darimi": ("Sunan ad-Darimi", "سنن الدارمي"),
    }
    
    for json_file in hadith_dir.glob("*.json"):
        book_key = json_file.stem.lower()
        if book_key not in book_mapping:
            log(f"Skipping unknown hadith file: {json_file.name}")
            continue
        
        log(f"Migrating Hadith: {json_file.name}...")
        
        with open(json_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        # Get book metadata
        metadata = data.get('metadata', {})
        name_en, name_ar = book_mapping[book_key]
        
        # Insert book
        cursor = conn.execute("""
            INSERT INTO hadith_books (book_key, name_arabic, name_english, author_arabic, author_english, total_hadiths)
            VALUES (?, ?, ?, ?, ?, ?)
        """, (
            book_key, 
            metadata.get('arabic', {}).get('title', name_ar),
            metadata.get('english', {}).get('title', name_en),
            metadata.get('arabic', {}).get('author'),
            metadata.get('english', {}).get('author'),
            metadata.get('length', 0)
        ))
        book_id = cursor.lastrowid
        
        # Insert chapters
        chapters = data.get('chapters', [])
        chapter_id_map = {}
        for chapter in chapters:
            cursor = conn.execute("""
                INSERT INTO hadith_chapters (book_id, chapter_number, name_arabic, name_english)
                VALUES (?, ?, ?, ?)
            """, (book_id, chapter.get('id'), chapter.get('arabic'), chapter.get('english')))
            chapter_id_map[chapter.get('id')] = cursor.lastrowid
        
        # Insert hadiths
        hadiths_list = data.get('hadiths', [])
        hadith_count = 0
        for hadith_item in hadiths_list:
            chapter_db_id = chapter_id_map.get(hadith_item.get('chapterId'))
            
            # 1. Arabic Text - flexible mapping
            arabic_text = hadith_item.get('arabic') or hadith_item.get('arab') or ""
            
            # 2. English mapping
            english_data = hadith_item.get('english')
            text_english = ""
            narrator_english = ""
            
            if isinstance(english_data, dict):
                text_english = english_data.get('text', "")
                narrator_english = english_data.get('narrator', "")
            elif isinstance(english_data, str):
                text_english = english_data
            
            # 3. Myanmar (Burmese) mapping
            burmese_data = hadith_item.get('burmese')
            text_myanmar = ""
            narrator_myanmar = ""
            
            if isinstance(burmese_data, dict):
                text_myanmar = burmese_data.get('text', "")
                narrator_myanmar = burmese_data.get('narrator', "")
            elif isinstance(burmese_data, str):
                text_myanmar = burmese_data
            
            # Fallback for books like Bukhari where "text" is primary Myanmar content
            if not text_myanmar:
                text_myanmar = hadith_item.get('text', "")
            if not narrator_myanmar:
                narrator_myanmar = hadith_item.get('narrator', "")
                
            # 4. Sub-chapter (Section) mapping
            sub_chapter = hadith_item.get('chapter') or {}
            chapter_arabic = sub_chapter.get('arabic', "")
            chapter_english = sub_chapter.get('english', "")
            chapter_number = sub_chapter.get('number', "")
            
            conn.execute("""
                INSERT INTO hadiths (
                    book_id, chapter_id, hadith_number, text_arabic, 
                    text_english, text_myanmar, narrator_english, narrator_myanmar, 
                    chapter_arabic, chapter_english, chapter_number,
                    grade, reference
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                book_id,
                chapter_db_id,
                hadith_item.get('idInBook') or hadith_item.get('id'),
                arabic_text,
                text_english,
                text_myanmar,
                narrator_english,
                narrator_myanmar,
                chapter_arabic,
                chapter_english,
                chapter_number,
                hadith_item.get('grade'),
                (hadith_item.get('references') or {}).get('reference') or hadith_item.get('reference')
            ))
            hadith_count += 1
        
        conn.commit()
        log(f"  Migrated {len(chapters)} chapters, {hadith_count} hadiths")

def migrate_sunnah(conn: sqlite3.Connection):
    """Migrate Sunnah collection"""
    sunnah_dir = get_asset_file("sunnah collection")
    if not sunnah_dir:
        log("Sunnah collection not found in assets or archive, skipping...")
        return
    
    # Migrate book info
    book_info_file = sunnah_dir / "book_info.json"
    if book_info_file.exists():
        log("Migrating Sunnah book info...")
        with open(book_info_file, 'r', encoding='utf-8') as f:
            info = json.load(f)
        
        contact = info.get('contact', {})
        conn.execute("""
            INSERT INTO sunnah_book_info (id, title, author, publisher, language, edition, contact_phone, contact_mobile, contact_email)
            VALUES (1, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            info.get('title'), info.get('author'), info.get('publisher'),
            info.get('language'), info.get('edition'),
            contact.get('phone'), contact.get('mobile'), contact.get('email')
        ))
        conn.commit()
    
    # Migrate chapters
    log("Migrating Sunnah chapters...")
    chapter_count = 0
    item_count = 0
    
    for chapter_file in sorted(sunnah_dir.glob("chapter_*.json")):
        with open(chapter_file, 'r', encoding='utf-8') as f:
            chapter_data = json.load(f)
        
        chapter_id = chapter_data.get('chapter_id')
        chapter_title = chapter_data.get('chapter_title')
        
        cursor = conn.execute("""
            INSERT INTO sunnah_chapters (id, chapter_number, title)
            VALUES (?, ?, ?)
        """, (chapter_id, chapter_id, chapter_title))
        db_chapter_id = cursor.lastrowid
        chapter_count += 1
        
        for item in chapter_data.get('items', []):
            conn.execute("""
                INSERT INTO sunnah_items (chapter_id, item_number, text, arabic_text, urdu_translation, references_json)
                VALUES (?, ?, ?, ?, ?, ?)
            """, (
                db_chapter_id,
                item.get('id'),
                item.get('text'),
                item.get('arabic_text'),
                item.get('urdu_translation'),
                json.dumps(item.get('references', []), ensure_ascii=False)
            ))
            item_count += 1
    
    conn.commit()
    log(f"  Migrated {chapter_count} chapters, {item_count} items")

def migrate_99_names(conn: sqlite3.Connection):
    """Migrate 99 Names of Allah"""
    file_path = get_asset_file("99names.json")
    if not file_path:
        log("99 Names file not found, skipping...")
        return
    
    log("Migrating 99 Names of Allah...")
    with open(file_path, 'r', encoding='utf-8') as f:
        names = json.load(f)
    
    for name in names:
        conn.execute("""
            INSERT INTO allah_names (arabic, english, urdu_meaning, english_meaning, english_explanation)
            VALUES (?, ?, ?, ?, ?)
        """, (
            name.get('arabic'),
            name.get('english'),
            name.get('urduMeaning'),
            name.get('englishMeaning'),
            name.get('englishExplanation')
        ))
    
    conn.commit()
    log(f"  Migrated {len(names)} names")



def migrate_munajat(conn: sqlite3.Connection):
    """Migrate Munajat data"""
    file_path = get_asset_file("munajat.json")
    if not file_path:
        log("Munajat file not found in assets or archive, skipping...")
        return
    
    log("Migrating Munajat data...")
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    count = 0
    if isinstance(data, list):
        for item in data:
            conn.execute("""
                INSERT INTO munajat (category, title, arabic_text, transliteration, translation, reference, data_json)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            """, (
                item.get('category'),
                item.get('title'),
                item.get('arabic') or item.get('arabicText'),
                item.get('transliteration'),
                item.get('translation'),
                item.get('reference'),
                json.dumps(item, ensure_ascii=False)
            ))
            count += 1
    elif isinstance(data, dict):
        # Store as JSON if it's a complex structure
        conn.execute("""
            INSERT INTO munajat (category, data_json)
            VALUES (?, ?)
        """, ('all', json.dumps(data, ensure_ascii=False)))
        count = 1
    
    conn.commit()
    log(f"  Migrated {count} munajat entries")

def migrate_tafseer_ibn_kathir_en(conn: sqlite3.Connection):
    """Migrate English Ibn Kathir Tafseer from external DB"""
    db_path = get_asset_file("quran_data/en-tafisr-ibn-kathir.db")
    if not db_path:
        log("English Tafseer DB not found, skipping...")
        return
    
    log(f"Migrating English Ibn Kathir Tafseer from {db_path}...")
    src_conn = sqlite3.connect(str(db_path))
    src_cursor = src_conn.cursor()
    
    try:
        # Check table structure
        src_cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
        tables = [r[0] for r in src_cursor.fetchall()]
        
        if 'tafseer' in tables:
            src_cursor.execute("SELECT * FROM tafseer")
            count = 0
            for row in src_cursor.fetchall():
                # Parse surah:ayah from the row
                # Table structure might vary, adapt as needed
                conn.execute("""
                    INSERT INTO tafseer (surah_id, verse_start, verse_end, language, source, text)
                    VALUES (?, ?, ?, ?, ?, ?)
                """, (
                    row[1] if len(row) > 1 else 1,  # surah_id
                    row[2] if len(row) > 2 else 1,  # verse_start
                    row[3] if len(row) > 3 else None,  # verse_end
                    'en',
                    'ibn-kathir',
                    row[4] if len(row) > 4 else str(row)
                ))
                count += 1
            conn.commit()
            log(f"  Migrated {count} English tafseer entries")
    except Exception as e:
        log(f"  Error migrating English tafseer: {e}")
    finally:
        src_conn.close()

def migrate_tafseer_ibn_kathir_mm(conn: sqlite3.Connection):
    """Migrate Myanmar Ibn Kathir Tafseer from JSON files"""
    tafseer_dir = get_asset_file("quran_data/tasfeer-ibn-kasir")
    if not tafseer_dir:
        log("Myanmar Tafseer directory not found, skipping...")
        return
    
    log("Migrating Myanmar Ibn Kathir Tafseer...")
    count = 0
    
    for json_file in sorted(tafseer_dir.glob("*.json")):
        try:
            with open(json_file, 'r', encoding='utf-8') as f:
                data = json.load(f)
            
            if isinstance(data, list):
                for item in data:
                    ayah_key = item.get('ayah_key', '')
                    from_ayah = item.get('from_ayah', ayah_key)
                    to_ayah = item.get('to_ayah', from_ayah)
                    text = item.get('text', '')
                    
                    # Parse surah:verse from ayah_key
                    if ':' in from_ayah:
                        surah_id, verse_start = from_ayah.split(':')
                        surah_id = int(surah_id)
                        verse_start = int(verse_start)
                    else:
                        continue
                    
                    if ':' in to_ayah:
                        _, verse_end = to_ayah.split(':')
                        verse_end = int(verse_end)
                    else:
                        verse_end = verse_start
                    
                    conn.execute("""
                        INSERT INTO tafseer (surah_id, verse_start, verse_end, language, source, text)
                        VALUES (?, ?, ?, ?, ?, ?)
                    """, (surah_id, verse_start, verse_end, 'mm', 'ibn-kathir', text))
                    count += 1
        except Exception as e:
            log(f"  Error processing {json_file.name}: {e}")
    
    conn.commit()
    log(f"  Migrated {count} Myanmar tafseer entries")

def migrate_surah_info_additional(conn: sqlite3.Connection):
    """Migrate additional Surah Info files (Urdu, Myanmar)"""
    files = [
        (ASSETS_DIR / "quran_data" / "surah-info-ur.json", "ur"),
        (ASSETS_DIR / "quran_data" / "suran-info-mm.json", "mm"),
    ]
    
    for file_path, lang in files:
        if not file_path.exists():
            log(f"Surah info {lang} not found: {file_path.name}")
            continue
        
        log(f"Migrating Surah Info ({lang})...")
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        count = 0
        if isinstance(data, dict):
            for surah_num, info in data.items():
                try:
                    surah_id = int(surah_num)
                    # Extract content - format is {surah_number: {text, short_text, ...}}
                    content = info.get('text', '') or json.dumps(info, ensure_ascii=False)
                    
                    # Insert or update surah_info
                    conn.execute("""
                        INSERT OR REPLACE INTO surah_info (surah_id, language, content)
                        VALUES (?, ?, ?)
                    """, (surah_id, lang, content))
                    count += 1
                except (ValueError, TypeError) as e:
                    continue
        
        conn.commit()
        log(f"  Migrated {count} surah info entries for {lang}")

def migrate_dua_dhikr(conn: sqlite3.Connection):
    """Migrate Dua & Dhikr data from JSON files"""
    base_dir = get_asset_file("dua_data")
    if not base_dir:
        log("Dua data directory not found in assets or archive, skipping...")
        return
        
    categories_file = base_dir / "core" / "categories.json"

    log("Migrating Dua & Dhikr...")
    
    # 1. Migrate Categories
    category_map = {} # slug -> id
    
    if categories_file.exists():
        with open(categories_file, 'r', encoding='utf-8') as f:
            cat_data = json.load(f)
            
        # Group by slug to get names in all languages
        slug_names = {}
        if isinstance(cat_data, dict):
            for lang, items in cat_data.items():
                for item in items:
                    slug = item['slug']
                    name = item['name']
                    if slug not in slug_names:
                        slug_names[slug] = {}
                    slug_names[slug][lang] = name
        
        # Insert categories
        count = 0
        for slug, names in slug_names.items():
            try:
                cursor = conn.execute("""
                    INSERT INTO dua_categories (category_key, name, description)
                    VALUES (?, ?, ?)
                """, (slug, json.dumps(names, ensure_ascii=False), names.get('en', '')))
                category_map[slug] = cursor.lastrowid
                count += 1
            except sqlite3.IntegrityError:
                cursor = conn.execute("SELECT id FROM dua_categories WHERE category_key = ?", (slug,))
                row = cursor.fetchone()
                if row:
                    category_map[slug] = row[0]
                    
        conn.commit()
        log(f"  Migrated {count} dua categories")
    
    # 2. Migrate Duas
    dhikr_dir = base_dir / "dua-dhikr"
    if not dhikr_dir.exists():
        return
        
    dua_count = 0
    for category_path in dhikr_dir.iterdir():
        if not category_path.is_dir():
            continue
            
        slug = category_path.name
        category_id = category_map.get(slug)
        
        # If category missing from json but exists as folder, create it
        if not category_id:
            try:
                cursor = conn.execute("""
                    INSERT INTO dua_categories (category_key, name, description)
                    VALUES (?, ?, ?)
                """, (slug, json.dumps({'en': slug.replace('-', ' ').title()}), slug.replace('-', ' ').title()))
                category_id = cursor.lastrowid
                category_map[slug] = category_id
            except Exception:
                 pass
            
        if not category_id:
            continue

        # Process language files
        for lang_file in category_path.glob("*.json"):
            lang = lang_file.stem # 'en', 'mm', 'id'
            
            try:
                with open(lang_file, 'r', encoding='utf-8') as f:
                    duas = json.load(f)
                    
                if isinstance(duas, list):
                    for dua in duas:
                        conn.execute("""
                            INSERT INTO duas (
                                category_id, language, title, arabic_text, 
                                transliteration, translation, reference, benefits
                            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                        """, (
                            category_id,
                            lang,
                            dua.get('title', ''),
                            dua.get('arabic', ''),
                            dua.get('latin', ''),
                            dua.get('translation', ''),
                            dua.get('source', ''),
                            dua.get('fawaid', '') or dua.get('benefits', '')
                        ))
                        dua_count += 1
            except Exception as e:
                log(f"    Error reading {lang_file}: {e}")
                
    conn.commit()
    log(f"  Migrated {dua_count} duas in {len(category_map)} categories")


def migrate_indopak_glyphs(conn: sqlite3.Connection):
    """Migrate IndoPak Nastaleeq glyphs from external DB"""
    db_path = ASSETS_DIR / "quran_data" / "quran_scripts" / "indopak-nastaleeq.db"
    
    if not db_path.exists():
        db_path = ARCHIVE_DIR / "quran_data" / "quran_scripts" / "indopak-nastaleeq.db"
    
    if not db_path.exists():
        log("IndoPak Nastaleeq DB not found in assets or archive, skipping glyphs...")
        return
    
    log(f"Migrating IndoPak Nastaleeq glyphs from {db_path}...")
    src_conn = sqlite3.connect(str(db_path))
    src_cursor = src_conn.cursor()
    
    try:
        # Check table structure
        src_cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
        tables = [r[0] for r in src_cursor.fetchall()]
        
        if 'glyphs' in tables:
            src_cursor.execute("SELECT * FROM glyphs")
            count = 0
            for row in src_cursor.fetchall():
                conn.execute("""
                    INSERT INTO indopak_glyphs (id, location, surah, ayah, word, text_tajweed)
                    VALUES (?, ?, ?, ?, ?, ?)
                """, row[:6] if len(row) >= 6 else (row + (None,) * (6 - len(row))))
                count += 1
            conn.commit()
            log(f"  Migrated {count} IndoPak glyphs")
    except Exception as e:
        log(f"  Error migrating IndoPak glyphs: {e}")
    finally:
        src_conn.close()



def migrate_indopak_words(conn: sqlite3.Connection):
    """Migrate IndoPak words from indopak-nastaleeq.db"""
    db_path = get_asset_file("quran_data/quran_scripts/indopak-nastaleeq.db")
    
    log(f"Checking IndoPak path: {db_path} ({db_path.exists() if db_path else 'Not found'})")
    
    if not db_path:
        log("[ERROR] IndoPak Nastaleeq DB not found in assets or archive, skipping words...")
        return
    
    log(f"Migrating IndoPak words from {db_path}...")
    src_conn = sqlite3.connect(str(db_path))
    src_cursor = src_conn.cursor()
    
    try:
        src_cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
        tables = [r[0] for r in src_cursor.fetchall()]
        log(f"  Source tables: {tables}")
        
        if 'words' in tables:
            src_cursor.execute("SELECT * FROM words")
            count = 0
            for row in src_cursor.fetchall():
                # Schema: id, location, sura, ayah, word, text, text_tajweed
                # Map by index based on inspection:
                # 0: id, 1: loc, 2: sura, 3: ayah, 4: word, 5: text, 6: tajweed
                conn.execute("""
                    INSERT INTO indopak_words (id, surah, ayah, word, text, char_type, text_tajweed)
                    VALUES (?, ?, ?, ?, ?, ?, ?)
                """, (
                    row[0],  # id
                    row[2],  # surah
                    row[3],  # ayah
                    row[4],  # word
                    row[5],  # text
                    None,    # char_type
                    row[6] if len(row) > 6 else None # text_tajweed
                ))
                count += 1
            conn.commit()
            log(f"  Migrated {count} IndoPak words")
    except Exception as e:
        log(f"  Error migrating IndoPak words: {e}")
    finally:
        src_conn.close()


def migrate_qpc_glyphs(conn: sqlite3.Connection):
    """Migrate QPC v4 glyphs from qpc-v4.db"""
    db_path = ASSETS_DIR / "quran_data" / "quran_scripts" / "qpc-v4.db"
    if not db_path.exists():
        log("QPC v4 DB not found, skipping...")
        return
    
    log("Migrating QPC v4 glyphs...")
    src_conn = sqlite3.connect(str(db_path))
    src_cursor = src_conn.cursor()
    
    try:
        src_cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
        tables = [r[0] for r in src_cursor.fetchall()]
        
        if 'glyphs' in tables:
            src_cursor.execute("SELECT * FROM glyphs")
            count = 0
            for row in src_cursor.fetchall():
                conn.execute("""
                    INSERT INTO qpc_glyphs (id, surah, ayah, word, page, line, text, glyph_code)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                """, (
                    row[0] if len(row) > 0 else None,
                    row[1] if len(row) > 1 else None,
                    row[2] if len(row) > 2 else None,
                    row[3] if len(row) > 3 else None,
                    row[4] if len(row) > 4 else None,
                    row[5] if len(row) > 5 else None,
                    row[6] if len(row) > 6 else None,
                    row[7] if len(row) > 7 else None,
                ))
                count += 1
            conn.commit()
            log(f"  Migrated {count} QPC glyphs")
    except Exception as e:
        log(f"  Error migrating QPC glyphs: {e}")
    finally:
        src_conn.close()

def migrate_mashaf_layout(conn: sqlite3.Connection):
    """Migrate Mashaf layout from qudratullah-indopak-15-lines.db"""
    db_path = get_asset_file("quran_data/mushaf_layout_data/qudratullah-indopak-15-lines.db")
    
    if not db_path:
        log("Mashaf layout DB not found, skipping...")
        return
    
    log(f"Migrating Mashaf layout from {db_path}...")
    src_conn = sqlite3.connect(str(db_path))
    src_cursor = src_conn.cursor()
    
    try:
        src_cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
        tables = [r[0] for r in src_cursor.fetchall()]
        
        if 'pages' in tables:
            src_cursor.execute("SELECT * FROM pages")
            rows = src_cursor.fetchall()
            src_cursor.execute("PRAGMA table_info(pages)")
            cols = [r[1] for r in src_cursor.fetchall()]
            
            count = 0
            for row in rows:
                row_dict = dict(zip(cols, row))
                
                # Normalize empty strings to None
                for k, v in row_dict.items():
                    if v == "":
                        row_dict[k] = None
                
                # Resolve surah/ayah from first_word_id
                surah = row_dict.get('surah_number')
                ayah = None
                fwid = row_dict.get('first_word_id')
                
                if not surah and fwid:
                    # Look up in already migrated indopak_words table
                    cursor = conn.execute("SELECT surah, ayah FROM indopak_words WHERE id = ?", (fwid,))
                    res = cursor.fetchone()
                    if res:
                        surah, ayah = res
                
                conn.execute("""
                    INSERT INTO mashaf_pages (page_number, surah, ayah, line, data_json)
                    VALUES (?, ?, ?, ?, ?)
                """, (
                    row_dict.get('page_number'),
                    surah,
                    ayah,
                    row_dict.get('line_number'),
                    json.dumps(row_dict, ensure_ascii=False),
                ))
                count += 1
            conn.commit()
            log(f"  Migrated {count} mashaf layout entries")
    except Exception as e:
        log(f"  Error migrating mashaf layout: {e}")
    finally:
        src_conn.close()

def build_fts_indexes(conn: sqlite3.Connection):
    """Build Full-Text Search indexes"""
    log("Building FTS indexes...")
    
    conn.execute("""
        INSERT INTO verses_fts(verses_fts) VALUES('rebuild')
    """)
    
    conn.execute("""
        INSERT INTO translations_fts(translations_fts) VALUES('rebuild')
    """)
    
    conn.commit()
    log("  FTS indexes built")

def record_migration(conn: sqlite3.Connection, source_files: List[str]):
    """Record migration metadata"""
    from datetime import datetime
    
    conn.execute("""
        INSERT INTO _migration_info (id, version, created_at, source_files)
        VALUES (1, 1, ?, ?)
    """, (datetime.now().isoformat(), json.dumps(source_files)))
    conn.commit()

def print_statistics(conn: sqlite3.Connection):
    """Print database statistics"""
    log("\n" + "="*50)
    log("DATABASE STATISTICS")
    log("="*50)
    
    tables = [
        ("surahs", "Surahs"),
        ("verses", "Verses"),
        ("translations", "Translations"),
        ("quran_ayah_metadata", "Ayah Metadata"),
        ("tafseer", "Tafseer"),
        ("hadith_books", "Hadith Books"),
        ("hadith_chapters", "Hadith Chapters"),
        ("hadiths", "Hadiths"),
        ("sunnah_chapters", "Sunnah Chapters"),
        ("sunnah_items", "Sunnah Items"),
        ("allah_names", "99 Names"),
        ("dua_categories", "Dua Categories"),
        ("duas", "Duas"),
        ("munajat", "Munajat"),
    ]
    
    for table, name in tables:
        try:
            cursor = conn.execute(f"SELECT COUNT(*) FROM {table}")
            count = cursor.fetchone()[0]
            log(f"  {name:.<30} {count:>8} rows")
        except:
            pass
    
    # Database file size
    db_size = OUTPUT_DB.stat().st_size / (1024 * 1024)
    log(f"\n  Database Size: {db_size:.2f} MB")
    log("="*50)

def main():
    """Main migration function"""
    log("Starting OasisMM Database Migration")
    log(f"Output: {OUTPUT_DB}")
    log("")
    
    # Create connection
    conn = create_connection()
    
    try:
        # Create schema
        create_schema(conn)
        
        # Run migrations
        migrate_quran_simple(conn)
        migrate_tajweed(conn)
        migrate_translations(conn)
        migrate_quran_metadata(conn)
        migrate_surah_info(conn)
        migrate_hadith(conn)
        migrate_sunnah(conn)
        migrate_99_names(conn)
        migrate_dua_dhikr(conn)
        migrate_munajat(conn)
        # migrate_tafseer_ibn_kathir_en(conn)  # Temporarily disabled due to crash/hang
        # migrate_tafseer_ibn_kathir_mm(conn)  # Temporarily disabled (slow)
        # migrate_surah_info_additional(conn) # Disabled to ensure IndoPak runs
        migrate_indopak_glyphs(conn)
        migrate_indopak_words(conn)
        migrate_qpc_glyphs(conn)
        migrate_mashaf_layout(conn)
        
        # Build FTS indexes
        build_fts_indexes(conn)
        
        # Record migration
        source_files = list(str(f) for f in ASSETS_DIR.rglob("*.json"))
        source_files.extend(str(f) for f in ASSETS_DIR.rglob("*.txt"))
        record_migration(conn, source_files)
        
        # Print statistics
        print_statistics(conn)
        
        log("\n✅ Migration completed successfully!")
        log(f"Database created at: {OUTPUT_DB}")
        
    except Exception as e:
        log(f"\n❌ Migration failed: {e}")
        raise
    finally:
        conn.close()

if __name__ == "__main__":
    main()
