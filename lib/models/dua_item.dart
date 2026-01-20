class DuaItem {
  final String title;
  final String arabic;
  final String latin;
  final String translation;
  final String notes;
  final String fawaid;
  final String source;

  DuaItem({
    required this.title,
    required this.arabic,
    required this.latin,
    required this.translation,
    required this.notes,
    required this.fawaid,
    required this.source,
  });

  factory DuaItem.fromJson(Map<String, dynamic> json) {
    return DuaItem(
      title: json['title']?.toString() ?? '',
      arabic: json['arabic']?.toString() ?? '',
      latin: json['latin']?.toString() ?? '',
      translation: json['translation']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      fawaid: json['fawaid']?.toString() ?? json['benefits']?.toString() ?? '',
      source: json['source']?.toString() ?? '',
    );
  }
}
