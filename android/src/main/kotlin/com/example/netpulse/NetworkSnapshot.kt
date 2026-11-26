package com.example.netpulse

/** The facts NetPulse reads from a network's capabilities. */
data class NetworkFacts(
    val wifi: Boolean = false,
    val cellular: Boolean = false,
    val ethernet: Boolean = false,
    val bluetooth: Boolean = false,
    val vpn: Boolean = false,
    val internet: Boolean = false,
    val validated: Boolean = false,
    val captivePortal: Boolean = false,
    val metered: Boolean = false,
    val dataSaverRestricted: Boolean? = null,
)

/** Converts [NetworkFacts] into the map understood by the Dart layer. */
object NetworkSnapshot {
    /** Builds a snapshot. A null [facts] means there is no default network. */
    fun toMap(facts: NetworkFacts?, timestamp: Long): Map<String, Any?> {
        if (facts == null) {
            return mapOf(
                "connectionType" to "none",
                "internetStatus" to "unavailable",
                "timestamp" to timestamp,
                "isMetered" to null,
                "isConstrained" to null,
                "isVpn" to false,
            )
        }
        return mapOf(
            "connectionType" to connectionType(facts),
            "internetStatus" to internetStatus(facts),
            "timestamp" to timestamp,
            "isMetered" to facts.metered,
            "isConstrained" to facts.dataSaverRestricted,
            "isVpn" to facts.vpn,
        )
    }

    // A VPN usually also reports its underlying transport, which is preferred.
    private fun connectionType(facts: NetworkFacts): String = when {
        facts.wifi -> "wifi"
        facts.ethernet -> "ethernet"
        facts.cellular -> "cellular"
        facts.bluetooth -> "bluetooth"
        facts.vpn -> "vpn"
        else -> "other"
    }

    private fun internetStatus(facts: NetworkFacts): String = when {
        facts.captivePortal -> "captivePortal"
        !facts.internet -> "unavailable"
        facts.validated -> "available"
        else -> "unknown"
    }
}
