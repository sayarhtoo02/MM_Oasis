import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:munajat_e_maqbool_app/config/glass_theme.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/masjid_card.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_card.dart';
import 'package:munajat_e_maqbool_app/providers/settings_provider.dart';
import 'package:munajat_e_maqbool_app/services/masjid_service.dart';
import 'package:munajat_e_maqbool_app/services/location_service.dart';
import 'package:munajat_e_maqbool_app/widgets/app_background_pattern.dart';
import 'package:munajat_e_maqbool_app/screens/masjid/masjid_map_view.dart';
import 'package:munajat_e_maqbool_app/screens/masjid/masjid_registration_screen.dart';
import 'package:munajat_e_maqbool_app/screens/masjid/masjid_detail_screen.dart';
import 'package:munajat_e_maqbool_app/screens/masjid/masjid_manager_dashboard.dart';

class MasjidListScreen extends StatefulWidget {
  const MasjidListScreen({super.key});

  @override
  State<MasjidListScreen> createState() => _MasjidListScreenState();
}

class _MasjidListScreenState extends State<MasjidListScreen>
    with SingleTickerProviderStateMixin {
  final MasjidService _masjidService = MasjidService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _masjids = [];
  List<Map<String, dynamic>> _filteredMasjids = [];
  bool _isLoading = true;
  LocationData? _userLocation;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _masjidService.getMasjids(),
        LocationService().getLocation(),
      ]);

      if (mounted) {
        setState(() {
          _masjids = (results[0] as List).cast<Map<String, dynamic>>();
          _userLocation = results[1] as LocationData?;
          _filteredMasjids = _masjids;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        if (query.isEmpty) {
          _filteredMasjids = _masjids;
        } else {
          _filteredMasjids = _masjids
              .where(
                (m) =>
                    m['name'].toString().toLowerCase().contains(
                      query.toLowerCase(),
                    ) ||
                    m['address'].toString().toLowerCase().contains(
                      query.toLowerCase(),
                    ),
              )
              .toList();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = settings.isDarkMode;
    final accentColor = GlassTheme.accent(isDark);
    final textColor = GlassTheme.text(isDark);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Container(color: GlassTheme.background(isDark)),
          const AppBackgroundPattern(),
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Premium Sliver App Bar
              SliverAppBar(
                expandedHeight: 200,
                floating: false,
                pinned: true,
                stretch: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [
                    StretchMode.zoomBackground,
                    StretchMode.blurBackground,
                  ],
                  centerTitle: true,
                  title: Text(
                    'Nearby Masjids',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      shadows: [
                        Shadow(
                          blurRadius: 10,
                          color: Colors.black.withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildHeaderBackground(accentColor),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              isDark
                                  ? Colors.black.withValues(alpha: 0.8)
                                  : Colors.white.withValues(alpha: 0.8),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      Icons.dashboard_customize_rounded,
                      color: accentColor,
                    ),
                    tooltip: 'My Masjids',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MasjidManagerDashboard(),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.map_rounded, color: accentColor),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MasjidMapView()),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.add_location_alt_rounded,
                      color: accentColor,
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MasjidRegistrationScreen(),
                      ),
                    ),
                  ),
                ],
              ),

              // Search Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: GlassCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    borderRadius: BorderRadius.circular(15),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: 'Search Masjid...',
                        hintStyle: TextStyle(
                          color: textColor.withValues(alpha: 0.5),
                        ),
                        border: InputBorder.none,
                        icon: Icon(Icons.search_rounded, color: accentColor),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: textColor.withValues(alpha: 0.5),
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
              ),

              // Masjid List
              _isLoading
                  ? const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _filteredMasjids.isEmpty
                  ? _buildEmptyState(textColor, accentColor)
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final masjid = _filteredMasjids[index];
                          return MasjidCard(
                            masjid: masjid,
                            userLocation: _userLocation,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    MasjidDetailScreen(masjidId: masjid['id']),
                              ),
                            ),
                          );
                        }, childCount: _filteredMasjids.length),
                      ),
                    ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBackground(Color accentColor) {
    return Center(
      child: Opacity(
        opacity: 0.2,
        child: Image.asset(
          'assets/icons/icon_masjid.png',
          width: 150,
          height: 150,
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color textColor, Color accentColor) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off_rounded,
              size: 80,
              color: accentColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Masjids Found',
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or add a new one!',
              style: TextStyle(color: textColor.withValues(alpha: 0.7)),
            ),
          ],
        ),
      ),
    );
  }
}
