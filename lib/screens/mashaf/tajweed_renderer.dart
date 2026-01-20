import 'package:flutter/material.dart';
import '../../services/tajweed/tajweed_rule.dart';
import '../../services/tajweed/tajweed_colors.dart';

/// Utility class for rendering Tajweed-colored text from pre-processed data
class TajweedRenderer {
  /// Parse pre-processed Tajweed data and return styled TextSpan
  static TextSpan buildTextSpan(
    BuildContext context,
    String text,
    TextStyle style, {
    String? tajweedData,
  }) {
    // If no Tajweed data, return plain text
    if (tajweedData == null || tajweedData.isEmpty) {
      return TextSpan(text: text, style: style);
    }

    // Parse the serialized format: "text:rule|text:rule|..."
    final segments = tajweedData.split('|');
    final spans = <TextSpan>[];

    for (final segment in segments) {
      if (segment.isEmpty) continue;

      final colonIndex = segment.lastIndexOf(':');
      if (colonIndex == -1) continue;

      // Unescape text
      var segmentText = segment.substring(0, colonIndex);
      segmentText = segmentText
          .replaceAll('&#124;', '|')
          .replaceAll('&#58;', ':');

      final ruleIndexStr = segment.substring(colonIndex + 1);
      final ruleIndex = int.tryParse(ruleIndexStr) ?? TajweedRule.none.index;

      // Map rule index to color using TajweedRule enum
      Color? color;
      if (ruleIndex >= 0 && ruleIndex < TajweedRule.values.length) {
        color = TajweedRule.values[ruleIndex].color(context);
      }

      spans.add(
        TextSpan(
          text: segmentText,
          style: TextStyle(
            color: color ?? style.color,
            fontFamily: style.fontFamily,
            fontSize: style.fontSize,
            height: style.height,
          ),
        ),
      );
    }

    if (spans.isEmpty) {
      return TextSpan(text: text, style: style);
    }

    return TextSpan(style: style, children: spans);
  }

  /// Parse pre-processed Tajweed data and return styled RichText
  static Widget buildRichText(
    BuildContext context,
    String text,
    TextStyle style, {
    String? tajweedData,
  }) {
    return RichText(
      text: buildTextSpan(context, text, style, tajweedData: tajweedData),
      textAlign: TextAlign.center,
    );
  }
}
