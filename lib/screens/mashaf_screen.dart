import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/quran_provider.dart';
import '../providers/settings_provider.dart';
import '../config/glass_theme.dart';
import 'mashaf/mashaf_page.dart';

/// Main Mashaf screen with page-by-page Quran display
class MashafScreen extends StatefulWidget {
  final int initialPage;

  const MashafScreen({super.key, this.initialPage = 1});

  @override
  State<MashafScreen> createState() => _MashafScreenState();
}

class _MashafScreenState extends State<MashafScreen> {
  late final PageController _pageController;
  Map<String, dynamic>? _surahMetadata;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialPage - 1);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<QuranProvider>(context, listen: false).loadMashafInfo();
      _loadMetadata();
    });
  }

  Future<void> _loadMetadata() async {
    try {
      final surahJson = await rootBundle.loadString(
        'assets/quran_data/quran-metadata-surah-name.json',
      );
      setState(() {
        _surahMetadata = json.decode(surahJson);
      });
    } catch (e) {
      debugPrint('Error loading metadata: $e');
    }
  }

  Map<String, dynamic>? _getSurahInfo(int surahNumber) {
    if (_surahMetadata == null) return null;
    return _surahMetadata!['$surahNumber'];
  }

  int _getJuzForPage(int pageNumber) {
    return ((pageNumber - 1) ~/ 20) + 1;
  }

  String _getHizbForPage(int pageNumber) {
    final hizb = ((pageNumber - 1) ~/ 10) + 1;
    final quarter = ((pageNumber - 1) % 10) ~/ 2.5;
    if (quarter == 0) return 'Hizb $hizb';
    return '¼ Hizb $hizb';
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        final isDark = settingsProvider.isDarkMode;
        final textColor = GlassTheme.text(isDark);
        final accentColor = GlassTheme.accent(isDark);

        return Scaffold(
          backgroundColor: GlassTheme.background(isDark),
          body: SafeArea(
            child: Consumer<QuranProvider>(
              builder: (context, provider, child) {
                if (provider.mashafError != null) {
                  return _buildErrorView(
                    provider,
                    isDark,
                    textColor,
                    accentColor,
                  );
                }

                if (provider.mashafInfo == null) {
                  return Center(
                    child: CircularProgressIndicator(color: accentColor),
                  );
                }

                return _buildPageView(provider);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorView(
    QuranProvider provider,
    bool isDark,
    Color textColor,
    Color accentColor,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(
            'Error loading Mashaf:\n${provider.mashafError}',
            textAlign: TextAlign.center,
            style: TextStyle(color: textColor),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => provider.toggleMode(),
            style: ElevatedButton.styleFrom(backgroundColor: accentColor),
            child: const Text('Go Back', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildPageView(QuranProvider provider) {
    return OrientationBuilder(
      builder: (context, orientation) {
        final isLandscape = orientation == Orientation.landscape;

        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.0)),
          child: PageView.builder(
            controller: _pageController,
            reverse: true,
            itemCount: provider.mashafInfo!.numberOfPages,
            onPageChanged: (page) => setState(() {}),
            itemBuilder: (context, index) {
              final pageNumber = index + 1;
              return MashafPage(
                pageNumber: pageNumber,
                isLandscape: isLandscape,
                surahInfo: _getSurahInfo(1),
                juzNumber: _getJuzForPage(pageNumber),
                hizbInfo: _getHizbForPage(pageNumber),
              );
            },
          ),
        );
      },
    );
  }
}
