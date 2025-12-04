package com.example.flutter_godot_bridge

import android.content.Context
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlin.coroutines.resume

class CommunicationBridge(private val channel: MethodChannel) {

    suspend fun initializeGodot(context: Context, config: Map<String, Any>): Boolean {
        return suspendCancellableCoroutine { continuation ->
            try {
                val projectPath = config["projectPath"] as? String ?: ""
                val result = nativeInitializeGodot(context, projectPath)
                continuation.resume(result)
            } catch (e: Exception) {
                continuation.resume(false)
            }
        }
    }

    suspend fun sendMessage(channel: String, data: Map<String, Any>, timestamp: Long): Boolean {
        return suspendCancellableCoroutine { continuation ->
            try {
                val result = nativeSendMessage(channel, data, timestamp)
                continuation.resume(result)
            } catch (e: Exception) {
                continuation.resume(false)
            }
        }
    }

    suspend fun sendMessageSync(channel: String, data: Map<String, Any>, timestamp: Long): Map<String, Any>? {
        return suspendCancellableCoroutine { continuation ->
            try {
                val result = nativeSendMessageSync(channel, data, timestamp)
                continuation.resume(result)
            } catch (e: Exception) {
                continuation.resume(null)
            }
        }
    }

    fun getPerformanceMetrics(): Map<String, Any> {
        return try {
            nativeGetPerformanceMetrics() ?: emptyMap()
        } catch (e: Exception) {
            emptyMap()
        }
    }

    fun dispose(): Boolean {
        return try {
            nativeDispose()
        } catch (e: Exception) {
            false
        }
    }

    // Native methods (implement these in your C++ code)
    private external fun nativeInitializeGodot(context: Context, projectPath: String): Boolean
    private external fun nativeSendMessage(channel: String, data: Map<String, Any>, timestamp: Long): Boolean
    private external fun nativeSendMessageSync(channel: String, data: Map<String, Any>, timestamp: Long): Map<String, Any>?
    private external fun nativeGetPerformanceMetrics(): Map<String, Any>?
    private external fun nativeDispose(): Boolean
}
