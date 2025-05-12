package com.example.weather_app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class WeatherWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            // Lấy dữ liệu từ bộ nhớ dùng chung
            val widgetData = HomeWidgetPlugin.getData(context)
            val weatherText = widgetData.getString("weather_widget_data", "test thời tiết")
            val locationText = widgetData.getString("weather_widget_location", "Vị trí không xác định")

            // Cập nhật widget
            val views = RemoteViews(context.packageName, R.layout.weather_widget_layout)
            views.setTextViewText(R.id.widget_text, weatherText)
            views.setTextViewText(R.id.location_text, locationText)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}