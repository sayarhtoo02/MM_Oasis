import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../models/dua_model.dart';

class LockScreenService {
  static Future<void> setDuaAsWallpaper(Dua dua, BuildContext context) async {
    try {
      // Create wallpaper with dua text
      final wallpaperPath = await _createDuaWallpaper(dua, context);

      // Set as wallpaper using platform channel
      await _setWallpaper(wallpaperPath);
    } catch (e) {
      throw Exception('Failed to set wallpaper: $e');
    }
  }

  static Future<String> _createDuaWallpaper(
    Dua dua,
    BuildContext context,
  ) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = const Size(1080, 1920); // Full HD resolution

    // Background gradient
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF1B5E20),
        const Color(0xFF2E7D32),
        const Color(0xFF388E3C),
      ],
    );

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Draw Arabic text
    final arabicTextPainter = TextPainter(
      text: TextSpan(
        text: dua.arabicText,
        style: const TextStyle(
          fontSize: 32,
          color: Colors.white,
          fontFamily: 'Indopak',
          letterSpacing: 0,
          height: 1.8,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.rtl,
    );

    arabicTextPainter.layout(maxWidth: size.width - 80);
    arabicTextPainter.paint(canvas, Offset(40, size.height * 0.3));

    // Draw app name
    final appNamePainter = TextPainter(
      text: const TextSpan(
        text: 'مناجات مقبول',
        style: TextStyle(
          fontSize: 24,
          color: Color(0xFFFFB300),
          fontFamily: 'Indopak',
          letterSpacing: 0,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.rtl,
    );

    appNamePainter.layout(maxWidth: size.width - 80);
    appNamePainter.paint(
      canvas,
      Offset((size.width - appNamePainter.width) / 2, size.height * 0.8),
    );

    // Convert to image
    final picture = recorder.endRecording();
    final image = await picture.toImage(
      size.width.toInt(),
      size.height.toInt(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    // Save to file
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/dua_wallpaper.png');
    await file.writeAsBytes(bytes);

    return file.path;
  }

  static Future<void> _setWallpaper(String imagePath) async {
    try {
      const platform = MethodChannel('com.munajat.wallpaper');
      await platform.invokeMethod('setWallpaper', {'path': imagePath});
    } catch (e) {
      // Fallback: Save image to gallery for manual wallpaper setting
      throw Exception('Please set wallpaper manually from gallery');
    }
  }
}
