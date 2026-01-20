import json
import os
import sys

def format_json_file(input_file, output_file=None, indent=4):
    """
    Format a single-line JSON file into a nicely indented format.
    
    Args:
        input_file (str): Path to the input JSON file
        output_file (str): Path to the output JSON file (optional, defaults to overwriting input)
        indent (int): Number of spaces for indentation (default: 4)
    """
    try:
        # Read the JSON file
        print(f"Reading {input_file}...")
        with open(input_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        # Determine output file
        if output_file is None:
            output_file = input_file
        
        # Write formatted JSON
        print(f"Writing formatted JSON to {output_file}...")
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=indent)
        
        print(f"✓ Successfully formatted {input_file}")
        return True
        
    except json.JSONDecodeError as e:
        print(f"✗ Error: Invalid JSON in {input_file}")
        print(f"  {str(e)}")
        return False
    except FileNotFoundError:
        print(f"✗ Error: File not found - {input_file}")
        return False
    except Exception as e:
        print(f"✗ Error formatting {input_file}: {str(e)}")
        return False

def format_directory(directory, pattern="*.json", indent=4):
    """
    Format all JSON files in a directory.
    
    Args:
        directory (str): Path to the directory
        pattern (str): File pattern to match (default: "*.json")
        indent (int): Number of spaces for indentation (default: 4)
    """
    import glob
    
    json_files = glob.glob(os.path.join(directory, pattern))
    
    if not json_files:
        print(f"No JSON files found in {directory}")
        return
    
    print(f"Found {len(json_files)} JSON file(s) to format\n")
    
    success_count = 0
    for json_file in json_files:
        if format_json_file(json_file, indent=indent):
            success_count += 1
        print()
    
    print(f"Summary: {success_count}/{len(json_files)} files formatted successfully")

def main():
    if len(sys.argv) < 2:
        print("JSON Formatter")
        print("=" * 50)
        print("\nUsage:")
        print("  python format_json.py <file_or_directory> [indent]")
        print("\nExamples:")
        print("  python format_json.py my-abudawud.json")
        print("  python format_json.py my-abudawud.json 2")
        print("  python format_json.py ./db/by_book/the_9_books/")
        print("  python format_json.py ./db/by_book/the_9_books/ 4")
        return
    
    path = sys.argv[1]
    indent = int(sys.argv[2]) if len(sys.argv) > 2 else 4
    
    if os.path.isfile(path):
        # Format single file
        format_json_file(path, indent=indent)
    elif os.path.isdir(path):
        # Format all JSON files in directory
        format_directory(path, indent=indent)
    else:
        print(f"✗ Error: '{path}' is not a valid file or directory")

if __name__ == "__main__":
    main()
