
import sqlite3
from pathlib import Path
import sys


def inspect_db():
    p = Path('data_archive/quran_data/quran_scripts/indopak-nastaleeq.db').absolute()
    with open('inspect_clean.txt', 'w', encoding='utf-8') as f:
        f.write(f"Checking DB at: {p}\n")
        if not p.exists():
            f.write("  File not found!\n")
            return

        try:
            conn = sqlite3.connect(str(p))
            c = conn.cursor()
            
            # Get tables
            c.execute("SELECT name FROM sqlite_master WHERE type='table'")
            tables = [r[0] for r in c.fetchall()]
            f.write(f"Tables: {tables}\n")
            
            for table in tables:
                f.write(f"\nSchema for table '{table}':\n")
                c.execute(f"PRAGMA table_info({table})")
                columns = c.fetchall()
                for col in columns:
                    f.write(f"  {col[1]} ({col[2]})\n")
                
                c.execute(f"SELECT COUNT(*) FROM {table}")
                count = c.fetchone()[0]
                f.write(f"  Row count: {count}\n")
                
                # Print sample row
                if count > 0:
                    c.execute(f"SELECT * FROM {table} LIMIT 1")
                    row = c.fetchone()
                    f.write(f"  Sample row: {row}\n")

        except Exception as e:
            f.write(f"Error: {e}\n")


if __name__ == "__main__":
    inspect_db()
