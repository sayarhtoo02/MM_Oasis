import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:munajat_e_maqbool_app/models/dua_item.dart';
import 'package:munajat_e_maqbool_app/providers/settings_provider.dart';
import 'package:munajat_e_maqbool_app/services/database/oasismm_database.dart';
import '../config/glass_theme.dart';
import '../widgets/glass/glass_scaffold.dart';
import '../widgets/glass/glass_card.dart';

class DuaDetailViewScreen extends StatefulWidget {
  final int categoryId;
  final String categoryName;
  final String categorySlug;
  final String language;
  final int initialIndex;

  const DuaDetailViewScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.categorySlug,
    required this.language,
    this.initialIndex = 0,
  });

  @override
  State<DuaDetailViewScreen> createState() => _DuaDetailViewScreenState();
}

class _DuaDetailViewScreenState extends State<DuaDetailViewScreen> {
  List<DuaItem> _duas = [];
  bool _isLoading = true;
  late int _currentIndex;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _loadDuas();
  }

  Future<void> _loadDuas() async {
    try {
      final rows = await OasisMMDatabase.getDuasByCategory(
        widget.categoryId,
        language: widget.language,
      );

      setState(() {
        _duas = rows.map((row) {
          return DuaItem(
            id: row['id']?.toString() ?? '',
            title: row['title'] ?? '',
            arabic: row['arabic_text'] ?? '',
            latin: row['transliteration'] ?? '',
            translation: row['translation'] ?? '',
            source: row['reference'] ?? '',
            fawaid: row['benefits'] ?? '',
            notes: '',
          );
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading duas in detail view: $e');
      setState(() {
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
          title: widget.categoryName,
          body: _isLoading
              ? Center(child: CircularProgressIndicator(color: accentColor))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${_currentIndex + 1} / ${_duas.length}',
                            style: TextStyle(
                              color: textColor.withValues(alpha: 0.7),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: (index) =>
                            setState(() => _currentIndex = index),
                        itemCount: _duas.length,
                        itemBuilder: (context, index) => _buildDuaCard(
                          _duas[index],
                          isDark,
                          textColor,
                          accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildDuaCard(
    DuaItem dua,
    bool isDark,
    Color textColor,
    Color accentColor,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: GlassCard(
        isDarkForce: isDark,
        borderRadius: 24,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              dua.title,
              style: TextStyle(
                fontFamily: widget.language == 'mm' ? 'Myanmar' : 'Roboto',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: accentColor.withValues(alpha: 0.2)),
              ),
              child: Text(
                dua.arabic,
                style: TextStyle(
                  fontFamily: 'Indopak',
                  letterSpacing: 0,
                  fontSize: 32,
                  height: 2.3,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: textColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: textColor.withValues(alpha: 0.1)),
              ),
              child: Text(
                dua.latin,
                style: TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: textColor.withValues(alpha: 0.7),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              dua.translation,
              style: TextStyle(
                fontFamily: widget.language == 'mm' ? 'Myanmar' : 'Roboto',
                fontSize: 18,
                height: 1.6,
                color: textColor.withValues(alpha: 0.9),
              ),
              textAlign: TextAlign.center,
            ),
            if (dua.notes.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.green,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        dua.notes,
                        style: TextStyle(
                          fontFamily: widget.language == 'mm'
                              ? 'Myanmar'
                              : 'Roboto',
                          fontSize: 15,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (dua.fawaid.isNotEmpty) ...[
              const SizedBox(height: 24),
              Divider(color: textColor.withValues(alpha: 0.1), thickness: 1),
              const SizedBox(height: 16),
              Text(
                widget.language == 'mm' ? 'အကျိုးကျေးဇူးများ' : 'Benefits',
                style: TextStyle(
                  fontFamily: 'Myanmar',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                dua.fawaid,
                style: TextStyle(
                  fontFamily: 'Myanmar',
                  fontSize: 16,
                  height: 1.6,
                  color: textColor.withValues(alpha: 0.9),
                ),
                textAlign: TextAlign.justify,
              ),
            ],
            if (dua.source.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Source: ${dua.source}',
                style: TextStyle(
                  fontFamily: widget.language == 'mm' ? 'Myanmar' : 'Roboto',
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: textColor.withValues(alpha: 0.5),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
