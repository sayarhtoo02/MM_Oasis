import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:munajat_e_maqbool_app/config/glass_theme.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_card.dart';
import 'package:munajat_e_maqbool_app/services/shop_image_service.dart';
import 'package:munajat_e_maqbool_app/services/shop_service.dart';
import 'package:munajat_e_maqbool_app/services/location_service.dart';
import 'package:munajat_e_maqbool_app/providers/settings_provider.dart';
import 'package:munajat_e_maqbool_app/screens/halal_shop/shop_detail_screen.dart';

class ShopCard extends StatelessWidget {
  final Map<String, dynamic> shop;
  final LocationData? userLocation;

  const ShopCard({super.key, required this.shop, this.userLocation});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final isDark = settings.isDarkMode;
        final textColor = GlassTheme.text(isDark);
        final accentColor = GlassTheme.accent(isDark);
        final shopId = shop['id'] as String;
        final category = shop['category'] as String?;

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: ShopImageService().getShopImages(shopId),
          builder: (context, snapshot) {
            final images = (snapshot.data ?? <Map<String, dynamic>>[])
                .cast<Map<String, dynamic>>();
            final coverImage = images.firstWhere(
              (img) => img['image_type'] == 'cover',
              orElse: () => <String, dynamic>{},
            );
            final logoImage = images.firstWhere(
              (img) => img['image_type'] == 'logo',
              orElse: () => <String, dynamic>{},
            );
            final coverUrl = coverImage['image_url'] as String?;
            final logoUrl = logoImage['image_url'] as String?;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: GlassCard(
                borderRadius: BorderRadius.circular(20),
                padding: EdgeInsets.zero,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ShopDetailScreen(shopId: shopId),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cover image with gradient overlay (Logo removed)
                    Stack(
                      children: [
                        // Cover image
                        Container(
                          height: 140,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                            color: accentColor.withValues(alpha: 0.1),
                          ),
                          child: coverUrl != null
                              ? ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(20),
                                  ),
                                  child: Image.network(
                                    coverUrl,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorBuilder:
                                        (context, error, stackTrace) => Center(
                                          child: Icon(
                                            Icons.storefront_rounded,
                                            size: 50,
                                            color: accentColor.withValues(
                                              alpha: 0.5,
                                            ),
                                          ),
                                        ),
                                  ),
                                )
                              : Center(
                                  child: Icon(
                                    Icons.storefront_rounded,
                                    size: 50,
                                    color: accentColor.withValues(alpha: 0.5),
                                  ),
                                ),
                        ),
                        // Gradient overlay
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          height: 60,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  (isDark ? Colors.black : Colors.white)
                                      .withValues(alpha: 0.8),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Category tag
                        if (category != null)
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(
                                  alpha: 0.9,
                                ), // Glassy accent
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Text(
                                category[0].toUpperCase() +
                                    category.substring(1),
                                style: TextStyle(
                                  color: isDark ? Colors.black : Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    // Shop info
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Shop Logo
                              Container(
                                width: 40,
                                height: 40,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark
                                      ? Colors.grey[800]
                                      : Colors.white,
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.grey[700]!
                                        : Colors.grey[300]!,
                                    width: 1.5,
                                  ),
                                ),
                                child: ClipOval(
                                  child: logoUrl != null
                                      ? Image.network(
                                          logoUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Icon(
                                                    Icons.store,
                                                    color: accentColor,
                                                    size: 20,
                                                  ),
                                        )
                                      : Icon(
                                          Icons.store,
                                          color: accentColor,
                                          size: 20,
                                        ),
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  shop['name'] ?? 'Unknown Shop',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (shop['is_pro'] == true) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Colors.amber, Colors.orange],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.verified,
                                        color: Colors.white,
                                        size: 10,
                                      ),
                                      SizedBox(width: 2),
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
                              ],
                              if (shop['is_verified'] == true) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.verified,
                                  color: Colors.blue,
                                  size: 20,
                                ),
                              ],
                            ],
                          ),
                          if (shop['description'] != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              shop['description'],
                              style: TextStyle(
                                color: textColor.withValues(alpha: 0.7),
                                fontSize: 13,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: accentColor,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  shop['address'] ?? 'No Address',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textColor.withValues(alpha: 0.6),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: SizedBox()),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildOpenStatusBadge(shop),
                              if (shop['is_delivery_available'] == true &&
                                  userLocation != null) ...[
                                const SizedBox(width: 8),
                                _buildDeliveryBadge(shop, textColor),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDeliveryBadge(Map<String, dynamic> shop, Color textColor) {
    if (userLocation == null) return const SizedBox.shrink();

    final userLoc = userLocation!;
    final shopLat = shop['lat'] as double?;
    final shopLng = shop['long'] as double?;
    final radiusKm = (shop['delivery_radius_km'] as num?)?.toDouble() ?? 5.0;

    if (shopLat == null || shopLng == null) return const SizedBox.shrink();

    final distanceKm = LocationService().calculateDistance(
      userLoc.latitude,
      userLoc.longitude,
      shopLat,
      shopLng,
    );

    if (distanceKm > radiusKm) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.directions_bike, size: 12, color: Colors.green),
          const SizedBox(width: 4),
          Text(
            'Delivers',
            style: TextStyle(
              color: Colors.green,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpenStatusBadge(Map<String, dynamic> shop) {
    final isOpen = ShopService.isOpen(shop);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOpen
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isOpen
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.red.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        isOpen ? 'Open' : 'Closed',
        style: TextStyle(
          color: isOpen ? Colors.green : Colors.red,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
