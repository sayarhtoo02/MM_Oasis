import 'dart:convert';
import 'dart:io';

void main() async {
  final file = File('assets/quran_data/quran_tajweed_indopak.json');
  final jsonString = await file.readAsString();
  final List<dynamic> data = jsonDecode(jsonString);

  // Find Al-Hamdu (Surah 1, Ayah 2, Word 1)
  final wordData = data.firstWhere(
    (w) => w['surah'] == 1 && w['ayah'] == 2 && w['word'] == 1,
  );

  String uthmani = wordData['text_uthmani'];
  String indopak = wordData['text_indopak'];

  print('Word: Al-Hamdu');
  print('Uthmani: $uthmani');
  print(
    'Uthmani Code Units: ${uthmani.runes.map((r) => r.toRadixString(16)).toList()}',
  );

  String tajweedIndopak = wordData['text_tajweed_indopak'];
  print('Tajweed Indopak: $tajweedIndopak');
  print(
    'Tajweed Indopak Code Units: ${tajweedIndopak.runes.map((r) => r.toRadixString(16)).toList()}',
  );

  print('Indopak: $indopak');
  print(
    'Indopak Code Units: ${indopak.runes.map((r) => r.toRadixString(16)).toList()}',
  );

  // Check specifically for Sukun chars
  final sukun = 0x0652;
  final headOfKhah = 0x06E1;
  final roundedZero = 0x06DF;

  print('\nAnalysis:');
  if (uthmani.runes.contains(sukun)) {
    print('Uthmani contains standard SUKUN (0652)');
  }
  if (uthmani.runes.contains(headOfKhah)) {
    print('Uthmani contains HEAD OF KHAH (06E1)');
  }

  if (indopak.runes.contains(sukun)) {
    print('Indopak contains standard SUKUN (0652)');
  }
  if (indopak.runes.contains(headOfKhah)) {
    print('Indopak contains HEAD OF KHAH (06E1)');
  }

  if (tajweedIndopak.runes.contains(sukun)) {
    print('Tajweed Indopak contains BAD Uthmani SUKUN (0652)');
  }
  if (tajweedIndopak.runes.contains(headOfKhah)) {
    print('Tajweed Indopak contains Correct Indopak HEAD OF KHAH (06E1)');
  }

  // Scan entire file for 0652 in text_tajweed_indopak
  int badCount = 0;
  for (var w in data) {
    String t = w['text_tajweed_indopak'];
    if (t.runes.contains(0x0652)) {
      badCount++;
    }
  }
  print('Total words with Uthmani Sukun (0652) in Indopak rules: $badCount');
}
