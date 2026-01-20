#!/usr/bin/env python3
"""Explore the cpfair/quran-tajweed JSON data properly"""

import json
from collections import Counter

with open('temp_quran_tajweed/output/tajweed.hafs.uthmani-pause-sajdah.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

print(f"Total entries: {len(data)}")
print(f"\nFirst entry structure:")
print(json.dumps(data[0], indent=2, ensure_ascii=False))

# Count all rules
rule_counter = Counter()
for entry in data:
    for ann in entry.get('annotations', []):
        rule_counter[ann['rule']] += 1

print(f"\n=== ALL TAJWEED RULES ({len(rule_counter)}) ===")
for rule, count in rule_counter.most_common():
    print(f"  {rule}: {count}")

# Show sample annotations for Surah 2
print("\n=== Sample: Surah 2, Ayah 1-5 ===")
for entry in data:
    if entry['surah'] == 2 and entry['ayah'] <= 5:
        print(f"\n{entry['surah']}:{entry['ayah']}")
        for ann in entry['annotations']:
            print(f"  {ann['rule']}: chars {ann['start']}-{ann['end']}")
