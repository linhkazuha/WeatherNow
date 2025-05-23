package com.example.weather_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import java.text.SimpleDateFormat
import java.util.*

class WeatherWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            // Lấy dữ liệu từ bộ nhớ dùng chung
            val widgetData = HomeWidgetPlugin.getData(context)
            val weatherText = widgetData.getString("weather_widget_data", "--°C") ?: "--°C"
            val locationText = widgetData.getString("weather_widget_location", "Vị trí không xác định") ?: "Vị trí không xác định"
            val descriptionText = widgetData.getString("weather_widget_description", "không có dữ liệu") ?: "không có dữ liệu"
            val iconCode = widgetData.getString("weather_widget_icon", "01d") ?: "01d"

            // Tạo thời gian cập nhật
            val dateFormat = SimpleDateFormat("HH:mm", Locale.getDefault())
            val currentTime = dateFormat.format(Date())
            val updateTimeText = "Cập nhật lúc: $currentTime"

            // Cập nhật widget
            val views = RemoteViews(context.packageName, R.layout.weather_widget_layout)
            views.setTextViewText(R.id.widget_text, weatherText)
            views.setTextViewText(R.id.location_text, locationText)
            views.setTextViewText(R.id.description_text, descriptionText)
            views.setTextViewText(R.id.update_time_text, updateTimeText)
            
            // Thiết lập icon thời tiết
            try {
                val iconResourceId = getWeatherIconResource(iconCode)
                views.setImageViewResource(R.id.weather_icon, iconResourceId)
            } catch (e: Exception) {
                // Sử dụng icon mặc định nếu có lỗi
                views.setImageViewResource(R.id.weather_icon, android.R.drawable.ic_menu_compass)
            }

            // Tạo intent để mở ứng dụng khi nhấn vào widget
            val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            if (intent != null) {
                // Đảm bảo intent này mở ứng dụng mới thay vì sử dụng instance đã có
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
                
                // Tạo PendingIntent từ intent
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    0,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                
                // Thiết lập để khi nhấn vào widget sẽ mở ứng dụng
                views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
    
    // Hàm chuyển đổi từ mã icon thời tiết sang resource id
    private fun getWeatherIconResource(iconCode: String): Int {
        return when (iconCode) {
            "01d" -> R.drawable.clear_day 
            "01n" -> R.drawable.clear_night
            "02d" -> R.drawable.few_clouds_day
            "02n" -> R.drawable.few_clouds_night
            "03d", "03n" -> R.drawable.scattered_clouds
            "04d", "04n" -> R.drawable.broken_clouds
            "09d", "09n" -> R.drawable.shower_rain
            "10d" -> R.drawable.rain_day
            "10n" -> R.drawable.rain_night
            "11d", "11n" -> R.drawable.thunderstorm
            "13d", "13n" -> R.drawable.snow
            "50d", "50n" -> R.drawable.mist
            else -> android.R.drawable.ic_menu_compass // Sử dụng icon mặc định từ hệ thống
        }
    }
}