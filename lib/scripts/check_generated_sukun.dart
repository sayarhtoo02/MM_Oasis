import 'dart:convert';
import 'dart:io';

void main() {
  final file = File('assets/quran_data/quran_tajweed_indopak.json');
  final content = file.readAsStringSync();
  final data = json.decode(content);

  int count0652 = 0;
  int count06E1 = 0;

  for (var item in data) {
    String text = item['text_tajweed_indopak'] ?? '';
    count0652 += RegExp('\u0652').allMatches(text).length;
    count06E1 += RegExp('\u06E1').allMatches(text).length;
  }

  print("Indopak count: $count06E1");
  if (count06E1 == 0) {
    print("VERIFICATION_PASS");
  } else {
    print("VERIFICATION_FAIL");
  }
}
