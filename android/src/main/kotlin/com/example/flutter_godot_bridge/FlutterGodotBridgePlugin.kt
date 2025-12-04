package com.example.flutter_godot_bridge

import android.app.Activity
import android.content.Intent
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class FlutterGodotBridgePlugin: FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private var activity: Activity? = null

    companion object {
        var instance: FlutterGodotBridgePlugin? = null
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "flutter_godot_bridge")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method == "launchGodot") {
            val currentActivity = activity
            if (currentActivity == null) {
                result.error("NO_ACTIVITY", "Cannot launch Godot, the app's activity is not available.", null)
                return
            }

            try {
                // THE FINAL FIX: Use the 'res://' prefix. This tells Godot to look for
                // the file within its own virtual file system for Android assets.
                val godotPckFile = "res://dodge_the_creep.pck"

                val godotActivityClass = Class.forName("com.example.flutter_godot_bridge_example.GodotGameActivity")
                val intent = Intent(currentActivity, godotActivityClass)

                val args = arrayListOf(
                    "--main-pack", godotPckFile,
                    "--verbose"
                )
                intent.putStringArrayListExtra("command_line_args", args)

                currentActivity.startActivity(intent)
                result.success(null)

            } catch (e: ClassNotFoundException) {
                result.error("CLASS_NOT_FOUND", "GodotGameActivity not found. Check AndroidManifest.xml and class name.", e.message)
            }
        } else {
            result.notImplemented()
        }
    }

    // NEW: Called from native when game finishes
    fun notifyGameOver(score: Int) {
        val args = mapOf("score" to score)
        channel.invokeMethod("gameOver", args)
    }

    // --- Boilerplate code ---
    override fun onAttachedToActivity(binding: ActivityPluginBinding) { activity = binding.activity }
    override fun onDetachedFromActivity() { activity = null }
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) { activity = binding.activity }
    override fun onDetachedFromActivityForConfigChanges() { activity = null }
    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) { channel.setMethodCallHandler(null) }
}
