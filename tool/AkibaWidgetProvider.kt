package PACKAGE_NAME

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class AkibaWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.akiba_widget).apply {
                setTextViewText(R.id.widget_label, widgetData.getString("label", "Akiba"))
                setTextViewText(R.id.widget_balance, widgetData.getString("balance", "-"))
                setTextViewText(R.id.widget_goal, widgetData.getString("goal", "Akiba"))
                setTextViewText(R.id.widget_today, widgetData.getString("today", ""))
                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java
                )
                setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
