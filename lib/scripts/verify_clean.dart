import 'dart:convert';
import 'dart:io';

void main() async {
  final file = File('assets/quran_data/quran_tajweed_indopak.json');
  final jsonString = await file.readAsString();
  final List<dynamic> data = jsonDecode(jsonString);

  int badCount = 0;
  for (var w in data) {
    String t = w['text_tajweed_indopak'];
    if (t.runes.contains(0x0652)) {
      badCount++;
    }
  }

  if (badCount == 0) {
    print("SUCCESS: 0 words contain Uthmani Sukun (0652).");
  } else {
    print("FAILURE: $badCount words still contain Uthmani Sukun (0652).");
  }
}
