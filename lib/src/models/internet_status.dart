/// Whether the public internet can be reached over the current network.
enum InternetStatus {
  /// Confirmed by the operating system or by a NetPulse reachability probe.
  available,

  /// There is no network, or a probe could not reach the internet.
  unavailable,

  /// The network requires sign-in through a captive portal (Android only).
  captivePortal,

  /// A network exists but internet access has not been confirmed.
  unknown;

  /// Parses a [name], returning [unknown] for unrecognised values.
  static InternetStatus parse(Object? name) =>
      values.asNameMap()[name] ?? unknown;
}
