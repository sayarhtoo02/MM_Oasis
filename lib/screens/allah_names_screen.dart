import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/allah_name.dart';
import '../services/allah_names_service.dart';
import '../providers/settings_provider.dart';
import '../widgets/glass/glass_scaffold.dart';
import '../widgets/glass/glass_card.dart';

import '../config/glass_theme.dart';

class AllahNamesScreen extends StatefulWidget {
  const AllahNamesScreen({super.key});

  @override
  State<AllahNamesScreen> createState() => _AllahNamesScreenState();
}

class _AllahNamesScreenState extends State<AllahNamesScreen> {
  final AllahNamesService _service = AllahNamesService();
  List<AllahName> _names = [];
  bool _isLoading = true;
  String _selectedLanguage = 'en';

  @override
  void initState() {
    super.initState();
    _loadNames();
  }

  Future<void> _loadNames() async {
    final names = await _service.getNames();
    setState(() {
      _names = names;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        final isDark = settingsProvider.isDarkMode;
        final textColor = GlassTheme.text(isDark);
        final accentColor = GlassTheme.accent(isDark);

        return GlassScaffold(
          title: '99 Names of Allah',
          actions: [
            PopupMenuButton<String>(
              initialValue: _selectedLanguage,
              icon: Icon(Icons.language, color: textColor),
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              onSelected: (lang) => setState(() => _selectedLanguage = lang),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'en', child: Text('English')),
                const PopupMenuItem(value: 'ur', child: Text('Urdu')),
                const PopupMenuItem(value: 'my', child: Text('Myanmar')),
              ],
            ),
          ],
          body: SafeArea(
            child: Column(
              children: [
                Expanded(child: _buildContent(isDark, textColor, accentColor)),
              ],
            ),
          ),
        );
      },
    );
  }

  // Widget _buildHeader() { ... } // Removed

  Widget _buildContent(bool isDark, Color textColor, Color accentColor) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: accentColor));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _names.length,
      itemBuilder: (context, index) {
        final name = _names[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            isDark: isDark,
            borderRadius: 16,
            padding: EdgeInsets.zero,
            onTap: () => _showDetailsDialog(name, index + 1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.arabic,
                          style: TextStyle(
                            fontFamily: 'Indopak',
                            fontSize: 30,
                            letterSpacing: 0,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          name.english,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: accentColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _selectedLanguage == 'ur'
                              ? name.urduMeaning
                              : _selectedLanguage == 'my'
                              ? 'Coming Soon'
                              : name.englishMeaning,
                          style: _selectedLanguage == 'ur'
                              ? GoogleFonts.notoNastaliqUrdu(
                                  fontSize: 12,
                                  color: textColor.withValues(alpha: 0.7),
                                )
                              : TextStyle(
                                  fontSize: 12,
                                  color: textColor.withValues(alpha: 0.7),
                                ),
                          textDirection: _selectedLanguage == 'ur'
                              ? TextDirection.rtl
                              : TextDirection.ltr,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: textColor.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDetailsDialog(AllahName name, int number) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          final isDark = settingsProvider.isDarkMode;
          final textColor = GlassTheme.text(isDark);
          final accentColor = GlassTheme.accent(isDark);

          return GlassCard(
            isDark: isDark,
            borderRadius: 25,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: textColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$number',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    name.arabic,
                    style: TextStyle(
                      fontFamily: 'Indopak',
                      fontSize: 50,
                      letterSpacing: 0,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    name.english,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedLanguage == 'ur'
                              ? 'معنی'
                              : _selectedLanguage == 'my'
                              ? 'အဓိပ္ပာယ်'
                              : 'Meaning',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _selectedLanguage == 'ur'
                              ? name.urduMeaning
                              : _selectedLanguage == 'my'
                              ? 'Coming Soon'
                              : name.englishMeaning,
                          style: _selectedLanguage == 'ur'
                              ? GoogleFonts.notoNastaliqUrdu(
                                  fontSize: 16,
                                  color: textColor,
                                )
                              : TextStyle(fontSize: 16, color: textColor),
                          textDirection: _selectedLanguage == 'ur'
                              ? TextDirection.rtl
                              : TextDirection.ltr,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _selectedLanguage == 'ur'
                              ? 'تشریح'
                              : _selectedLanguage == 'my'
                              ? 'ရှင်းလင်းချက်'
                              : 'Explanation',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _selectedLanguage == 'my'
                              ? 'Myanmar translation coming soon...'
                              : name.englishExplanation,
                          style: _selectedLanguage == 'ur'
                              ? GoogleFonts.notoNastaliqUrdu(
                                  fontSize: 14,
                                  color: textColor,
                                  height: 1.5,
                                )
                              : TextStyle(
                                  fontSize: 14,
                                  color: textColor,
                                  height: 1.5,
                                ),
                          textDirection: _selectedLanguage == 'ur'
                              ? TextDirection.rtl
                              : TextDirection.ltr,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
