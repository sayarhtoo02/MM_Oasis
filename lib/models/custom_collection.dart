import 'package:munajat_e_maqbool_app/models/dua_model.dart';

class CustomCollection {
  final String id;
  final String name;
  final List<String> duaIds;

  CustomCollection({
    required this.id,
    required this.name,
    required this.duaIds,
  });

  CustomCollection copyWith({
    String? id,
    String? name,
    List<String>? duaIds,
  }) {
    return CustomCollection(
      id: id ?? this.id,
      name: name ?? this.name,
      duaIds: duaIds ?? this.duaIds,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'duaIds': duaIds,
      };

  factory CustomCollection.fromJson(Map<String, dynamic> json) => CustomCollection(
        id: json['id'] as String,
        name: json['name'] as String,
        duaIds: (json['duaIds'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      );
}
