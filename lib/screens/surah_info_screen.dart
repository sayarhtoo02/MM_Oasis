import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:provider/provider.dart';
import '../models/quran_surah.dart';
import '../providers/quran_provider.dart';
import '../providers/settings_provider.dart';
import '../config/glass_theme.dart';
import '../widgets/glass/glass_scaffold.dart';
import '../widgets/glass/glass_card.dart';

class SurahInfoScreen extends StatefulWidget {
  final QuranSurah surah;

  const SurahInfoScreen({super.key, required this.surah});

  @override
  State<SurahInfoScreen> createState() => _SurahInfoScreenState();
}

class _SurahInfoScreenState extends State<SurahInfoScreen> {
  Map<String, dynamic>? _info;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    final info = await context.read<QuranProvider>().getSurahInfo(
      widget.surah.number,
    );
    if (mounted) {
      setState(() {
        _info = info;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        final isDark = settingsProvider.isDarkMode;
        final textColor = GlassTheme.text(isDark);
        final accentColor = GlassTheme.accent(isDark);

        return GlassScaffold(
          title: widget.surah.englishName,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Surah Header Card
                GlassCard(
                  isDark: isDark,
                  borderRadius: 24,
                  child: Column(
                    children: [
                      Text(
                        widget.surah.name,
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 36,
                          color: textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.surah.englishName,
                        style: TextStyle(
                          fontSize: 20,
                          color: textColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        widget.surah.englishNameTranslation,
                        style: TextStyle(
                          fontSize: 14,
                          color: textColor.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Stats Row
                GlassCard(
                  isDark: isDark,
                  borderRadius: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        Icons.format_list_numbered,
                        '${widget.surah.numberOfAyahs}',
                        'Ayahs',
                        textColor,
                        accentColor,
                      ),
                      Container(
                        height: 40,
                        width: 1,
                        color: textColor.withValues(alpha: 0.1),
                      ),
                      _buildStatItem(
                        Icons.location_on,
                        widget.surah.revelationType,
                        'Revelation',
                        textColor,
                        accentColor,
                      ),
                      Container(
                        height: 40,
                        width: 1,
                        color: textColor.withValues(alpha: 0.1),
                      ),
                      _buildStatItem(
                        Icons.tag,
                        '${widget.surah.number}',
                        'Surah No.',
                        textColor,
                        accentColor,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Info Content
                if (_isLoading)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: CircularProgressIndicator(color: accentColor),
                    ),
                  )
                else if (_info == null)
                  Center(
                    child: Text(
                      'Info not available',
                      style: TextStyle(color: textColor.withValues(alpha: 0.7)),
                    ),
                  )
                else
                  GlassCard(
                    isDark: isDark,
                    borderRadius: 16,
                    child: HtmlWidget(
                      _info!['text'] ?? '',
                      textStyle: TextStyle(
                        fontSize: 16,
                        height: 1.8,
                        color: textColor.withValues(alpha: 0.9),
                      ),
                      customStylesBuilder: (element) {
                        if (element.localName == 'h2') {
                          return {
                            'color': isDark ? '#E0B40A' : '#0D3B2E',
                            'font-size': '20px',
                            'font-weight': 'bold',
                            'margin-top': '24px',
                            'margin-bottom': '12px',
                            'border-bottom':
                                '2px solid ${isDark ? 'rgba(255,255,255,0.1)' : '#E0E0E0'}',
                            'padding-bottom': '8px',
                          };
                        }
                        if (element.localName == 'p') {
                          return {
                            'margin-bottom': '16px',
                            'text-align': 'justify',
                          };
                        }
                        return null;
                      },
                    ),
                  ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String value,
    String label,
    Color textColor,
    Color accentColor,
  ) {
    return Column(
      children: [
        Icon(icon, color: accentColor, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: textColor.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
