package com.example.netpulse

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.mockito.Mockito
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

internal class NetpulsePluginTest {
    @Test
    fun noNetworkMapsToNone() {
        val map = NetworkSnapshot.toMap(null, 42L)
        assertEquals("none", map["connectionType"])
        assertEquals("unavailable", map["internetStatus"])
        assertEquals(42L, map["timestamp"])
        assertNull(map["isMetered"])
    }

    @Test
    fun validatedWifiIsAvailable() {
        val facts = NetworkFacts(wifi = true, internet = true, validated = true)
        val map = NetworkSnapshot.toMap(facts, 0L)
        assertEquals("wifi", map["connectionType"])
        assertEquals("available", map["internetStatus"])
    }

    @Test
    fun unvalidatedNetworkIsUnknown() {
        val facts = NetworkFacts(cellular = true, internet = true)
        assertEquals("unknown", NetworkSnapshot.toMap(facts, 0L)["internetStatus"])
    }

    @Test
    fun captivePortalTakesPrecedence() {
        val facts = NetworkFacts(wifi = true, internet = true, captivePortal = true)
        assertEquals("captivePortal", NetworkSnapshot.toMap(facts, 0L)["internetStatus"])
    }

    @Test
    fun vpnReportsUnderlyingTransport() {
        val facts = NetworkFacts(cellular = true, vpn = true)
        val map = NetworkSnapshot.toMap(facts, 0L)
        assertEquals("cellular", map["connectionType"])
        assertEquals(true, map["isVpn"])
    }

    @Test
    fun callsBeforeAttachFail() {
        val result = Mockito.mock(MethodChannel.Result::class.java)
        NetpulsePlugin().onMethodCall(MethodCall("getCurrentState", null), result)
        Mockito.verify(result)
            .error("platformFailure", "NetPulse is not attached to an engine.", null)
    }
}
