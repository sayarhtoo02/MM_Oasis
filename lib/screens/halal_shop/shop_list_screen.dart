import 'dart:async';
import 'package:flutter/material.dart';
import 'package:munajat_e_maqbool_app/screens/main_app_shell.dart';

import 'package:provider/provider.dart';
import 'package:munajat_e_maqbool_app/config/glass_theme.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/shop_card.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_card.dart';
import 'package:munajat_e_maqbool_app/providers/settings_provider.dart';
import 'package:munajat_e_maqbool_app/services/shop_service.dart';
import 'package:munajat_e_maqbool_app/services/auth_service.dart';
import 'package:munajat_e_maqbool_app/screens/halal_shop/shop_registration_screen.dart';
import 'package:munajat_e_maqbool_app/screens/halal_shop/shop_owner_dashboard.dart';
import 'package:munajat_e_maqbool_app/screens/halal_shop/shop_map_view.dart';
import 'package:munajat_e_maqbool_app/screens/halal_shop/favorite_shops_screen.dart';
import 'package:munajat_e_maqbool_app/screens/auth/login_screen.dart';
import 'package:munajat_e_maqbool_app/screens/halal_shop/order_history_screen.dart';
import 'package:munajat_e_maqbool_app/services/location_service.dart';
import 'package:munajat_e_maqbool_app/widgets/app_background_pattern.dart';

class ShopListScreen extends StatefulWidget {
  const ShopListScreen({super.key});

  @override
  State<ShopListScreen> createState() => _ShopListScreenState();
}

class _ShopListScreenState extends State<ShopListScreen>
    with SingleTickerProviderStateMixin {
  final ShopService _shopService = ShopService();
  final AuthService _authService = AuthService();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _shops = [];
  List<Map<String, dynamic>>? _searchResults;
  bool _isLoading = true;
  bool _isSearchingLoading = false;

  // Pagination State
  int _currentPage = 0;
  final int _pageSize = 10;
  bool _hasMore = true;
  bool _isLoadMoreRunning = false;

  String? _selectedCategory;
  LocationData? _userLocation;

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  final List<String> _categories = [
    'restaurant',
    'grocery',
    'bakery',
    'butcher',
    'cafe',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    _loadData(); // Initial load
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    _scrollController.dispose(); // Listener removed automatically
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        !_isLoadMoreRunning &&
        _hasMore &&
        _searchResults == null) {
      _loadMore();
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _currentPage = 0;
      _shops.clear();
      _hasMore = true;
    });

    try {
      final results = await Future.wait([
        _shopService.getShops(
          limit: _pageSize,
          offset: 0,
          category: _selectedCategory,
        ),
        LocationService().getLocation(),
      ]);

      if (mounted) {
        final newShops = results[0] as List<Map<String, dynamic>>;
        setState(() {
          _shops = newShops;
          _userLocation = results[1] as LocationData?;
          _searchResults = null;

          if (newShops.length < _pageSize) {
            _hasMore = false;
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadMoreRunning || !_hasMore) return;

    setState(() => _isLoadMoreRunning = true);

    try {
      final nextPage = _currentPage + 1;
      final offset = nextPage * _pageSize;

      final newShops = await _shopService.getShops(
        limit: _pageSize,
        offset: offset,
        category: _selectedCategory,
      );

      if (mounted) {
        setState(() {
          if (newShops.isNotEmpty) {
            _shops.addAll(newShops);
            _currentPage = nextPage;
          }

          if (newShops.length < _pageSize) {
            _hasMore = false;
          }

          _isLoadMoreRunning = false;
        });
      }
    } catch (e) {
      debugPrint('Load more error: $e');
      if (mounted) {
        setState(() => _isLoadMoreRunning = false);
      }
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isEmpty) {
        setState(() {
          _searchResults = null;
          _searchResults = null;
          _loadData(); // Restore main list
        });
      } else {
        _performSearch(query);
      }
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isSearchingLoading = true);
    try {
      final results = await _shopService.searchShops(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _searchResults = results;
          // _applyFilter(); // Removed
          _isSearchingLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Search error: $e');
      if (mounted) setState(() => _isSearchingLoading = false);
    }
  }

  // No longer needed as filtering is server-side
  // void _applyFilter() { ... }

  void _setCategory(String? category) {
    if (_selectedCategory == category) return;

    setState(() {
      _selectedCategory = category;
      // Selecting a category triggers a reload (server-side filter)
      _loadData();
    });
  }

  void _onAddShop() {
    if (_authService.currentUser == null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      ).then((_) {
        if (_authService.currentUser != null) _navigateToAddShop();
      });
    } else {
      _navigateToAddShop();
    }
  }

  void _navigateToAddShop() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ShopRegistrationScreen()),
    ).then((_) => _loadData());
  }

  void _navigateToMyShops() {
    if (_authService.currentUser == null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      ).then((_) {
        if (!mounted) return;
        if (_authService.currentUser != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ShopOwnerDashboard()),
          );
        }
      });
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ShopOwnerDashboard()),
      );
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
          backgroundColor: GlassTheme.background(isDark),
          extendBody: true,
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 80.0), // Clear bottom nav
            child: FloatingActionButton(
              onPressed: _onAddShop,
              elevation: 8,
              backgroundColor: accentColor,
              child: Icon(
                Icons.add_business_rounded,
                color: isDark ? Colors.black : Colors.white,
              ),
            ),
          ),
          body: Stack(
            children: [
              // 1. Dynamic Background
              Container(color: GlassTheme.background(isDark)),
              AppBackgroundPattern(
                patternColor: isDark ? Colors.white : Colors.black,
                opacity: isDark ? 0.05 : 0.03,
              ),

              // 2. Custom Scroll View
              RefreshIndicator(
                onRefresh: _loadData,
                color: accentColor,
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // A. Premium Sliver App Bar
                    SliverAppBar(
                      expandedHeight: 140.0,
                      floating: false,
                      pinned: true,
                      leading: IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: textColor,
                        ),
                        onPressed: () {
                          mainAppShellKey.currentState?.closeFeature();
                        },
                      ),
                      backgroundColor: GlassTheme.glassGradient(
                        isDark,
                      ).first.withValues(alpha: 0.9),
                      elevation: 0,
                      flexibleSpace: FlexibleSpaceBar(
                        titlePadding: const EdgeInsets.only(
                          left: 56,
                          bottom: 16,
                        ),
                        title: Text(
                          'Halal Shops',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                offset: Offset(0, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                        background: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                accentColor.withValues(alpha: 0.2),
                                Colors.transparent,
                              ],
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                            ),
                          ),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                right: 20,
                                top: 20,
                              ),
                              child: Icon(
                                Icons.storefront_rounded,
                                size: 120,
                                color: accentColor.withValues(alpha: 0.1),
                              ),
                            ),
                          ),
                        ),
                      ),
                      actions: [
                        _buildGlassActionButton(
                          icon: Icons.favorite_border,
                          textColor: textColor,
                          isDark: isDark,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const FavoriteShopsScreen(),
                            ),
                          ),
                        ),
                        _buildGlassActionButton(
                          icon: Icons.map_outlined,
                          textColor: textColor,
                          isDark: isDark,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ShopMapView(),
                            ),
                          ),
                        ),
                        _buildGlassActionButton(
                          icon: Icons.store_outlined,
                          textColor: textColor,
                          isDark: isDark,
                          onTap: _navigateToMyShops,
                        ),
                        // Profile/More Menu (Orders)
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert_rounded, color: textColor),
                          color: isDark ? Colors.grey[900] : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          onSelected: (value) {
                            if (value == 'my_shops') {
                              _navigateToMyShops();
                            } else if (value == 'orders') {
                              if (_authService.currentUser == null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const LoginScreen(),
                                  ),
                                );
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const OrderHistoryScreen(),
                                  ),
                                );
                              }
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'orders',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.receipt_long_outlined,
                                    color: accentColor,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Order History',
                                    style: TextStyle(color: textColor),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // B. Search Bar (Sticky-like behavior with SliverToBox)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: _buildSearchBar(isDark, textColor, accentColor),
                      ),
                    ),

                    // C. Filter Chips
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 60,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          children: [
                            _buildFilterChip(
                              'All',
                              null,
                              textColor,
                              accentColor,
                              isDark,
                            ),
                            ..._categories.map(
                              (c) => _buildFilterChip(
                                c[0].toUpperCase() + c.substring(1),
                                c,
                                textColor,
                                accentColor,
                                isDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // D. Loading / Empty / List State
                    if (_isLoading)
                      SliverFillRemaining(
                        child: Center(
                          child: CircularProgressIndicator(color: accentColor),
                        ),
                      )
                    else if (_shops.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: accentColor.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.store_outlined,
                                  size: 48,
                                  color: accentColor.withValues(alpha: 0.6),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No shops found nearby.',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: textColor.withValues(alpha: 0.8),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Try changing your filters or search query.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: textColor.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            // Display Search Results if available
                            if (_searchResults != null) {
                              return _buildStaggeredListItem(
                                index,
                                _searchResults![index],
                                _userLocation,
                              );
                            }

                            // Display Paginated List
                            if (index < _shops.length) {
                              return _buildStaggeredListItem(
                                index,
                                _shops[index],
                                _userLocation,
                              );
                            } else {
                              // Loading indicator at bottom
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 32,
                                ),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: accentColor,
                                  ),
                                ),
                              );
                            }
                          },
                          // Count: if search, use search length.
                          // If normal, use shops.length + 1 for loader (if hasMore).
                          childCount: _searchResults != null
                              ? _searchResults!.length
                              : _shops.length + (_hasMore ? 1 : 0),
                        ),
                      ),

                    // Extra padding at bottom for FAB
                    const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGlassActionButton({
    required IconData icon,
    required Color textColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (isDark ? Colors.black : Colors.white).withValues(
              alpha: 0.1,
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: textColor, size: 20),
        ),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildSearchBar(bool isDark, Color textColor, Color accentColor) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      borderRadius: BorderRadius.circular(24),
      blurStrength: 10,
      gradientColors: [
        (isDark ? Colors.black : Colors.white).withValues(alpha: 0.05),
        (isDark ? Colors.black : Colors.white).withValues(alpha: 0.05),
      ],
      isDarkForce: isDark,
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
          hintText: 'Search for shops or dishes...',
          hintStyle: TextStyle(color: textColor.withValues(alpha: 0.5)),
          prefixIcon: Icon(Icons.search, color: accentColor),
          suffixIcon: _isSearchingLoading
              ? Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: accentColor,
                    ),
                  ),
                )
              : (_searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: textColor),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null),
          filled: false,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String? category,
    Color textColor,
    Color accentColor,
    bool isDark,
  ) {
    final isSelected = _selectedCategory == category;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => _setCategory(category),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? accentColor
                : (isDark ? Colors.white : Colors.black).withValues(
                    alpha: 0.05,
                  ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected ? accentColor : GlassTheme.glassBorder(isDark),
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? (isDark ? Colors.black : Colors.white)
                  : textColor.withValues(alpha: 0.8),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  // Manual staggered animation item
  Widget _buildStaggeredListItem(
    int index,
    Map<String, dynamic> shop,
    LocationData? location,
  ) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100).clamp(0, 600)),
      curve: Curves.easeOutQuart,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ShopCard(shop: shop, userLocation: location),
            ),
          ),
        );
      },
    );
  }
}
