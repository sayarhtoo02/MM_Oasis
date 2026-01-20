#!/usr/bin/env python3
"""Analyze Tajweed tag types from API data"""

import json
import re
from collections import Counter

with open('quran_tajweed_api.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

print(f"Total words: {len(data)}")

# Find all rule classes
tag_pattern = re.compile(r'class=([a-z_]+)')
rule_counter = Counter()

for word in data:
    tj = word.get('text_tajweed', '')
    if tj:
        matches = tag_pattern.findall(tj)
        rule_counter.update(matches)

print(f"\n=== TAJWEED RULE CLASSES ({len(rule_counter)}) ===")
for rule, count in rule_counter.most_common():
    print(f"  {rule}: {count}")

# Show sample for each rule
print("\n\n=== SAMPLE FOR EACH RULE ===")
seen_rules = set()
for word in data:
    tj = word.get('text_tajweed', '')
    if tj:
        matches = tag_pattern.findall(tj)
        for rule in matches:
            if rule not in seen_rules:
                seen_rules.add(rule)
                print(f"\n{rule}:")
                print(f"  Location: {word['surah']}:{word['ayah']}:{word['word']}")
                print(f"  Uthmani: {word['text_uthmani']}")
                print(f"  Tajweed: {tj}")
                
                if len(seen_rules) >= 20:
                    break
    if len(seen_rules) >= 20:
        break
