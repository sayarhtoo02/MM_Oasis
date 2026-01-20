import '../services/tajweed/tajweed.dart';

void main() {
  // Surah Fatiha Ayah 2 (Al-Hamdu...) Indopak script
  // Note: Indopak uses standard Arabic unicode but different font/glyphs often.
  // The provided text in JSON: "اَلۡحَمۡدُ لِلّٰهِ رَبِّ الۡعٰلَمِيۡنَۙ"
  const text = "اَلۡحَمۡدُ لِلّٰهِ رَبِّ الۡعٰلَمِيۡنَۙ";

  print("Testing text: $text");

  final tokens = Tajweed.tokenize(text, 1, 2);

  for (var t in tokens) {
    print("'${t.text}' -> ${t.rule}");
  }
}
