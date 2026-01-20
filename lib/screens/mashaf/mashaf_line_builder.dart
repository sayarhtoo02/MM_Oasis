import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../models/mashaf_models.dart';
import 'surah_header_data.dart';
import 'tajweed_renderer.dart';

/// Builds text lines for Mashaf pages
class MashafLineBuilder {
  final BuildContext context;
  final double fontSize;
  final Function(int surah, int ayah)? onAyahTap;
  final Map<String, dynamic>? selectedAyah;

  MashafLineBuilder({
    required this.context,
    required this.fontSize,
    this.onAyahTap,
    this.selectedAyah,
  });

  /// Build all lines for a page
  List<Widget> buildLines(List<MashafPageLine> lines) {
    final List<Widget> widgets = [];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      switch (line.lineType) {
        case 'surah_name':
          widgets.add(_buildSurahHeader(line.surahNumber));
          break;
        case 'basmallah':
          widgets.add(_buildBismillah());
          break;
        case 'ayah':
        default:
          if (line.words.isNotEmpty) {
            widgets.add(_buildTextLine(line));
          } else {
            widgets.add(const SizedBox(height: 4));
          }
          break;
      }

      // Add divider between lines
      if (i < lines.length - 1 &&
          line.lineType == 'ayah' &&
          line.words.isNotEmpty) {
        widgets.add(
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(vertical: 0.5),
            color: const Color(0xFFEEEEEE),
          ),
        );
      }
    }

    return widgets;
  }

  Widget _buildSurahHeader(int surahNumber) {
    final ligature = surahHeaderLigatures[surahNumber] ?? '';
    return Container(
      margin: EdgeInsets.zero,
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            ligature,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'SurahHeader',
              fontSize: 75,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBismillah() {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Indopak',
              fontSize: fontSize * 0.75,
              color: Colors.black,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextLine(MashafPageLine line) {
    final isCentered = line.isCentered;

    final textStyle = TextStyle(
      fontFamily: 'Indopak',
      fontSize: fontSize,
      fontWeight: FontWeight.normal,
      height: 1.7,
      color: Colors.black,
      letterSpacing: 0,
    );

    // Group words by Ayah
    final List<InlineSpan> spans = [];
    List<MashafWord> currentAyahWords = [];
    int? currentSurah;
    int? currentAyah;

    void flushAyah() {
      if (currentAyahWords.isEmpty) return;

      final ayahText = currentAyahWords.map((w) => w.text).join(' ');
      final tajweedData = currentAyahWords
          .map((w) => w.textTajweed ?? '')
          .join('| :100|');

      final isSelected =
          selectedAyah != null &&
          selectedAyah!['surah'] == currentSurah &&
          selectedAyah!['ayah'] == currentAyah;

      final span = TajweedRenderer.buildTextSpan(
        context,
        ayahText,
        textStyle.copyWith(
          backgroundColor: isSelected
              ? const Color(0xFF0D3B2E).withValues(alpha: 0.1)
              : null,
        ),
        tajweedData: tajweedData,
      );

      // Wrap in a recognizer span
      spans.add(
        TextSpan(
          children: [
            span,
            const TextSpan(text: ' '),
          ], // Add space
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              if (onAyahTap != null &&
                  currentSurah != null &&
                  currentAyah != null) {
                onAyahTap!(currentSurah, currentAyah);
              }
            },
        ),
      );

      currentAyahWords = [];
    }

    for (final word in line.words) {
      if (currentSurah != word.surah || currentAyah != word.ayah) {
        flushAyah();
        currentSurah = word.surah;
        currentAyah = word.ayah;
      }

      // DEDUPLICATION: Skip redundant stop signs (rumuz)
      // Sometimes the database includes rumuz as a separate "word"
      // even if it's already attached to the previous word's Tajweed data.
      bool isRedundant = false;
      if (currentAyahWords.isNotEmpty) {
        final lastWord = currentAyahWords.last;
        final currentWordText = word.text.trim();

        // Broad range for Indopak rumuz, ayah markers, and decorations
        // Includes private use area (around \uF500) where Indopak markers live
        final rumuzRegex = RegExp(
          r'^[\u0610-\u061A\u06D6-\u06ED\uF500-\uF5FF\s]+$',
        );

        if (rumuzRegex.hasMatch(currentWordText)) {
          // Get the full text rendered by the last word (including Tajweed parts)
          String lastWordRenderedText = lastWord.text;
          if (lastWord.textTajweed != null) {
            lastWordRenderedText = lastWord.textTajweed!
                .split('|')
                .map(
                  (s) =>
                      s.contains(':') ? s.substring(0, s.lastIndexOf(':')) : s,
                )
                .join('');
          }

          if (lastWordRenderedText.contains(currentWordText) ||
              lastWord.text.contains(currentWordText)) {
            isRedundant = true;
          }
        }
      }

      if (!isRedundant) {
        currentAyahWords.add(word);
      }
    }
    flushAyah();

    if (isCentered) {
      return Padding(
        padding: EdgeInsets.zero,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: RichText(
                text: TextSpan(children: spans),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.zero,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;

            // Calculate width to decide layout.
            // MUST include the word padding (2px per word) to prevent right overflow.
            double totalWordsWidth = 0;
            for (final word in line.words) {
              final tp = TextPainter(
                text: TextSpan(text: word.text, style: textStyle),
                textDirection: TextDirection.rtl,
              )..layout();
              totalWordsWidth += tp.width + 2; // +2 for horizontal padding
            }

            // If it fits, we can use RichText directly.
            // Note: The original code used Row for justified look when it fits.
            // But Row breaks our single-span-per-ayah logic if an Ayah is split across widgets?
            // Actually, if we use RichText with TextAlign.justify, it might work better.
            // But Flutter's RichText justify is not always perfect for Arabic.
            // The original code used Row(mainAxisAlignment: MainAxisAlignment.spaceBetween)
            // This spreads words evenly.
            // To keep interaction working, we can still use Row, but each child must be a GestureDetector.

            // Use a small safety buffer (5px) to prevent sub-pixel overflow issues.
            // We always use Full Justification (spaceBetween) to keep words trapped
            // between the page corners as requested.
            if (totalWordsWidth <= availableWidth - 5 &&
                line.words.length > 1) {
              // Use Row for Full Justification
              final wordWidgets = line.words.map((word) {
                final isSelected =
                    selectedAyah != null &&
                    selectedAyah!['surah'] == word.surah &&
                    selectedAyah!['ayah'] == word.ayah;

                return GestureDetector(
                  onTap: () {
                    if (onAyahTap != null) {
                      onAyahTap!(word.surah, word.ayah);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    color: isSelected
                        ? const Color(0xFF0D3B2E).withValues(alpha: 0.1)
                        : null,
                    child: TajweedRenderer.buildRichText(
                      context,
                      word.text,
                      textStyle,
                      tajweedData: word.textTajweed,
                    ),
                  ),
                );
              }).toList();

              return SizedBox(
                width: availableWidth,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: availableWidth,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: wordWidgets,
                    ),
                  ),
                ),
              );
            } else {
              // Use FittedBox with RichText
              return FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: RichText(
                  text: TextSpan(children: spans),
                  textAlign: TextAlign.right,
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
