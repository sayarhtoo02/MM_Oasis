import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'tajweed_rule.dart';

class TajweedDataProvider {
  static final TajweedDataProvider _instance = TajweedDataProvider._internal();
  factory TajweedDataProvider() => _instance;
  TajweedDataProvider._internal();

  Map<String, String>? _tajweedMap;
  bool _isLoaded = false;

  Future<void> load() async {
    if (_isLoaded) return;

    try {
      debugPrint('Loading Tajweed JSON data...');
      final jsonString = await rootBundle.loadString(
        'assets/quran_data/quran_tajweed_indopak.json',
      );
      final List<dynamic> jsonData = json.decode(jsonString);

      _tajweedMap = {};
      for (final item in jsonData) {
        if (item is Map<String, dynamic>) {
          // Key format: surah:ayah:word
          final key = '${item['surah']}:${item['ayah']}:${item['word']}';
          _tajweedMap![key] = item['text_tajweed_indopak'] ?? '';
        }
      }

      _isLoaded = true;
      debugPrint('Loaded ${_tajweedMap?.length} Tajweed words.');
    } catch (e) {
      debugPrint('Error loading Tajweed JSON: $e');
      _tajweedMap = {}; // Empty map on error to prevent nulls
    }
  }

  // Mapping from JSON XML-like tags to TajweedRule
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

  // Import html parser
  // (Add this to imports at top of file: import 'package:html/parser.dart' as html_parser; import 'package:html/dom.dart' as dom;)

  String _parseAndSerialize(String tajweedText, String originalText) {
    // Use full parse to ensure custom tags like <rule> are parsed correctly (usually land in body)
    final document = html_parser.parse(tajweedText);
    final nodes = document.body?.nodes ?? [];

    final List<String> segments = [];
    for (final node in nodes) {
      _traverseNodes(node, segments, TajweedRule.none);
    }

    // If parsing produced nothing (empty string?), fallback to original text
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
