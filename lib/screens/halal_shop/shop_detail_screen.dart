import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:munajat_e_maqbool_app/config/glass_theme.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_scaffold.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_card.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_button.dart';
import 'package:munajat_e_maqbool_app/widgets/app_background_pattern.dart';
import 'package:munajat_e_maqbool_app/providers/settings_provider.dart';
import 'package:munajat_e_maqbool_app/services/shop_service.dart';
import 'package:munajat_e_maqbool_app/services/shop_image_service.dart';
import 'package:munajat_e_maqbool_app/services/shop_menu_service.dart';
import 'package:munajat_e_maqbool_app/services/review_service.dart';
import 'package:munajat_e_maqbool_app/services/auth_service.dart';
import 'package:munajat_e_maqbool_app/services/location_service.dart';

import 'package:munajat_e_maqbool_app/screens/halal_shop/shop_menu_screen.dart';

class ShopDetailScreen extends StatefulWidget {
  final String shopId;

  const ShopDetailScreen({super.key, required this.shopId});

  @override
  State<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends State<ShopDetailScreen>
    with TickerProviderStateMixin {
  final ShopService _shopService = ShopService();
  final ShopImageService _imageService = ShopImageService();
  final ShopMenuService _menuService = ShopMenuService();
  final ReviewService _reviewService = ReviewService();
  final AuthService _authService = AuthService();

  Map<String, dynamic>? _shop;
  List<Map<String, dynamic>> _images = [];
  List<Map<String, dynamic>> _menu = [];
  List<Map<String, dynamic>> _reviews = [];
  double _averageRating = 0;
  bool _isLoading = true;

  // Animation controllers
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

    final results = await Future.wait([
      _shopService.getShopById(widget.shopId),
      _imageService.getShopImages(widget.shopId),
      _menuService.getFullMenu(widget.shopId),
      _reviewService.getShopReviews(widget.shopId),
      _reviewService.getShopAverageRating(widget.shopId),
    ]);

    if (mounted) {
      setState(() {
        _shop = results[0] as Map<String, dynamic>?;
        _images = results[1] as List<Map<String, dynamic>>;
        _menu = results[2] as List<Map<String, dynamic>>;
        _reviews = results[3] as List<Map<String, dynamic>>;
        _averageRating = results[4] as double;
        _isLoading = false;
      });
      // Start animations after data loads
      _fadeController.forward();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  String? _getCoverImage() {
    final cover = _images
        .where((img) => img['image_type'] == 'cover')
        .firstOrNull;
    return cover?['image_url'] as String?;
  }

  String? _getLogoImage() {
    final logo = _images
        .where((img) => img['image_type'] == 'logo')
        .firstOrNull;
    return logo?['image_url'] as String?;
  }

  List<Map<String, dynamic>> _getGalleryImages() {
    return _images.where((img) => img['image_type'] == 'gallery').toList();
  }

  Future<void> _openMaps() async {
    final lat = _shop?['lat'];
    final lng = _shop?['long'];

    if (lat != null && lng != null) {
      // Try google.navigation scheme first for direct navigation
      final navUrl = Uri.parse('google.navigation:q=$lat,$lng');
      if (await canLaunchUrl(navUrl)) {
        await launchUrl(navUrl);
        return;
      }

      // Fallback to web link
      final webUrl = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
      );

      try {
        if (await canLaunchUrl(webUrl)) {
          await launchUrl(webUrl, mode: LaunchMode.externalApplication);
        } else {
          // Try launching anyway as canLaunchUrl can be false negative
          await launchUrl(webUrl, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Could not open maps')));
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Location not available')));
      }
    }
  }

  Future<void> _callShop() async {
    final phone = _shop?['contact_phone'] as String?;
    if (phone != null && phone.isNotEmpty) {
      final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
      final url = Uri.parse('tel:$cleanPhone');

      try {
        if (await canLaunchUrl(url)) {
          await launchUrl(url);
        } else {
          // Try launching anyway, as canLaunchUrl can be false negative on some devices
          await launchUrl(url);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not launch phone dialer')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No phone number available')),
        );
      }
    }
  }

  Widget _buildDeliveryStatus(Color textColor, Color accentColor) {
    return FutureBuilder<LocationData>(
      future: LocationService().getLocation(),
      builder: (context, snapshot) {
        String baseText =
            'Delivery: ${_shop!['delivery_range'] ?? 'Available'}';

        if (!snapshot.hasData) {
          return _buildInfoRow(Icons.directions_bike, baseText, textColor);
        }

        final userLoc = snapshot.data!;
        final shopLat = _shop!['lat'] as double?;
        final shopLng = _shop!['long'] as double?;
        final radiusKm =
            (_shop!['delivery_radius_km'] as num?)?.toDouble() ?? 5.0;

        if (shopLat == null || shopLng == null) {
          return _buildInfoRow(Icons.directions_bike, baseText, textColor);
        }

        final distanceKm = LocationService().calculateDistance(
          userLoc.latitude,
          userLoc.longitude,
          shopLat,
          shopLng,
        );

        final isWithinRange = distanceKm <= radiusKm;
        final color = isWithinRange ? Colors.green : Colors.red;
        final icon = isWithinRange ? Icons.check_circle : Icons.highlight_off;
        final statusText = isWithinRange
            ? 'Delivers to you (${distanceKm.toStringAsFixed(1)} km away)'
            : 'Out of delivery range (${distanceKm.toStringAsFixed(1)} km away)';

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 80,
                child: Icon(
                  Icons.directions_bike,
                  size: 20,
                  color: textColor.withValues(alpha: 0.5),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _shop!['delivery_range'] ?? 'Delivery Available',
                      style: TextStyle(color: textColor, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(icon, size: 14, color: color),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            statusText,
                            style: TextStyle(
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
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

  Future<void> _showReviewDialog() async {
    if (_authService.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to leave a review')),
      );
      return;
    }

    int selectedRating = 5;
    final commentController = TextEditingController();

    // Check for existing review
    final existingReview = await _reviewService.getUserReview(widget.shopId);
    if (existingReview != null) {
      selectedRating = existingReview['rating'] as int;
      commentController.text = existingReview['comment'] ?? '';
    }

    if (!mounted) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(
              existingReview != null ? 'Update Review' : 'Leave a Review',
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < selectedRating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 36,
                      ),
                      onPressed: () =>
                          setDialogState(() => selectedRating = index + 1),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: commentController,
                  decoration: const InputDecoration(
                    labelText: 'Comment (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Submit'),
              ),
            ],
          );
        },
      ),
    );

    if (result == true) {
      try {
        await _reviewService.submitReview(
          shopId: widget.shopId,
          rating: selectedRating,
          comment: commentController.text.isEmpty
              ? null
              : commentController.text,
        );
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Review submitted!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final isDark = settings.isDarkMode;
        final textColor = GlassTheme.text(isDark);
        final accentColor = GlassTheme.accent(isDark);

        if (_isLoading) {
          return GlassScaffold(
            title: 'Shop Details',
            body: Center(child: CircularProgressIndicator(color: accentColor)),
          );
        }

        if (_shop == null) {
          return GlassScaffold(
            title: 'Shop Details',
            body: Center(
              child: Text('Shop not found', style: TextStyle(color: textColor)),
            ),
          );
        }

        final coverImage = _getCoverImage();

        return Scaffold(
          extendBody: true,
          backgroundColor: Colors.transparent,
          body: Stack(
            fit: StackFit.expand,
            children: [
              // Background
              Container(color: GlassTheme.background(isDark)),
              AppBackgroundPattern(
                patternColor: isDark ? Colors.white : Colors.black,
                opacity: isDark ? 0.05 : 0.03,
              ),

              // Content
              CustomScrollView(
                slivers: [
                  _buildSliverAppBar(
                    coverImage,
                    isDark,
                    textColor,
                    accentColor,
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeaderSection(isDark, textColor, accentColor),
                          const SizedBox(height: 16),
                          _buildActionButtons(isDark, textColor, accentColor),
                          const SizedBox(height: 24),
                          _buildAboutSection(isDark, textColor, accentColor),
                          const SizedBox(height: 24),
                          if (_getGalleryImages().isNotEmpty) ...[
                            _buildGallerySection(
                              isDark,
                              textColor,
                              accentColor,
                            ),
                            const SizedBox(height: 24),
                          ],
                          if (_menu.isNotEmpty) ...[
                            _buildMenuSection(isDark, textColor, accentColor),
                            const SizedBox(height: 24),
                          ],
                          _buildReviewsSection(isDark, textColor, accentColor),
                          const SizedBox(height: 40),
                        ],
                      ),
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

  Widget _buildSliverAppBar(
    String? coverImage,
    bool isDark,
    Color textColor,
    Color accentColor,
  ) {
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      stretch: true,
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.fadeTitle],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Cover image with shimmer loading
            if (coverImage != null)
              Image.network(
                coverImage,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    _buildPlaceholderCover(accentColor),
              )
            else
              _buildPlaceholderCover(accentColor),
            // Gradient overlay for text readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.7),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderCover(Color accentColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor,
            accentColor.withValues(alpha: 0.6),
            accentColor.withValues(alpha: 0.3),
          ],
        ),
      ),
      child: const Center(
        child: Icon(Icons.storefront, size: 80, color: Colors.white54),
      ),
    );
  }

  Widget _buildHeaderSection(bool isDark, Color textColor, Color accentColor) {
    final logoImage = _getLogoImage();
    final isOpen = ShopService.isOpen(_shop);

    return GlassCard(
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (logoImage != null)
                Container(
                  width: 70,
                  height: 70,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: DecorationImage(
                      image: NetworkImage(logoImage),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _shop!['name'] ?? 'Shop',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_shop!['is_pro'] == true) ...[
                          const SizedBox(width: 8),
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.elasticOut,
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFFFD700),
                                        Color(0xFFB8860B),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.amber.withValues(
                                          alpha: 0.4,
                                        ),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.verified,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'PRO',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (_shop!['category'] != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: accentColor.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Text(
                              (_shop!['category'] as String).toUpperCase(),
                              style: TextStyle(
                                color: accentColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (_shop!['is_verified'] == true) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.verified,
                                  color: Colors.green,
                                  size: 14,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Verified',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        const SizedBox(width: 8),

                        // Enhanced Open Status Chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isOpen
                                ? Colors.green.withValues(alpha: 0.15)
                                : Colors.red.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isOpen
                                  ? Colors.green.withValues(alpha: 0.3)
                                  : Colors.red.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isOpen
                                    ? Icons.access_time_filled
                                    : Icons.access_time,
                                size: 12,
                                color: isOpen ? Colors.green : Colors.red,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isOpen ? 'Open Now' : 'Closed',
                                style: TextStyle(
                                  color: isOpen ? Colors.green : Colors.red,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Stat Chips Row
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        _buildStatChip(
                          icon: Icons.star_rounded,
                          label: _averageRating > 0
                              ? _averageRating.toStringAsFixed(1)
                              : 'New',
                          color: const Color(0xFFFFB800),
                          isDark: isDark,
                        ),
                        _buildStatChip(
                          icon: Icons.reviews_rounded,
                          label: '${_reviews.length} Reviews',
                          color: Colors.blueAccent,
                          isDark: isDark,
                        ),
                        _buildStatChip(
                          icon: Icons.location_on_rounded,
                          // TODO: Calculate actual distance
                          label: '2.5 km',
                          color: Colors.redAccent,
                          isDark: isDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Rate Button
                    Center(
                      child: GlassButton(
                        onPressed: _showReviewDialog,
                        label: 'Rate This Shop',
                        icon: const Icon(
                          Icons.star_rate_rounded,
                          color: Colors.amber,
                          size: 18,
                        ),
                        height: 36,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isDark, Color textColor, Color accentColor) {
    final isOpen = ShopService.isOpen(_shop!['operating_hours']);
    final isPro = _shop!['is_pro'] == true;
    final canOrder = isOpen && isPro;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          // Main CTA Button with gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: canOrder
                    ? [const Color(0xFFFF6B35), const Color(0xFFFF8C42)]
                    : [Colors.grey.shade600, Colors.grey.shade500],
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: canOrder
                  ? [
                      BoxShadow(
                        color: const Color(0xFFFF6B35).withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: (isOpen || !isPro)
                    ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ShopMenuScreen(
                            shopId: widget.shopId,
                            shopName: _shop!['name'] ?? 'Shop',
                            orderingEnabled: canOrder,
                          ),
                        ),
                      )
                    : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        !isPro
                            ? Icons.restaurant_menu
                            : (canOrder
                                  ? Icons.shopping_cart
                                  : Icons.lock_clock),
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        !isPro
                            ? 'View Menu'
                            : (canOrder
                                  ? 'View Menu & Order'
                                  : 'Currently Closed'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Secondary action buttons
          Row(
            children: [
              Expanded(
                child: _buildPillButton(
                  icon: Icons.directions,
                  label: 'Directions',
                  onTap: _openMaps,
                  isDark: isDark,
                  accentColor: accentColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPillButton(
                  icon: Icons.phone,
                  label: 'Call',
                  onTap: _callShop,
                  isDark: isDark,
                  accentColor: accentColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPillButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
    required Color accentColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade300,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: accentColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.grey.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAboutSection(bool isDark, Color textColor, Color accentColor) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About & Contact',
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (_shop!['description'] != null) ...[
            Text(
              _shop!['description'],
              style: TextStyle(
                color: textColor.withValues(alpha: 0.8),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Divider(color: textColor.withValues(alpha: 0.1)),
            const SizedBox(height: 16),
          ],
          _buildInfoRow(Icons.location_on, _shop!['address'], textColor),
          _buildInfoRow(Icons.phone, _shop!['contact_phone'], textColor),
          _buildInfoRow(Icons.email, _shop!['contact_email'], textColor),
          _buildInfoRow(Icons.language, _shop!['website'], textColor),
          if (_shop!['is_delivery_available'] == true) ...[
            const SizedBox(height: 8),
            _buildDeliveryStatus(textColor, accentColor),
          ],
        ],
      ),
    );
  }

  Widget _buildGallerySection(bool isDark, Color textColor, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Gallery',
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _getGalleryImages().length,
            itemBuilder: (context, index) {
              final img = _getGalleryImages()[index];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GlassCard(
                  padding: EdgeInsets.zero,
                  width: 140,
                  height: 140,
                  child: Image.network(img['image_url'], fit: BoxFit.cover),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMenuSection(bool isDark, Color textColor, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Menu',
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: _menu.map((category) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    color: accentColor.withValues(alpha: 0.1),
                    child: Text(
                      category['name'] ?? 'Items',
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...((category['items'] as List?) ?? []).map((item) {
                    final isAvailable = item['is_available'] as bool? ?? true;
                    return ListTile(
                      title: Text(
                        item['name'],
                        style: TextStyle(
                          color: isAvailable
                              ? textColor
                              : textColor.withValues(alpha: 0.5),
                          decoration: isAvailable
                              ? null
                              : TextDecoration.lineThrough,
                        ),
                      ),
                      trailing: item['price'] != null
                          ? Text(
                              'K ${(item['price'] as num).toStringAsFixed(0)}',
                              style: TextStyle(
                                color: accentColor,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                      dense: true,
                    );
                  }),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsSection(bool isDark, Color textColor, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Recent Reviews',
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (_reviews.isEmpty)
          GlassCard(
            child: Center(
              child: Text(
                'No reviews yet',
                style: TextStyle(color: textColor.withValues(alpha: 0.6)),
              ),
            ),
          )
        else
          ..._reviews
              .take(5)
              .map(
                (review) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: accentColor.withValues(
                                alpha: 0.2,
                              ),
                              child: Text(
                                (review['user']?['username'] ?? 'U')[0]
                                    .toUpperCase(),
                                style: TextStyle(color: accentColor),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                review['user']?['username'] ?? 'Anonymous',
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Icon(Icons.star, color: Colors.amber, size: 16),
                            Text(
                              ' ${review['rating']}',
                              style: TextStyle(color: textColor),
                            ),
                          ],
                        ),
                        if (review['comment'] != null &&
                            review['comment'].isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            review['comment'],
                            style: TextStyle(
                              color: textColor.withValues(alpha: 0.8),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String? value, Color textColor) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: textColor.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 16,
              color: textColor.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: textColor.withValues(alpha: 0.8),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.grey.shade700,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
