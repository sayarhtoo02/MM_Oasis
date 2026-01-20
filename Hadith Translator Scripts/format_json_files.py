import json
import os

def format_json_files(input_dir, output_dir):
    for root, dirs, files in os.walk(input_dir):
        # Create corresponding subdirectory in output_dir
        relative_path = os.path.relpath(root, input_dir)
        target_dir = os.path.join(output_dir, relative_path)
        
        if not os.path.exists(target_dir):
            os.makedirs(target_dir)
            
        for file in files:
            if file.endswith(".json"):
                input_path = os.path.join(root, file)
                output_path = os.path.join(target_dir, file)
                
                print(f"Formatting {input_path}...")
                
                try:
                    with open(input_path, 'r', encoding='utf-8') as f:
                        data = json.load(f)
                    
                    with open(output_path, 'w', encoding='utf-8') as f:
                        json.dump(data, f, indent=4, ensure_ascii=False)
                        
                except Exception as e:
                    print(f"Error formatting {file}: {e}")

if __name__ == "__main__":
    base_dir = os.getcwd()
    input_directory = os.path.join(base_dir, "db")
    output_directory = os.path.join(base_dir, "formatted_db")
    
    print("Starting formatting process...")
    format_json_files(input_directory, output_directory)
    print("Done! Formatted files are in 'formatted_db' folder.")
