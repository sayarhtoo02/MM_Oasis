import 'package:munajat_e_maqbool_app/models/dua_model.dart';

class DuaPreferences {
  final Dua? lastReadDua;
  final List<Dua> favoriteDuas;

  DuaPreferences({
    this.lastReadDua,
    required this.favoriteDuas,
  });

  DuaPreferences copyWith({
    Dua? lastReadDua,
    List<Dua>? favoriteDuas,
  }) {
    return DuaPreferences(
      lastReadDua: lastReadDua ?? this.lastReadDua,
      favoriteDuas: favoriteDuas ?? this.favoriteDuas,
    );
  }

  Map<String, dynamic> toJson() => {
        'lastReadDua': lastReadDua?.toJson(),
        'favoriteDuas': favoriteDuas.map((dua) => dua.toJson()).toList(),
      };

  factory DuaPreferences.fromJson(Map<String, dynamic> json) => DuaPreferences(
        lastReadDua: json['lastReadDua'] != null ? Dua.fromJson(json['lastReadDua']) : null,
        favoriteDuas: (json['favoriteDuas'] as List<dynamic>?)
                ?.map((item) => Dua.fromJson(item as Map<String, dynamic>))
                .toList() ??
            [],
      );

  static DuaPreferences initial() => DuaPreferences(
        lastReadDua: null,
        favoriteDuas: [],
      );
}
