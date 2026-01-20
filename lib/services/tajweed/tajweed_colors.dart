import 'package:flutter/material.dart';
import 'tajweed_rule.dart';

extension TajweedRuleColors on TajweedRule {
  Color? color(BuildContext context) {
    bool isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    switch (this) {
      // Core Rules - Visible
      case TajweedRule.ghunna:
        return isDarkTheme ? Colors.orange[300] : Colors.orange[800];
      case TajweedRule.ikhfaa:
        return isDarkTheme ? Colors.red[300] : Colors.red[700];
      case TajweedRule.idghamWithGhunna:
        return isDarkTheme ? Colors.pink[300] : Colors.pink[700];
      case TajweedRule.idghamWithoutGhunna:
        return isDarkTheme ? Colors.blueGrey[300] : Colors.blueGrey[600];
      case TajweedRule.izhar:
        return isDarkTheme ? Colors.teal[300] : Colors.teal[700];
      case TajweedRule.iqlab:
        return isDarkTheme ? Colors.blue[300] : Colors.blue[700];

      // Hidden Rules - Return null (no special coloring)
      case TajweedRule.qalqala:
      case TajweedRule.LAFZATULLAH:
      case TajweedRule.prolonging:
      case TajweedRule.silent:
      case TajweedRule.alefTafreeq:
      case TajweedRule.hamzatulWasli:
      case TajweedRule.lamShamsiyyah:
      case TajweedRule.none:
        return null;
    }
  }
}
