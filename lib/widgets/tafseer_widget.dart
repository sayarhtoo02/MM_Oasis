import 'package:flutter/material.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html_dom;
import '../services/tafseer_service.dart';
import 'dart:math' as math;

class TafseerWidget extends StatefulWidget {
  final String ayahKey;
  final String language; // 'my' for Myanmar, 'en' for English

  const TafseerWidget({super.key, required this.ayahKey, this.language = 'my'});

  @override
  State<TafseerWidget> createState() => _TafseerWidgetState();
}

class _TafseerWidgetState extends State<TafseerWidget> {
  List<TafseerItem> tafseerItems = [];
  bool isLoading = true;
  String currentLanguage = 'my';
  double fontSize = 16.0;
  double lineHeight = 1.8;
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    currentLanguage = widget.language;
    _loadTafseer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    isDarkMode = Theme.of(context).brightness == Brightness.dark;
  }

  Future<void> _loadTafseer() async {
    setState(() => isLoading = true);

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
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _switchLanguage() {
    setState(() {
      currentLanguage = currentLanguage == 'my' ? 'en' : 'my';
    });
    _loadTafseer();
  }

  void _adjustFontSize(double delta) {
    setState(() {
      fontSize = math.max(12.0, math.min(24.0, fontSize + delta));
    });
  }

  void _adjustLineHeight(double delta) {
    setState(() {
      lineHeight = math.max(1.2, math.min(2.5, lineHeight + delta));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enhanced Header with controls
          Container(
            padding: const EdgeInsets.all(16.0),
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
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
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
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                          ),
                          Text(
                            'تفسير ابن كثير',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(
                                context,
                              ).primaryColor.withValues(alpha: 0.7),
                              fontFamily: 'Indopak',
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).primaryColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            currentLanguage == 'my' ? 'မြန်မာ' : 'English',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 8),
                          Switch(
                            value: currentLanguage == 'en',
                            onChanged: (_) => _switchLanguage(),
                            thumbColor: WidgetStateProperty.resolveWith((
                              states,
                            ) {
                              if (states.contains(WidgetState.selected)) {
                                return Theme.of(context).primaryColor;
                              }
                              return null;
                            }),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Reading Controls
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(
                      alpha: isDarkMode ? 0.1 : 0.7,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      // Font Size Controls
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.text_fields,
                              size: 16,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () => _adjustFontSize(-1),
                              icon: const Icon(Icons.remove, size: 16),
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            Text(
                              '${fontSize.toInt()}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            IconButton(
                              onPressed: () => _adjustFontSize(1),
                              icon: const Icon(Icons.add, size: 16),
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ),

                      // Line Height Controls
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.format_line_spacing,
                              size: 16,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () => _adjustLineHeight(-0.1),
                              icon: const Icon(Icons.remove, size: 16),
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            Text(
                              lineHeight.toStringAsFixed(1),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            IconButton(
                              onPressed: () => _adjustLineHeight(0.1),
                              icon: const Icon(Icons.add, size: 16),
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
                ),
              ],
            ),
          ),

          // Content
          if (isLoading)
            Container(
              padding: const EdgeInsets.all(40.0),
              child: Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      currentLanguage == 'my'
                          ? 'တဖ်စီရ် ရယူနေသည်...'
                          : 'Loading tafseer...',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            )
          else if (tafseerItems.isEmpty)
            Container(
              padding: const EdgeInsets.all(40.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.book_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      currentLanguage == 'my'
                          ? 'ဤအာယတ်အတွက် တဖ်စီရ် မရှိပါ'
                          : 'No tafseer available for this ayah',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ...tafseerItems.map((item) => _buildTafseerItem(item)),
        ],
      ),
    );
  }

  Widget _buildTafseerItem(TafseerItem item) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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
          // Ayah range info with enhanced styling
          if (item.fromAyah != item.toAyah)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    Theme.of(context).primaryColor.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.bookmark_outline,
                    size: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    currentLanguage == 'my'
                        ? 'အာယတ် ${item.fromAyah} - ${item.toAyah}'
                        : 'Ayah ${item.fromAyah} - ${item.toAyah}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          // Tafseer content with enhanced HTML parsing
          _buildEnhancedHtmlContent(item.text),
        ],
      ),
    );
  }

  Widget _buildEnhancedHtmlContent(String htmlContent) {
    final document = html_parser.parse(htmlContent);
    final parts = <Widget>[];

    for (final element in document.body?.children ?? []) {
      parts.add(_parseHtmlElement(element));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: parts,
    );
  }

  Widget _parseHtmlElement(html_dom.Element element) {
    final tagName = element.localName?.toLowerCase();
    final className = element.attributes['class'] ?? '';
    final lang = element.attributes['lang'] ?? '';
    final text = element.text.trim();

    if (text.isEmpty) return const SizedBox.shrink();

    // Arabic text styling
    if (lang == 'ar' ||
        className.contains('ar') ||
        RegExp(r'[\u0600-\u06FF]').hasMatch(text)) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.all(16),
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
        margin: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          text,
          style: TextStyle(
            fontSize:
                fontSize +
                (tagName == 'h1'
                    ? 6
                    : tagName == 'h2'
                    ? 4
                    : 2),
            height: lineHeight - 0.2,
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
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: _buildMyanmarText(text),
      );
    }

    // English or other text
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          height: lineHeight,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).textTheme.bodyLarge?.color,
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
              color: Theme.of(context).textTheme.bodyLarge?.color,
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
            fontWeight: FontWeight.w500,
            color: Theme.of(
              context,
            ).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
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
            color: Theme.of(context).textTheme.bodyLarge?.color,
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
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ]
            : parts,
      ),
      textAlign: TextAlign.justify,
    );
  }
}
