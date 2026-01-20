import 'dart:convert';
import 'dart:io';

void main() {
  final file = File('assets/quran_data/quran_tajweed_indopak.json');
  try {
    final content = file.readAsStringSync();
    final data = json.decode(content);
    print("JSON Valid. Loaded ${data.length} records.");
  } catch (e) {
    print("JSON INVALID: $e");
  }
}
