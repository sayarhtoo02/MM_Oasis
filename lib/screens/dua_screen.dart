import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:munajat_e_maqbool_app/models/dua_item.dart';
import 'package:munajat_e_maqbool_app/screens/dua_detail_view_screen.dart';
import 'package:munajat_e_maqbool_app/services/database/oasismm_database.dart';
import '../providers/settings_provider.dart';
import '../config/glass_theme.dart';
import '../widgets/glass/glass_scaffold.dart';
import '../widgets/glass/glass_card.dart';

class DuaScreen extends StatefulWidget {
  const DuaScreen({super.key});

  @override
  State<DuaScreen> createState() => _DuaScreenState();
}

class _DuaScreenState extends State<DuaScreen> {
  List<Map<String, dynamic>> _categories = [];
  String _selectedLanguage = 'mm';
  String? _expandedCategory;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final rows = await OasisMMDatabase.getDuaCategories();
      setState(() {
        _categories = rows.map((row) {
          final names = json.decode(row['name'] as String);
          return {
            'id': row['id'],
            'slug': row['category_key'],
            'name': names[_selectedLanguage] ?? names['en'],
            'description': row['description'],
          };
        }).toList();
      });
    } catch (e) {
      debugPrint('Error loading categories: $e');
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
          title: 'Daily Duas',
          actions: [
            PopupMenuButton<String>(
              icon: Icon(Icons.language, color: textColor),
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              onSelected: (value) {
                setState(() {
                  _selectedLanguage = value;
                });
                _loadCategories();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'en', child: Text('English')),
                const PopupMenuItem(
                  value: 'id',
                  child: Text('Bahasa Indonesia'),
                ),
                const PopupMenuItem(value: 'mm', child: Text('Myanmar')),
              ],
            ),
          ],
          body: _categories.isEmpty
              ? Center(child: CircularProgressIndicator(color: accentColor))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    return _buildCategoryCard(
                      category['id'],
                      category['name'],
                      category['slug'],
                      _getCategoryIcon(category['slug']),
                      _getCategoryColor(index),
                      isDark,
                      textColor,
                      accentColor,
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildCategoryCard(
    int id,
    String name,
    String slug,
    IconData icon,
    Color color,
    bool isDark,
    Color textColor,
    Color accentColor,
  ) {
    final isExpanded = _expandedCategory == slug;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          GlassCard(
            isDarkForce: isDark,
            borderRadius: 16,
            padding: EdgeInsets.zero,
            onTap: () {
              setState(() {
                _expandedCategory = isExpanded ? null : slug;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: _selectedLanguage == 'mm'
                            ? 'Myanmar'
                            : 'Roboto',
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            GlassCard(
              isDarkForce: isDark,
              borderRadius: 16,
              padding: const EdgeInsets.all(12),
              child: FutureBuilder<List<DuaItem>>(
                future: _loadDuas(id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: CircularProgressIndicator(color: accentColor),
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'No duas found',
                        style: TextStyle(color: textColor),
                      ),
                    );
                  }
                  return Column(
                    children: snapshot.data!
                        .map(
                          (dua) => _buildDuaCard(
                            dua,
                            slug,
                            snapshot.data!,
                            color,
                            isDark,
                            textColor,
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDuaCard(
    DuaItem dua,
    String slug,
    List<DuaItem> allDuas,
    Color parentColor,
    bool isDark,
    Color textColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        isDarkForce: isDark,
        borderRadius: 16,
        padding: EdgeInsets.zero,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DuaDetailViewScreen(
                categoryId: _categories.firstWhere(
                  (c) => c['slug'] == slug,
                )['id'],
                categoryName: _categories.firstWhere(
                  (c) => c['slug'] == slug,
                )['name'],
                categorySlug: slug,
                language: _selectedLanguage,
                initialIndex: allDuas.indexOf(dua),
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: parentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.menu_book, color: parentColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  dua.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    fontFamily: _selectedLanguage == 'mm'
                        ? 'Myanmar'
                        : 'Roboto',
                    color: textColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: parentColor.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<DuaItem>> _loadDuas(int categoryId) async {
    try {
      final rows = await OasisMMDatabase.getDuasByCategory(
        categoryId,
        language: _selectedLanguage,
      );
      return rows.map((row) {
        return DuaItem(
          id: row['id']?.toString() ?? '',
          title: row['title'] ?? '',
          arabic: row['arabic_text'] ?? '',
          latin: row['transliteration'] ?? '',
          translation: row['translation'] ?? '',
          source: row['reference'] ?? '',
          fawaid: row['benefits'] ?? '',
          notes: '', // Notes not in DB currently?
        );
      }).toList();
    } catch (e) {
      debugPrint('Error loading preview duas: $e');
      return [];
    }
  }

  IconData _getCategoryIcon(String slug) {
    switch (slug) {
      case 'morning-dhikr':
        return Icons.wb_sunny;
      case 'evening-dhikr':
        return Icons.brightness_3;
      case 'daily-dua':
        return Icons.today;
      case 'selected-dua':
        return Icons.star;
      case 'dhikr-after-salah':
        return Icons.self_improvement;
      default:
        return Icons.menu_book;
    }
  }

  Color _getCategoryColor(int index) {
    final colors = [
      const Color(0xFFFFB74D),
      const Color(0xFF4CAF50),
      const Color(0xFF00897B),
      const Color(0xFF7E57C2),
      const Color(0xFF42A5F5),
    ];
    return colors[index % colors.length];
  }
}
