import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../models/mashaf_models.dart';
import 'surah_header_data.dart';

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

    return Padding(
      padding: EdgeInsets.zero,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;

            // Calculate natural width of words at current fontSize
            double naturalWidth = 0;
            const double wordSpacing =
                2.0; // horizontal padding (1.0 on each side)

            for (final word in line.words) {
              final tp = TextPainter(
                text: TextSpan(text: word.text, style: textStyle),
                textDirection: TextDirection.rtl,
              )..layout();
              naturalWidth += tp.width + wordSpacing;
            }

            if (isCentered) {
              final List<InlineSpan> spans = [];
              int? currentSurah;
              int? currentAyah;
              StringBuffer ayahTextBuffer = StringBuffer();

              void flushAyah() {
                if (ayahTextBuffer.isEmpty) return;
                final text = ayahTextBuffer.toString();
                final surah = currentSurah;
                final ayah = currentAyah;
                final isSelected =
                    selectedAyah != null &&
                    selectedAyah!['surah'] == surah &&
                    selectedAyah!['ayah'] == ayah;

                spans.add(
                  TextSpan(
                    text: text,
                    style: textStyle.copyWith(
                      backgroundColor: isSelected
                          ? const Color(0xFF0D3B2E).withValues(alpha: 0.1)
                          : null,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        if (onAyahTap != null &&
                            surah != null &&
                            ayah != null) {
                          onAyahTap!(surah, ayah);
                        }
                      },
                  ),
                );
                ayahTextBuffer.clear();
              }

              for (final word in line.words) {
                if (currentSurah != word.surah || currentAyah != word.ayah) {
                  flushAyah();
                  currentSurah = word.surah;
                  currentAyah = word.ayah;
                }
                if (ayahTextBuffer.isNotEmpty) ayahTextBuffer.write(' ');
                ayahTextBuffer.write(word.text);
              }
              flushAyah();

              return Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: RichText(
                    text: TextSpan(children: spans),
                    textAlign: TextAlign.center,
                    textScaler: TextScaler.noScaling,
                  ),
                ),
              );
            }

            // For normal lines, use Row for "corners trapped" justification
            if (line.words.length > 1) {
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
                    child: Text(
                      word.text,
                      style: textStyle,
                      textScaler: TextScaler.noScaling,
                    ),
                  ),
                );
              }).toList();

              // SMART SIZING LOGIC:
              // 1. If line is narrower than screen -> Spread words to edges (Justify)
              // 2. If line is wider than screen -> Scale down the whole row (Fit)

              if (naturalWidth < availableWidth - 5) {
                // CASE 1: STRETCH (Normal Justification)
                return SizedBox(
                  width: availableWidth,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    textDirection: TextDirection.rtl,
                    children: wordWidgets,
                  ),
                );
              } else {
                // CASE 2: SHRINK (Scaled to Fit)
                // We use IntrinsicWidth to let Row calculate its actual width,
                // then FittedBox scales it down into availableWidth.
                return SizedBox(
                  width: availableWidth,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.center,
                    child: IntrinsicWidth(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        textDirection: TextDirection.rtl,
                        children: wordWidgets,
                      ),
                    ),
                  ),
                );
              }
            } else if (line.words.isNotEmpty) {
              // Single word line
              final word = line.words.first;
              final isSelected =
                  selectedAyah != null &&
                  selectedAyah!['surah'] == word.surah &&
                  selectedAyah!['ayah'] == word.ayah;

              return Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
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
                    child: Text(
                      word.text,
                      style: textStyle,
                      textScaler: TextScaler.noScaling,
                    ),
                  ),
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
