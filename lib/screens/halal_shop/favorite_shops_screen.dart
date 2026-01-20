import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:munajat_e_maqbool_app/config/glass_theme.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_scaffold.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_card.dart';
import 'package:munajat_e_maqbool_app/providers/settings_provider.dart';
import 'package:munajat_e_maqbool_app/services/favorites_service.dart';
import 'package:munajat_e_maqbool_app/screens/halal_shop/shop_detail_screen.dart';

class FavoriteShopsScreen extends StatefulWidget {
  const FavoriteShopsScreen({super.key});

  @override
  State<FavoriteShopsScreen> createState() => _FavoriteShopsScreenState();
}

class _FavoriteShopsScreenState extends State<FavoriteShopsScreen> {
  final FavoritesService _favoritesService = FavoritesService();
  List<Map<String, dynamic>> _shops = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);
    final shops = await _favoritesService.getFavoriteShops();
    if (mounted) {
      setState(() {
        _shops = shops;
        _isLoading = false;
      });
    }
  }

  Future<void> _removeFavorite(String shopId) async {
    try {
      await _favoritesService.removeFavorite(shopId);
      await _loadFavorites();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Removed from favorites')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
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

        return GlassScaffold(
          title: 'My Favorites',
          body: _isLoading
              ? Center(child: CircularProgressIndicator(color: accentColor))
              : _shops.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite_border,
                        size: 64,
                        color: textColor.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No favorite shops yet',
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap the heart icon on any shop to add it here',
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.3),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadFavorites,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _shops.length,
                    itemBuilder: (context, index) {
                      final shop = _shops[index];
                      return _buildShopCard(
                        shop,
                        isDark,
                        textColor,
                        accentColor,
                      );
                    },
                  ),
                ),
        );
      },
    );
  }

  Widget _buildShopCard(
    Map<String, dynamic> shop,
    bool isDark,
    Color textColor,
    Color accentColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        isDark: isDark,
        borderRadius: 16,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ShopDetailScreen(shopId: shop['id']),
            ),
          ).then((_) => _loadFavorites());
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Shop Logo
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: shop['logo_url'] != null
                    ? Image.network(
                        shop['logo_url'],
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _buildPlaceholderLogo(accentColor),
                      )
                    : _buildPlaceholderLogo(accentColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shop['name'] ?? 'Shop',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (shop['address'] != null)
                      Text(
                        shop['address'],
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (shop['category'] != null)
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
                          shop['category'].toString().toUpperCase(),
                          style: TextStyle(color: accentColor, fontSize: 10),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.favorite, color: Colors.red),
                onPressed: () => _removeFavorite(shop['id']),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderLogo(Color accentColor) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.storefront, color: accentColor),
    );
  }
}
