import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class ShopImageService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  static const String _bucketName = 'shop-images';

  /// Create the storage bucket if it doesn't exist
  /// Note: This should be done via Supabase dashboard or migration

  /// Pick image from gallery
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (image != null) {
        return File(image.path);
      }
    } catch (e) {
      debugPrint('Pick image error: $e');
    }
    return null;
  }

  /// Pick image from camera
  Future<File?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (image != null) {
        return File(image.path);
      }
    } catch (e) {
      debugPrint('Camera error: $e');
    }
    return null;
  }

  /// Upload image to Supabase Storage
  Future<String?> uploadImage({
    required File file,
    required String shopId,
    required String imageType, // logo, cover, gallery
  }) async {
    try {
      final ext = path.extension(file.path);
      final fileName =
          '${shopId}_${imageType}_${DateTime.now().millisecondsSinceEpoch}$ext';
      final storagePath = '$shopId/$fileName';

      await _supabase.storage
          .from(_bucketName)
          .upload(
            storagePath,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      // Get public URL
      final publicUrl = _supabase.storage
          .from(_bucketName)
          .getPublicUrl(storagePath);
      return publicUrl;
    } catch (e) {
      debugPrint('Upload error: $e');
      rethrow;
    }
  }

  /// Save image URL to database
  Future<void> saveShopImage({
    required String shopId,
    required String imageUrl,
    required String imageType,
    int displayOrder = 0,
  }) async {
    try {
      // If it's logo or cover, remove existing one first
      if (imageType == 'logo' || imageType == 'cover') {
        await _supabase
            .schema('munajat_app')
            .from('shop_images')
            .delete()
            .eq('shop_id', shopId)
            .eq('image_type', imageType);
      }

      await _supabase.schema('munajat_app').from('shop_images').insert({
        'shop_id': shopId,
        'image_url': imageUrl,
        'image_type': imageType,
        'display_order': displayOrder,
      });
    } catch (e) {
      debugPrint('Save image error: $e');
      rethrow;
    }
  }

  /// Get all images for a shop
  Future<List<Map<String, dynamic>>> getShopImages(String shopId) async {
    try {
      final response = await _supabase
          .schema('munajat_app')
          .from('shop_images')
          .select()
          .eq('shop_id', shopId)
          .order('display_order', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get images error: $e');
      return [];
    }
  }

  /// Get specific image type for a shop
  Future<String?> getShopImage(String shopId, String imageType) async {
    try {
      final response = await _supabase
          .schema('munajat_app')
          .from('shop_images')
          .select('image_url')
          .eq('shop_id', shopId)
          .eq('image_type', imageType)
          .maybeSingle();
      return response?['image_url'] as String?;
    } catch (e) {
      debugPrint('Get image error: $e');
      return null;
    }
  }

  /// Get specific image type for multiple shops
  Future<Map<String, String>> getShopImagesForShops(
    List<String> shopIds,
    String imageType,
  ) async {
    try {
      final response = await _supabase
          .schema('munajat_app')
          .from('shop_images')
          .select('shop_id, image_url')
          .eq('image_type', imageType)
          .filter('shop_id', 'in', shopIds);

      final data = List<Map<String, dynamic>>.from(response);
      return {
        for (var item in data)
          item['shop_id'] as String: item['image_url'] as String,
      };
    } catch (e) {
      debugPrint('Get images for shops error: $e');
      return {};
    }
  }

  /// Delete an image
  Future<void> deleteShopImage(String imageId) async {
    try {
      await _supabase
          .schema('munajat_app')
          .from('shop_images')
          .delete()
          .eq('id', imageId);
    } catch (e) {
      debugPrint('Delete image error: $e');
      rethrow;
    }
  }

  /// Upload and save in one call
  Future<String?> uploadAndSaveImage({
    required File file,
    required String shopId,
    required String imageType,
    int displayOrder = 0,
  }) async {
    final url = await uploadImage(
      file: file,
      shopId: shopId,
      imageType: imageType,
    );

    if (url != null) {
      await saveShopImage(
        shopId: shopId,
        imageUrl: url,
        imageType: imageType,
        displayOrder: displayOrder,
      );
    }

    return url;
  }
}
