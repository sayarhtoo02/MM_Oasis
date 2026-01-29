import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/reading_stats_service.dart';
import '../config/glass_theme.dart';
import '../providers/settings_provider.dart';
import '../providers/quran_provider.dart';
import '../widgets/glass/glass_card.dart';

class KhatamPlannerScreen extends StatefulWidget {
  const KhatamPlannerScreen({super.key});

  @override
  State<KhatamPlannerScreen> createState() => _KhatamPlannerScreenState();
}

class _KhatamPlannerScreenState extends State<KhatamPlannerScreen> {
  DateTime _targetDate = DateTime.now().add(const Duration(days: 30));
  Map<String, dynamic>? _calculations;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _calculate() async {
    final result = await ReadingStatsService.getKhatamCalculations(_targetDate);
    setState(() {
      _calculations = result;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _targetDate,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        final isDark = Provider.of<SettingsProvider>(context).isDarkMode;
        return Theme(
          data: isDark ? ThemeData.dark() : ThemeData.light(),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _targetDate) {
      setState(() {
        _targetDate = picked;
      });
      _calculate();
    }
  }

  Future<void> _showResetConfirmation(BuildContext context) async {
    final isDark = Provider.of<SettingsProvider>(
      context,
      listen: false,
    ).isDarkMode;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: GlassTheme.background(isDark),
        title: Text(
          'Reset All Tracking?',
          style: TextStyle(color: GlassTheme.accent(isDark)),
        ),
        content: Text(
          'This will permanently delete all your reading statistics, streaks, and Khatam plans. This action cannot be undone.',
          style: TextStyle(
            color: GlassTheme.text(isDark).withValues(alpha: 0.8),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: GlassTheme.text(isDark).withValues(alpha: 0.6),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<QuranProvider>().resetTracking();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All tracking data has been reset')),
      );
      Navigator.pop(context); // Close the screen after reset
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<SettingsProvider>(context).isDarkMode;
    final textColor = GlassTheme.text(isDark);
    final accentColor = GlassTheme.accent(isDark);
    final backgroundColor = GlassTheme.background(isDark);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        systemOverlayStyle: GlassTheme.systemOverlayStyle(isDark),
        foregroundColor: accentColor,
        title: Text(
          'Khatam Planner',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reset Tracking',
            onPressed: () => _showResetConfirmation(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTargetCard(isDark, textColor, accentColor),
            const SizedBox(height: 24),
            if (_calculations != null && _calculations!['error'] == null)
              _buildResults(isDark, textColor, accentColor)
            else if (_calculations != null)
              Center(
                child: Text(
                  _calculations!['error'],
                  style: const TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetCard(bool isDark, Color textColor, Color accentColor) {
    return GlassCard(
      isDark: isDark,
      padding: const EdgeInsets.all(24),
      borderRadius: 24,
      child: Column(
        children: [
          Icon(Icons.flag_rounded, color: accentColor, size: 48),
          const SizedBox(height: 16),
          Text(
            'When do you want to finish?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Set your goal date for Quran completion',
            style: TextStyle(
              fontSize: 14,
              color: textColor.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          InkWell(
            onTap: () => _selectDate(context),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: accentColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_month, color: accentColor, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    '${_targetDate.day}/${_targetDate.month}/${_targetDate.year}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(bool isDark, Color textColor, Color accentColor) {
    final days = _calculations!['remaining_days'];
    final verses = _calculations!['verses_per_day'];
    final pages = _calculations!['pages_per_day'];
    final juz = (_calculations!['juz_per_day'] as double).toStringAsFixed(2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daily Requirement',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 16),
        _buildStatRow(
          Icons.timer_outlined,
          'Remaining Days',
          '$days days',
          isDark,
          textColor,
          accentColor,
        ),
        const SizedBox(height: 12),
        _buildStatRow(
          Icons.menu_book_rounded,
          'Pages per day',
          '$pages pages',
          isDark,
          textColor,
          accentColor,
        ),
        const SizedBox(height: 12),
        _buildStatRow(
          Icons.format_list_numbered_rounded,
          'Verses per day',
          '$verses verses',
          isDark,
          textColor,
          accentColor,
        ),
        const SizedBox(height: 12),
        _buildStatRow(
          Icons.auto_stories_rounded,
          'Juz per day',
          '$juz Juz',
          isDark,
          textColor,
          accentColor,
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () {
            // Save plan logic here
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Khatam Plan saved successfully')),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: isDark ? Colors.black : Colors.white,
            padding: const EdgeInsets.all(20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 8,
            shadowColor: accentColor.withValues(alpha: 0.5),
          ),
          child: const Center(
            child: Text(
              'Start My Plan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(
    IconData icon,
    String label,
    String value,
    bool isDark,
    Color textColor,
    Color accentColor,
  ) {
    return GlassCard(
      isDark: isDark,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      borderRadius: 16,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: textColor.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accentColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: textColor, fontSize: 15),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
