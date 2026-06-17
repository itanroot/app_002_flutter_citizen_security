package com.example.seguridad_ciudadana_app

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
  private val channelName = "com.example.seguridad_ciudadana_app/background_location"
  private val eventChannelName = "com.example.seguridad_ciudadana_app/background_location_events"
  private val foregroundLocationRequestCode = 1001
  private var pendingPermissionResult: MethodChannel.Result? = null

  companion object {
    private var eventSink: EventChannel.EventSink? = null

    fun sendLocationEvent(data: Map<String, Any?>) {
      eventSink?.success(data)
    }
  }

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)

    EventChannel(flutterEngine.dartExecutor.binaryMessenger, eventChannelName).setStreamHandler(object : EventChannel.StreamHandler {
      override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
      }

      override fun onCancel(arguments: Any?) {
        eventSink = null
      }
    })

    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
      when (call.method) {
        "requestForegroundServiceLocationPermission" -> {
          if (hasForegroundServiceLocationPermission()) {
            result.success(true)
            return@setMethodCallHandler
          }

          if (pendingPermissionResult != null) {
            result.error("PERMISSION_IN_PROGRESS", "A permission request is already in progress.", null)
            return@setMethodCallHandler
          }

          pendingPermissionResult = result
          ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.FOREGROUND_SERVICE_LOCATION),
            foregroundLocationRequestCode,
          )
        }
        "start" -> {
          val token = call.argument<String>("token")
          val endpoint = call.argument<String>("endpoint")

          if (token.isNullOrEmpty() || endpoint.isNullOrEmpty()) {
            result.error("INVALID_ARGUMENTS", "Token and endpoint are required.", null)
            return@setMethodCallHandler
          }

          val intent = Intent(this, BackgroundLocationService::class.java).apply {
            putExtra("authToken", token)
            putExtra("endpoint", endpoint)
          }

          if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            ContextCompat.startForegroundService(this, intent)
          } else {
            startService(intent)
          }

          result.success(null)
        }
        "stop" -> {
          val intent = Intent(this, BackgroundLocationService::class.java)
          stopService(intent)
          result.success(null)
        }
        else -> result.notImplemented()
      }
    }
  }

  private fun hasForegroundServiceLocationPermission(): Boolean {
    return ContextCompat.checkSelfPermission(
      this,
      Manifest.permission.FOREGROUND_SERVICE_LOCATION,
    ) == PackageManager.PERMISSION_GRANTED
  }

  override fun onRequestPermissionsResult(
    requestCode: Int,
    permissions: Array<out String>,
    grantResults: IntArray,
  ) {
    if (requestCode == foregroundLocationRequestCode) {
      val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
      pendingPermissionResult?.success(granted)
      pendingPermissionResult = null
      return
    }
    super.onRequestPermissionsResult(requestCode, permissions, grantResults)
  }
}

