import '../models/allah_name.dart';
import 'database/oasismm_database.dart';

class AllahNamesService {
  static final AllahNamesService _instance = AllahNamesService._internal();
  factory AllahNamesService() => _instance;
  AllahNamesService._internal();

  List<AllahName>? _names;

  Future<List<AllahName>> getNames() async {
    if (_names != null) return _names!;

    final rows = await OasisMMDatabase.getAllahNames();
    _names = rows
        .map(
          (row) => AllahName(
            arabic: row['arabic'] ?? '',
            english: row['english'] ?? '',
            urduMeaning: row['urdu_meaning'] ?? '',
            englishMeaning: row['english_meaning'] ?? '',
            englishExplanation: row['english_explanation'] ?? '',
          ),
        )
        .toList();

    return _names!;
  }

  void clearCache() {
    _names = null;
  }
}
