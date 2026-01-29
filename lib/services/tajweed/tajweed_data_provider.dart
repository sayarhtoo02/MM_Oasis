import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'tajweed_rule.dart';
import '../database/oasismm_database.dart';

class TajweedDataProvider {
  static final TajweedDataProvider _instance = TajweedDataProvider._internal();
  factory TajweedDataProvider() => _instance;
  TajweedDataProvider._internal();

  Map<String, String>? _tajweedMap;
  bool _isLoaded = false;
  bool _isLoading = false;

  Future<void> load() async {
    if (_isLoaded || _isLoading) return;
    _isLoading = true;

    try {
      debugPrint('Loading Tajweed data from database...');

      // Get all indopak words with tajweed data
      final db = await OasisMMDatabase.database;
      final rows = await db.query(
        'indopak_words',
        columns: ['surah', 'ayah', 'word', 'text_tajweed'],
        where: 'text_tajweed IS NOT NULL AND text_tajweed != ""',
      );

      _tajweedMap = {};
      for (final row in rows) {
        final surah = row['surah'];
        final ayah = row['ayah'];
        final word = row['word'];
        final textTajweed = row['text_tajweed'] as String?;

        if (surah != null &&
            ayah != null &&
            word != null &&
            textTajweed != null) {
          final key = '$surah:$ayah:$word';
          _tajweedMap![key] = textTajweed;
        }
      }

      _isLoaded = true;
      _isLoading = false;
      debugPrint(
        'Loaded ${_tajweedMap?.length ?? 0} Tajweed words from database.',
      );
    } catch (e) {
      debugPrint('Error loading Tajweed data: $e');
      _tajweedMap = {};
      _isLoading = false;
    }
  }

  // Mapping from XML-like tags to TajweedRule
  static final Map<String, TajweedRule> ruleMapping = {
    'ghunnah': TajweedRule.ghunna,
    'idgham_ghunnah': TajweedRule.idghamWithGhunna,
    'idgham_wo_ghunnah': TajweedRule.idghamWithoutGhunna,
    'ikhafa': TajweedRule.ikhfaa,
    'ikhafa_shafawi': TajweedRule.ikhfaa,
    'iqlab': TajweedRule.iqlab,
    'qalaqah': TajweedRule.qalqala,
    'ham_wasl': TajweedRule.hamzatulWasli,
    'laam_shamsiyah': TajweedRule.lamShamsiyyah,
    'slnt': TajweedRule.silent,
    'madda_normal': TajweedRule.prolonging,
    'madda_permissible': TajweedRule.prolonging,
    'madda_necessary': TajweedRule.prolonging,
    'madda_obligatory_monfasel': TajweedRule.prolonging,
    'madda_obligatory_mottasel': TajweedRule.prolonging,
  };

  String? getTajweed(int surah, int ayah, int word, String originalText) {
    if (!_isLoaded) {
      return null;
    }

    final key = '$surah:$ayah:$word';
    final rawTajweed = _tajweedMap?[key];
    if (rawTajweed == null || rawTajweed.isEmpty) {
      return '$originalText:${TajweedRule.none.index}';
    }

    return _parseAndSerialize(rawTajweed, originalText);
  }

  String _parseAndSerialize(String tajweedText, String originalText) {
    final document = html_parser.parse(tajweedText);
    final nodes = document.body?.nodes ?? [];

    final List<String> segments = [];
    for (final node in nodes) {
      _traverseNodes(node, segments, TajweedRule.none);
    }

    if (segments.isEmpty) {
      return '$originalText:${TajweedRule.none.index}';
    }

    return segments.join('|');
  }

  void _traverseNodes(
    dom.Node node,
    List<String> segments,
    TajweedRule parentRule,
  ) {
    if (node.nodeType == dom.Node.TEXT_NODE) {
      final text = node.text ?? '';
      if (text.isNotEmpty) {
        segments.add('$text:${parentRule.index}');
      }
    } else if (node.nodeType == dom.Node.ELEMENT_NODE) {
      final element = node as dom.Element;
      TajweedRule currentRule = parentRule;

      if (element.localName == 'rule') {
        final className = element.attributes['class'];
        if (className != null) {
          final mappedRule = ruleMapping[className];
          if (mappedRule != null) {
            currentRule = mappedRule;
          }
        }
      }

      for (final child in node.nodes) {
        _traverseNodes(child, segments, currentRule);
      }
    }
  }
}
