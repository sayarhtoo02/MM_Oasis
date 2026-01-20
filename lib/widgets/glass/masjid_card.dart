import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:munajat_e_maqbool_app/config/glass_theme.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_card.dart';
import 'package:munajat_e_maqbool_app/services/masjid_image_service.dart';
import 'package:munajat_e_maqbool_app/services/location_service.dart';
import 'package:munajat_e_maqbool_app/providers/settings_provider.dart';

class MasjidCard extends StatelessWidget {
  final Map<String, dynamic> masjid;
  final LocationData? userLocation;
  final VoidCallback? onTap;

  const MasjidCard({
    super.key,
    required this.masjid,
    this.userLocation,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final isDark = settings.isDarkMode;
        final textColor = GlassTheme.text(isDark);
        final accentColor = GlassTheme.accent(isDark);
        final masjidId = masjid['id'] as String;

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: MasjidImageService().getMasjidImages(masjidId),
          builder: (context, snapshot) {
            final images = (snapshot.data ?? <Map<String, dynamic>>[])
                .cast<Map<String, dynamic>>();
            final coverImage = images.firstWhere(
              (img) => img['image_type'] == 'exterior',
              orElse: () =>
                  images.isNotEmpty ? images.first : <String, dynamic>{},
            );
            final logoImage = images.firstWhere(
              (img) => img['image_type'] == 'logo',
              orElse: () => <String, dynamic>{},
            );

            final coverUrl = coverImage['image_url'] as String?;
            final logoUrl = logoImage['image_url'] as String?;

            // Calculate distance
            String? distanceStr;
            if (userLocation != null &&
                masjid['lat'] != null &&
                masjid['long'] != null) {
              final dist = LocationService().calculateDistance(
                userLocation!.latitude,
                userLocation!.longitude,
                masjid['lat'] as double,
                masjid['long'] as double,
              );
              distanceStr = '${dist.toStringAsFixed(1)} km';
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: GlassCard(
                borderRadius: BorderRadius.circular(20),
                padding: EdgeInsets.zero,
                onTap: onTap,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cover image with gradient overlay
                    Stack(
                      children: [
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
                                    errorBuilder: (_, _, _) =>
                                        _buildPlaceholder(accentColor),
                                  ),
                                )
                              : _buildPlaceholder(accentColor),
                        ),
                        // Gradient overlay
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  isDark
                                      ? Colors.black.withValues(alpha: 0.6)
                                      : Colors.white.withValues(alpha: 0.4),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Status Badge (Pending/Approved) - only show if not approved and manager views it
                        if (masjid['status'] != 'approved')
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(masjid['status']),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                masjid['status'].toString().toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),

                    // Info Row
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Masjid Logo
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark
                                  ? Colors.white10
                                  : Colors.black.withValues(alpha: 0.05),
                              border: Border.all(
                                color: accentColor.withValues(alpha: 0.3),
                                width: 2,
                              ),
                            ),
                            child: logoUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(25),
                                    child: Image.network(
                                      logoUrl,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Image.asset(
                                      'assets/icons/icon_masjid.png',
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  masjid['name'] ?? 'Unknown Masjid',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_rounded,
                                      size: 14,
                                      color: accentColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        masjid['address'] ?? '',
                                        style: TextStyle(
                                          color: textColor.withValues(
                                            alpha: 0.7,
                                          ),
                                          fontSize: 12,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (distanceStr != null) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        distanceStr,
                                        style: TextStyle(
                                          color: accentColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if (masjid['facilities'] != null &&
                                    (masjid['facilities'] as Map)
                                        .isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    children: (masjid['facilities'] as Map)
                                        .entries
                                        .where((e) => e.value == true)
                                        .take(3)
                                        .map(
                                          (e) => _buildFacilityChip(
                                            e.key,
                                            accentColor,
                                            isDark,
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ],
                              ],
                            ),
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

  Widget _buildPlaceholder(Color accentColor) {
    return Center(
      child: Image.asset('assets/icons/icon_masjid.png', width: 50, height: 50),
    );
  }

  Widget _buildFacilityChip(String label, Color accentColor, bool isDark) {
    final name = label.replaceAll('_', ' ').toUpperCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
      ),
      child: Text(
        name,
        style: TextStyle(
          color: accentColor,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getStatusColor(dynamic status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
