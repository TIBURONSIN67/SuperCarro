package com.plugin.godotlibrary

import android.util.Log
import android.widget.Toast
import org.godotengine.godot.BuildConfig
import org.godotengine.godot.Godot
import org.godotengine.godot.plugin.GodotPlugin
import org.godotengine.godot.plugin.UsedByGodot

class MainPlugin(godot: Godot) : GodotPlugin(godot) {

    override fun getPluginName() = "KotlinPlugin"

    @UsedByGodot
    fun helloWorld() {
        Toast.makeText(godot.getActivity(), "Hello from Kotlin!", Toast.LENGTH_SHORT).show()
    }
}
