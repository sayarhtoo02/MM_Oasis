import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:munajat_e_maqbool_app/config/glass_theme.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_scaffold.dart';
import 'package:munajat_e_maqbool_app/providers/settings_provider.dart';
import 'package:munajat_e_maqbool_app/services/shop_image_service.dart';
import 'package:munajat_e_maqbool_app/services/subscription_service.dart';
import 'package:munajat_e_maqbool_app/screens/halal_shop/subscription_screen.dart';

class ShopImageManager extends StatefulWidget {
  final String shopId;
  final String shopName;

  const ShopImageManager({
    super.key,
    required this.shopId,
    required this.shopName,
  });

  @override
  State<ShopImageManager> createState() => _ShopImageManagerState();
}

class _ShopImageManagerState extends State<ShopImageManager> {
  final ShopImageService _imageService = ShopImageService();
  List<Map<String, dynamic>> _images = [];
  bool _isLoading = true;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    setState(() => _isLoading = true);
    final images = await _imageService.getShopImages(widget.shopId);
    if (mounted) {
      setState(() {
        _images = images;
        _isLoading = false;
      });
    }
  }

  String? _getImageByType(String type) {
    final image = _images.where((img) => img['image_type'] == type).firstOrNull;
    return image?['image_url'] as String?;
  }

  List<Map<String, dynamic>> _getGalleryImages() {
    return _images.where((img) => img['image_type'] == 'gallery').toList();
  }

  Future<void> _uploadImage(String imageType) async {
    // Check limit for gallery images
    if (imageType == 'gallery') {
      final canAdd = await SubscriptionService().canAddImage(widget.shopId);
      if (!canAdd) {
        if (mounted) _showUpgradeDialog();
        return;
      }
    }

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    File? file;
    if (source == ImageSource.gallery) {
      file = await _imageService.pickImageFromGallery();
    } else {
      file = await _imageService.pickImageFromCamera();
    }

    if (file == null || !mounted) return;

    setState(() => _isUploading = true);

    try {
      await _imageService.uploadAndSaveImage(
        file: file,
        shopId: widget.shopId,
        imageType: imageType,
        displayOrder: imageType == 'gallery' ? _getGalleryImages().length : 0,
      );
      await _loadImages();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _deleteImage(String imageId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Image?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _imageService.deleteShopImage(imageId);
      await _loadImages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    }
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limit Reached'),
        content: const Text(
          'You have reached the maximum number of gallery images for your current plan. Please upgrade to add more images.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
              );
            },
            child: const Text('Upgrade Plan'),
          ),
        ],
      ),
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
          title: 'Manage Images',
          body: _isLoading
              ? Center(child: CircularProgressIndicator(color: accentColor))
              : Stack(
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Logo Section
                          _buildImageSection(
                            'Logo',
                            'logo',
                            _getImageByType('logo'),
                            isDark,
                            textColor,
                            accentColor,
                            aspectRatio: 1,
                            size: 120,
                          ),
                          const SizedBox(height: 24),

                          // Cover Section
                          _buildImageSection(
                            'Cover Image',
                            'cover',
                            _getImageByType('cover'),
                            isDark,
                            textColor,
                            accentColor,
                            aspectRatio: 16 / 9,
                          ),
                          const SizedBox(height: 24),

                          // Gallery Section
                          Text(
                            'Gallery Images',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add photos of your shop, food, and ambiance',
                            style: TextStyle(
                              color: textColor.withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildGalleryGrid(isDark, textColor, accentColor),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                    if (_isUploading)
                      Container(
                        color: Colors.black54,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(color: accentColor),
                              const SizedBox(height: 16),
                              Text(
                                'Uploading...',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildImageSection(
    String title,
    String imageType,
    String? imageUrl,
    bool isDark,
    Color textColor,
    Color accentColor, {
    double aspectRatio = 1,
    double? size,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _uploadImage(imageType),
          child: Container(
            width: size ?? double.infinity,
            height: size,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.1),
              ),
            ),
            child: imageUrl != null
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: size != null
                            ? Image.network(
                                imageUrl,
                                width: size,
                                height: size,
                                fit: BoxFit.cover,
                              )
                            : AspectRatio(
                                aspectRatio: aspectRatio,
                                child: Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                ),
                              ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 20,
                            ),
                            onPressed: () => _uploadImage(imageType),
                          ),
                        ),
                      ),
                    ],
                  )
                : AspectRatio(
                    aspectRatio: aspectRatio,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 40,
                          color: accentColor,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to add $title',
                          style: TextStyle(
                            color: textColor.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildGalleryGrid(bool isDark, Color textColor, Color accentColor) {
    final galleryImages = _getGalleryImages();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: galleryImages.length + 1, // +1 for add button
      itemBuilder: (context, index) {
        if (index == galleryImages.length) {
          // Add button
          return GestureDetector(
            onTap: () => _uploadImage('gallery'),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.3),
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, color: accentColor, size: 32),
                  const SizedBox(height: 4),
                  Text(
                    'Add',
                    style: TextStyle(color: accentColor, fontSize: 11),
                  ),
                ],
              ),
            ),
          );
        }

        final image = galleryImages[index];
        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                image['image_url'],
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _deleteImage(image['id']),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
