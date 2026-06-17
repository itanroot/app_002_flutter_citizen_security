package com.example.seguridad_ciudadana_app

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Build
import android.os.Bundle
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import org.json.JSONObject
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL

class BackgroundLocationService : Service(), LocationListener {
  private lateinit var locationManager: LocationManager
  private var authToken: String? = null
  private var endpoint: String? = null
  private var lastSentLocation: Location? = null
  private var lastSentTimestampMs: Long = 0

  companion object {
    const val CHANNEL_ID = "background_location_channel"
    const val NOTIFICATION_ID = 8921
    private const val MIN_SEND_DISTANCE_METERS = 25f
    private const val MIN_SEND_INTERVAL_MS = 60000L
  }

  override fun onCreate() {
    super.onCreate()
    locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
  }

  override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
    authToken = intent?.getStringExtra("authToken")
    endpoint = intent?.getStringExtra("endpoint")

    if (authToken.isNullOrEmpty() || endpoint.isNullOrEmpty()) {
      stopSelf()
      return START_NOT_STICKY
    }

    createNotificationChannel()
    startForeground(NOTIFICATION_ID, buildNotification())
    startLocationUpdates()

    return START_STICKY
  }

  override fun onDestroy() {
    stopLocationUpdates()
    super.onDestroy()
  }

  override fun onBind(intent: Intent?): IBinder? = null

  private fun createNotificationChannel() {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
      val channel = NotificationChannel(
        CHANNEL_ID,
        "Background location tracking",
        NotificationManager.IMPORTANCE_LOW,
      ).apply {
        description = "Location updates running in the background"
      }
      val manager = getSystemService(NotificationManager::class.java)
      manager.createNotificationChannel(channel)
    }
  }

  private fun buildNotification(): Notification {
    val notificationIntent = packageManager.getLaunchIntentForPackage(packageName)
      ?: Intent(this, MainActivity::class.java)
    val pendingIntent = PendingIntent.getActivity(
      this,
      0,
      notificationIntent,
      PendingIntent.FLAG_UPDATE_CURRENT or if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0,
    )

    return NotificationCompat.Builder(this, CHANNEL_ID)
      .setContentTitle("Serenazgo tracking activo")
      .setContentText("La ubicación se está enviando en segundo plano")
      .setSmallIcon(android.R.drawable.ic_menu_mylocation)
      .setContentIntent(pendingIntent)
      .setOngoing(true)
      .build()
  }

  private fun startLocationUpdates() {
    val hasFineLocation = ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
    val hasCoarseLocation = ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED
    val hasBackgroundLocation = ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_BACKGROUND_LOCATION) == PackageManager.PERMISSION_GRANTED

    if (!hasFineLocation && !hasCoarseLocation) {
      stopSelf()
      return
    }

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && !hasBackgroundLocation) {
      stopSelf()
      return
    }

    try {
      locationManager.requestLocationUpdates(LocationManager.GPS_PROVIDER, 15000L, 10f, this)
    } catch (_: Exception) {
      // Ignore GPS provider errors; continue with network provider if possible.
    }

    try {
      locationManager.requestLocationUpdates(LocationManager.NETWORK_PROVIDER, 15000L, 10f, this)
    } catch (_: Exception) {
      // Ignore network provider errors.
    }
  }

  private fun stopLocationUpdates() {
    try {
      locationManager.removeUpdates(this)
    } catch (_: Exception) {
      // ignore
    }
  }

  override fun onLocationChanged(location: Location) {
    if (shouldSendLocation(location)) {
      sendLocation(location)
      lastSentLocation = location
      lastSentTimestampMs = location.time
    }
  }

  private fun shouldSendLocation(location: Location): Boolean {
    val previousLocation = lastSentLocation
    if (previousLocation == null) {
      return true
    }

    val distance = location.distanceTo(previousLocation)
    val timeDelta = location.time - lastSentTimestampMs

    return distance >= MIN_SEND_DISTANCE_METERS || timeDelta >= MIN_SEND_INTERVAL_MS
  }

  override fun onProviderEnabled(provider: String) {}

  override fun onProviderDisabled(provider: String) {}

  override fun onStatusChanged(provider: String, status: Int, extras: Bundle?) {}

  private fun sendLocation(location: Location) {
    val targetUrl = endpoint ?: return
    val token = authToken ?: return

    Thread {
      try {
        val url = URL(targetUrl)
        val roundedLatitude = String.format("%.6f", location.latitude).toDouble()
        val roundedLongitude = String.format("%.6f", location.longitude).toDouble()
        val body = JSONObject().apply {
          put("latitude", roundedLatitude)
          put("longitude", roundedLongitude)
          put("timestamp", location.time)
        }

        val connection = (url.openConnection() as HttpURLConnection).apply {
          requestMethod = "POST"
          connectTimeout = 15000
          readTimeout = 15000
          doOutput = true
          setRequestProperty("Content-Type", "application/json; charset=UTF-8")
          setRequestProperty("Authorization", "Bearer $token")
        }

        OutputStreamWriter(connection.outputStream, "UTF-8").use { it.write(body.toString()) }
        connection.inputStream.close()
        connection.disconnect()

        MainActivity.sendLocationEvent(mapOf(
          "latitude" to roundedLatitude,
          "longitude" to roundedLongitude,
          "timestamp" to location.time,
        ))
      } catch (exception: Exception) {
        Log.e("BackgroundLocationService", "Failed to send location", exception)
      }
    }.start()
  }
}
