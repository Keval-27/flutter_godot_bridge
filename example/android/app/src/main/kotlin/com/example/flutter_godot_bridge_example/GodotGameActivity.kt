package com.example.flutter_godot_bridge_example

import org.godotengine.godot.GodotActivity

class GodotGameActivity : GodotActivity() {

    companion object {
        init {
            System.loadLibrary("c++_shared")
        }
    }
    override fun getCommandLine(): MutableList<String> { // <-- UPDATED: Changed from List to MutableList
        val intentArgs = intent.getStringArrayListExtra("command_line_args")

        return intentArgs?.toMutableList() ?: super.getCommandLine()
    }
}
