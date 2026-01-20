import 'package:home_widget/home_widget.dart';
import '../models/dua_model.dart';
import '../models/widget_settings.dart';

class WidgetService {
  static const String _homeScreenWidgetName = 'HomeWidgetGlanceReceiver';

  static Future<void> initialize() async {
    try {
      await HomeWidget.setAppGroupId('group.munajat_e_maqbool');
    } catch (e) {
      // Ignore error
    }
  }

  static Future<void> updateLockScreenWidget({
    required Dua dua,
    required WidgetSettings settings,
  }) async {
    if (!settings.isLockScreenWidgetEnabled) return;
  }

  static Future<void> updateHomeScreenWidget({
    required Dua dua,
    required WidgetSettings settings,
  }) async {
    if (!settings.isHomeScreenWidgetEnabled) return;

    try {
      final arabicText = _truncateText(dua.arabicText, 120);
      final translation = _truncateText(
        dua.translations.getTranslationText(settings.preferredLanguage),
        150,
      );
      final progress = 'Day ${dua.manzilNumber}';

      await HomeWidget.saveWidgetData<String>('widget_arabic_text', arabicText);
      await HomeWidget.saveWidgetData<String>(
        'widget_translation',
        translation,
      );
      await HomeWidget.saveWidgetData<String>('widget_progress', progress);

      await HomeWidget.updateWidget(
        androidName: _homeScreenWidgetName,
        iOSName: _homeScreenWidgetName,
      );
    } catch (e) {
      // Ignore error
    }
  }

  static String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  static Future<bool> isWidgetSupported() async {
    try {
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> requestPinWidget() async {
    try {
      await HomeWidget.requestPinWidget(androidName: _homeScreenWidgetName);
      return true;
    } catch (e) {
      return false;
    }
  }
}
