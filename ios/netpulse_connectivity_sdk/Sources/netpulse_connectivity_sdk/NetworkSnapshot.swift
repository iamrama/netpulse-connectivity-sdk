import Foundation
import Network

/// Converts an `NWPath` into the map understood by the Dart layer.
enum NetworkSnapshot {
  /// Builds a snapshot of `path`.
  static func make(from path: NWPath, at date: Date = Date()) -> [String: Any] {
    let connected = path.status == .satisfied
    var map: [String: Any] = [
      "connectionType": connected ? connectionType(of: path) : "none",
      // A satisfied path proves a route exists, not that the internet is
      // reachable. The Dart layer verifies it.
      "internetStatus": connected ? "unknown" : "unavailable",
      "timestamp": Int64(date.timeIntervalSince1970 * 1000),
    ]
    // NWPath cannot reliably report VPN use, so "isVpn" is omitted.
    if connected {
      map["isMetered"] = path.isExpensive
      map["isConstrained"] = path.isConstrained
    }
    return map
  }

  private static func connectionType(of path: NWPath) -> String {
    // `availableInterfaces` is ordered by system preference.
    for interface in path.availableInterfaces where path.usesInterfaceType(interface.type) {
      switch interface.type {
      case .wifi: return "wifi"
      case .cellular: return "cellular"
      case .wiredEthernet: return "ethernet"
      default: continue
      }
    }
    if path.usesInterfaceType(.wifi) { return "wifi" }
    if path.usesInterfaceType(.wiredEthernet) { return "ethernet" }
    if path.usesInterfaceType(.cellular) { return "cellular" }
    return "other"
  }
}
