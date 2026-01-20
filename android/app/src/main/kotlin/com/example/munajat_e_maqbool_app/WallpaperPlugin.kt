package com.example.munajat_e_maqbool_app

import android.app.WallpaperManager
import android.content.Context
import android.graphics.BitmapFactory
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File

class WallpaperPlugin: FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.munajat.wallpaper")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "setWallpaper" -> {
                val imagePath = call.argument<String>("path")
                if (imagePath != null) {
                    setWallpaper(imagePath, result)
                } else {
                    result.error("INVALID_ARGUMENT", "Image path is required", null)
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun setWallpaper(imagePath: String, result: Result) {
        try {
            val wallpaperManager = WallpaperManager.getInstance(context)
            val bitmap = BitmapFactory.decodeFile(imagePath)
            
            if (bitmap != null) {
                wallpaperManager.setBitmap(bitmap, null, true, WallpaperManager.FLAG_LOCK)
                result.success("Wallpaper set successfully")
            } else {
                result.error("BITMAP_ERROR", "Failed to decode image", null)
            }
        } catch (e: Exception) {
            result.error("WALLPAPER_ERROR", "Failed to set wallpaper: ${e.message}", null)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}