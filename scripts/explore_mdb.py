#!/usr/bin/env python3
"""Explore the Quran DB databases"""

import os
import pyodbc

db_folder = 'Quran DB'

# List of MDB files to try
mdb_files = [
    'dbQuran.mdb',
    'dbTafsir.mdb',
    'OnDemand.mdb',
    'dbUser.mdb',
    'dbUpdts.mdb',
]

for mdb_file in mdb_files:
    mdb_path = os.path.abspath(os.path.join(db_folder, mdb_file))
    
    if not os.path.exists(mdb_path):
        continue
    
    print(f"\n{'='*70}")
    print(f"FILE: {mdb_file} ({os.path.getsize(mdb_path):,} bytes)")
    print('='*70)
    
    # Try without password first
    for pwd in ['', 'quran', 'Quran', 'tajweed', '1234']:
        try:
            conn_str = (
                r'DRIVER={Microsoft Access Driver (*.mdb, *.accdb)};'
                f'DBQ={mdb_path};'
                f'PWD={pwd};'
            )
            
            conn = pyodbc.connect(conn_str)
            cursor = conn.cursor()
            
            if pwd:
                print(f"Connected with password: '{pwd}'")
            else:
                print("Connected (no password)")
            
            # Get list of tables
            tables = []
            for table in cursor.tables(tableType='TABLE'):
                if not table.table_name.startswith('MSys'):
                    tables.append(table.table_name)
            
            print(f"Tables ({len(tables)}): {tables[:15]}{'...' if len(tables) > 15 else ''}")
            
            # Explore first few tables
            for table_name in tables[:5]:
                print(f"\n  --- {table_name} ---")
                try:
                    cursor.execute(f"SELECT * FROM [{table_name}] WHERE 1=0")
                    columns = [col[0] for col in cursor.description]
                    print(f"  Columns: {columns}")
                    
                    cursor.execute(f"SELECT COUNT(*) FROM [{table_name}]")
                    count = cursor.fetchone()[0]
                    print(f"  Rows: {count}")
                    
                    if count > 0:
                        cursor.execute(f"SELECT TOP 2 * FROM [{table_name}]")
                        rows = cursor.fetchall()
                        for row in rows:
                            row_str = str(row)
                            if len(row_str) > 150:
                                row_str = row_str[:150] + "..."
                            print(f"    {row_str}")
                except Exception as e:
                    print(f"  Error: {e}")
            
            conn.close()
            break
            
        except pyodbc.Error as e:
            if '1905' in str(e) or 'password' in str(e).lower():
                continue
            else:
                print(f"Error: {e}")
                break
    else:
        print("Password protected - could not open")

print("\n\nDone!")
