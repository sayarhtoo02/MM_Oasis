import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:munajat_e_maqbool_app/config/glass_theme.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_scaffold.dart';
import 'package:munajat_e_maqbool_app/widgets/glass/glass_card.dart';
import 'package:munajat_e_maqbool_app/providers/settings_provider.dart';
import 'package:munajat_e_maqbool_app/services/ads_service.dart';
import 'package:munajat_e_maqbool_app/services/admin_supabase_client.dart';

class AdsManagementScreen extends StatefulWidget {
  const AdsManagementScreen({super.key});

  @override
  State<AdsManagementScreen> createState() => _AdsManagementScreenState();
}

class _AdsManagementScreenState extends State<AdsManagementScreen> {
  final AdsService _adsService = AdsService();
  // Use admin client for storage operations (bypasses RLS)
  final SupabaseClient _supabase = AdminSupabaseClient.client;
  List<Map<String, dynamic>> _ads = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAds();
  }

  Future<void> _loadAds() async {
    setState(() => _isLoading = true);
    final ads = await _adsService.getAllAds();
    if (mounted) {
      setState(() {
        _ads = ads;
        _isLoading = false;
      });
    }
  }

  Future<String?> _uploadImage(File imageFile) async {
    final fileName = 'ad_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = 'ads-banners/$fileName';

    debugPrint('Uploading image to: shop-images/$path');

    // Upload the file
    await _supabase.storage.from('shop-images').upload(path, imageFile);
    debugPrint('Upload successful');

    // Get public URL
    final url = _supabase.storage.from('shop-images').getPublicUrl(path);
    debugPrint('Public URL: $url');
    return url;
  }

  Future<void> _showAdDialog({Map<String, dynamic>? ad}) async {
    final isEdit = ad != null;
    final titleController = TextEditingController(text: ad?['title'] ?? '');
    final descController = TextEditingController(
      text: ad?['description'] ?? '',
    );
    String? imageUrl = ad?['image_url'];
    File? selectedImage;
    final linkUrlController = TextEditingController(
      text: ad?['link_url'] ?? '',
    );
    final priorityController = TextEditingController(
      text: (ad?['priority'] ?? 0).toString(),
    );
    bool isActive = ad?['is_active'] ?? true;
    DateTime? startDate = ad?['start_date'] != null
        ? DateTime.parse(ad!['start_date'])
        : DateTime.now();
    DateTime? endDate = ad?['end_date'] != null
        ? DateTime.parse(ad!['end_date'])
        : null;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(isEdit ? 'Edit Ad' : 'Create Ad'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title *'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),

                  // Image Upload Section
                  const Text(
                    'Banner Image',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final picked = await picker.pickImage(
                        source: ImageSource.gallery,
                      );
                      if (picked != null) {
                        // Crop the image with 2:1 aspect ratio for banner
                        final croppedFile = await ImageCropper().cropImage(
                          sourcePath: picked.path,
                          aspectRatio: const CropAspectRatio(
                            ratioX: 2,
                            ratioY: 1,
                          ),
                          uiSettings: [
                            AndroidUiSettings(
                              toolbarTitle: 'Crop Banner Image',
                              toolbarColor: const Color(0xFF0D3B2E),
                              toolbarWidgetColor: Colors.white,
                              initAspectRatio: CropAspectRatioPreset.ratio16x9,
                              lockAspectRatio: true,
                            ),
                            IOSUiSettings(
                              title: 'Crop Banner Image',
                              aspectRatioLockEnabled: true,
                            ),
                          ],
                        );
                        if (croppedFile != null) {
                          setDialogState(() {
                            selectedImage = File(croppedFile.path);
                          });
                        }
                      }
                    },
                    child: Container(
                      height: 100,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[400]!),
                      ),
                      child: selectedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                selectedImage!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : imageUrl != null && imageUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildImagePlaceholder(),
                              ),
                            )
                          : _buildImagePlaceholder(),
                    ),
                  ),

                  const SizedBox(height: 8),
                  TextField(
                    controller: linkUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Link URL (optional)',
                      hintText: 'https://...',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: priorityController,
                    decoration: const InputDecoration(
                      labelText: 'Priority',
                      hintText: 'Higher = shown first',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Active'),
                    value: isActive,
                    onChanged: (v) => setDialogState(() => isActive = v),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: startDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (date != null) {
                              setDialogState(() => startDate = date);
                            }
                          },
                          child: Text(
                            startDate != null
                                ? 'Start: ${DateFormat('MMM d').format(startDate!)}'
                                : 'Set Start Date',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate:
                                  endDate ??
                                  DateTime.now().add(const Duration(days: 30)),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (date != null) {
                              setDialogState(() => endDate = date);
                            }
                          },
                          child: Text(
                            endDate != null
                                ? 'End: ${DateFormat('MMM d').format(endDate!)}'
                                : 'No End Date',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(isEdit ? 'Update' : 'Create'),
              ),
            ],
          );
        },
      ),
    );

    if (result == true && titleController.text.isNotEmpty) {
      // Upload image if selected
      String? finalImageUrl = imageUrl;
      if (selectedImage != null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Uploading image...')));
        }
        try {
          finalImageUrl = await _uploadImage(selectedImage!);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Image upload failed: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return; // Don't create ad if image upload fails
        }
      }

      final adData = {
        'title': titleController.text,
        'description': descController.text,
        'image_url': finalImageUrl,
        'link_url': linkUrlController.text.isEmpty
            ? null
            : linkUrlController.text,
        'priority': int.tryParse(priorityController.text) ?? 0,
        'is_active': isActive,
        // Convert to UTC to ensure consistent timezone handling with database
        'start_date': startDate?.toUtc().toIso8601String(),
        'end_date': endDate?.toUtc().toIso8601String(),
      };

      try {
        if (isEdit) {
          await _adsService.updateAd(ad['id'], adData);
        } else {
          await _adsService.createAd(adData);
        }
        await _loadAds();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isEdit ? 'Ad updated!' : 'Ad created!'),
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

  Widget _buildImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate, size: 32, color: Colors.grey[500]),
        const SizedBox(height: 4),
        Text(
          'Tap to upload',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }

  Future<void> _deleteAd(Map<String, dynamic> ad) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Ad?'),
        content: Text('Delete "${ad['title']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _adsService.deleteAd(ad['id']);
        await _loadAds();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Ad deleted')));
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

        return GlassScaffold(
          title: 'Ads Management',
          actions: [
            IconButton(
              icon: Icon(Icons.add, color: textColor),
              onPressed: () => _showAdDialog(),
            ),
          ],
          body: _isLoading
              ? Center(child: CircularProgressIndicator(color: accentColor))
              : _ads.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.campaign,
                        size: 64,
                        color: textColor.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No ads yet',
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _showAdDialog(),
                        child: const Text('Create Ad'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAds,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _ads.length,
                    itemBuilder: (context, index) {
                      final ad = _ads[index];
                      return _buildAdCard(ad, isDark, textColor, accentColor);
                    },
                  ),
                ),
        );
      },
    );
  }

  Widget _buildAdCard(
    Map<String, dynamic> ad,
    bool isDark,
    Color textColor,
    Color accentColor,
  ) {
    final isActive = ad['is_active'] as bool? ?? true;
    final imageUrl = ad['image_url'] as String?;
    final viewCount = ad['view_count'] as int? ?? 0;
    final clickCount = ad['click_count'] as int? ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        isDark: isDark,
        borderRadius: 16,
        onTap: () => _showAdDialog(ad: ad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image preview
            if (imageUrl != null && imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Image.network(
                  imageUrl,
                  height: 100,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 100,
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image, size: 40),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          ad['title'] ?? 'Ad',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.green.withValues(alpha: 0.2)
                              : Colors.grey.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isActive ? 'ACTIVE' : 'INACTIVE',
                          style: TextStyle(
                            color: isActive ? Colors.green : Colors.grey,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red,
                          size: 20,
                        ),
                        onPressed: () => _deleteAd(ad),
                      ),
                    ],
                  ),
                  if (ad['description'] != null &&
                      (ad['description'] as String).isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      ad['description'],
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.6),
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.visibility,
                        size: 14,
                        color: textColor.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$viewCount views',
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.touch_app,
                        size: 14,
                        color: textColor.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$clickCount clicks',
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Priority: ${ad['priority'] ?? 0}',
                        style: TextStyle(color: accentColor, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
