import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:munajat_e_maqbool_app/providers/ramadan_provider.dart';
import 'package:munajat_e_maqbool_app/providers/settings_provider.dart';
import 'package:munajat_e_maqbool_app/services/prayer_time_service.dart';
import 'package:munajat_e_maqbool_app/utils/haptic_feedback_helper.dart';
import 'package:adhan/adhan.dart';
import 'package:munajat_e_maqbool_app/screens/zakat_calculator_screen.dart';
import '../config/glass_theme.dart';
import '../widgets/glass/glass_scaffold.dart';
import '../widgets/glass/glass_card.dart';

class RamadanScreen extends StatefulWidget {
  const RamadanScreen({super.key});

  @override
  State<RamadanScreen> createState() => _RamadanScreenState();
}

class _RamadanScreenState extends State<RamadanScreen> {
  late DateTime _currentDate;

  @override
  void initState() {
    super.initState();
    _currentDate = DateTime.now();
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
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(textColor, accentColor),
                  _buildTimingsCard(isDark, settingsProvider),
                  _buildFastingTracker(isDark, textColor, accentColor),
                  _buildAshraDuas(isDark, textColor),
                  _buildDeedsChecklist(isDark, textColor, accentColor),
                  _buildZakatEntry(isDark, textColor),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(Color textColor, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ramadan Kareem',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'May Allah accept our fasts',
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedbackHelper.lightImpact();
              _showSettingsDialog(context);
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.settings_rounded, color: accentColor, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimingsCard(bool isDark, SettingsProvider settings) {
    final service = PrayerTimeService();
    final prayerTimes = service.calculatePrayerTimes(
      date: DateTime.now(),
      latitude: settings.appSettings.prayerLatitude ?? 21.4225,
      longitude: settings.appSettings.prayerLongitude ?? 96.0836,
      asrMethod: settings.appSettings.prayerAsrMethod == 'shafi'
          ? Madhab.shafi
          : Madhab.hanafi,
      method: settings.appSettings.prayerCalculationMethod != null
          ? CalculationMethod.values.firstWhere(
              (m) => m.name == settings.appSettings.prayerCalculationMethod,
              orElse: () => CalculationMethod.other,
            )
          : CalculationMethod.karachi,
    );

    return Consumer<RamadanProvider>(
      builder: (context, ramadanProvider, _) {
        final sehriTime = DateFormat('h:mm a').format(
          prayerTimes.fajr.add(Duration(minutes: ramadanProvider.sehriOffset)),
        );
        final iftarTime = DateFormat('h:mm a').format(
          prayerTimes.maghrib.add(
            Duration(minutes: ramadanProvider.iftarOffset),
          ),
        );
        final accentColor = GlassTheme.accent(isDark);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: GlassCard(
            isDark: isDark,
            borderRadius: 24,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accentColor.withValues(alpha: 0.15),
                    accentColor.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildTimeColumn(
                    'Sehri Ends',
                    sehriTime,
                    Icons.wb_twilight_rounded,
                    isDark,
                  ),
                  Container(
                    height: 40,
                    width: 1,
                    color: GlassTheme.text(isDark).withValues(alpha: 0.2),
                  ),
                  _buildTimeColumn(
                    'Iftar Time',
                    iftarTime,
                    Icons.wb_sunny_rounded,
                    isDark,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimeColumn(
    String label,
    String time,
    IconData icon,
    bool isDark,
  ) {
    final textColor = GlassTheme.text(isDark);
    final accentColor = GlassTheme.accent(isDark);
    return Column(
      children: [
        Icon(icon, color: accentColor, size: 24),
        const SizedBox(height: 8),
        Text(
          time,
          style: TextStyle(
            color: textColor,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: textColor.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildFastingTracker(bool isDark, Color textColor, Color accentColor) {
    return Consumer<RamadanProvider>(
      builder: (context, provider, _) {
        return Container(
          margin: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fasting Tracker',
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              GlassCard(
                isDark: isDark,
                borderRadius: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildTrackerButton(
                      'Fasted',
                      Icons.check_circle_outline,
                      const Color(0xFF4CAF50),
                      provider.getFastingStatus(_currentDate) == 'fasted',
                      textColor,
                      () => provider.setFastingStatus(_currentDate, 'fasted'),
                    ),
                    _buildTrackerButton(
                      'Missed',
                      Icons.cancel_outlined,
                      const Color(0xFFE57373),
                      provider.getFastingStatus(_currentDate) == 'missed',
                      textColor,
                      () => provider.setFastingStatus(_currentDate, 'missed'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrackerButton(
    String label,
    IconData icon,
    Color color,
    bool isSelected,
    Color textColor,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedbackHelper.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.2)
              : textColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : textColor.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : textColor.withValues(alpha: 0.6),
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : textColor.withValues(alpha: 0.8),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAshraDuas(bool isDark, Color textColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ashra Duas',
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              children: [
                _buildAshraCard(
                  '1st Ashra (Mercy)',
                  'رَبِّ اغْفِرْ وَارْحَمْ وَأَنْتَ خَيْرُ الرَّاحِمِينَ',
                  'My Lord! Forgive and have mercy, for You are the Best of those who show mercy.',
                  const Color(0xFF4CAF50),
                  isDark,
                ),
                _buildAshraCard(
                  '2nd Ashra (Forgiveness)',
                  'أَسْتَغْفِرُ اللهَ رَبِّي مِنْ كُلِّ ذَنْبٍ وَأَتُوبُ إِلَيْهِ',
                  'I seek forgiveness from Allah, my Lord, from every sin and I turn to Him in repentance.',
                  const Color(0xFF2196F3),
                  isDark,
                ),
                _buildAshraCard(
                  '3rd Ashra (Refuge)',
                  'اللَّهُمَّ أَجِرْنِي مِنَ النَّارِ',
                  'O Allah, save me from the fire of Hell.',
                  const Color(0xFFFF9800),
                  isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAshraCard(
    String title,
    String arabic,
    String translation,
    Color color,
    bool isDark,
  ) {
    final textColor = GlassTheme.text(isDark);
    return Container(
      width: 300,
      margin: const EdgeInsets.only(right: 16),
      child: GlassCard(
        isDark: isDark,
        borderRadius: 20,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.15),
                color.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    arabic,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Indopak',
                      color: textColor,
                      fontSize: 22,
                      letterSpacing: 0,
                      height: 1.5,
                    ),
                    textDirection: ui.TextDirection.rtl,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  translation,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeedsChecklist(bool isDark, Color textColor, Color accentColor) {
    final deeds = [
      {'id': 'fajr', 'label': 'Pray Fajr'},
      {'id': 'quran', 'label': 'Read Quran'},
      {'id': 'charity', 'label': 'Give Sadaqah'},
      {'id': 'taraweeh', 'label': 'Pray Taraweeh'},
      {'id': 'dhikr', 'label': 'Morning/Evening Adhkar'},
    ];

    return Consumer<RamadanProvider>(
      builder: (context, provider, _) {
        return Container(
          margin: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Daily Deeds',
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              GlassCard(
                isDark: isDark,
                borderRadius: 20,
                padding: EdgeInsets.zero,
                child: Column(
                  children: deeds.map((deed) {
                    final isCompleted = provider.isDeedCompleted(
                      _currentDate,
                      deed['id']!,
                    );
                    return ListTile(
                      onTap: () {
                        HapticFeedbackHelper.lightImpact();
                        provider.toggleDeed(_currentDate, deed['id']!);
                      },
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? accentColor.withValues(alpha: 0.2)
                              : textColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCompleted ? Icons.check : Icons.circle_outlined,
                          color: isCompleted
                              ? accentColor
                              : textColor.withValues(alpha: 0.3),
                          size: 20,
                        ),
                      ),
                      title: Text(
                        deed['label']!,
                        style: TextStyle(
                          color: isCompleted
                              ? textColor
                              : textColor.withValues(alpha: 0.7),
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: textColor.withValues(alpha: 0.3),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildZakatEntry(bool isDark, Color textColor) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ZakatCalculatorScreen()),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: GlassCard(
          isDark: isDark,
          borderRadius: 20,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF00BCD4).withValues(alpha: 0.15),
                  const Color(0xFF00BCD4).withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00BCD4).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.calculate_rounded,
                      color: Color(0xFF00BCD4),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Zakat Calculator',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Calculate your Zakat easily',
                          style: TextStyle(
                            color: textColor.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: textColor.withValues(alpha: 0.5),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    final isDark = Provider.of<SettingsProvider>(
      context,
      listen: false,
    ).isDarkMode;
    final textColor = GlassTheme.text(isDark);
    final accentColor = GlassTheme.accent(isDark);

    showDialog(
      context: context,
      builder: (context) => Consumer<RamadanProvider>(
        builder: (context, provider, _) {
          return AlertDialog(
            backgroundColor: GlassTheme.background(isDark),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: accentColor.withValues(alpha: 0.3)),
            ),
            title: Text('Ramadan Timings', style: TextStyle(color: textColor)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildOffsetControl(
                  'Sehri Offset',
                  provider.sehriOffset,
                  (val) => provider.updateTimeOffsets(sehri: val),
                  textColor,
                ),
                const SizedBox(height: 16),
                _buildOffsetControl(
                  'Iftar Offset',
                  provider.iftarOffset,
                  (val) => provider.updateTimeOffsets(iftar: val),
                  textColor,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Done', style: TextStyle(color: accentColor)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOffsetControl(
    String label,
    int value,
    Function(int) onChanged,
    Color textColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: textColor.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: textColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: textColor.withValues(alpha: 0.1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(
                  Icons.remove_rounded,
                  color: textColor.withValues(alpha: 0.7),
                ),
                onPressed: () {
                  HapticFeedbackHelper.lightImpact();
                  onChanged(value - 1);
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Text(
                '${value > 0 ? '+' : ''}$value min',
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: Icon(
                  Icons.add_rounded,
                  color: textColor.withValues(alpha: 0.7),
                ),
                onPressed: () {
                  HapticFeedbackHelper.lightImpact();
                  onChanged(value + 1);
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
