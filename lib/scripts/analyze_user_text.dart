void main() {
  const text = "وَاغْفِرْ";
  print("Analyzing text: $text");
  print("Length: ${text.length}");
  for (var i = 0; i < text.runes.length; i++) {
    var char = String.fromCharCode(text.runes.elementAt(i));
    var hex = text.runes.elementAt(i).toRadixString(16).padLeft(4, '0');
    print("Char: $char | Hex: \\u$hex");
  }
}
