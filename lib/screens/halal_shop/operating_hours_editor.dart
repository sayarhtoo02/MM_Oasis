import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:munajat_e_maqbool_app/config/glass_theme.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_card.dart';
import 'package:munajat_e_maqbool_app/providers/settings_provider.dart';

class OperatingHoursEditor extends StatefulWidget {
  final Map<String, dynamic> initialHours;
  final Function(Map<String, dynamic>) onSave;

  const OperatingHoursEditor({
    super.key,
    required this.initialHours,
    required this.onSave,
  });

  @override
  State<OperatingHoursEditor> createState() => _OperatingHoursEditorState();
}

class _OperatingHoursEditorState extends State<OperatingHoursEditor> {
  late Map<String, dynamic> _hours;

  final List<String> _days = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  final Map<String, String> _dayLabels = {
    'monday': 'Monday',
    'tuesday': 'Tuesday',
    'wednesday': 'Wednesday',
    'thursday': 'Thursday',
    'friday': 'Friday',
    'saturday': 'Saturday',
    'sunday': 'Sunday',
  };

  @override
  void initState() {
    super.initState();
    _hours = Map<String, dynamic>.from(widget.initialHours);
    // Initialize defaults if empty
    for (final day in _days) {
      if (!_hours.containsKey(day)) {
        _hours[day] = {'open': '09:00', 'close': '21:00', 'closed': false};
      }
    }
  }

  void _save() {
    widget.onSave(_hours);
    Navigator.pop(context);
  }

  Future<void> _selectTime(String day, String field) async {
    final currentTime = _hours[day][field] as String? ?? '09:00';
    final parts = currentTime.split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      setState(() {
        _hours[day][field] =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final isDark = settings.isDarkMode;
        final textColor = GlassTheme.text(isDark);
        final accentColor = GlassTheme.accent(isDark);

        return Scaffold(
          backgroundColor: isDark
              ? const Color(0xFF121212)
              : const Color(0xFFF5F5F5),
          appBar: AppBar(
            title: Text('Operating Hours', style: TextStyle(color: textColor)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: textColor),
            actions: [
              TextButton(
                onPressed: _save,
                child: Text(
                  'Save',
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          body: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _days.length,
            itemBuilder: (context, index) {
              final day = _days[index];
              return _buildDayRow(day, isDark, textColor, accentColor);
            },
          ),
        );
      },
    );
  }

  Widget _buildDayRow(
    String day,
    bool isDark,
    Color textColor,
    Color accentColor,
  ) {
    final dayData = _hours[day] as Map<String, dynamic>? ?? {};
    final isClosed = dayData['closed'] as bool? ?? false;
    final openTime = dayData['open'] as String? ?? '09:00';
    final closeTime = dayData['close'] as String? ?? '21:00';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        isDark: isDark,
        borderRadius: 12,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _dayLabels[day] ?? day,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Switch(
                    value: !isClosed,
                    activeThumbColor: accentColor,
                    onChanged: (open) {
                      setState(() {
                        _hours[day]['closed'] = !open;
                      });
                    },
                  ),
                  Text(
                    isClosed ? 'Closed' : 'Open',
                    style: TextStyle(
                      color: isClosed ? Colors.red : Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (!isClosed) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildTimeButton(
                        label: 'Opens',
                        time: openTime,
                        onTap: () => _selectTime(day, 'open'),
                        textColor: textColor,
                        accentColor: accentColor,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Icon(Icons.arrow_forward, size: 20),
                    ),
                    Expanded(
                      child: _buildTimeButton(
                        label: 'Closes',
                        time: closeTime,
                        onTap: () => _selectTime(day, 'close'),
                        textColor: textColor,
                        accentColor: accentColor,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeButton({
    required String label,
    required String time,
    required VoidCallback onTap,
    required Color textColor,
    required Color accentColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: accentColor.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: textColor.withValues(alpha: 0.5),
                fontSize: 10,
              ),
            ),
            Text(
              time,
              style: TextStyle(
                color: accentColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
