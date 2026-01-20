class BookInfo {
  final String title;
  final String author;
  final String publisher;
  final String language;
  final String edition;
  final ContactInfo contact;

  BookInfo({
    required this.title,
    required this.author,
    required this.publisher,
    required this.language,
    required this.edition,
    required this.contact,
  });

  factory BookInfo.fromJson(Map<String, dynamic> json) {
    return BookInfo(
      title: json['title'] as String,
      author: json['author'] as String,
      publisher: json['publisher'] as String,
      language: json['language'] as String,
      edition: json['edition'] as String,
      contact: ContactInfo.fromJson(json['contact'] as Map<String, dynamic>),
    );
  }
}

class ContactInfo {
  final String phone;
  final String mobile;
  final String email;

  ContactInfo({required this.phone, required this.mobile, required this.email});

  factory ContactInfo.fromJson(Map<String, dynamic> json) {
    return ContactInfo(
      phone: json['phone'] as String,
      mobile: json['mobile'] as String,
      email: json['email'] as String,
    );
  }
}
