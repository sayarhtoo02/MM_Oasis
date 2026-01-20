import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:munajat_e_maqbool_app/config/glass_theme.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_scaffold.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_card.dart';
import 'package:munajat_e_maqbool_app/providers/settings_provider.dart';
import 'package:munajat_e_maqbool_app/services/shop_service.dart';
import 'package:munajat_e_maqbool_app/services/shop_menu_service.dart';
import 'package:munajat_e_maqbool_app/services/shop_image_service.dart';
import 'package:munajat_e_maqbool_app/screens/halal_shop/cart_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class ShopMenuScreen extends StatefulWidget {
  final String shopId;
  final String? shopName;
  final bool orderingEnabled;

  const ShopMenuScreen({
    super.key,
    required this.shopId,
    this.shopName,
    this.orderingEnabled = true,
  });

  @override
  State<ShopMenuScreen> createState() => _ShopMenuScreenState();
}

class _ShopMenuScreenState extends State<ShopMenuScreen>
    with SingleTickerProviderStateMixin {
  final ShopService _shopService = ShopService();
  final ShopMenuService _menuService = ShopMenuService();
  final ShopImageService _imageService = ShopImageService();

  Map<String, dynamic>? _shop;
  List<Map<String, dynamic>> _menu = [];
  String? _coverUrl;
  String? _logoUrl;
  bool _isLoading = true;

  // Cart state
  final Map<String, CartItem> _cart = {};

  // Animation state
  late AnimationController _fabController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _fabController, curve: Curves.easeOut));

    _loadData();
  }

  @override
  void dispose() {
    // Clear any SnackBars when leaving this screen
    _fabController.dispose();
    ScaffoldMessenger.of(context).clearSnackBars();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final shop = await _shopService.getShopById(widget.shopId);
    final menu = await _menuService.getFullMenu(widget.shopId);
    final images = await _imageService.getShopImages(widget.shopId);

    final cover = images.firstWhere(
      (img) => img['image_type'] == 'cover',
      orElse: () => <String, dynamic>{},
    );
    final logo = images.firstWhere(
      (img) => img['image_type'] == 'logo',
      orElse: () => <String, dynamic>{},
    );

    if (mounted) {
      setState(() {
        _shop = shop;
        _menu = menu;
        _coverUrl = cover['image_url'] as String?;
        _logoUrl = logo['image_url'] as String?;
        _isLoading = false;
      });
    }
  }

  void _addToCart(Map<String, dynamic> item) {
    final itemId = item['id'] as String;
    setState(() {
      if (_cart.containsKey(itemId)) {
        _cart[itemId]!.quantity++;
      } else {
        _cart[itemId] = CartItem(
          id: itemId,
          name: item['name'] as String,
          price: (item['price'] as num?)?.toDouble() ?? 0,
          imageUrl: item['image_url'] as String?,
          quantity: 1,
        );
      }
    });

    // Trigger FAB animation
    _fabController.reset();
    _fabController.forward();

    // Clear existing SnackBars before showing new one
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text('Added ${item['name']} to cart'),
          duration: const Duration(seconds: 1),
          action: SnackBarAction(label: 'View Cart', onPressed: _openCart),
        ),
      );
  }

  void _openCart() {
    // Clear any existing SnackBars before navigating
    ScaffoldMessenger.of(context).clearSnackBars();

    if (_cart.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cart is empty')));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CartScreen(
          shopId: widget.shopId,
          shopName: _shop?['name'] ?? 'Shop',
          cartItems: _cart.values.toList(),
          onCartUpdated: (updatedCart) {
            setState(() {
              _cart.clear();
              for (final item in updatedCart) {
                _cart[item.id] = item;
              }
            });
          },
        ),
      ),
    );
  }

  Future<void> _callShop() async {
    final phone = _shop?['contact_phone'] as String?;
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number available')),
      );
      return;
    }

    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch phone dialer')),
        );
      }
    }
  }

  int get _cartItemCount {
    return _cart.values.fold(0, (sum, item) => sum + item.quantity);
  }

  double get _cartTotal {
    return _cart.values.fold(
      0,
      (sum, item) => sum + (item.price * item.quantity),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final isDark = settings.isDarkMode;
        final textColor = GlassTheme.text(isDark);
        final accentColor = GlassTheme.accent(isDark);

        return GlassScaffold(
          title: _shop?['name'] ?? widget.shopName ?? 'Menu',
          actions: [
            IconButton(
              icon: const Icon(Icons.phone),
              onPressed: _callShop,
              tooltip: 'Call Shop',
            ),
          ],
          floatingActionButton: widget.orderingEnabled && _cart.isNotEmpty
              ? ScaleTransition(
                  scale: _fabAnimation,
                  child: FloatingActionButton.extended(
                    onPressed: _openCart,
                    backgroundColor: accentColor,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    icon: Badge(
                      label: Text('$_cartItemCount'),
                      child: const Icon(Icons.shopping_cart),
                    ),
                    label: Text('K ${_cartTotal.toStringAsFixed(0)}'),
                  ),
                )
              : null,
          body: _isLoading
              ? Center(child: CircularProgressIndicator(color: accentColor))
              : CustomScrollView(
                  slivers: [
                    // Shop Header
                    SliverToBoxAdapter(
                      child: _buildShopHeader(isDark, textColor, accentColor),
                    ),

                    // Menu Categories with Sticky Headers
                    ..._menu.map((category) {
                      return SliverMainAxisGroup(
                        slivers: [
                          SliverPersistentHeader(
                            pinned: true,
                            delegate: _MenuHeaderDelegate(
                              title: category['name'] ?? 'Section',
                              isDark: isDark,
                              accentColor: accentColor,
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final items =
                                      category['items'] as List? ?? [];
                                  if (index >= items.length) return null;
                                  return _buildMenuItem(
                                    items[index],
                                    isDark,
                                    textColor,
                                    accentColor,
                                  );
                                },
                                childCount:
                                    (category['items'] as List? ?? []).length,
                              ),
                            ),
                          ),
                        ],
                      );
                    }),

                    // Bottom padding for FAB
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildShopHeader(bool isDark, Color textColor, Color accentColor) {
    return Stack(
      children: [
        // Cover image
        Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                accentColor.withValues(alpha: 0.3),
                accentColor.withValues(alpha: 0.1),
              ],
            ),
          ),
          child: _coverUrl != null
              ? Image.network(_coverUrl!, fit: BoxFit.cover)
              : Center(
                  child: Icon(
                    Icons.storefront,
                    size: 60,
                    color: accentColor.withValues(alpha: 0.5),
                  ),
                ),
        ),
        // Gradient overlay
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 100,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  (isDark ? Colors.black : Colors.white).withValues(alpha: 0.9),
                ],
              ),
            ),
          ),
        ),
        // Shop info
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Row(
            children: [
              // Logo
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? Colors.grey[800] : Colors.white,
                  border: Border.all(color: accentColor, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _logoUrl != null
                      ? Image.network(_logoUrl!, fit: BoxFit.cover)
                      : Icon(Icons.store, color: accentColor, size: 32),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _shop?['name'] ?? 'Shop',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    if (_shop?['category'] != null)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          (_shop!['category'] as String).toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: accentColor,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySection(
    Map<String, dynamic> category,
    bool isDark,
    Color textColor,
    Color accentColor,
  ) {
    final items = category['items'] as List? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            category['name'] as String,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
        ),
        ...items.map(
          (item) => _buildMenuItem(item, isDark, textColor, accentColor),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildMenuItem(
    Map<String, dynamic> item,
    bool isDark,
    Color textColor,
    Color accentColor,
  ) {
    final isAvailable = item['is_available'] as bool? ?? true;
    final price = item['price'] as num?;
    final imageUrl = item['image_url'] as String?;
    final isHalal = item['is_halal_certified'] as bool? ?? false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        isDark: isDark,
        borderRadius: 16,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.05),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: imageUrl != null
                      ? Image.network(imageUrl, fit: BoxFit.cover)
                      : Icon(
                          Icons.restaurant,
                          color: textColor.withValues(alpha: 0.3),
                          size: 32,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item['name'] as String,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isAvailable
                                  ? textColor
                                  : textColor.withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                        if (isHalal)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified,
                                  color: Colors.green,
                                  size: 10,
                                ),
                                const SizedBox(width: 2),
                                const Text(
                                  'HALAL',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    if (item['description'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        item['description'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor.withValues(alpha: 0.6),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (price != null)
                          Text(
                            'K ${price.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: accentColor,
                            ),
                          ),
                        if (widget.orderingEnabled && isAvailable)
                          ElevatedButton.icon(
                            onPressed: () => _addToCart(item),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              foregroundColor: isDark
                                  ? Colors.black
                                  : Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Unavailable',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 11,
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
        ),
      ),
    );
  }
}

class _MenuHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String title;
  final bool isDark;
  final Color accentColor;

  _MenuHeaderDelegate({
    required this.title,
    required this.isDark,
    required this.accentColor,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      height: 60,
      color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F5F7),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: accentColor.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: accentColor,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  @override
  double get maxExtent => 60;

  @override
  double get minExtent => 60;

  @override
  bool shouldRebuild(covariant _MenuHeaderDelegate oldDelegate) {
    return title != oldDelegate.title ||
        isDark != oldDelegate.isDark ||
        accentColor != oldDelegate.accentColor;
  }
}

/// Cart item model
class CartItem {
  final String id;
  final String name;
  final double price;
  final String? imageUrl;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    this.imageUrl,
    this.quantity = 1,
  });

  double get total => price * quantity;
}
