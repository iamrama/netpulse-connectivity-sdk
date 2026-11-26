/// The transport carrying the device's default network.
enum ConnectionType {
  /// Wi-Fi.
  wifi,

  /// Mobile data.
  cellular,

  /// Wired Ethernet.
  ethernet,

  /// A VPN whose underlying transport is not reported by the OS.
  vpn,

  /// Bluetooth tethering.
  bluetooth,

  /// A transport that fits no other value.
  other,

  /// No usable network.
  none,

  /// The transport could not be determined.
  unknown;

  /// Parses a [name], returning [unknown] for unrecognised values.
  static ConnectionType parse(Object? name) =>
      values.asNameMap()[name] ?? unknown;
}
