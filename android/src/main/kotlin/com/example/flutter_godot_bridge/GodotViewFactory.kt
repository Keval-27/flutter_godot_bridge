package com.example.flutter_godot_bridge

import android.app.Activity
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class GodotViewFactory(
    private val messenger: BinaryMessenger,
    private val activity: Activity
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    companion object {
        private const val TAG = "GodotViewFactory"
    }

    override fun create(context: android.content.Context, viewId: Int, args: Any?): PlatformView {
        Log.d(TAG, "Creating platform view with ID: $viewId")
        val params = args as? Map<String, Any>
        return GodotPlatformView(activity, viewId, params)
    }
}
