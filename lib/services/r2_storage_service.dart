import 'dart:io';
import 'package:http/http.dart' as http;

class R2StorageService {
  // Use the custom domain you set up
  static const String customDomain = 'app.oasismm.site';

  // MUST match the password you put in your Cloudflare Worker code
  static const String workerSecret = 'my-super-secret-password';

  Future<String?> uploadFile({
    required File file,
    required String path,
    String? contentType,
  }) async {
    try {
      final fileBytes = await file.readAsBytes();
      final mimeType = contentType ?? _getContentType(path);
      final fileSizeMB = fileBytes.length / (1024 * 1024);

      // 1. Prepare the URL (Targeting your Worker)
      // Example: https://app.oasismm.site/shop-images/ads/photo.jpg
      final uri = Uri.parse('https://$customDomain/$path');

      print('📤 Uploading to: $uri');
      print('📊 File size: ${fileSizeMB.toStringAsFixed(2)} MB');

      // 2. Use client with extended timeout
      final client = http.Client();
      try {
        final request = http.Request('PUT', uri);
        request.headers['x-upload-secret'] = workerSecret;
        request.headers['Content-Type'] = mimeType;
        request.bodyBytes = fileBytes;

        // Send request with reasonable timeout (5 minutes)
        final streamedResponse = await client
            .send(request)
            .timeout(
              const Duration(minutes: 5),
              onTimeout: () {
                throw Exception(
                  'Upload timeout - check your internet connection',
                );
              },
            );

        final response = await http.Response.fromStream(streamedResponse);

        // 3. Check Result
        if (response.statusCode == 200) {
          print('✅ Upload Success: $uri');
          return uri.toString();
        } else {
          print('❌ Upload Failed: ${response.statusCode}');
          print('Response Body: ${response.body}');
          return null;
        }
      } finally {
        client.close();
      }
    } catch (e) {
      print('❌ Upload Error: $e');
      return null;
    }
  }

  // Helper to guess content type
  String _getContentType(String path) {
    if (path.endsWith('.jpg') || path.endsWith('.jpeg')) return 'image/jpeg';
    if (path.endsWith('.png')) return 'image/png';
    if (path.endsWith('.apk')) return 'application/vnd.android.package-archive';
    return 'application/octet-stream';
  }

  // Delete File
  Future<bool> deleteFile(String path) async {
    try {
      final uri = Uri.parse('https://$customDomain/$path');
      print('🗑️ Deleting: $uri');

      final response = await http.delete(
        uri,
        headers: {'x-upload-secret': workerSecret},
      );

      if (response.statusCode == 200) {
        print('✅ Delete Success: $uri');
        return true;
      } else {
        print('❌ Delete Failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Delete Error: $e');
      return false;
    }
  }

  // Get Public URL
  String getPublicUrl(String path) {
    return 'https://$customDomain/$path';
  }
}
