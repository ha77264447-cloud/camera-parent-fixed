package com.example.camera_parent

import android.hardware.Camera
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class CameraReleaseChannel {
    companion object {
        const val CHANNEL_NAME = "camera_parent/camera"
        private var camera: Camera? = null
        private const val TAG = "CameraReleaseChannel"

        fun setup(flutterEngine: FlutterEngine) {
            val channel = MethodChannel(flutterEngine.dartExecutor, CHANNEL_NAME)
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "releaseCamera" -> {
                        try {
                            Log.d(TAG, "Releasing camera resources")
                            camera?.release()
                            camera = null
                            Log.d(TAG, "Camera released successfully")
                            result.success(true)
                        } catch (e: Exception) {
                            Log.e(TAG, "Error releasing camera: ${e.message}", e)
                            result.error("CAMERA_ERROR", e.message, null)
                        }
                    }
                    else -> {
                        Log.w(TAG, "Unknown method: ${call.method}")
                        result.notImplemented()
                    }
                }
            }
        }
    }
}
