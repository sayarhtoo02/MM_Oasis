import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:munajat_e_maqbool_app/config/glass_theme.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_card.dart';
import 'package:munajat_e_maqbool_app/widgets/app_background_pattern.dart';
import 'package:munajat_e_maqbool_app/providers/settings_provider.dart';
import 'package:munajat_e_maqbool_app/services/masjid_service.dart';

class MasjidDetailScreen extends StatefulWidget {
  final String masjidId;

  const MasjidDetailScreen({super.key, required this.masjidId});

  @override
  State<MasjidDetailScreen> createState() => _MasjidDetailScreenState();
}

class _MasjidDetailScreenState extends State<MasjidDetailScreen>
    with TickerProviderStateMixin {
  final MasjidService _masjidService = MasjidService();

  Map<String, dynamic>? _masjid;
  bool _isLoading = true;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final data = await _masjidService.getMasjidDetails(widget.masjidId);
      if (mounted) {
        setState(() {
          _masjid = data;
          _isLoading = false;
        });
        _fadeController.forward();
      }
    } catch (e) {
      debugPrint('Error loading masjid details: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _openMaps() async {
    final lat = _masjid?['lat'];
    final lng = _masjid?['long'];

    if (lat != null && lng != null) {
      final webUrl = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
      );
      try {
        if (await canLaunchUrl(webUrl)) {
          await launchUrl(webUrl, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Could not open maps')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = settings.isDarkMode;
    final accentColor = GlassTheme.accent(isDark);
    final textColor = GlassTheme.text(isDark);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            const AppBackgroundPattern(),
            const Center(child: CircularProgressIndicator()),
          ],
        ),
      );
    }

    if (_masjid == null) {
      return Scaffold(
        body: Center(
          child: Text('Masjid not found', style: TextStyle(color: textColor)),
        ),
      );
    }

    final images = (_masjid!['images'] as List? ?? [])
        .cast<Map<String, dynamic>>();
    final coverUrl = images.firstWhere(
      (img) => img['image_type'] == 'exterior',
      orElse: () => images.isNotEmpty ? images.first : <String, dynamic>{},
    )['image_url'];
    final logoUrl = images.firstWhere(
      (img) => img['image_type'] == 'logo',
      orElse: () => <String, dynamic>{},
    )['image_url'];
    final jamatTimes = (_masjid!['jamat_times'] as Map?)
        ?.cast<String, dynamic>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Container(color: GlassTheme.background(isDark)),
          const AppBackgroundPattern(),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Hero Section with Parallax
              SliverAppBar(
                expandedHeight: 320,
                pinned: true,
                elevation: 0,
                stretch: true,
                backgroundColor: Colors.transparent,
                leading: _buildBackButton(context, isDark),
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [
                    StretchMode.zoomBackground,
                    StretchMode.blurBackground,
                  ],
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildHeroImage(coverUrl, accentColor),
                      _buildHeaderOverlay(isDark),
                      _buildHeaderContent(
                        _masjid!,
                        logoUrl,
                        accentColor,
                        textColor,
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Jamat Times Grid
                        _buildSectionTitle(
                          'Jamat Times',
                          Icons.access_time_filled_rounded,
                          accentColor,
                          textColor,
                        ),
                        const SizedBox(height: 16),
                        _buildJamatGrid(
                          jamatTimes,
                          accentColor,
                          textColor,
                          isDark,
                        ),

                        const SizedBox(height: 32),

                        // About Section
                        if (_masjid!['description'] != null &&
                            _masjid!['description'].toString().isNotEmpty) ...[
                          _buildSectionTitle(
                            'About Masjid',
                            Icons.info_outline_rounded,
                            accentColor,
                            textColor,
                          ),
                          const SizedBox(height: 12),
                          _buildDescriptionCard(
                            _masjid!['description'],
                            textColor,
                            isDark,
                          ),
                          const SizedBox(height: 32),
                        ],

                        // Facilities
                        if (_masjid!['facilities'] != null ||
                            _masjid!['bayan_languages'] != null) ...[
                          _buildSectionTitle(
                            'Facilities & Languages',
                            Icons.auto_awesome_rounded,
                            accentColor,
                            textColor,
                          ),
                          const SizedBox(height: 16),
                          _buildModernChips(
                            _masjid!,
                            accentColor,
                            textColor,
                            isDark,
                          ),
                          const SizedBox(height: 32),
                        ],

                        // Interactive Actions
                        _buildFloatingActions(accentColor, isDark),

                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: Colors.black.withValues(alpha: 0.2),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroImage(String? url, Color accent) {
    return Hero(
      tag: 'masjid_hero_${widget.masjidId}',
      child: url != null
          ? Image.network(url, fit: BoxFit.cover)
          : Container(
              color: accent.withValues(alpha: 0.1),
              child: Center(
                child: Image.asset(
                  'assets/icons/icon_masjid.png',
                  width: 100,
                  height: 100,
                ),
              ),
            ),
    );
  }

  Widget _buildHeaderOverlay(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.3),
            Colors.transparent,
            isDark ? Colors.black : Colors.white.withValues(alpha: 0.5),
          ],
          stops: const [0.0, 0.4, 1.0],
        ),
      ),
    );
  }

  Widget _buildHeaderContent(
    Map<String, dynamic> masjid,
    String? logoUrl,
    Color accent,
    Color textColor,
  ) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildFloatingLogo(logoUrl, accent),
            const SizedBox(height: 16),
            Text(
              masjid['name'] ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on_rounded, size: 14, color: accent),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    masjid['address'] ?? '',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingLogo(String? url, Color accent) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [accent, accent.withValues(alpha: 0.5)],
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        child: CircleAvatar(
          radius: 40,
          backgroundColor: Colors.white,
          backgroundImage: url != null ? NetworkImage(url) : null,
          child: url == null
              ? Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.asset('assets/icons/icon_masjid.png'),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(
    String title,
    IconData icon,
    Color accent,
    Color textColor,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: accent),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildJamatGrid(
    Map<String, dynamic>? times,
    Color accent,
    Color textColor,
    bool isDark,
  ) {
    final prayers = [
      {'label': 'Fajr', 'key': 'fajr', 'icon': Icons.wb_twilight_rounded},
      {'label': 'Dhuhr', 'key': 'dhuhr', 'icon': Icons.wb_sunny_rounded},
      {'label': 'Asr', 'key': 'asr', 'icon': Icons.wb_cloudy_rounded},
      {'label': 'Maghrib', 'key': 'maghrib', 'icon': Icons.nights_stay_rounded},
      {'label': 'Isha', 'key': 'isha', 'icon': Icons.dark_mode_rounded},
      {
        'label': 'Jummah',
        'key': 'jummah',
        'icon': 'assets/icons/icon_masjid.png',
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: prayers.length,
      itemBuilder: (context, index) {
        final p = prayers[index];
        final time = times?[p['key']] ?? '--:--';
        return _buildPrayerCard(
          p['label'] as String,
          time,
          p['icon']!,
          accent,
          textColor,
          isDark,
        );
      },
    );
  }

  Widget _buildPrayerCard(
    String label,
    String time,
    dynamic icon,
    Color accent,
    Color textColor,
    bool isDark,
  ) {
    return GlassCard(
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withValues(alpha: 0.1), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            icon is IconData
                ? Icon(icon, size: 20, color: accent.withValues(alpha: 0.8))
                : Image.asset(icon as String, width: 20, height: 20),
            const SizedBox(height: 8),
            Text(
              time,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: textColor.withValues(alpha: 0.5),
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionCard(String text, Color textColor, bool isDark) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(24),
      child: Text(
        text,
        style: TextStyle(
          color: textColor.withValues(alpha: 0.8),
          fontSize: 15,
          height: 1.6,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  Widget _buildModernChips(
    Map<String, dynamic> masjid,
    Color accent,
    Color textColor,
    bool isDark,
  ) {
    final facilities = Map<String, dynamic>.from(masjid['facilities'] ?? {});
    final bayanLangs = masjid['bayan_languages'] as List? ?? [];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        ...facilities.entries
            .where((e) => e.value == true)
            .map(
              (e) => _buildModernChip(
                e.key.replaceAll('_', ' ').toUpperCase(),
                accent,
                textColor,
                isDark,
              ),
            ),
        ...bayanLangs.map(
          (l) => _buildModernChip(
            '$l BAYAN',
            Colors.blueAccent,
            textColor,
            isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildModernChip(
    String label,
    Color color,
    Color textColor,
    bool isDark,
  ) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      borderRadius: BorderRadius.circular(15),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActions(Color accent, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildPremiumActionButton(
            'DIRECTIONS',
            Icons.near_me_rounded,
            accent,
            isDark,
            _openMaps,
          ),
        ),
        const SizedBox(width: 16),
        if (_masjid!['contact_number'] != null)
          Expanded(
            child: _buildPremiumActionButton(
              'CALL NOW',
              Icons.phone_in_talk_rounded,
              Colors.greenAccent[700]!,
              isDark,
              () => launchUrl(Uri.parse('tel:${_masjid!['contact_number']}')),
            ),
          ),
      ],
    );
  }

  Widget _buildPremiumActionButton(
    String label,
    IconData icon,
    Color color,
    bool isDark,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 20),
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
