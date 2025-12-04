package com.example.flutter_godot_bridge

import android.content.Context
import android.graphics.Color
import android.util.Log
import android.view.Gravity
import android.view.View
import android.widget.FrameLayout
import android.widget.TextView
import io.flutter.plugin.platform.PlatformView

class GodotPlatformView(
    private val context: Context,
    private val viewId: Int,
    private val params: Map<String, Any>?
) : PlatformView {

    companion object {
        private const val TAG = "GodotPlatformView"
    }

    private val containerView: FrameLayout = FrameLayout(context)

    init {
        Log.d(TAG, "GodotPlatformView created with ID: $viewId, params: $params")
        setupView()
    }

    private fun setupView() {
        try {
            // Try to load Godot via reflection to avoid compile-time dependencies
            val godotClass = Class.forName("org.godotengine.godot.Godot")
            Log.d(TAG, "Godot class found: $godotClass")

            // For now, show a placeholder with instructions
            val textView = TextView(context).apply {
                text = "Godot View (ID: $viewId)\n\n" +
                        "Godot Engine Detected!\n" +
                        "Full integration requires\n" +
                        "Godot-specific initialization"
                textSize = 18f
                setTextColor(Color.WHITE)
                setBackgroundColor(Color.parseColor("#2C3E50"))
                gravity = Gravity.CENTER
                setPadding(32, 32, 32, 32)
            }

            containerView.addView(textView, FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            ))

        } catch (e: ClassNotFoundException) {
            Log.e(TAG, "Godot class not found", e)
            showError("Godot engine not found in AAR")
        } catch (e: Exception) {
            Log.e(TAG, "Error setting up Godot view", e)
            showError("Error: ${e.message}")
        }
    }

    private fun showError(message: String) {
        val errorView = TextView(context).apply {
            text = "Godot View Error\n\n$message"
            textSize = 16f
            setTextColor(Color.RED)
            setBackgroundColor(Color.LTGRAY)
            gravity = Gravity.CENTER
            setPadding(32, 32, 32, 32)
        }

        containerView.removeAllViews()
        containerView.addView(errorView, FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.MATCH_PARENT
        ))
    }

    override fun getView(): View = containerView

    override fun dispose() {
        Log.d(TAG, "Disposing GodotPlatformView $viewId")
        containerView.removeAllViews()
    }
}
