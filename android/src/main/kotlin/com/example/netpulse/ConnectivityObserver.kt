package com.example.netpulse

import android.content.Context
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel

/**
 * Streams changes of the default network to Dart.
 *
 * All methods must be called on the main thread. [ConnectivityManager]
 * delivers callbacks on a background thread, so they are posted back to it.
 */
internal class ConnectivityObserver(private val context: Context) : EventChannel.StreamHandler {
    private val mainHandler = Handler(Looper.getMainLooper())
    private var callback: ConnectivityManager.NetworkCallback? = null

    private val manager: ConnectivityManager
        get() = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager

    /** Returns the current state of the default network. */
    fun currentSnapshot(): Map<String, Any?> {
        val connectivity = manager
        val capabilities = connectivity.activeNetwork?.let(connectivity::getNetworkCapabilities)
        return snapshot(capabilities)
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        // A hot restart can listen again without cancelling first.
        stop()
        try {
            // Posted callbacks run after this method returns, so the initial
            // snapshot is always delivered first.
            events.success(currentSnapshot())
            val registered = object : ConnectivityManager.NetworkCallback() {
                override fun onCapabilitiesChanged(
                    network: Network,
                    networkCapabilities: NetworkCapabilities,
                ) {
                    deliver(this, events, snapshot(networkCapabilities))
                }

                override fun onLost(network: Network) {
                    deliver(this, events, snapshot(null))
                }
            }
            manager.registerDefaultNetworkCallback(registered)
            callback = registered
        } catch (error: RuntimeException) {
            // SecurityException, or too many callbacks registered by the app.
            events.error("platformFailure", error.message, null)
        }
    }

    override fun onCancel(arguments: Any?) = stop()

    /** Unregisters the network callback. Safe to call repeatedly. */
    fun stop() {
        val registered = callback ?: return
        callback = null
        try {
            manager.unregisterNetworkCallback(registered)
        } catch (_: IllegalArgumentException) {
            // The system had already unregistered it.
        }
    }

    private fun deliver(
        source: ConnectivityManager.NetworkCallback,
        events: EventChannel.EventSink,
        value: Map<String, Any?>,
    ) {
        mainHandler.post {
            // Drop events from a callback that has since been unregistered.
            if (callback === source) events.success(value)
        }
    }

    private fun snapshot(capabilities: NetworkCapabilities?): Map<String, Any?> {
        val facts = capabilities?.let {
            NetworkFacts(
                wifi = it.hasTransport(NetworkCapabilities.TRANSPORT_WIFI),
                cellular = it.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR),
                ethernet = it.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET),
                bluetooth = it.hasTransport(NetworkCapabilities.TRANSPORT_BLUETOOTH),
                vpn = it.hasTransport(NetworkCapabilities.TRANSPORT_VPN),
                internet = it.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET),
                validated = it.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED),
                captivePortal =
                    it.hasCapability(NetworkCapabilities.NET_CAPABILITY_CAPTIVE_PORTAL),
                metered = !it.hasCapability(NetworkCapabilities.NET_CAPABILITY_NOT_METERED),
                // Data Saver only restricts metered networks.
                dataSaverRestricted =
                    !it.hasCapability(NetworkCapabilities.NET_CAPABILITY_NOT_METERED) &&
                        manager.restrictBackgroundStatus ==
                        ConnectivityManager.RESTRICT_BACKGROUND_STATUS_ENABLED,
            )
        }
        return NetworkSnapshot.toMap(facts, System.currentTimeMillis())
    }
}
