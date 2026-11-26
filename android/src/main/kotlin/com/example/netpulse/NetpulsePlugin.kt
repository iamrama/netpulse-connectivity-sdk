package com.example.netpulse

import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** Registers the NetPulse channels with a Flutter engine. */
class NetpulsePlugin : FlutterPlugin, MethodCallHandler {
    private var context: Context? = null
    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var observer: ConnectivityObserver? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val applicationContext = binding.applicationContext
        context = applicationContext
        val connectivity = ConnectivityObserver(applicationContext)
        observer = connectivity
        methodChannel = MethodChannel(binding.binaryMessenger, "netpulse/methods").also {
            it.setMethodCallHandler(this)
        }
        eventChannel = EventChannel(binding.binaryMessenger, "netpulse/connectivity").also {
            it.setStreamHandler(connectivity)
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        val applicationContext = context
        val connectivity = observer
        if (applicationContext == null || connectivity == null) {
            result.error("platformFailure", "NetPulse is not attached to an engine.", null)
            return
        }
        when (call.method) {
            "getCurrentState" -> try {
                result.success(connectivity.currentSnapshot())
            } catch (error: RuntimeException) {
                result.error("platformFailure", error.message, null)
            }
            // Excluded from cloud backup: history describes this device only.
            "getStorageDirectory" ->
                result.success(applicationContext.noBackupFilesDir.absolutePath)
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel?.setMethodCallHandler(null)
        eventChannel?.setStreamHandler(null)
        observer?.stop()
        methodChannel = null
        eventChannel = null
        observer = null
        context = null
    }
}
