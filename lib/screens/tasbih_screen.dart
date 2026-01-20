import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:munajat_e_maqbool_app/utils/haptic_feedback_helper.dart';
import '../providers/settings_provider.dart';
import '../config/glass_theme.dart';
import '../widgets/glass/glass_scaffold.dart';
import '../widgets/glass/glass_card.dart';

class TasbihScreen extends StatefulWidget {
  const TasbihScreen({super.key});

  @override
  State<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends State<TasbihScreen>
    with TickerProviderStateMixin {
  int _count = 0;
  int _target = 33;
  int _totalCount = 0;
  int _currentDhikrIndex = 0;
  String _currentDhikr = 'سُبْحَانَ ٱللَّٰهِ';
  String _currentDhikrTranslation = 'SubhanAllah';
  String _currentDhikrMeaning = 'Glory be to Allah';

  late AnimationController _pulseController;
  late AnimationController _rippleController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rippleAnimation;

  final List<Map<String, dynamic>> _dhikrList = [
    {
      'arabic': 'سُبْحَانَ ٱللَّٰهِ',
      'translation': 'SubhanAllah',
      'meaning': 'Glory be to Allah',
      'color': const Color(0xFF4CAF50),
    },
    {
      'arabic': 'ٱلْحَمْدُ لِلَّٰهِ',
      'translation': 'Alhamdulillah',
      'meaning': 'Praise be to Allah',
      'color': const Color(0xFF2196F3),
    },
    {
      'arabic': 'ٱللَّٰهُ أَكْبَرُ',
      'translation': 'Allahu Akbar',
      'meaning': 'Allah is the Greatest',
      'color': const Color(0xFFFF9800),
    },
    {
      'arabic': 'لَا إِلَٰهَ إِلَّا ٱللَّٰهُ',
      'translation': 'La ilaha illallah',
      'meaning': 'There is no god but Allah',
      'color': const Color(0xFF9C27B0),
    },
    {
      'arabic': 'أَسْتَغْفِرُ ٱللَّٰهَ',
      'translation': 'Astaghfirullah',
      'meaning': 'I seek forgiveness from Allah',
      'color': const Color(0xFFE91E63),
    },
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _rippleAnimation = Tween<double>(begin: 0.8, end: 1.5).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );
    _loadData();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rippleController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final customDhikrJson = prefs.getString('custom_dhikr_list');
    if (customDhikrJson != null) {
      final List<dynamic> decoded = jsonDecode(customDhikrJson);
      _dhikrList.addAll(
        decoded.map((e) => Map<String, dynamic>.from(e)).toList(),
      );
    }
    setState(() {
      _count = prefs.getInt('tasbih_count') ?? 0;
      _totalCount = prefs.getInt('tasbih_total') ?? 0;
      _target = prefs.getInt('tasbih_target') ?? 33;
      _currentDhikrIndex = prefs.getInt('tasbih_dhikr_index') ?? 0;
      _updateDhikr();
    });
  }

  Future<void> _saveCustomDhikr() async {
    final prefs = await SharedPreferences.getInstance();
    final customList = _dhikrList.skip(5).toList();
    await prefs.setString('custom_dhikr_list', jsonEncode(customList));
  }

  void _updateDhikr() {
    if (_currentDhikrIndex >= _dhikrList.length) {
      _currentDhikrIndex = 0;
    }
    final dhikr = _dhikrList[_currentDhikrIndex];
    _currentDhikr = dhikr['arabic'];
    _currentDhikrTranslation = dhikr['translation'];
    _currentDhikrMeaning = dhikr['meaning'] ?? '';
  }

  void _nextDhikr() {
    HapticFeedbackHelper.lightImpact();
    setState(() {
      _currentDhikrIndex = (_currentDhikrIndex + 1) % _dhikrList.length;
      _updateDhikr();
    });
    _saveDhikrIndex();
  }

  void _previousDhikr() {
    HapticFeedbackHelper.lightImpact();
    setState(() {
      _currentDhikrIndex =
          (_currentDhikrIndex - 1 + _dhikrList.length) % _dhikrList.length;
      _updateDhikr();
    });
    _saveDhikrIndex();
  }

  Future<void> _saveDhikrIndex() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('tasbih_dhikr_index', _currentDhikrIndex);
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('tasbih_count', _count);
    await prefs.setInt('tasbih_total', _totalCount);
    await prefs.setInt('tasbih_target', _target);
  }

  void _increment() {
    try {
      Vibration.vibrate(duration: 30);
    } catch (e) {
      // Vibration not supported
    }

    _pulseController.forward().then((_) => _pulseController.reverse());
    _rippleController.forward(from: 0);

    setState(() {
      _count++;
      _totalCount++;
    });

    if (_count >= _target) {
      _showCompletionDialog();
    }

    _saveData();
  }

  void _reset() {
    HapticFeedbackHelper.buttonPress();
    setState(() {
      _count = 0;
    });
    _saveData();
  }

  double get _progress =>
      _target > 0 ? (_count / _target).clamp(0.0, 1.0) : 0.0;

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        final isDark = settingsProvider.isDarkMode;
        final textColor = GlassTheme.text(isDark);
        // Use the dhikr-specific color as accent, or fallback to theme accent
        final effectiveAccentColor =
            _dhikrList[_currentDhikrIndex]['color'] as Color? ??
            GlassTheme.accent(isDark);

        return GlassScaffold(
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(isDark, textColor, effectiveAccentColor),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 100),
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          _buildDhikrCard(
                            isDark,
                            textColor,
                            effectiveAccentColor,
                          ),
                          const SizedBox(height: 32),
                          _buildCounterDisplay(
                            isDark,
                            textColor,
                            effectiveAccentColor,
                          ),
                          const SizedBox(height: 32),
                          _buildTapButton(effectiveAccentColor),
                          const SizedBox(height: 24),
                          _buildControlButtons(
                            isDark,
                            textColor,
                            effectiveAccentColor,
                          ),
                          const SizedBox(height: 24),
                          _buildQuickTargets(
                            isDark,
                            textColor,
                            effectiveAccentColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isDark, Color textColor, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.touch_app_rounded, color: accentColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Digital Tasbih',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Today\'s total: $_totalCount',
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          GlassCard(
            isDark: isDark,
            borderRadius: 12,
            padding: EdgeInsets.zero,
            child: IconButton(
              icon: Icon(Icons.list_alt_rounded, color: textColor),
              onPressed: _showDhikrDialog,
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDhikrCard(bool isDark, Color textColor, Color accentColor) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! > 0) {
          _previousDhikr();
        } else if (details.primaryVelocity! < 0) {
          _nextDhikr();
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: GlassCard(
          isDark: isDark,
          borderRadius: 24,
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Arabic Text
              Text(
                _currentDhikr,
                style: TextStyle(
                  fontFamily: 'Indopak',
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 38,
                  letterSpacing: 0,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 12),
              // Translation
              Text(
                _currentDhikrTranslation,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              // Meaning
              Text(
                _currentDhikrMeaning,
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              // Dhikr Navigation Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _previousDhikr,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: textColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.chevron_left_rounded,
                        color: textColor.withValues(alpha: 0.7),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Row(
                    children: List.generate(
                      _dhikrList.length.clamp(0, 5),
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: index == _currentDhikrIndex % 5 ? 20 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: index == _currentDhikrIndex % 5
                              ? accentColor
                              : textColor.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _nextDhikr,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: textColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: textColor.withValues(alpha: 0.7),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCounterDisplay(bool isDark, Color textColor, Color accentColor) {
    return Column(
      children: [
        // Progress Ring with Count
        SizedBox(
          width: 180,
          height: 180,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Rotating decorative ring
              AnimatedBuilder(
                animation: _rotationController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotationController.value * 2 * math.pi,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: textColor.withValues(alpha: 0.05),
                          width: 2,
                        ),
                      ),
                      child: CustomPaint(
                        painter: _DottedCirclePainter(
                          color: accentColor.withValues(alpha: 0.3),
                          dotCount: 33,
                        ),
                      ),
                    ),
                  );
                },
              ),
              // Background ring
              SizedBox(
                width: 160,
                height: 160,
                child: CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 8,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    textColor.withValues(alpha: 0.1),
                  ),
                ),
              ),
              // Progress ring
              SizedBox(
                width: 160,
                height: 160,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: _progress),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return CircularProgressIndicator(
                      value: value,
                      strokeWidth: 8,
                      strokeCap: StrokeCap.round,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                    );
                  },
                ),
              ),
              // Count Display
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Text(
                          '$_count',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 52,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: accentColor.withValues(alpha: 0.5),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  Text(
                    'of $_target',
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.5),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Percentage
        Text(
          '${(_progress * 100).toInt()}% Complete',
          style: TextStyle(
            color: accentColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTapButton(Color accentColor) {
    return GestureDetector(
      onTap: _increment,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ripple effect
          AnimatedBuilder(
            animation: _rippleController,
            builder: (context, child) {
              return Transform.scale(
                scale: _rippleAnimation.value,
                child: Opacity(
                  opacity: (1 - _rippleController.value).clamp(0.0, 1.0),
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: accentColor, width: 3),
                    ),
                  ),
                ),
              );
            },
          ),
          // Main button
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [accentColor, accentColor.withValues(alpha: 0.7)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.5),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons(bool isDark, Color textColor, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            isDark: isDark,
            textColor: textColor,
            icon: Icons.refresh_rounded,
            label: 'Reset',
            onTap: _reset,
          ),
          _buildControlButton(
            isDark: isDark,
            textColor: textColor,
            icon: Icons.flag_rounded,
            label: 'Target',
            onTap: _showTargetDialog,
          ),
          _buildControlButton(
            isDark: isDark,
            textColor: textColor,
            icon: Icons.add_circle_outline_rounded,
            label: 'Add',
            onTap: _showAddDhikrDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required bool isDark,
    required Color textColor,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GlassCard(
      isDark: isDark,
      borderRadius: 16,
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: [
            Icon(icon, color: textColor.withValues(alpha: 0.8), size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: textColor.withValues(alpha: 0.6),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickTargets(bool isDark, Color textColor, Color accentColor) {
    final targets = [33, 99, 100];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Targets',
            style: TextStyle(
              color: textColor.withValues(alpha: 0.6),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: targets.map((t) {
              final isSelected = _target == t;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedbackHelper.lightImpact();
                    setState(() => _target = t);
                    _saveData();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? accentColor.withValues(alpha: 0.2)
                          : textColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? accentColor
                            : textColor.withValues(alpha: 0.1),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$t',
                        style: TextStyle(
                          color: isSelected ? accentColor : textColor,
                          fontSize: 16,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _showCompletionDialog() {
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    final isDark = settingsProvider.isDarkMode;
    final textColor = GlassTheme.text(isDark);
    final accentColor =
        _dhikrList[_currentDhikrIndex]['color'] as Color? ??
        GlassTheme.accent(isDark);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassCard(
          isDark: isDark,
          borderRadius: 24,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.celebration_rounded,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'MashaAllah!',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'You completed $_target dhikr',
                  style: TextStyle(fontSize: 16, color: textColor),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: textColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.stars_rounded, color: accentColor),
                      const SizedBox(width: 8),
                      Text(
                        'Total Today: $_totalCount',
                        style: TextStyle(fontSize: 14, color: accentColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Close',
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _reset();
                      },
                      child: const Text(
                        'Continue',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTargetDialog() {
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    final isDark = settingsProvider.isDarkMode;
    final textColor = GlassTheme.text(isDark);
    final accentColor =
        _dhikrList[_currentDhikrIndex]['color'] as Color? ??
        GlassTheme.accent(isDark);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassCard(
          isDark: isDark,
          borderRadius: 24,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.flag_rounded, color: accentColor),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Set Target',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTargetOption(
                  33,
                  'Sunnah (After Salah)',
                  isDark,
                  textColor,
                  accentColor,
                ),
                _buildTargetOption(
                  99,
                  'Names of Allah',
                  isDark,
                  textColor,
                  accentColor,
                ),
                _buildTargetOption(
                  100,
                  'Century',
                  isDark,
                  textColor,
                  accentColor,
                ),
                _buildTargetOption(
                  1000,
                  'Advanced',
                  isDark,
                  textColor,
                  accentColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTargetOption(
    int value,
    String label,
    bool isDark,
    Color textColor,
    Color accentColor,
  ) {
    final isSelected = _target == value;
    return InkWell(
      onTap: () {
        setState(() => _target = value);
        _saveData();
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.2)
              : textColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? accentColor : textColor.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? accentColor
                    : textColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  '$value',
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : textColor.withValues(alpha: 0.7),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? accentColor : textColor,
                ),
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: accentColor),
          ],
        ),
      ),
    );
  }

  void _showDhikrDialog() {
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    final isDark = settingsProvider.isDarkMode;
    final textColor = GlassTheme.text(isDark);
    final accentColor =
        _dhikrList[_currentDhikrIndex]['color'] as Color? ??
        GlassTheme.accent(isDark);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassCard(
          isDark: isDark,
          borderRadius: 24,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.format_quote_rounded,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Select Dhikr',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _dhikrList.length,
                    itemBuilder: (context, index) {
                      final dhikr = _dhikrList[index];
                      final isSelected = index == _currentDhikrIndex;
                      final color = dhikr['color'] as Color;
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _currentDhikrIndex = index;
                            _updateDhikr();
                          });
                          _saveDhikrIndex();
                          Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withValues(alpha: 0.2)
                                : textColor.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? color
                                  : textColor.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      dhikr['arabic'],
                                      style: TextStyle(
                                        fontFamily: 'Indopak',
                                        fontSize: 18,
                                        color: textColor,
                                        letterSpacing: 0,
                                      ),
                                      textDirection: TextDirection.rtl,
                                    ),
                                    Text(
                                      dhikr['translation'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(Icons.check_circle, color: color),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddDhikrDialog() {
    final arabicController = TextEditingController();
    final translationController = TextEditingController();
    final meaningController = TextEditingController();

    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    final isDark = settingsProvider.isDarkMode;
    final textColor = GlassTheme.text(isDark);
    final accentColor =
        _dhikrList[_currentDhikrIndex]['color'] as Color? ??
        GlassTheme.accent(isDark);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassCard(
          isDark: isDark,
          borderRadius: 24,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Add Custom Dhikr',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: arabicController,
                  decoration: InputDecoration(
                    labelText: 'Arabic Text',
                    labelStyle: TextStyle(
                      color: textColor.withValues(alpha: 0.6),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: textColor.withValues(alpha: 0.2),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: accentColor),
                    ),
                  ),
                  style: TextStyle(
                    fontFamily: 'Indopak',
                    fontSize: 20,
                    color: textColor,
                  ),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: translationController,
                  decoration: InputDecoration(
                    labelText: 'Translation',
                    labelStyle: TextStyle(
                      color: textColor.withValues(alpha: 0.6),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: textColor.withValues(alpha: 0.2),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: accentColor),
                    ),
                  ),
                  style: TextStyle(color: textColor),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: meaningController,
                  decoration: InputDecoration(
                    labelText: 'Meaning',
                    labelStyle: TextStyle(
                      color: textColor.withValues(alpha: 0.6),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: textColor.withValues(alpha: 0.2),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: accentColor),
                    ),
                  ),
                  style: TextStyle(color: textColor),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        if (arabicController.text.isNotEmpty) {
                          setState(() {
                            _dhikrList.add({
                              'arabic': arabicController.text,
                              'translation': translationController.text,
                              'meaning': meaningController.text,
                              'color': const Color(
                                0xFFE0B40A,
                              ), // Default to gold for custom
                            });
                          });
                          _saveCustomDhikr();
                          Navigator.pop(context);
                        }
                      },
                      child: const Text(
                        'Add',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Custom painter for dotted circle decoration
class _DottedCirclePainter extends CustomPainter {
  final Color color;
  final int dotCount;

  _DottedCirclePainter({required this.color, required this.dotCount});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    for (int i = 0; i < dotCount; i++) {
      final angle = (2 * math.pi * i) / dotCount;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      canvas.drawCircle(Offset(x, y), 2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
