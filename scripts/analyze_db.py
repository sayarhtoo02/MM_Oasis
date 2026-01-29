import sqlite3
import os

def analyze_db(db_path):
    if not os.path.exists(db_path):
        print(f"File {db_path} not found.")
        return

    file_size = os.path.getsize(db_path) / (1024 * 1024)
    print(f"Total Database Size: {file_size:.2f} MB")
    print("-" * 50)

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Get row counts
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
    tables = [row[0] for row in cursor.fetchall()]

    stats = []
    for table in tables:
        try:
            cursor.execute(f"SELECT COUNT(*) FROM {table}")
            count = cursor.fetchone()[0]
            
            # Estimate size by summing length of all columns
            cursor.execute(f"PRAGMA table_info({table})")
            columns = [col[1] for col in cursor.fetchall()]
            
            size_query = " + ".join([f"SUM(LENGTH(CAST(COALESCE(\"{col}\", '') AS BLOB)))" for col in columns])
            cursor.execute(f"SELECT {size_query} FROM {table}")
            size_bytes = cursor.fetchone()[0] or 0
            
            stats.append((table, count, size_bytes))
        except Exception as e:
            # print(f"Error reading {table}: {e}")
            stats.append((table, count, 0))

    # Sort by estimated size
    stats.sort(key=lambda x: x[2], reverse=True)

    with open("analyze_results.txt", "w", encoding="utf-8") as f_out:
        f_out.write(f"Total Database Size: {file_size:.2f} MB\n")
        f_out.write("-" * 65 + "\n")
        f_out.write(f"{'Table Name':<30} | {'Count':<10} | {'Est. Size (MB)':<15}\n")
        f_out.write("-" * 65 + "\n")
        for table, count, size_bytes in stats:
            f_out.write(f"{table:<30} | {count:<10} | {size_bytes / (1024*1024):<15.2f}\n")

        f_out.write("\nDetailed breakdown of specific content types:\n")
        
        # Check JSON blob sizes
        blob_tables = [
            ('mashaf_pages', 'data_json'),
            ('munajat', 'data_json'),
            ('sunnah_items', 'references_json')
        ]
        
        for table, col in blob_tables:
            try:
                cursor.execute(f"SELECT SUM(LENGTH({col})) FROM {table}")
                size = cursor.fetchone()[0] or 0
                f_out.write(f"{table} ({col}): {size / 1024:.2f} KB\n")
            except:
                pass

    print("Results written to analyze_results.txt")

    conn.close()

if __name__ == "__main__":
    analyze_db("assets/oasismm.db")
