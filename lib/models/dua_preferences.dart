import 'package:munajat_e_maqbool_app/models/dua_model.dart';

class DuaPreferences {
  final Dua? lastReadDua;
  final List<Dua> favoriteDuas;
  final Map<int, String> manzilProgress; // New: Manzil number to last read Dua ID (Dua ID is String)

  DuaPreferences({
    this.lastReadDua,
    required this.favoriteDuas,
    required this.manzilProgress, // Initialize new field
  });

  DuaPreferences copyWith({
    Dua? lastReadDua,
    List<Dua>? favoriteDuas,
    Map<int, String>? manzilProgress, // Add to copyWith
  }) {
    return DuaPreferences(
      lastReadDua: lastReadDua ?? this.lastReadDua,
      favoriteDuas: favoriteDuas ?? this.favoriteDuas,
      manzilProgress: manzilProgress ?? this.manzilProgress, // Copy new field
    );
  }

  Map<String, dynamic> toJson() => {
        'lastReadDua': lastReadDua?.toJson(),
        'favoriteDuas': favoriteDuas.map((dua) => dua.toJson()).toList(),
        'manzilProgress': manzilProgress, // Add to toJson
      };

  factory DuaPreferences.fromJson(Map<String, dynamic> json) => DuaPreferences(
        lastReadDua: json['lastReadDua'] != null ? Dua.fromJson(json['lastReadDua']) : null,
        favoriteDuas: (json['favoriteDuas'] as List<dynamic>?)
                ?.map((item) => Dua.fromJson(item as Map<String, dynamic>))
                .toList() ??
            [],
        manzilProgress: (json['manzilProgress'] as Map<String, dynamic>?)
                ?.map((key, value) => MapEntry(int.parse(key), value as String)) ??
            {}, // Parse new field as String
      );

  static DuaPreferences initial() => DuaPreferences(
        lastReadDua: null,
        favoriteDuas: [],
        manzilProgress: {}, // Initialize empty map
      );
}
