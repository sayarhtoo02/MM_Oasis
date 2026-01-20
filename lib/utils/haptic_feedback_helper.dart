import 'package:flutter/services.dart';

class HapticFeedbackHelper {
  static void lightImpact() {
    HapticFeedback.lightImpact();
  }

  static void mediumImpact() {
    HapticFeedback.mediumImpact();
  }

  static void heavyImpact() {
    HapticFeedback.heavyImpact();
  }

  static void selectionClick() {
    HapticFeedback.selectionClick();
  }

  static void buttonPress() {
    HapticFeedback.lightImpact();
  }

  static void swipeGesture() {
    HapticFeedback.selectionClick();
  }

  static void bookmarkToggle() {
    HapticFeedback.mediumImpact();
  }

  static void navigationChange() {
    HapticFeedback.lightImpact();
  }

  static void success() {
    HapticFeedback.mediumImpact();
  }
}
