import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:munajat_e_maqbool_app/providers/ramadan_provider.dart';
import 'package:munajat_e_maqbool_app/providers/settings_provider.dart';
import 'package:munajat_e_maqbool_app/utils/haptic_feedback_helper.dart';
import '../config/glass_theme.dart';
import '../widgets/glass/glass_scaffold.dart';
import '../widgets/glass/glass_card.dart';

class ZakatCalculatorScreen extends StatefulWidget {
  const ZakatCalculatorScreen({super.key});

  @override
  State<ZakatCalculatorScreen> createState() => _ZakatCalculatorScreenState();
}

class _ZakatCalculatorScreenState extends State<ZakatCalculatorScreen> {
  final _goldController = TextEditingController();
  final _silverController = TextEditingController();
  final _cashController = TextEditingController();
  final _assetsController = TextEditingController();
  final _liabilitiesController = TextEditingController();

  double _totalAssets = 0;
  double _zakatPayable = 0;

  @override
  void dispose() {
    _goldController.dispose();
    _silverController.dispose();
    _cashController.dispose();
    _assetsController.dispose();
    _liabilitiesController.dispose();
    super.dispose();
  }

  void _calculateZakat() {
    HapticFeedbackHelper.lightImpact();

    final provider = context.read<RamadanProvider>();
    final goldValue =
        (double.tryParse(_goldController.text) ?? 0) * provider.goldPrice;
    final silverValue =
        (double.tryParse(_silverController.text) ?? 0) * provider.silverPrice;
    final cash = double.tryParse(_cashController.text) ?? 0;
    final otherAssets = double.tryParse(_assetsController.text) ?? 0;
    final liabilities = double.tryParse(_liabilitiesController.text) ?? 0;

    setState(() {
      _totalAssets = goldValue + silverValue + cash + otherAssets - liabilities;
      if (_totalAssets > 0) {
        _zakatPayable = _totalAssets * 0.025;
      } else {
        _zakatPayable = 0;
      }
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
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(textColor),
                  const SizedBox(height: 20),
                  _buildSettingsCard(isDark, textColor),
                  const SizedBox(height: 20),
                  _buildInputSection(isDark, textColor, accentColor),
                  const SizedBox(height: 20),
                  _buildResultCard(isDark, textColor),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(Color textColor) {
    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Zakat Calculator',
              style: TextStyle(
                color: textColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Calculate your 2.5% obligation',
              style: TextStyle(
                color: textColor.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSettingsCard(bool isDark, Color textColor) {
    return Consumer<RamadanProvider>(
      builder: (context, provider, _) {
        return GlassCard(
          isDark: isDark,
          borderRadius: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gold & Silver Prices (per gram)',
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildPriceInput(
                      'Gold Price',
                      provider.goldPrice.toString(),
                      (val) => provider.updateZakatSettings(
                        goldPrice: double.tryParse(val),
                      ),
                      isDark,
                      textColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildPriceInput(
                      'Silver Price',
                      provider.silverPrice.toString(),
                      (val) => provider.updateZakatSettings(
                        silverPrice: double.tryParse(val),
                      ),
                      isDark,
                      textColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPriceInput(
    String label,
    String initialValue,
    Function(String) onChanged,
    bool isDark,
    Color textColor,
  ) {
    return TextFormField(
      initialValue: initialValue == '0.0' ? '' : initialValue,
      keyboardType: TextInputType.number,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: textColor.withValues(alpha: 0.7)),
        filled: true,
        fillColor: textColor.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildInputSection(bool isDark, Color textColor, Color accentColor) {
    return Column(
      children: [
        _buildInputField(
          'Gold (grams)',
          _goldController,
          Icons.monetization_on_outlined,
          isDark,
          textColor,
        ),
        const SizedBox(height: 12),
        _buildInputField(
          'Silver (grams)',
          _silverController,
          Icons.money_rounded,
          isDark,
          textColor,
        ),
        const SizedBox(height: 12),
        _buildInputField(
          'Cash in Hand/Bank',
          _cashController,
          Icons.account_balance_wallet_outlined,
          isDark,
          textColor,
        ),
        const SizedBox(height: 12),
        _buildInputField(
          'Other Assets (Value)',
          _assetsController,
          Icons.business_center_outlined,
          isDark,
          textColor,
        ),
        const SizedBox(height: 12),
        _buildInputField(
          'Liabilities/Debts',
          _liabilitiesController,
          Icons.money_off_outlined,
          isDark,
          textColor,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _calculateZakat,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00BCD4),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Calculate Zakat',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller,
    IconData icon,
    bool isDark,
    Color textColor,
  ) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: textColor.withValues(alpha: 0.7)),
        prefixIcon: Icon(icon, color: textColor.withValues(alpha: 0.7)),
        filled: true,
        fillColor: textColor.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildResultCard(bool isDark, Color textColor) {
    return GlassCard(
      isDark: isDark,
      borderRadius: 24,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF00BCD4).withValues(alpha: 0.15),
              const Color(0xFF00BCD4).withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            children: [
              Text(
                'Total Zakat Payable',
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _zakatPayable.toStringAsFixed(2),
                style: TextStyle(
                  color: textColor,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: textColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Net Assets',
                      style: TextStyle(color: textColor.withValues(alpha: 0.7)),
                    ),
                    Text(
                      _totalAssets.toStringAsFixed(2),
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
