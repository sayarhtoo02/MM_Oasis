import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/book_info_model.dart';
import '../../config/glass_theme.dart';
import '../../widgets/glass/glass_scaffold.dart';
import '../../widgets/glass/glass_card.dart';
import '../../providers/settings_provider.dart';

class BookInfoScreen extends StatelessWidget {
  final BookInfo bookInfo;

  const BookInfoScreen({super.key, required this.bookInfo});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        final isDark = settingsProvider.isDarkMode;
        final textColor = GlassTheme.text(isDark);
        final accentColor = GlassTheme.accent(isDark);

        return GlassScaffold(
          title: 'စာအုပ်အချက်အလက်',
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(isDark, textColor, accentColor),
                const SizedBox(height: 24),
                _buildInfoCard(
                  icon: Icons.book_rounded,
                  title: 'စာအုပ်အမည်',
                  content: bookInfo.title,
                  isDark: isDark,
                  textColor: textColor,
                  accentColor: accentColor,
                ),
                const SizedBox(height: 16),
                _buildInfoCard(
                  icon: Icons.person_rounded,
                  title: 'ရေးသားသူ',
                  content: bookInfo.author,
                  isDark: isDark,
                  textColor: textColor,
                  accentColor: accentColor,
                ),
                const SizedBox(height: 16),
                _buildInfoCard(
                  icon: Icons.business_rounded,
                  title: 'ထုတ်ဝေသူ',
                  content: bookInfo.publisher,
                  isDark: isDark,
                  textColor: textColor,
                  accentColor: accentColor,
                ),
                const SizedBox(height: 16),
                _buildInfoCard(
                  icon: Icons.language_rounded,
                  title: 'ဘာသာစကား',
                  content: bookInfo.language,
                  isDark: isDark,
                  textColor: textColor,
                  accentColor: accentColor,
                ),
                const SizedBox(height: 16),
                _buildInfoCard(
                  icon: Icons.calendar_today_rounded,
                  title: 'ထုတ်ဝေမှု',
                  content: bookInfo.edition,
                  isDark: isDark,
                  textColor: textColor,
                  accentColor: accentColor,
                ),
                const SizedBox(height: 24),
                _buildContactSection(isDark, textColor, accentColor),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isDark, Color textColor, Color accentColor) {
    return GlassCard(
      isDark: isDark,
      borderRadius: 24,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: accentColor.withValues(alpha: 0.3)),
            ),
            child: Icon(Icons.menu_book_rounded, size: 48, color: accentColor),
          ),
          const SizedBox(height: 16),
          Text(
            'ချစ်မြတ်နိုးဖွယ်ရာ စွန္နသ်တော်များ',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: textColor,
              fontFamily: 'Myanmar',
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
    required bool isDark,
    required Color textColor,
    required Color accentColor,
  }) {
    return GlassCard(
      isDark: isDark,
      borderRadius: 20,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textColor.withValues(alpha: 0.8),
                    fontFamily: 'Myanmar',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 16,
              height: 1.6,
              fontWeight: FontWeight.w600,
              color: textColor,
              fontFamily: 'Myanmar',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection(bool isDark, Color textColor, Color accentColor) {
    return GlassCard(
      isDark: isDark,
      borderRadius: 20,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.contact_phone_rounded,
                  color: accentColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'ဆက်သွယ်ရန်',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: textColor.withValues(alpha: 0.8),
                  fontFamily: 'Myanmar',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildContactItem(
            icon: Icons.phone_rounded,
            label: 'ဖုန်း',
            value: bookInfo.contact.phone,
            onTap: () => _launchUrl('tel:${bookInfo.contact.phone}'),
            isDark: isDark,
            textColor: textColor,
            accentColor: accentColor,
          ),
          const SizedBox(height: 12),
          _buildContactItem(
            icon: Icons.smartphone_rounded,
            label: 'မိုဘိုင်း',
            value: bookInfo.contact.mobile,
            onTap: () => _launchUrl('tel:${bookInfo.contact.mobile}'),
            isDark: isDark,
            textColor: textColor,
            accentColor: accentColor,
          ),
          const SizedBox(height: 12),
          _buildContactItem(
            icon: Icons.email_rounded,
            label: 'အီးမေးလ်',
            value: bookInfo.contact.email,
            onTap: () => _launchUrl('mailto:${bookInfo.contact.email}'),
            isDark: isDark,
            textColor: textColor,
            accentColor: accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
    required bool isDark,
    required Color textColor,
    required Color accentColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: textColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: textColor.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: accentColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        color: textColor.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Myanmar',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: textColor.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }
}
