"""Database statistics script"""
import sqlite3
from pathlib import Path

DB_PATH = Path(__file__).parent.parent / "assets" / "oasismm.db"

def main():
    conn = sqlite3.connect(str(DB_PATH))
    c = conn.cursor()
    
    tables = [
        ("surahs", "Surahs"),
        ("verses", "Verses"),
        ("translations", "Translations"),
        ("surah_info", "Surah Info"),
        ("quran_sajda", "Sajda Positions"),
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
        ("indopak_glyphs", "IndoPak Glyphs"),
    ]
    
    print("=" * 50)
    print("OASISMM DATABASE STATISTICS")
    print("=" * 50)
    
    for table, name in tables:
        try:
            c.execute(f"SELECT COUNT(*) FROM {table}")
            count = c.fetchone()[0]
            print(f"  {name:.<30} {count:>8} rows")
        except Exception as e:
            print(f"  {name:.<30} ERROR: {e}")
    
    print("=" * 50)
    print(f"Database size: {DB_PATH.stat().st_size / (1024*1024):.2f} MB")
    print("=" * 50)
    
    conn.close()

if __name__ == "__main__":
    main()
