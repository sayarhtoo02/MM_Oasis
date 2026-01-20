import 'package:flutter/material.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html_dom;
import '../services/tafseer_service.dart';
import '../services/tafseer_preferences_service.dart';
import 'dart:math' as math;

class EnhancedTafseerWidget extends StatefulWidget {
  final String ayahKey;
  final String? initialLanguage;
  final Function(String)? onLanguageChanged;

  const EnhancedTafseerWidget({
    super.key,
    required this.ayahKey,
    this.initialLanguage,
    this.onLanguageChanged,
  });

  @override
  State<EnhancedTafseerWidget> createState() => _EnhancedTafseerWidgetState();
}

class _EnhancedTafseerWidgetState extends State<EnhancedTafseerWidget>
    with TickerProviderStateMixin {
  List<TafseerItem> tafseerItems = [];
  bool isLoading = true;
  String currentLanguage = 'my';

  // Reading preferences
  double fontSize = 16.0;
  double lineHeight = 1.8;
  Color backgroundColor = Colors.white;
  Color textColor = Colors.black87;

  late AnimationController _fadeController;
  late AnimationController _slideController;

  @override
  void initState() {
    super.initState();
    currentLanguage = widget.initialLanguage ?? 'my';

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _loadPreferences();
    _loadTafseer();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    fontSize = await TafseerPreferencesService.getFontSize();
    lineHeight = await TafseerPreferencesService.getLineHeight();
    backgroundColor = await TafseerPreferencesService.getBackgroundColor();
    textColor = await TafseerPreferencesService.getTextColor();
    currentLanguage = await TafseerPreferencesService.getLanguage();

    if (mounted) {
      setState(() {});
      widget.onLanguageChanged?.call(currentLanguage);
    }
  }

  Future<void> _loadTafseer() async {
    setState(() => isLoading = true);
    _fadeController.reset();

    try {
      List<TafseerItem> items;
      if (currentLanguage == 'my') {
        items = await TafseerService.getMyanmarTafseer(widget.ayahKey);
      } else {
        items = await TafseerService.getEnglishTafseer(widget.ayahKey);
      }

      setState(() {
        tafseerItems = items;
        isLoading = false;
      });

      _fadeController.forward();
      _slideController.forward();
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _switchLanguage() async {
    final newLanguage = currentLanguage == 'my' ? 'en' : 'my';
    setState(() => currentLanguage = newLanguage);

    await TafseerPreferencesService.setLanguage(newLanguage);
    widget.onLanguageChanged?.call(newLanguage);

    _loadTafseer();
  }

  void _adjustFontSize(double delta) async {
    final newSize = math.max(12.0, math.min(28.0, fontSize + delta));
    setState(() => fontSize = newSize);
    await TafseerPreferencesService.setFontSize(newSize);
  }

  void _adjustLineHeight(double delta) async {
    final newHeight = math.max(1.2, math.min(3.0, lineHeight + delta));
    setState(() => lineHeight = newHeight);
    await TafseerPreferencesService.setLineHeight(newHeight);
  }

  void _applyTheme(String themeName) async {
    await TafseerPreferencesService.applyTheme(themeName);
    await _loadPreferences();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      color: backgroundColor,
      child: Card(
        margin: const EdgeInsets.all(8.0),
        elevation: 6,
        color: backgroundColor,
        shadowColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [_buildEnhancedHeader(), _buildContent()],
        ),
      ),
    );
  }

  Widget _buildEnhancedHeader() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withValues(alpha: 0.1),
            Theme.of(context).primaryColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          // Title and Language Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tafseer Ibn Kathir',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'تفسير ابن كثير',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(
                          context,
                        ).primaryColor.withValues(alpha: 0.7),
                        fontFamily: 'Indopak',
                        letterSpacing: 0,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              _buildLanguageToggle(),
            ],
          ),

          const SizedBox(height: 16),

          // Reading Controls
          _buildReadingControls(),

          const SizedBox(height: 12),

          // Theme Presets
          _buildThemePresets(),
        ],
      ),
    );
  }

  Widget _buildLanguageToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLanguageOption('my', 'မြန်မာ'),
          _buildLanguageOption('en', 'English'),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(String lang, String label) {
    final isSelected = currentLanguage == lang;
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          _switchLanguage();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Theme.of(context).primaryColor,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildReadingControls() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          // Font Size Control
          Row(
            children: [
              Icon(
                Icons.text_fields,
                size: 18,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () => _adjustFontSize(-1),
                      icon: const Icon(Icons.remove, size: 18),
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${fontSize.toInt()}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _adjustFontSize(1),
                      icon: const Icon(Icons.add, size: 18),
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Line Height Control
          Row(
            children: [
              Icon(
                Icons.format_line_spacing,
                size: 18,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () => _adjustLineHeight(-0.1),
                      icon: const Icon(Icons.remove, size: 18),
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        lineHeight.toStringAsFixed(1),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _adjustLineHeight(0.1),
                      icon: const Icon(Icons.add, size: 18),
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemePresets() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: TafseerPreferencesService.readingThemes.entries.map((entry) {
          final theme = entry.value;
          final isSelected =
              backgroundColor.toARGB32() == theme['backgroundColor'];

          return GestureDetector(
            onTap: () => _applyTheme(entry.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Color(theme['backgroundColor']),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey.withValues(alpha: 0.3),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Text(
                theme['name'],
                style: TextStyle(
                  color: Color(theme['textColor']),
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return Container(
        padding: const EdgeInsets.all(40.0),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(color: Theme.of(context).primaryColor),
              const SizedBox(height: 16),
              Text(
                currentLanguage == 'my'
                    ? 'တဖ်စီရ် ရှာနေသည်...'
                    : 'Loading tafseer...',
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.7),
                  fontSize: fontSize - 2,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (tafseerItems.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40.0),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.book_outlined,
                size: 48,
                color: textColor.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 16),
              Text(
                currentLanguage == 'my'
                    ? 'ဤအာယတ်အတွက် တဖ်စီရ် မရှိပါ'
                    : 'No tafseer available for this ayah',
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.7),
                  fontSize: fontSize,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeController,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
            .animate(
              CurvedAnimation(
                parent: _slideController,
                curve: Curves.easeOutCubic,
              ),
            ),
        child: Column(
          children: tafseerItems
              .map((item) => _buildTafseerItem(item))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildTafseerItem(TafseerItem item) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.fromAyah != item.toAyah) _buildAyahRange(item),
          _buildEnhancedHtmlContent(item.text),
        ],
      ),
    );
  }

  Widget _buildAyahRange(TafseerItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withValues(alpha: 0.1),
            Theme.of(context).primaryColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bookmark_outline,
            size: 18,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 8),
          Text(
            currentLanguage == 'my'
                ? 'အာယတ် ${item.fromAyah} - ${item.toAyah}'
                : 'Ayah ${item.fromAyah} - ${item.toAyah}',
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w600,
              fontSize: fontSize - 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedHtmlContent(String htmlContent) {
    final document = html_parser.parse(htmlContent);
    final parts = <Widget>[];

    for (final element in document.body?.children ?? []) {
      final widget = _parseHtmlElement(element);
      if (widget != null) {
        parts.add(widget);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: parts,
    );
  }

  Widget? _parseHtmlElement(html_dom.Element element) {
    final tagName = element.localName?.toLowerCase();
    final className = element.attributes['class'] ?? '';
    final lang = element.attributes['lang'] ?? '';
    final text = element.text.trim();

    if (text.isEmpty) return null;

    // Arabic text styling
    if (lang == 'ar' ||
        className.contains('ar') ||
        RegExp(r'[\u0600-\u06FF]').hasMatch(text)) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border(
            right: BorderSide(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
              width: 4,
            ),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: fontSize + 4,
            height: lineHeight + 0.2,
            fontFamily: 'Indopak',
            letterSpacing: 0,
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.normal,
          ),
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
        ),
      );
    }

    // Heading styles
    if (tagName == 'h1' || tagName == 'h2' || tagName == 'h3') {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 20),
        child: Text(
          text,
          style: TextStyle(
            fontSize:
                fontSize +
                (tagName == 'h1'
                    ? 8
                    : tagName == 'h2'
                    ? 6
                    : 4),
            height: lineHeight - 0.1,
            fontFamily: currentLanguage == 'my' ? 'Myanmar' : null,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
      );
    }

    // Myanmar text with enhanced styling
    if (lang == 'my' ||
        className.contains('my') ||
        RegExp(r'[\u1000-\u109F]').hasMatch(text)) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        child: _buildMyanmarText(text),
      );
    }

    // English or other text
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          height: lineHeight,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildMyanmarText(String text) {
    final parts = <TextSpan>[];
    final regex = RegExp(r'\([^)]*\)|\([^)]*\)');
    final matches = regex.allMatches(text);

    int lastEnd = 0;

    for (final match in matches) {
      // Add text before the match
      if (match.start > lastEnd) {
        final beforeText = text.substring(lastEnd, match.start);
        parts.add(
          TextSpan(
            text: beforeText,
            style: TextStyle(
              fontSize: fontSize,
              height: lineHeight,
              fontFamily: 'Myanmar',
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        );
      }

      // Add the matched text (parentheses) with different styling
      parts.add(
        TextSpan(
          text: match.group(0),
          style: TextStyle(
            fontSize: fontSize - 1,
            height: lineHeight,
            fontFamily: 'Myanmar',
            fontWeight: FontWeight.w600,
            color: textColor.withValues(alpha: 0.7),
            fontStyle: FontStyle.italic,
          ),
        ),
      );

      lastEnd = match.end;
    }

    // Add remaining text
    if (lastEnd < text.length) {
      final remainingText = text.substring(lastEnd);
      parts.add(
        TextSpan(
          text: remainingText,
          style: TextStyle(
            fontSize: fontSize,
            height: lineHeight,
            fontFamily: 'Myanmar',
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      );
    }

    return RichText(
      text: TextSpan(
        children: parts.isEmpty
            ? [
                TextSpan(
                  text: text,
                  style: TextStyle(
                    fontSize: fontSize,
                    height: lineHeight,
                    fontFamily: 'Myanmar',
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ]
            : parts,
      ),
      textAlign: TextAlign.justify,
    );
  }
}
