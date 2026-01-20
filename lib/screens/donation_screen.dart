import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../config/glass_theme.dart';
import '../widgets/glass/glass_scaffold.dart';
import '../widgets/glass/glass_card.dart';

class DonationScreen extends StatelessWidget {
  const DonationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        final isDark = settingsProvider.isDarkMode;
        final textColor = GlassTheme.text(isDark);
        final accentColor = GlassTheme.accent(isDark);

        return GlassScaffold(
          title: 'Support Our Mission',
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.volunteer_activism, size: 60, color: accentColor),
                  const SizedBox(height: 16),
                  Text(
                    'Help us spread Islamic knowledge',
                    style: TextStyle(
                      fontSize: 16,
                      color: textColor.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildInfoCard(isDark, textColor, accentColor),
                  const SizedBox(height: 20),
                  _buildPaymentMethods(context, isDark, textColor, accentColor),
                  const SizedBox(height: 20),
                  _buildImpactSection(isDark, textColor, accentColor),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(bool isDark, Color textColor, Color accentColor) {
    return GlassCard(
      isDark: isDark,
      borderRadius: 20,
      child: Column(
        children: [
          const Icon(Icons.favorite, size: 50, color: Color(0xFFFF6B6B)),
          const SizedBox(height: 16),
          Text(
            'Your donation helps us:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildBenefitItem(
            Icons.book,
            'Maintain free Islamic content',
            textColor,
            accentColor,
          ),
          _buildBenefitItem(
            Icons.translate,
            'Add more translations',
            textColor,
            accentColor,
          ),
          _buildBenefitItem(
            Icons.update,
            'Regular app updates',
            textColor,
            accentColor,
          ),
          _buildBenefitItem(
            Icons.cloud,
            'Server & hosting costs (for upcoming features)',
            textColor,
            accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(
    IconData icon,
    String text,
    Color textColor,
    Color accentColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 24, color: accentColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: textColor.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods(
    BuildContext context,
    bool isDark,
    Color textColor,
    Color accentColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Payment Methods',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 16),
        GlassCard(
          isDark: isDark,
          borderRadius: 16,
          padding: const EdgeInsets.all(16),
          onTap: () =>
              _showMobilePayment(context, isDark, textColor, accentColor),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.phone_android,
                  color: Colors.green,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mobile Payment',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'View mobile payment options',
                      style: TextStyle(
                        fontSize: 12,
                        color: textColor.withValues(alpha: 0.6),
                      ),
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
      ],
    );
  }

  Widget _buildImpactSection(bool isDark, Color textColor, Color accentColor) {
    return GlassCard(
      isDark: isDark,
      borderRadius: 20,
      child: Column(
        children: [
          Text(
            '💝 May Allah reward you',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            '"The believer\'s shade on the Day of Resurrection will be his charity." - Tirmidhi',
            style: TextStyle(
              fontSize: 14,
              color: textColor.withValues(alpha: 0.8),
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showMobilePayment(
    BuildContext context,
    bool isDark,
    Color textColor,
    Color accentColor,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: GlassTheme.glassGradient(isDark)),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          border: Border.all(color: GlassTheme.glassBorder(isDark)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: textColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Mobile Payment',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 20),
            _buildDetailRow('Wave Money', '097905•••••', textColor),
            _buildDetailRow('KBZ Pay', '097905•••••', textColor),
            _buildDetailRow('AYA Pay', '097905•••••', textColor),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(const ClipboardData(text: '09790588195'));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Phone number copied!')),
                );
              },
              icon: const Icon(Icons.copy, color: Colors.white),
              label: const Text(
                'Copy Phone Number',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String maskedValue, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          Text(
            maskedValue,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: textColor.withValues(alpha: 0.6),
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
