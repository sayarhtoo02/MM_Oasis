import 'dart:async';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:munajat_e_maqbool_app/config/glass_theme.dart';
import 'package:munajat_e_maqbool_app/providers/settings_provider.dart';
import 'package:munajat_e_maqbool_app/services/ads_service.dart';

class AdsBannerWidget extends StatefulWidget {
  const AdsBannerWidget({super.key});

  @override
  State<AdsBannerWidget> createState() => _AdsBannerWidgetState();
}

class _AdsBannerWidgetState extends State<AdsBannerWidget> {
  final AdsService _adsService = AdsService();
  late PageController _pageController; // Changed to late
  List<Map<String, dynamic>> _ads = [];
  Timer? _autoScrollTimer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.96); // Wider peek
    _loadAds();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadAds() async {
    final ads = await _adsService.getActiveAds();
    if (mounted && ads.isNotEmpty) {
      setState(() => _ads = ads);
      _startAutoScroll();
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    if (_ads.length <= 1) return;

    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_pageController.hasClients) return;

      _currentPage = (_currentPage + 1) % _ads.length;
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> _handleAdTap(Map<String, dynamic> ad) async {
    final linkUrl = ad['link_url'] as String?;
    if (linkUrl != null && linkUrl.isNotEmpty) {
      final uri = Uri.tryParse(linkUrl);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ads.isEmpty) return const SizedBox.shrink();

    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final isDark = settings.isDarkMode;
        final textColor = GlassTheme.text(isDark);
        final accentColor = GlassTheme.accent(isDark);

        return Column(
          children: [
            AspectRatio(
              aspectRatio: 3.0, // Strict 3:1 Ratio
              child: PageView.builder(
                controller: _pageController,
                itemCount: _ads.length,
                padEnds:
                    false, // Ensure first item starts at edge if desired, or true for center
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final ad = _ads[index];
                  // Animated scale for focus effect
                  return AnimatedBuilder(
                    animation: _pageController,
                    builder: (context, child) {
                      double value = 1.0;
                      if (_pageController.position.haveDimensions) {
                        value = _pageController.page! - index;
                        value = (1 - (value.abs() * 0.1)).clamp(0.9, 1.0);
                      }
                      return Center(
                        child: SizedBox(
                          height:
                              Curves.easeOut.transform(value) *
                              300, // Dynamic height constraint
                          width:
                              Curves.easeOut.transform(value) *
                              500, // Dynamic width constraint
                          child: child,
                        ),
                      );
                    },
                    child: _buildAdSlide(ad, isDark, textColor, accentColor),
                  );
                },
              ),
            ),
            // Page indicators (dots) - Keep them close
            const SizedBox(height: 8),
            if (_ads.length > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _ads.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: _currentPage == index ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: _currentPage == index
                          ? accentColor
                          : accentColor.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildAdSlide(
    Map<String, dynamic> ad,
    bool isDark,
    Color textColor,
    Color accentColor,
  ) {
    final hasImage =
        ad['image_url'] != null && (ad['image_url'] as String).isNotEmpty;
    final hasLink =
        ad['link_url'] != null && (ad['link_url'] as String).isNotEmpty;

    return GestureDetector(
      onTap: hasLink ? () => _handleAdTap(ad) : null,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accentColor.withValues(alpha: 0.2)),
          color: accentColor.withValues(alpha: 0.05),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: hasImage
              ? Image.network(
                  ad['image_url'],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Icon(Icons.campaign, color: accentColor, size: 30),
                  ),
                )
              : Center(
                  child: Icon(Icons.campaign, color: accentColor, size: 30),
                ),
        ),
      ),
    );
  }
}
