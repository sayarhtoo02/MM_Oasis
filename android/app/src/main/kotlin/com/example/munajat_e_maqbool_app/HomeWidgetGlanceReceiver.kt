package com.example.munajat_e_maqbool_app

import es.antonborri.home_widget.HomeWidgetProvider
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import android.app.PendingIntent
import android.content.Intent
import android.os.Build
import android.util.Log
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Typeface
import android.text.Layout
import android.text.StaticLayout
import android.text.TextPaint
import androidx.core.content.res.ResourcesCompat

class HomeWidgetGlanceReceiver : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            val arabicText = widgetData.getString("widget_arabic_text", null) ?: "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ"
            val translation = widgetData.getString("widget_translation", null) ?: "Select a dua from the app to display here"
            val progress = widgetData.getString("widget_progress", null) ?: "Day 1"
            val dayName = java.text.SimpleDateFormat("EEEE", java.util.Locale.getDefault()).format(java.util.Date())
            
            Log.d("HomeWidget", "Updating widget $widgetId")
            
            val views = RemoteViews(context.packageName, R.layout.home_screen_widget).apply {
                // Create bitmap with custom font for Arabic text
                val arabicBitmap = createTextBitmap(context, arabicText, 1200, 600)
                setImageViewBitmap(R.id.widget_arabic_image, arabicBitmap)
                
                setTextViewText(R.id.widget_translation, translation)
                setTextViewText(R.id.widget_progress, progress)
                setTextViewText(R.id.widget_date, dayName)
                
                val intent = Intent(context, MainActivity::class.java)
                intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                
                val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                } else {
                    PendingIntent.FLAG_UPDATE_CURRENT
                }
                
                val pendingIntent = PendingIntent.getActivity(context, 0, intent, flags)
                
                setOnClickPendingIntent(R.id.widget_arabic_image, pendingIntent)
                setOnClickPendingIntent(R.id.main_content, pendingIntent)
                setOnClickPendingIntent(R.id.footer_section, pendingIntent)
            }
            
            appWidgetManager.updateAppWidget(widgetId, views)
            Log.d("HomeWidget", "Widget $widgetId updated successfully")
        }
    }
    
    private fun createTextBitmap(context: Context, text: String, width: Int, height: Int): Bitmap {
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        
        val paint = TextPaint().apply {
            color = android.graphics.Color.parseColor("#1B5E20")
            textSize = 140f
            isAntiAlias = true
            
            // Load custom font
            try {
                val typeface = ResourcesCompat.getFont(context, R.font.arabic_font)
                if (typeface != null) {
                    this.typeface = typeface
                }
            } catch (e: Exception) {
                Log.e("HomeWidget", "Error loading font: ${e.message}")
            }
        }
        
        // Create multi-line text layout with proper centering
        val textWidth = width - 120
        val staticLayout = StaticLayout.Builder.obtain(text, 0, text.length, paint, textWidth)
            .setAlignment(Layout.Alignment.ALIGN_CENTER)
            .setLineSpacing(25f, 1f)
            .setMaxLines(4)
            .build()
        
        // Center the text both horizontally and vertically
        val textHeight = staticLayout.height
        val x = (width - textWidth) / 2f
        val y = (height - textHeight) / 2f
        
        canvas.save()
        canvas.translate(x, y)
        staticLayout.draw(canvas)
        canvas.restore()
        
        return bitmap
    }
}