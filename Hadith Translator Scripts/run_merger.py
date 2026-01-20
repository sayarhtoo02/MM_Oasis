import os
from merger.loaders import SkeletonLoader, BurmeseLoader, get_book_names
from merger.merge_engine import MergeEngine

def main():
    base_dir = os.getcwd()
    skeleton_path = os.path.join(base_dir, 'formatted_db', 'by_book', 'the_9_books')
    burmese_path = os.path.join(base_dir, 'my-hadith')
    output_dir = os.path.join(base_dir, 'merged_dataset')
    log_path = os.path.join(base_dir, 'unmatched_burmese.log')

    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    print("Initializing Loaders...")
    skeleton_loader = SkeletonLoader(skeleton_path)
    burmese_loader = BurmeseLoader(burmese_path)
    
    engine = MergeEngine(skeleton_loader, burmese_loader)
    
    books = get_book_names()
    
    for book in books:
        print(f"\nProcessing {book}...")
        try:
            merged_data = engine.merge_book(book)
            output_file = os.path.join(output_dir, f"{book}.json")
            engine.save_merged_file(merged_data, output_file)
            print(f"Saved merged file to {output_file}")
        except Exception as e:
            print(f"Error processing {book}: {e}")

    print(f"\nWriting unmatched log to {log_path}...")
    engine.write_log(log_path)
    print("Done!")

if __name__ == "__main__":
    main()
