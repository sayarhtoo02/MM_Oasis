import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

import 'package:munajat_e_maqbool_app/services/r2_storage_service.dart';

class MasjidImageService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();
  final R2StorageService _r2Storage = R2StorageService();

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

  /// Upload image to R2 Storage
  Future<String?> uploadImage({
    required File file,
    required String masjidId,
    required String imageType, // logo, exterior, interior
  }) async {
    try {
      final ext = path.extension(file.path);
      final fileName =
          '${masjidId}_${imageType}_${DateTime.now().millisecondsSinceEpoch}$ext';
      final storagePath = 'masjid-images/$masjidId/$fileName';

      // Upload to R2
      final publicUrl = await _r2Storage.uploadFile(
        file: file,
        path: storagePath,
        contentType: 'image/${ext.replaceAll('.', '')}',
      );

      return publicUrl;
    } catch (e) {
      debugPrint('Upload error: $e');
      rethrow;
    }
  }

  /// Save image URL to database
  Future<void> saveMasjidImage({
    required String masjidId,
    required String imageUrl,
    required String imageType,
    int displayOrder = 0,
  }) async {
    try {
      // If it's logo or exterior, remove existing one first (optional, following shop pattern)
      if (imageType == 'logo') {
        await _supabase
            .schema('munajat_app')
            .from('masjid_images')
            .delete()
            .eq('masjid_id', masjidId)
            .eq('image_type', imageType);
      }

      await _supabase.schema('munajat_app').from('masjid_images').insert({
        'masjid_id': masjidId,
        'image_url': imageUrl,
        'image_type': imageType,
        'display_order': displayOrder,
      });
    } catch (e) {
      debugPrint('Save image error: $e');
      rethrow;
    }
  }

  /// Get all images for a masjid
  Future<List<Map<String, dynamic>>> getMasjidImages(String masjidId) async {
    try {
      final response = await _supabase
          .schema('munajat_app')
          .from('masjid_images')
          .select()
          .eq('masjid_id', masjidId)
          .order('display_order', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get images error: $e');
      return [];
    }
  }

  /// Get specific image types for multiple masjids
  Future<Map<String, String>> getMasjidImagesForMasjids(
    List<String> masjidIds,
    String imageType,
  ) async {
    try {
      final response = await _supabase
          .schema('munajat_app')
          .from('masjid_images')
          .select('masjid_id, image_url')
          .eq('image_type', imageType)
          .filter('masjid_id', 'in', masjidIds);

      final data = List<Map<String, dynamic>>.from(response);
      return {
        for (var item in data)
          item['masjid_id'] as String: item['image_url'] as String,
      };
    } catch (e) {
      debugPrint('Get images for masjids error: $e');
      return {};
    }
  }

  /// Upload and save in one call
  Future<String?> uploadAndSaveImage({
    required File file,
    required String masjidId,
    required String imageType,
    int displayOrder = 0,
  }) async {
    final url = await uploadImage(
      file: file,
      masjidId: masjidId,
      imageType: imageType,
    );

    if (url != null) {
      await saveMasjidImage(
        masjidId: masjidId,
        imageUrl: url,
        imageType: imageType,
        displayOrder: displayOrder,
      );
    }

    return url;
  }
}
